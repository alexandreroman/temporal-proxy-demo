package main

import (
	"net/http"
	"net/http/httptest"
	"regexp"
	"strings"
	"testing"
)

var (
	htmlTag    = regexp.MustCompile(`<[^>]*>`)
	whitespace = regexp.MustCompile(`\s+`)
)

// What the page shows, as opposed to how it marks it up: each caption item sits in an element of
// its own, so the tags come out and the whitespace they leave behind is collapsed.
func shownText(body string) string {
	return whitespace.ReplaceAllString(htmlTag.ReplaceAllString(body, " "), " ")
}

// No t.Parallel here: these cases set the environment variable pageHandler reads when newMux
// builds it.
func TestPage(t *testing.T) {
	tests := []struct {
		name      string
		namespace string
		// Two caption items, not the Namespace alone: "demo" by itself also occurs in the page's
		// own script.
		wantCaption string
	}{
		{
			name:        "namespace supplied",
			namespace:   "demo",
			wantCaption: `plaintext namespace "demo"`,
		},
		{
			// Empty reads as unset, so the code falls back to what a Temporal dev server serves.
			name:        "namespace empty",
			wantCaption: `plaintext namespace "default"`,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Setenv("TEMPORAL_NAMESPACE", tt.namespace)

			var fake fakeGreeter
			rec := httptest.NewRecorder()
			newMux(fake.greet).ServeHTTP(rec, httptest.NewRequest(http.MethodGet, "/", nil))

			if rec.Code != http.StatusOK {
				t.Fatalf("status = %d, want %d", rec.Code, http.StatusOK)
			}
			if got, want := rec.Header().Get("Content-Type"), "text/html; charset=utf-8"; got != want {
				t.Errorf("content type = %q, want %q", got, want)
			}
			if !strings.Contains(shownText(rec.Body.String()), tt.wantCaption) {
				t.Errorf("body does not show the endpoint caption %q", tt.wantCaption)
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
