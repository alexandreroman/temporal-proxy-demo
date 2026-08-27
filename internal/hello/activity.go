package hello

import (
	"context"
	"fmt"
	"time"

	"go.temporal.io/sdk/activity"
)

// greetDelay stands in for real work. It is a variable so tests do not have to wait for it.
var greetDelay = 2 * time.Second

// Greet returns a greeting for name once the simulated work is done.
func Greet(ctx context.Context, name string) (string, error) {
	activity.GetLogger(ctx).Info("Greeting", "name", name)

	// Honour cancellation: a bare time.Sleep would keep the Worker busy after the
	// Workflow gave up on this Activity.
	select {
	case <-time.After(greetDelay):
		return fmt.Sprintf("Hello, %s!", name), nil
	case <-ctx.Done():
		return "", fmt.Errorf("greet %s: %w", name, ctx.Err())
	}
}
