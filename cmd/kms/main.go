// Command kms wraps and unwraps the data encryption keys that seal payloads: a
// gRPC service implementing api.kms.v1.EncryptionService. Only key material
// crosses the wire; payload plaintext never reaches it.
//
// The keyring, which derives one key per Namespace, is all the cryptography this
// command contributes: ext.NewKeyWrapper seals with those keys and frames the
// result, and ext.Serve runs the gRPC server behind the bearer-token check and the
// TLS key pair this command loads.
//
// KMS_API_KEY is the bearer token every call has to present. KMS_MASTER_SECRET is
// what every Namespace's wrapping key is derived from. Both are required, and the
// process refuses to start without either.
package main

import (
	"context"
	"crypto/subtle"
	"os"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials"

	"go.temporal.io/proxy/pkg/ext"
	"go.temporal.io/proxy/pkg/logger"
	"go.temporal.io/proxy/pkg/logger/tag"

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

	// Keys are unversioned, so the Version a request names is ignored and none is reported.
	wrapper, err := ext.NewKeyWrapper(func(_ context.Context, req ext.KeyRequest) (ext.Key, error) {
		key, err := keys.Key(req.Namespace)
		return ext.Key{Bytes: key}, err
	})
	if err != nil {
		log.Fatal("building the key wrapper failed", tag.Error(err))
	}

	creds, err := credentials.NewServerTLSFromFile(certFile, keyFile)
	if err != nil {
		log.Fatal("loading the key pair failed", tag.Error(err))
	}

	if err := ext.Serve(
		context.Background(),
		ext.WithAddr(listenAddr),
		ext.WithServerAuth("authorization", func(token string) bool {
			return subtle.ConstantTimeCompare([]byte(token), expected) == 1
		}),
		ext.WithKMS(wrapper),
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
		log.Fatal("required variable not set", tag.String("variable", name))
	}

	return v
}
