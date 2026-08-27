// Command api exposes the hello Workflow over HTTP.
//
// POST /hello starts one Workflow Execution, waits for its result and writes the greeting
// back. Like the Worker, it only knows a plaintext local Temporal endpoint.
package main

import (
	"cmp"
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/alexandreroman/temporal-proxy-demo/internal/temporalclient"
)

const (
	defaultPort     = "8080"
	shutdownTimeout = 10 * time.Second
)

func main() {
	// Text output rather than JSON: this demo is watched in a terminal.
	slog.SetDefault(slog.New(slog.NewTextHandler(os.Stdout, nil)))

	if err := run(); err != nil {
		slog.Error("api stopped", "error", err)
		os.Exit(1)
	}
}

func run() error {
	ctx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	c, err := temporalclient.Dial(ctx)
	if err != nil {
		return err
	}
	defer c.Close()

	srv := &http.Server{
		// Bind every interface so the API is reachable from outside its container.
		Addr:              net.JoinHostPort("0.0.0.0", cmp.Or(os.Getenv("PORT"), defaultPort)),
		Handler:           newMux(startHelloWorkflow(c)),
		ReadHeaderTimeout: 5 * time.Second,
	}

	serveErr := make(chan error, 1)
	go func() { serveErr <- srv.ListenAndServe() }()
	slog.Info("api started", "address", srv.Addr)

	select {
	case err := <-serveErr:
		if !errors.Is(err, http.ErrServerClosed) {
			return fmt.Errorf("serve http: %w", err)
		}
		return nil
	case <-ctx.Done():
		return shutdown(srv)
	}
}

// shutdown lets in-flight requests finish before the process exits.
func shutdown(srv *http.Server) error {
	slog.Info("shutting down")

	ctx, cancel := context.WithTimeout(context.Background(), shutdownTimeout)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		return fmt.Errorf("shut down http server: %w", err)
	}
	return nil
}

func newMux(greet greeter) *http.ServeMux {
	mux := http.NewServeMux()
	// The method in the pattern makes the mux answer 405 to anything but POST.
	mux.HandleFunc("POST /hello", helloHandler(greet))
	return mux
}
