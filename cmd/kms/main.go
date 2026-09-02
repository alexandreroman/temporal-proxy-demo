// Command kms wraps and unwraps the data encryption keys that seal payloads: a
// gRPC service implementing api.kms.v1.EncryptionService. Only key material
// crosses the wire; payload plaintext never reaches it.
//
// KMS_API_KEY is the bearer token every call has to present. KMS_MASTER_SECRET is
// what every Namespace's wrapping key is derived from. Both are required, and the
// process refuses to start without either.
package main

import (
	"context"
	"crypto/subtle"
	"crypto/tls"
	"os"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"

	"github.com/temporalio/temporal-proxy/pkg/ext"
	"github.com/temporalio/temporal-proxy/pkg/logger"
	"github.com/temporalio/temporal-proxy/pkg/logger/tag"

	"github.com/alexandreroman/temporal-proxy-demo/internal/kms"
)

// Fixed here rather than configurable: the Deployment runs the binary with no arguments.
const (
	listenAddr = ":9443"
	certFile   = "/etc/kms/tls.crt"
	keyFile    = "/etc/kms/tls.key"
)

func main() {
	log := logger.Default().With(tag.Component("kms"))
	secret := requireEnv("KMS_MASTER_SECRET", log)
	expected := []byte("Bearer " + requireEnv("KMS_API_KEY", log))

	keys, err := kms.NewKeyring([]byte(secret))
	if err != nil {
		log.Fatal("building the keyring failed", tag.Error(err))
	}

	cert, err := tls.LoadX509KeyPair(certFile, keyFile)
	if err != nil {
		log.Fatal("loading the key pair failed", tag.Error(err))
	}

	// TLS 1.2 is the floor the caller's dialer enforces; two Go peers negotiate 1.3.
	creds := credentials.NewTLS(&tls.Config{
		Certificates: []tls.Certificate{cert},
		MinVersion:   tls.VersionTLS12,
	})

	if err := ext.Serve(
		context.Background(),
		ext.WithAddr(listenAddr),
		ext.WithServerAuth("authorization", func(token string) bool {
			return subtle.ConstantTimeCompare([]byte(token), expected) == 1
		}),
		ext.WithKMS(keys),
		ext.WithLogger(log),
		ext.WithServerOption(grpc.Creds(creds)),
	); err != nil {
		log.Fatal("kms stopped", tag.Error(err))
	}
}

// requireEnv reads name, or stops the process saying which variable was missing.
func requireEnv(name string, log logger.Logger) string {
	v := os.Getenv(name)
	if v == "" {
		log.Fatal(name + " is required")
	}

	return v
}
