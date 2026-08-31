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

// What the page shows, as opposed to how it marks it up: the caption's address sits in an element
// of its own, so the tags come out and the whitespace they leave behind is collapsed.
func shownText(body string) string {
	return whitespace.ReplaceAllString(htmlTag.ReplaceAllString(body, " "), " ")
}

// No t.Parallel here: these cases set the environment variables pageHandler reads when newMux
// builds it.
func TestPage(t *testing.T) {
	tests := []struct {
		name      string
		address   string
		namespace string
		// The caption both endpoint stations carry, which is the resolved pair as the page shows
		// it. The caption is a list of three items, and the bullet in front of each one is
		// supplied by the stylesheet, so what the markup holds is the three values in order.
		// Matching the whole caption rather than each value keeps the case from passing on a
		// coincidence: "demo" alone also occurs inside the page's own script.
		wantCaption string
	}{
		{
			name:        "endpoint supplied",
			address:     "temporal.example:7233",
			namespace:   "demo",
			wantCaption: `temporal.example:7233 plaintext namespace "demo"`,
		},
		{
			// Both unset: the fallbacks in the code, which are what a Temporal dev server serves.
			name:        "endpoint unset",
			wantCaption: `localhost:7233 plaintext namespace "default"`,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Setenv("TEMPORAL_ADDRESS", tt.address)
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
