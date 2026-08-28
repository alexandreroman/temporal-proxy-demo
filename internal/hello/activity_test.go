package hello

import (
	"context"
	"testing"
	"time"

	"go.temporal.io/sdk/testsuite"
	"go.temporal.io/sdk/worker"
)

func TestGreet(t *testing.T) {
	setGreetDelay(t, time.Millisecond)

	var suite testsuite.WorkflowTestSuite
	env := suite.NewTestActivityEnvironment()
	env.RegisterActivity(Greet)

	result, err := env.ExecuteActivity(Greet, Request{Name: "Ada"})
	if err != nil {
		t.Fatalf("ExecuteActivity() error = %v, want nil", err)
	}

	var got Response
	if err := result.Get(&got); err != nil {
		t.Fatalf("Get() error = %v, want nil", err)
	}
	if want := (Response{Greeting: "Hello, Ada!"}); got != want {
		t.Errorf("response = %+v, want %+v", got, want)
	}
}

func TestGreetCancelled(t *testing.T) {
	// Long enough that the Activity can only finish through the cancelled context.
	setGreetDelay(t, time.Minute)

	ctx, cancel := context.WithCancel(t.Context())
	cancel()

	var suite testsuite.WorkflowTestSuite
	env := suite.NewTestActivityEnvironment()
	env.SetWorkerOptions(worker.Options{BackgroundActivityContext: ctx})
	env.RegisterActivity(Greet)

	// The SDK wraps Activity failures, so only the presence of an error is asserted.
	if _, err := env.ExecuteActivity(Greet, Request{Name: "Ada"}); err == nil {
		t.Fatal("ExecuteActivity() error = nil, want a cancellation error")
	}
}

// setGreetDelay shortens the simulated work for the duration of one test.
func setGreetDelay(t *testing.T, d time.Duration) {
	t.Helper()

	original := greetDelay
	greetDelay = d
	t.Cleanup(func() { greetDelay = original })
}
