package main

import (
	"cmp"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
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
type greeter func(ctx context.Context, req hello.Request) (hello.Response, error)

func helloHandler(greet greeter) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		req, err := decodeRequest(r)
		if err != nil {
			slog.Warn("rejecting request", "error", err)
			http.Error(w, "invalid request body", http.StatusBadRequest)
			return
		}

		res, err := greet(r.Context(), req)
		if err != nil {
			slog.Error("greeting failed", "name", req.Name, "error", err)
			http.Error(w, "greeting failed", http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		if err := json.NewEncoder(w).Encode(res); err != nil {
			slog.Error("writing response failed", "error", err)
		}
	}
}

// decodeRequest reads the JSON body and falls back to defaultName when it carries no
// name. Fields hello.Request does not declare are ignored, so a client may send more
// than this version reads.
func decodeRequest(r *http.Request) (hello.Request, error) {
	var req hello.Request

	// An empty body reads as io.EOF and is as valid as `{}`: greet whoever is the default.
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil && !errors.Is(err, io.EOF) {
		return hello.Request{}, fmt.Errorf("decode hello request: %w", err)
	}

	req.Name = cmp.Or(req.Name, defaultName)
	return req, nil
}

// newWorkflowID returns the identifier of one Workflow Execution. The prefix makes the
// Execution recognizable in the Temporal Web UI, and the random suffix lets the demo be
// replayed without colliding with an earlier Execution.
func newWorkflowID() string {
	return "hello-" + uuid.NewString()
}

// startHelloWorkflow starts one Workflow Execution and waits for its result.
func startHelloWorkflow(c client.Client) greeter {
	return func(ctx context.Context, req hello.Request) (hello.Response, error) {
		options := client.StartWorkflowOptions{
			ID:        newWorkflowID(),
			TaskQueue: hello.TaskQueue,
		}

		run, err := c.ExecuteWorkflow(ctx, options, hello.HelloWorkflow, req)
		if err != nil {
			return hello.Response{}, fmt.Errorf("start hello workflow: %w", err)
		}
		slog.Info("workflow started", "workflow_id", run.GetID(), "run_id", run.GetRunID())

		var res hello.Response
		if err := run.Get(ctx, &res); err != nil {
			return hello.Response{}, fmt.Errorf("wait for workflow %s: %w", run.GetID(), err)
		}
		return res, nil
	}
}
