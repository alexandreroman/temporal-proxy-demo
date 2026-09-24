package kms

import (
	"bytes"
	"testing"
)

// A 32-byte secret, the floor the package documents. Real deployments take one
// from `openssl rand -base64 32`; a fixed one here keeps the tests deterministic.
const testSecret = "0123456789abcdef0123456789abcdef"

func newTestKeyring(t *testing.T) *Keyring {
	t.Helper()

	k, err := NewKeyring([]byte(testSecret))
	if err != nil {
		t.Fatalf("NewKeyring: %v", err)
	}

	return k
}

func deriveKey(t *testing.T, k *Keyring, namespace string) []byte {
	t.Helper()

	key, err := k.Key(namespace)
	if err != nil {
		t.Fatalf("Key(%q): %v", namespace, err)
	}

	return key
}

func TestNewKeyringRejectsAnEmptySecret(t *testing.T) {
	if _, err := NewKeyring(nil); err == nil {
		t.Fatal("NewKeyring accepted an empty secret")
	}
}

// Two keyrings stand in for a process before and after a restart.
func TestKeyIsDeterministicPerNamespace(t *testing.T) {
	first := deriveKey(t, newTestKeyring(t), "demo")
	second := deriveKey(t, newTestKeyring(t), "demo")

	if len(first) != keySize {
		t.Fatalf("Key returned %d bytes, want %d", len(first), keySize)
	}

	if !bytes.Equal(first, second) {
		t.Fatal("the same Namespace derived two different keys")
	}
}

func TestKeyDiffersAcrossNamespaces(t *testing.T) {
	k := newTestKeyring(t)

	if bytes.Equal(deriveKey(t, k, "demo"), deriveKey(t, k, "prod")) {
		t.Fatal("two Namespaces derived the same key")
	}
}
