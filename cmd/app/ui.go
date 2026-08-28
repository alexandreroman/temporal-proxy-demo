package main

import (
	"embed"
	"html/template"
	"log/slog"
	"net/http"
	"os"
)

//go:embed templates/*.html
var templateFiles embed.FS

// pages is parsed once at startup, so a broken template fails the process instead of the first
// request that reaches it. Embedding them means the binary carries its own page.
var pages = template.Must(template.ParseFS(templateFiles, "templates/*.html"))

// pageData is what the page needs to render. Target is a display label for where Workflow
// Executions end up, supplied by the deployment: the application cannot work it out from its
// own connection.
type pageData struct {
	Target string
}

func pageHandler() http.HandlerFunc {
	// Read once: the label is deployment configuration, fixed for the lifetime of the process.
	// An unset variable leaves it empty, which the page renders as "unknown" rather than
	// guessing a value the application has no way to know.
	data := pageData{Target: os.Getenv("TEMPORAL_TARGET")}

	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/html; charset=utf-8")

		// The status line is already sent, so a rendering failure can only be logged.
		if err := pages.ExecuteTemplate(w, "index.html", data); err != nil {
			slog.Error("rendering the page failed", "error", err)
		}
	}
}
