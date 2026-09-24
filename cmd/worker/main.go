// Command worker runs the Temporal Worker of the hello-workflow demo.
//
// It polls the hello-workflow task queue over a plaintext local Temporal endpoint: no
// credential, no TLS material and no fully-qualified Namespace live in this binary.
package main

import (
	"context"
	"fmt"
	"log/slog"
	"os"

	"github.com/alexandreroman/temporal-proxy-demo/internal/hello"
	"github.com/alexandreroman/temporal-proxy-demo/internal/temporalclient"
	"go.temporal.io/sdk/worker"
)

func main() {
	// Text output rather than JSON: this demo is watched in a terminal.
	slog.SetDefault(slog.New(slog.NewTextHandler(os.Stdout, nil)))

	if err := run(); err != nil {
		slog.Error("worker stopped", "error", err)
		os.Exit(1)
	}
}

func run() error {
	c, err := temporalclient.Dial(context.Background())
	if err != nil {
		return err
	}
	defer c.Close()

	w := worker.New(c, hello.TaskQueue, worker.Options{})
	w.RegisterWorkflow(hello.HelloWorkflow)
	w.RegisterActivity(hello.Greet)

	slog.Info("worker started", "task_queue", hello.TaskQueue)

	// Runs until SIGINT or SIGTERM.
	if err := w.Run(worker.InterruptCh()); err != nil {
		return fmt.Errorf("run worker: %w", err)
	}
	return nil
}
