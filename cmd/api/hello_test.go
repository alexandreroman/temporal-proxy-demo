package main

import (
	"context"
	"errors"
	"net/http"
	"net/http/httptest"
	"testing"
)

// fakeGreeter records the name it was called with, so the tests can check what the HTTP
// layer would have sent to Temporal. No Temporal server is involved.
type fakeGreeter struct {
	called bool
	name   string
	err    error
}

func (f *fakeGreeter) greet(_ context.Context, name string) (string, error) {
	f.called = true
	f.name = name
	if f.err != nil {
		return "", f.err
	}
	return "Hello, " + name + "!", nil
}

func TestHelloEndpoint(t *testing.T) {
	tests := []struct {
		name     string
		target   string
		wantName string
		wantBody string
	}{
		{"name from the query", "/hello?name=Ada", "Ada", "Hello, Ada!\n"},
		{"missing name", "/hello", defaultName, "Hello, Temporal!\n"},
		{"empty name", "/hello?name=", defaultName, "Hello, Temporal!\n"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			var fake fakeGreeter
			rec := httptest.NewRecorder()
			newMux(fake.greet).ServeHTTP(rec, httptest.NewRequest(http.MethodPost, tt.target, nil))

			if rec.Code != http.StatusOK {
				t.Fatalf("status = %d, want %d", rec.Code, http.StatusOK)
			}
			if fake.name != tt.wantName {
				t.Errorf("greeted name = %q, want %q", fake.name, tt.wantName)
			}
			if rec.Body.String() != tt.wantBody {
				t.Errorf("body = %q, want %q", rec.Body.String(), tt.wantBody)
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
