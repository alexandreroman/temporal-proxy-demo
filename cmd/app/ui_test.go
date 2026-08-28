package main

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

// No t.Parallel here: these cases set TEMPORAL_TARGET, which pageHandler reads when newMux
// builds it.
func TestPage(t *testing.T) {
	tests := []struct {
		name   string
		target string
	}{
		{"target supplied", "cloud"},
		// Unset means the deployment said nothing, and the page has to render anyway.
		{"target unset", ""},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Setenv("TEMPORAL_TARGET", tt.target)

			var fake fakeGreeter
			rec := httptest.NewRecorder()
			newMux(fake.greet).ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/", nil))

			if rec.Code != http.StatusOK {
				t.Fatalf("status = %d, want %d", rec.Code, http.StatusOK)
			}
			if got, want := rec.Header().Get("Content-Type"), "text/html; charset=utf-8"; got != want {
				t.Errorf("content type = %q, want %q", got, want)
			}
			if tt.target != "" && !strings.Contains(rec.Body.String(), tt.target) {
				t.Errorf("body does not mention the target %q", tt.target)
			}
		})
	}
}

// "GET /{$}" matches the root and nothing else, so the page never swallows a wrong URL.
func TestPageOnlyServesTheRoot(t *testing.T) {
	t.Parallel()

	var fake fakeGreeter
	rec := httptest.NewRecorder()
	newMux(fake.greet).ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/nope", nil))

	if rec.Code != http.StatusNotFound {
		t.Fatalf("status = %d, want %d", rec.Code, http.StatusNotFound)
	}
}
