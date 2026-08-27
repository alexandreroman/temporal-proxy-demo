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
		name  string
		input string
		want  string
	}{
		{"named guest", "Ada", "Hello, Ada!"},
		{"default guest", "Temporal", "Hello, Temporal!"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()

			var suite testsuite.WorkflowTestSuite
			env := suite.NewTestWorkflowEnvironment()
			env.OnActivity(Greet, mock.Anything, tt.input).Return(tt.want, nil)

			env.ExecuteWorkflow(HelloWorkflow, tt.input)

			if !env.IsWorkflowCompleted() {
				t.Fatal("workflow did not complete")
			}
			if err := env.GetWorkflowError(); err != nil {
				t.Fatalf("workflow error = %v, want nil", err)
			}

			var got string
			if err := env.GetWorkflowResult(&got); err != nil {
				t.Fatalf("GetWorkflowResult() error = %v, want nil", err)
			}
			if got != tt.want {
				t.Errorf("result = %q, want %q", got, tt.want)
			}
			env.AssertExpectations(t)
		})
	}
}

func TestHelloWorkflowActivityFails(t *testing.T) {
	var suite testsuite.WorkflowTestSuite
	env := suite.NewTestWorkflowEnvironment()
	env.OnActivity(Greet, mock.Anything, "Ada").Return("", errors.New("greeting unavailable"))

	env.ExecuteWorkflow(HelloWorkflow, "Ada")

	if !env.IsWorkflowCompleted() {
		t.Fatal("workflow did not complete")
	}
	if err := env.GetWorkflowError(); err == nil {
		t.Fatal("workflow error = nil, want the activity failure")
	}
}
