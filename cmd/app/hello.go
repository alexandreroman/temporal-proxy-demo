package main

import (
	"cmp"
	"context"
	"crypto/rand"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/http"

	"github.com/alexandreroman/temporal-proxy-demo/internal/hello"
	"go.temporal.io/sdk/client"
)

const (
	// defaultName is greeted when the request carries no name.
	defaultName = "John Doe"

	// maxRequestBody caps how much of a request body is read: a name needs a fraction of it.
	maxRequestBody = 1 << 20
)

// execution names the Workflow Execution that produced a greeting, and carries the JSON names
// those identifiers go out under. The Workflow itself does not report them — they belong to the
// Execution, not to its result.
type execution struct {
	WorkflowID string `json:"workflowId"`
	RunID      string `json:"runId"`
}

// greeter runs one greeting and returns its result, plus the Execution that produced it. The
// HTTP layer depends on this function rather than on a Temporal client, which keeps the
// handler testable without a server.
type greeter func(ctx context.Context, req hello.Request) (hello.Response, execution, error)

// helloResponse is the JSON body of a successful request. Both embedded types contribute their
// own fields, flattened into one object, so the greeting and the two identifiers sit side by
// side in the body.
type helloResponse struct {
	hello.Response
	execution
}

func helloHandler(greet greeter) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		r.Body = http.MaxBytesReader(w, r.Body, maxRequestBody)

		req, err := decodeRequest(r)
		if err != nil {
			slog.Warn("rejecting request", "error", err)
			http.Error(w, "invalid request body", http.StatusBadRequest)
			return
		}

		res, exec, err := greet(r.Context(), req)
		if err != nil {
			slog.Error("greeting failed", "name", req.Name, "error", err)
			http.Error(w, "greeting failed", http.StatusInternalServerError)
			return
		}

		body := helloResponse{res, exec}

		w.Header().Set("Content-Type", "application/json")
		if err := json.NewEncoder(w).Encode(body); err != nil {
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

// startHelloWorkflow starts one Workflow Execution and waits for its result.
func startHelloWorkflow(c client.Client) greeter {
	return func(ctx context.Context, req hello.Request) (hello.Response, execution, error) {
		options := client.StartWorkflowOptions{
			ID:        "hello-" + rand.Text(), // Recognizable in the Web UI, and unique across replays.
			TaskQueue: hello.TaskQueue,
		}

		run, err := c.ExecuteWorkflow(ctx, options, hello.HelloWorkflow, req)
		if err != nil {
			return hello.Response{}, execution{}, fmt.Errorf("start hello workflow: %w", err)
		}

		exec := execution{WorkflowID: run.GetID(), RunID: run.GetRunID()}
		slog.Info("workflow started", "workflow_id", exec.WorkflowID, "run_id", exec.RunID)

		var res hello.Response
		if err := run.Get(ctx, &res); err != nil {
			return hello.Response{}, execution{}, fmt.Errorf("wait for workflow %s: %w", exec.WorkflowID, err)
		}
		return res, exec, nil
	}
}
