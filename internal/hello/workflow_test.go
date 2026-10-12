package hello

import (
	"context"
	"errors"
	"sync/atomic"
	"testing"

	"github.com/stretchr/testify/mock"
	"go.temporal.io/sdk/testsuite"
)

// The Activity is mocked throughout: the Workflow logic is what is under test here, and a
// mock also spares the tests the Activity's simulated work.
func TestHelloWorkflow(t *testing.T) {
	t.Parallel()

	req := Request{Name: "Ada"}
	want := Response{Greeting: "Hello, Ada!"}

	var suite testsuite.WorkflowTestSuite
	env := suite.NewTestWorkflowEnvironment()
	env.OnActivity(Greet, mock.Anything, req).Return(want, nil)

	env.ExecuteWorkflow(HelloWorkflow, req)

	if !env.IsWorkflowCompleted() {
		t.Fatal("workflow did not complete")
	}
	if err := env.GetWorkflowError(); err != nil {
		t.Fatalf("workflow error = %v, want nil", err)
	}

	var got Response
	if err := env.GetWorkflowResult(&got); err != nil {
		t.Fatalf("GetWorkflowResult() error = %v, want nil", err)
	}
	if got != want {
		t.Errorf("result = %+v, want %+v", got, want)
	}
	env.AssertExpectations(t)
}

func TestHelloWorkflowActivityFails(t *testing.T) {
	t.Parallel()

	req := Request{Name: "Ada"}

	// Counted by hand rather than with .Times(3): a call past that limit panics inside the mock, and
	// the SDK reports the panic as one more failed attempt, so a fourth attempt would go unnoticed.
	var attempts atomic.Int32

	var suite testsuite.WorkflowTestSuite
	env := suite.NewTestWorkflowEnvironment()
	env.OnActivity(Greet, mock.Anything, req).Return(func(context.Context, Request) (Response, error) {
		attempts.Add(1)
		return Response{}, errors.New("greeting unavailable")
	})

	env.ExecuteWorkflow(HelloWorkflow, req)

	if !env.IsWorkflowCompleted() {
		t.Fatal("workflow did not complete")
	}
	if err := env.GetWorkflowError(); err == nil {
		t.Fatal("workflow error = nil, want the activity failure")
	}
	if got, want := attempts.Load(), int32(3); got != want {
		t.Errorf("activity attempts = %d, want %d", got, want)
	}
	env.AssertExpectations(t)
}
