// Package hello holds the demo Workflow and the Activity it calls.
package hello

import (
	"fmt"
	"time"

	"go.temporal.io/sdk/workflow"
)

// TaskQueue is the queue the Worker polls and the HTTP API targets.
const TaskQueue = "hello-workflow"

// HelloWorkflow greets name by running the Greet Activity once.
func HelloWorkflow(ctx workflow.Context, name string) (string, error) {
	ctx = workflow.WithActivityOptions(ctx, workflow.ActivityOptions{
		// Comfortably above the Activity's own delay, so a slow Activity is not a timeout.
		StartToCloseTimeout: 10 * time.Second,
	})

	workflow.GetLogger(ctx).Info("Starting hello workflow", "name", name)

	var greeting string
	if err := workflow.ExecuteActivity(ctx, Greet, name).Get(ctx, &greeting); err != nil {
		return "", fmt.Errorf("execute Greet activity: %w", err)
	}
	return greeting, nil
}
