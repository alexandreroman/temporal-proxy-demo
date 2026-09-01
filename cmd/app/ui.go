package main

import (
	"embed"
	"html/template"
	"log/slog"
	"net/http"

	"github.com/alexandreroman/temporal-proxy-demo/internal/temporalclient"
)

//go:embed templates/*.html
var templateFiles embed.FS

// pages is parsed once at startup, so a broken template fails the process instead of the first
// request that reaches it. Embedding them means the binary carries its own page.
var pages = template.Must(template.ParseFS(templateFiles, "templates/*.html"))

func pageHandler() http.HandlerFunc {
	// The endpoint is the address the application dials and the short Namespace name it asks for:
	// the whole of what it knows about where it connects, so the whole of what the page can show.
	// Read once, because it is deployment configuration, fixed for the lifetime of the process.
	// Resolving it the same way the client does is what keeps the page honest — it shows the pair
	// that was dialled, and cannot go stale against the deployment it is running in.
	endpoint := temporalclient.ResolveEndpoint()

	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/html; charset=utf-8")

		// The status line is already sent, so a rendering failure can only be logged.
		if err := pages.ExecuteTemplate(w, "index.html", endpoint); err != nil {
			slog.Error("rendering the page failed", "error", err)
		}
	}
}
