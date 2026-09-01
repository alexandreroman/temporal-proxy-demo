// Package hello holds the demo Workflow and the Activity it calls.
package hello

import (
	"fmt"
	"time"

	"go.temporal.io/sdk/temporal"
	"go.temporal.io/sdk/workflow"
)

// TaskQueue is the queue the Worker polls and the HTTP API targets.
const TaskQueue = "hello-workflow"

// Request is what the Workflow and the Greet Activity are given. The JSON tags are
// explicit because the same shape travels over HTTP and through Temporal payloads.
type Request struct {
	Name string `json:"name"`
}

// Response is what the Workflow and the Greet Activity both return.
type Response struct {
	Greeting string `json:"greeting"`
}

// HelloWorkflow greets req.Name by running the Greet Activity once.
func HelloWorkflow(ctx workflow.Context, req Request) (Response, error) {
	ctx = workflow.WithActivityOptions(ctx, workflow.ActivityOptions{
		// Comfortably above the Activity's own delay, so a slow Activity is not a timeout.
		StartToCloseTimeout: 10 * time.Second,
		// Temporal retries forever by default. A demo bounds it: after three attempts the
		// failure surfaces instead of leaving the caller waiting.
		RetryPolicy: &temporal.RetryPolicy{MaximumAttempts: 3},
	})

	workflow.GetLogger(ctx).Info("Starting hello workflow", "name", req.Name)

	var res Response
	if err := workflow.ExecuteActivity(ctx, Greet, req).Get(ctx, &res); err != nil {
		return Response{}, fmt.Errorf("execute Greet activity: %w", err)
	}
	return res, nil
}
