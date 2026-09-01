// Package kms derives the keys that wrap payload encryption keys, one per Namespace.
package kms

import (
	"context"
	"crypto/aes"
	"crypto/cipher"
	"crypto/hkdf"
	"crypto/rand"
	"crypto/sha256"
	"encoding/binary"
	"errors"
	"fmt"
	"math"
)

const (
	// formatVersion leads every ciphertext, so a later change to the framing is
	// rejected outright rather than misread.
	formatVersion = 0x01

	// headerSize is the fixed part of a frame: the version byte, then the uint16
	// length of the Namespace that follows it.
	headerSize = 3

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

// Wrap seals dek under the key derived for namespace.
//
// The Namespace is framed in the clear because Unwrap is handed nothing else and
// has to derive the same key again. It is the GCM additional data as well, so a
// ciphertext relabelled under another Namespace fails to open. A Namespace is not
// a secret — it already travels in request metadata.
func (k *Keyring) Wrap(_ context.Context, namespace string, dek []byte) ([]byte, error) {
	if len(namespace) > math.MaxUint16 {
		return nil, fmt.Errorf("kms: namespace is too long to frame: %d bytes", len(namespace))
	}

	gcm, err := k.cipher(namespace)
	if err != nil {
		return nil, err
	}

	out := make([]byte, 0, headerSize+len(namespace)+gcm.NonceSize()+len(dek)+gcm.Overhead())
	out = append(out, formatVersion)
	out = binary.BigEndian.AppendUint16(out, uint16(len(namespace)))
	out = append(out, namespace...)

	nonce := make([]byte, gcm.NonceSize())
	// crypto/rand.Read never returns an error; it crashes the program instead.
	_, _ = rand.Read(nonce)
	out = append(out, nonce...)

	return gcm.Seal(out, nonce, dek, []byte(namespace)), nil
}

// Unwrap opens a ciphertext produced by Wrap, deriving the key from the Namespace
// the frame carries.
func (k *Keyring) Unwrap(_ context.Context, ciphertext []byte) ([]byte, error) {
	if len(ciphertext) < headerSize {
		return nil, errors.New("kms: ciphertext is too short to hold a header")
	}

	if ciphertext[0] != formatVersion {
		return nil, fmt.Errorf("kms: unsupported ciphertext version: %#x", ciphertext[0])
	}

	nsLen := int(binary.BigEndian.Uint16(ciphertext[1:headerSize]))
	if len(ciphertext) < headerSize+nsLen {
		return nil, errors.New("kms: ciphertext is truncated inside its namespace")
	}

	namespace := string(ciphertext[headerSize : headerSize+nsLen])
	sealed := ciphertext[headerSize+nsLen:]

	gcm, err := k.cipher(namespace)
	if err != nil {
		return nil, err
	}

	if len(sealed) < gcm.NonceSize() {
		return nil, errors.New("kms: ciphertext is truncated inside its nonce")
	}

	dek, err := gcm.Open(nil, sealed[:gcm.NonceSize()], sealed[gcm.NonceSize():], []byte(namespace))
	if err != nil {
		return nil, fmt.Errorf("kms: failed to open the ciphertext for namespace %q: %w", namespace, err)
	}

	return dek, nil
}

// cipher derives the wrapping key for namespace and returns a GCM cipher over it.
// Derivation is deterministic, so a restarted process opens what it sealed before.
func (k *Keyring) cipher(namespace string) (cipher.AEAD, error) {
	key, err := hkdf.Key(sha256.New, k.secret, nil, infoPrefix+namespace, keySize)
	if err != nil {
		return nil, fmt.Errorf("kms: failed to derive a key for namespace %q: %w", namespace, err)
	}

	block, err := aes.NewCipher(key)
	if err != nil {
		return nil, fmt.Errorf("kms: failed to create a cipher: %w", err)
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return nil, fmt.Errorf("kms: failed to create GCM: %w", err)
	}

	return gcm, nil
}
