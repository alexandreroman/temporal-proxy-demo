package main

import (
	"cmp"
	"context"
	"fmt"
	"log/slog"
	"net/http"

	"github.com/alexandreroman/temporal-proxy-demo/internal/hello"
	"github.com/google/uuid"
	"go.temporal.io/sdk/client"
)

// defaultName is greeted when the request carries no name.
const defaultName = "Temporal"

// greeter runs one greeting and returns its result. The HTTP layer depends on this function
// rather than on a Temporal client, which keeps the handler testable without a server.
type greeter func(ctx context.Context, name string) (string, error)

func helloHandler(greet greeter) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// cmp.Or falls back to the default for both a missing and an empty name.
		name := cmp.Or(r.URL.Query().Get("name"), defaultName)

		greeting, err := greet(r.Context(), name)
		if err != nil {
			slog.Error("greeting failed", "name", name, "error", err)
			http.Error(w, "greeting failed", http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
		fmt.Fprintln(w, greeting)
	}
}

// newWorkflowID returns the identifier of one Workflow Execution. The prefix makes the
// Execution recognizable in the Temporal Web UI, and the random suffix lets the demo be
// replayed without colliding with an earlier Execution.
func newWorkflowID() string {
	return "hello-" + uuid.NewString()
}

// startHelloWorkflow starts one Workflow Execution and waits for its result.
func startHelloWorkflow(c client.Client) greeter {
	return func(ctx context.Context, name string) (string, error) {
		options := client.StartWorkflowOptions{
			ID:        newWorkflowID(),
			TaskQueue: hello.TaskQueue,
		}

		run, err := c.ExecuteWorkflow(ctx, options, hello.HelloWorkflow, name)
		if err != nil {
			return "", fmt.Errorf("start hello workflow: %w", err)
		}
		slog.Info("workflow started", "workflow_id", run.GetID(), "run_id", run.GetRunID())

		var greeting string
		if err := run.Get(ctx, &greeting); err != nil {
			return "", fmt.Errorf("wait for workflow %s: %w", run.GetID(), err)
		}
		return greeting, nil
	}
}
