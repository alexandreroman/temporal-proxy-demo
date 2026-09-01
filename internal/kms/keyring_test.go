package kms

import (
	"bytes"
	"context"
	"testing"
)

// A 32-byte secret, the floor the package documents. Real deployments take one
// from `openssl rand -base64 32`; a fixed one here keeps the tests deterministic.
const testSecret = "0123456789abcdef0123456789abcdef"

// Both namespaces are four bytes long, so one can be spliced over the other in a
// frame without moving anything after it.
const (
	nsDemo = "demo"
	nsProd = "prod"
)

func newTestKeyring(t *testing.T) *Keyring {
	t.Helper()

	k, err := NewKeyring([]byte(testSecret))
	if err != nil {
		t.Fatalf("NewKeyring: %v", err)
	}

	return k
}

func testDEK() []byte {
	return []byte("fedcba9876543210fedcba9876543210")
}

func TestNewKeyringRejectsAnEmptySecret(t *testing.T) {
	if _, err := NewKeyring(nil); err == nil {
		t.Fatal("NewKeyring accepted an empty secret")
	}
}

func TestWrapUnwrapRoundTrip(t *testing.T) {
	k := newTestKeyring(t)
	dek := testDEK()

	ct, err := k.Wrap(context.Background(), nsDemo, dek)
	if err != nil {
		t.Fatalf("Wrap: %v", err)
	}

	if bytes.Contains(ct, dek) {
		t.Fatal("Wrap returned the key material in the clear")
	}

	got, err := k.Unwrap(context.Background(), ct)
	if err != nil {
		t.Fatalf("Unwrap: %v", err)
	}

	if !bytes.Equal(got, dek) {
		t.Fatalf("Unwrap = %q, want %q", got, dek)
	}
}

func TestUnwrapRejectsAnotherNamespace(t *testing.T) {
	k := newTestKeyring(t)

	ct, err := k.Wrap(context.Background(), nsDemo, testDEK())
	if err != nil {
		t.Fatalf("Wrap: %v", err)
	}

	// Splice the other name over the framed one. The namespace is the GCM
	// additional data as well as the key selector, so this has to fail twice over.
	relabelled := bytes.Clone(ct)
	copy(relabelled[headerSize:headerSize+len(nsDemo)], nsProd)

	if _, err := k.Unwrap(context.Background(), relabelled); err == nil {
		t.Fatal("Unwrap opened a ciphertext relabelled under another namespace")
	}
}

func TestUnwrapRejectsAnotherMasterSecret(t *testing.T) {
	k := newTestKeyring(t)

	ct, err := k.Wrap(context.Background(), nsDemo, testDEK())
	if err != nil {
		t.Fatalf("Wrap: %v", err)
	}

	other, err := NewKeyring([]byte("ffffffffffffffffffffffffffffffff"))
	if err != nil {
		t.Fatalf("NewKeyring: %v", err)
	}

	if _, err := other.Unwrap(context.Background(), ct); err == nil {
		t.Fatal("a keyring opened a ciphertext sealed under another master secret")
	}
}

func TestUnwrapRejectsAnUnknownVersion(t *testing.T) {
	k := newTestKeyring(t)

	ct, err := k.Wrap(context.Background(), nsDemo, testDEK())
	if err != nil {
		t.Fatalf("Wrap: %v", err)
	}

	bumped := bytes.Clone(ct)
	bumped[0] = formatVersion + 1

	if _, err := k.Unwrap(context.Background(), bumped); err == nil {
		t.Fatal("Unwrap accepted an unknown format version")
	}
}

func TestUnwrapRejectsTruncatedCiphertext(t *testing.T) {
	k := newTestKeyring(t)

	ct, err := k.Wrap(context.Background(), nsDemo, testDEK())
	if err != nil {
		t.Fatalf("Wrap: %v", err)
	}

	for _, n := range []int{0, headerSize - 1, headerSize, headerSize + len(nsDemo), len(ct) - 1} {
		if _, err := k.Unwrap(context.Background(), ct[:n]); err == nil {
			t.Fatalf("Unwrap accepted a ciphertext truncated to %d bytes", n)
		}
	}
}
