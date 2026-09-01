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

// Each case damages one part of a frame Wrap produced. Every case owns its own
// ciphertext, so a corruption that writes in place disturbs nothing else.
func TestUnwrapRejectsACorruptedFrame(t *testing.T) {
	tests := []struct {
		name    string
		corrupt func(ct []byte) []byte
	}{
		// Splice the other name over the framed one. The namespace is the GCM
		// additional data as well as the key selector, so this has to fail twice over.
		{"another namespace", func(ct []byte) []byte {
			copy(ct[headerSize:headerSize+len(nsDemo)], nsProd)
			return ct
		}},
		{"an unknown format version", func(ct []byte) []byte {
			ct[0] = formatVersion + 1
			return ct
		}},
		{"too short for a header", func(ct []byte) []byte { return ct[:headerSize-1] }},
		{"truncated inside its namespace", func(ct []byte) []byte { return ct[:headerSize] }},
		{"truncated inside its nonce", func(ct []byte) []byte { return ct[:headerSize+len(nsDemo)] }},
		{"missing its last byte", func(ct []byte) []byte { return ct[:len(ct)-1] }},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			k := newTestKeyring(t)

			ct, err := k.Wrap(context.Background(), nsDemo, testDEK())
			if err != nil {
				t.Fatalf("Wrap: %v", err)
			}

			if _, err := k.Unwrap(context.Background(), tt.corrupt(ct)); err == nil {
				t.Fatal("Unwrap opened a corrupted ciphertext")
			}
		})
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
