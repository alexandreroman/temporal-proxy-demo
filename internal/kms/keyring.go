// Package kms derives the keys that wrap payload encryption keys, one per Namespace.
//
// It supplies key material and nothing else: sealing, framing and nonces are left
// to the caller.
package kms

import (
	"crypto/hkdf"
	"crypto/sha256"
	"errors"
	"fmt"
)

const (
	// keySize selects AES-256.
	keySize = 32

	// infoPrefix separates these derived keys from any other use of the same
	// master secret.
	infoPrefix = "payload-encryption-kek/v1/"
)

// Keyring derives one wrapping key per Namespace, so learning one Namespace's key
// does not hand over the others.
type Keyring struct {
	secret []byte
}

// NewKeyring returns a Keyring over secret.
//
// secret should be at least 32 bytes of cryptographic randomness, from
// `openssl rand -base64 32` rather than a memorable phrase: HKDF extracts entropy
// from it rather than adding any, so a guessable secret makes every derived key
// guessable with it. Only emptiness is checked here — nothing can tell a random
// secret from a chosen one by looking at it.
func NewKeyring(secret []byte) (*Keyring, error) {
	if len(secret) == 0 {
		return nil, errors.New("kms: a master secret is required")
	}

	return &Keyring{secret: secret}, nil
}

// Key derives the wrapping key for namespace.
//
// Keys are not versioned. Derivation is deterministic, so a restarted process
// derives the same keys again and whatever was sealed before stays readable.
func (k *Keyring) Key(namespace string) ([]byte, error) {
	key, err := hkdf.Key(sha256.New, k.secret, nil, infoPrefix+namespace, keySize)
	if err != nil {
		return nil, fmt.Errorf("kms: failed to derive a key for namespace %q: %w", namespace, err)
	}

	return key, nil
}
