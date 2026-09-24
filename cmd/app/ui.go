package main

import (
	_ "embed"
	"html/template"
	"log/slog"
	"net/http"

	"github.com/alexandreroman/temporal-proxy-demo/internal/temporalclient"
)

//go:embed templates/index.html
var indexHTML string

// page is parsed once at startup, so a broken template fails the process instead of the first
// request that reaches it. Embedding it means the binary carries its own page.
var page = template.Must(template.New("index").Parse(indexHTML))

func pageHandler() http.HandlerFunc {
	// Read once, and resolved the same way the client does, so the page cannot go stale. The
	// Namespace is all the page shows of the endpoint.
	namespace := temporalclient.ResolveEndpoint().Namespace

	return func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/html; charset=utf-8")

		// The status line is already sent, so a rendering failure can only be logged.
		if err := page.Execute(w, namespace); err != nil {
			slog.Error("rendering the page failed", "error", err)
		}
	}
}
