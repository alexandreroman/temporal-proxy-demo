// Package hello holds the demo Workflow and the Activity it calls.
package hello

import (
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
		// Activities retry without limit by default. A demo bounds it: after three attempts the
		// Activity's failure fails the Workflow.
		RetryPolicy: &temporal.RetryPolicy{MaximumAttempts: 3},
	})

	workflow.GetLogger(ctx).Info("hello workflow started", "name", req.Name)

	var res Response
	if err := workflow.ExecuteActivity(ctx, Greet, req).Get(ctx, &res); err != nil {
		return Response{}, err
	}
	return res, nil
}
