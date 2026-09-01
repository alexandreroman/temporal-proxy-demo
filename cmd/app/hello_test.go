package main

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"reflect"
	"strings"
	"testing"

	"github.com/alexandreroman/temporal-proxy-demo/internal/hello"
)

// fakeGreeter records the request it was called with, so the tests can check what the HTTP
// layer would have sent to Temporal. No Temporal server is involved.
type fakeGreeter struct {
	called bool
	req    hello.Request
	err    error
}

func (f *fakeGreeter) greet(_ context.Context, req hello.Request) (hello.Response, execution, error) {
	f.called = true
	f.req = req
	if f.err != nil {
		return hello.Response{}, execution{}, f.err
	}

	res := hello.Response{Greeting: "Hello, " + req.Name + "!"}
	exec := execution{WorkflowID: "hello-" + req.Name, RunID: "run-1"}
	return res, exec, nil
}

func TestHelloEndpoint(t *testing.T) {
	tests := []struct {
		name     string
		body     io.Reader
		wantName string
	}{
		{"name in the body", strings.NewReader(`{"name": "Ada"}`), "Ada"},
		{"extra field alongside the name", strings.NewReader(`{"name": "Ada", "nickname": "A"}`), "Ada"},
		{"no body at all", nil, defaultName},
		{"empty body", strings.NewReader(""), defaultName},
		{"empty object", strings.NewReader(`{}`), defaultName},
		{"empty name", strings.NewReader(`{"name": ""}`), defaultName},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			var fake fakeGreeter
			rec := httptest.NewRecorder()
			req := httptest.NewRequest(http.MethodPost, "/hello", tt.body)
			req.Header.Set("Content-Type", "application/json")
			newMux(fake.greet).ServeHTTP(rec, req)

			if rec.Code != http.StatusOK {
				t.Fatalf("status = %d, want %d", rec.Code, http.StatusOK)
			}
			if got, want := rec.Header().Get("Content-Type"), "application/json"; got != want {
				t.Errorf("Content-Type = %q, want %q", got, want)
			}
			if fake.req.Name != tt.wantName {
				t.Errorf("greeted name = %q, want %q", fake.req.Name, tt.wantName)
			}

			var res helloResponse
			if err := json.NewDecoder(rec.Body).Decode(&res); err != nil {
				t.Fatalf("decoding response body: %v", err)
			}
			if want := "Hello, " + tt.wantName + "!"; res.Greeting != want {
				t.Errorf("greeting = %q, want %q", res.Greeting, want)
			}
			if want := "hello-" + tt.wantName; res.WorkflowID != want {
				t.Errorf("workflow ID = %q, want %q", res.WorkflowID, want)
			}
			if want := "run-1"; res.RunID != want {
				t.Errorf("run ID = %q, want %q", res.RunID, want)
			}
		})
	}
}

// The page reads two field names off the body, "greeting" and "workflowId", and "runId"
// completes the Execution's identity on the wire. All three sit flat, so the embedded
// hello.Response has to contribute a "greeting" and not a nested object.
func TestHelloEndpointBodyFields(t *testing.T) {
	t.Parallel()

	var fake fakeGreeter
	rec := httptest.NewRecorder()
	newMux(fake.greet).ServeHTTP(rec, httptest.NewRequest(http.MethodPost, "/hello", nil))

	var got map[string]any
	if err := json.Unmarshal(rec.Body.Bytes(), &got); err != nil {
		t.Fatalf("decode body %q: %v", rec.Body.String(), err)
	}

	want := map[string]any{
		"greeting":   "Hello, " + defaultName + "!",
		"workflowId": "hello-" + defaultName,
		"runId":      "run-1",
	}
	if !reflect.DeepEqual(got, want) {
		t.Errorf("body = %v, want %v", got, want)
	}
}

func TestHelloEndpointRejectsInvalidBody(t *testing.T) {
	t.Parallel()

	tests := []struct {
		name string
		body string
	}{
		{"not json", `Ada`},
		{"truncated", `{"name": "Ada"`},
		{"wrong type", `{"name": 42}`},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			var fake fakeGreeter
			rec := httptest.NewRecorder()
			req := httptest.NewRequest(http.MethodPost, "/hello", strings.NewReader(tt.body))
			newMux(fake.greet).ServeHTTP(rec, req)

			if rec.Code != http.StatusBadRequest {
				t.Fatalf("status = %d, want %d", rec.Code, http.StatusBadRequest)
			}
			if fake.called {
				t.Error("greeter was called, want no workflow started")
			}
			if got, want := rec.Header().Get("Content-Type"), "text/plain; charset=utf-8"; got != want {
				t.Errorf("content type = %q, want %q", got, want)
			}
		})
	}
}

func TestHelloEndpointRejectsNonPost(t *testing.T) {
	t.Parallel()

	for _, method := range []string{http.MethodGet, http.MethodPut, http.MethodDelete} {
		t.Run(method, func(t *testing.T) {
			t.Parallel()

			var fake fakeGreeter
			rec := httptest.NewRecorder()
			newMux(fake.greet).ServeHTTP(rec, httptest.NewRequest(method, "/hello", nil))

			if rec.Code != http.StatusMethodNotAllowed {
				t.Fatalf("status = %d, want %d", rec.Code, http.StatusMethodNotAllowed)
			}
			if fake.called {
				t.Error("greeter was called, want no workflow started")
			}
		})
	}
}

func TestHelloEndpointGreetingFails(t *testing.T) {
	t.Parallel()

	fake := fakeGreeter{err: errors.New("workflow failed")}
	rec := httptest.NewRecorder()
	newMux(fake.greet).ServeHTTP(rec, httptest.NewRequest(http.MethodPost, "/hello", nil))

	if rec.Code != http.StatusInternalServerError {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusInternalServerError)
	}
}
