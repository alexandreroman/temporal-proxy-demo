package hello

import (
	"errors"
	"testing"

	"github.com/stretchr/testify/mock"
	"go.temporal.io/sdk/testsuite"
)

// The Activity is mocked throughout: the Workflow logic is what is under test here, and a
// mock also spares the tests the Activity's simulated work.
func TestHelloWorkflow(t *testing.T) {
	tests := []struct {
		name string
		req  Request
		want Response
	}{
		{"named guest", Request{Name: "Ada"}, Response{Greeting: "Hello, Ada!"}},
		{"default guest", Request{Name: "Temporal"}, Response{Greeting: "Hello, Temporal!"}},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			var suite testsuite.WorkflowTestSuite
			env := suite.NewTestWorkflowEnvironment()
			env.OnActivity(Greet, mock.Anything, tt.req).Return(tt.want, nil)

			env.ExecuteWorkflow(HelloWorkflow, tt.req)

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
			if got != tt.want {
				t.Errorf("result = %+v, want %+v", got, tt.want)
			}
			env.AssertExpectations(t)
		})
	}
}

func TestHelloWorkflowActivityFails(t *testing.T) {
	t.Parallel()

	req := Request{Name: "Ada"}

	var suite testsuite.WorkflowTestSuite
	env := suite.NewTestWorkflowEnvironment()
	env.OnActivity(Greet, mock.Anything, req).Return(Response{}, errors.New("greeting unavailable"))

	env.ExecuteWorkflow(HelloWorkflow, req)

	if !env.IsWorkflowCompleted() {
		t.Fatal("workflow did not complete")
	}
	if err := env.GetWorkflowError(); err == nil {
		t.Fatal("workflow error = nil, want the activity failure")
	}
}
