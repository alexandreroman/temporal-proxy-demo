// Package temporalclient builds the Temporal client shared by the Worker and the HTTP API.
//
// What is absent here is the point of the demo: no TLS material, no API key, no host name of
// its own, no fully-qualified Namespace. The client dials a local Temporal endpoint in plaintext
// with a short Namespace name, and stays unaware of what backs that endpoint.
package temporalclient

import (
	"cmp"
	"context"
	"fmt"
	"log/slog"
	"os"

	"go.temporal.io/sdk/client"
	"go.temporal.io/sdk/log"
)

const (
	// defaultAddress is the local Temporal endpoint used unless TEMPORAL_ADDRESS says otherwise.
	defaultAddress = "localhost:7233"
	// defaultNamespace stays a short local name: nothing environment-specific belongs in the code.
	defaultNamespace = "default"
)

// Endpoint is everything the application knows about where it connects: an address to dial and
// the short Namespace name to ask for.
type Endpoint struct {
	Address   string
	Namespace string
}

// ResolveEndpoint reads the endpoint from the environment. Dial goes through it, so a caller that
// reports where the application connects reports the very pair that was dialled.
func ResolveEndpoint() Endpoint {
	// cmp.Or returns the first non-empty value, so an unset variable falls back to the default.
	return Endpoint{
		Address:   cmp.Or(os.Getenv("TEMPORAL_ADDRESS"), defaultAddress),
		Namespace: cmp.Or(os.Getenv("TEMPORAL_NAMESPACE"), defaultNamespace),
	}
}

// Dial connects to the local Temporal endpoint in plaintext. The context covers the initial
// connection only, and the caller is responsible for closing the client.
func Dial(ctx context.Context) (client.Client, error) {
	endpoint := ResolveEndpoint()
	options := client.Options{
		HostPort:  endpoint.Address,
		Namespace: endpoint.Namespace,
		Logger:    log.NewStructuredLogger(slog.Default()),
	}

	slog.Info("connecting to Temporal", "address", options.HostPort, "namespace", options.Namespace)

	c, err := client.DialContext(ctx, options)
	if err != nil {
		return nil, fmt.Errorf("connect to Temporal at %s: %w", options.HostPort, err)
	}
	return c, nil
}
