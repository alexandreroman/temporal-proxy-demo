package hello

import (
	"context"
	"fmt"
	"time"

	"go.temporal.io/sdk/activity"
)

// greetDelay stands in for real work. It is a variable so tests do not have to wait for it.
var greetDelay = 2 * time.Second

// Greet returns a greeting for req.Name once the simulated work is done.
func Greet(ctx context.Context, req Request) (Response, error) {
	activity.GetLogger(ctx).Info("Greeting", "name", req.Name)

	// Honour cancellation: a bare time.Sleep would keep the Worker busy after the
	// Workflow gave up on this Activity.
	select {
	case <-time.After(greetDelay):
		return Response{Greeting: fmt.Sprintf("Hello, %s!", req.Name)}, nil
	case <-ctx.Done():
		return Response{}, fmt.Errorf("greet %s: %w", req.Name, ctx.Err())
	}
}
