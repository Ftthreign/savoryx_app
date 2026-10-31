package domain

import (
	"crypto/rand"
	"database/sql/driver"
	"encoding/hex"
	"errors"
	"fmt"
	"strings"
	"time"
)

var (
	ErrInvalidUUIDLength = errors.New("domain: invalid UUID length")
	ErrInvalidUUIDFormat = errors.New("domain: invalid UUID format")
)

var NilUUID = UUID{}

type UUID [16]byte

func NewUUIDv7() UUID {
	var u UUID
	now := time.Now().UnixMilli()

	u[0] = byte(now >> 40)
	u[1] = byte(now >> 32)
	u[2] = byte(now >> 24)
	u[3] = byte(now >> 16)
	u[4] = byte(now >> 8)
	u[5] = byte(now)

	if _, err := rand.Read(u[6:]); err != nil {
		panic(fmt.Sprintf("domain: failed to read crypto/rand entropy: %v", err))
	}

	u[6] = (u[6] & 0x0f) | 0x70 // Version 7
	u[8] = (u[8] & 0x3f) | 0x80 // Variant 10 (RFC 9562)

	return u
}

func FromBytes(b [16]byte) UUID {
	return UUID(b)
}

func ParseUUID(s string) (UUID, error) {
	var u UUID
	s = strings.TrimSpace(s)
	if after, ok := strings.CutPrefix(s, "urn:uuid:"); ok {
		s = after
	}

	switch len(s) {
	case 36:
		if s[8] != '-' || s[13] != '-' || s[18] != '-' || s[23] != '-' {
			return NilUUID, fmt.Errorf("%w: missing or displaced hyphens in %q", ErrInvalidUUIDFormat, s)
		}
		clean := s[0:8] + s[9:13] + s[14:18] + s[19:23] + s[24:36]
		n, err := hex.Decode(u[:], []byte(clean))
		if err != nil || n != 16 {
			return NilUUID, fmt.Errorf("%w: non-hex characters in %q", ErrInvalidUUIDFormat, s)
		}
		return u, nil

	case 32:
		n, err := hex.Decode(u[:], []byte(s))
		if err != nil || n != 16 {
			return NilUUID, fmt.Errorf("%w: non-hex characters in %q", ErrInvalidUUIDFormat, s)
		}
		return u, nil

	default:
		return NilUUID, fmt.Errorf("%w: expected 32 or 36 characters, got %d", ErrInvalidUUIDLength, len(s))
	}
}

func MustParseUUID(s string) UUID {
	u, err := ParseUUID(s)
	if err != nil {
		panic(fmt.Sprintf("domain: invalid UUID %q: %v", s, err))
	}
	return u
}

func (u UUID) String() string {
	buf := make([]byte, 36)
	hex.Encode(buf[0:8], u[0:4])
	buf[8] = '-'
	hex.Encode(buf[9:13], u[4:6])
	buf[13] = '-'
	hex.Encode(buf[14:18], u[6:8])
	buf[18] = '-'
	hex.Encode(buf[19:23], u[8:10])
	buf[23] = '-'
	hex.Encode(buf[24:36], u[10:16])
	return string(buf)
}

func (u UUID) Bytes() [16]byte {
	return [16]byte(u)
}

func (u UUID) IsZero() bool {
	return u == NilUUID
}

func (u UUID) MarshalText() ([]byte, error) {
	return []byte(u.String()), nil
}

func (u *UUID) UnmarshalText(data []byte) error {
	if len(data) == 0 {
		*u = NilUUID
		return nil
	}
	parsed, err := ParseUUID(string(data))
	if err != nil {
		return err
	}
	*u = parsed
	return nil
}

func (u UUID) MarshalJSON() ([]byte, error) {
	return []byte(`"` + u.String() + `"`), nil
}

func (u *UUID) UnmarshalJSON(data []byte) error {
	str := string(data)
	if str == "null" || str == `""` || str == "" {
		*u = NilUUID
		return nil
	}
	if len(str) < 2 || str[0] != '"' || str[len(str)-1] != '"' {
		return fmt.Errorf("%w: json value must be a quoted string", ErrInvalidUUIDFormat)
	}
	unquoted := str[1 : len(str)-1]
	parsed, err := ParseUUID(unquoted)
	if err != nil {
		return err
	}
	*u = parsed
	return nil
}

func (u UUID) Value() (driver.Value, error) {
	return u.String(), nil
}

func (u *UUID) Scan(src any) error {
	if src == nil {
		*u = NilUUID
		return nil
	}

	switch v := src.(type) {
	case string:
		parsed, err := ParseUUID(v)
		if err != nil {
			return err
		}
		*u = parsed
		return nil

	case []byte:
		if len(v) == 16 {
			copy(u[:], v)
			return nil
		}
		parsed, err := ParseUUID(string(v))
		if err != nil {
			return err
		}
		*u = parsed
		return nil

	case [16]byte:
		*u = UUID(v)
		return nil

	default:
		return fmt.Errorf("domain: cannot scan type %T into UUID", src)
	}
}
