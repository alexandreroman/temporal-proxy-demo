package main

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/alexandreroman/temporal-proxy-demo/internal/hello"
	"github.com/google/uuid"
)

// fakeGreeter records the request it was called with, so the tests can check what the HTTP
// layer would have sent to Temporal. No Temporal server is involved.
type fakeGreeter struct {
	called bool
	req    hello.Request
	err    error
}

func (f *fakeGreeter) greet(_ context.Context, req hello.Request) (hello.Response, error) {
	f.called = true
	f.req = req
	if f.err != nil {
		return hello.Response{}, f.err
	}
	return hello.Response{Greeting: "Hello, " + req.Name + "!"}, nil
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

			var res hello.Response
			if err := json.NewDecoder(rec.Body).Decode(&res); err != nil {
				t.Fatalf("decoding response body: %v", err)
			}
			if want := "Hello, " + tt.wantName + "!"; res.Greeting != want {
				t.Errorf("greeting = %q, want %q", res.Greeting, want)
			}
		})
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

func TestNewWorkflowID(t *testing.T) {
	t.Parallel()

	id := newWorkflowID()

	suffix, ok := strings.CutPrefix(id, "hello-")
	if !ok {
		t.Fatalf("workflow ID = %q, want a %q prefix", id, "hello-")
	}
	if _, err := uuid.Parse(suffix); err != nil {
		t.Errorf("workflow ID suffix %q is not a UUID: %v", suffix, err)
	}
}

func TestNewWorkflowIDIsUnique(t *testing.T) {
	t.Parallel()

	if first, second := newWorkflowID(), newWorkflowID(); first == second {
		t.Errorf("two workflow IDs are equal: %q", first)
	}
}
