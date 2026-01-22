package conf

import (
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"slices"
)

type KCP struct {
	Mode   string `yaml:"mode"`
	MTU    int    `yaml:"mtu"`
	Rcvwnd int    `yaml:"rcvwnd"`
	Sndwnd int    `yaml:"sndwnd"`
	Dshard int    `yaml:"dshard"`
	Pshard int    `yaml:"pshard"`

	Block string `yaml:"block"`
	Kkey  string `yaml:"key"`
	Key   []byte `yaml:"-"`

	Smuxbuf   int `yaml:"smuxbuf"`
	Streambuf int `yaml:"streambuf"`
}

func (k *KCP) setDefaults(role string) {
	if k.Mode == "" {
		k.Mode = "fast"
	}
	if k.MTU == 0 {
		k.MTU = 1350
	}

	if k.Rcvwnd == 0 {
		if role == "server" {
			k.Rcvwnd = 1024
		} else {
			k.Rcvwnd = 512
		}
	}
	if k.Sndwnd == 0 {
		if role == "server" {
			k.Sndwnd = 1024
		} else {
			k.Sndwnd = 512
		}
	}

	// if k.Dshard == 0 {
	// 	k.Dshard = 10
	// }
	// if k.Pshard == 0 {
	// 	k.Pshard = 3
	// }

	if k.Block == "" {
		k.Block = "aes"
	}

	if k.Smuxbuf == 0 {
		k.Smuxbuf = 4 * 1024 * 1024
	}
	if k.Streambuf == 0 {
		k.Streambuf = 2 * 1024 * 1024
	}
}

func (k *KCP) validate() []error {
	var errors []error

	validModes := []string{"normal", "fast", "fast2", "fast3"}
	if !slices.Contains(validModes, k.Mode) {
		errors = append(errors, fmt.Errorf("KCP mode must be one of: %v", validModes))
	}

	if k.MTU < 50 || k.MTU > 1500 {
		errors = append(errors, fmt.Errorf("KCP MTU must be between 50-1500 bytes"))
	}

	if k.Rcvwnd < 1 || k.Rcvwnd > 32768 {
		errors = append(errors, fmt.Errorf("KCP rcvwnd must be between 1-32768"))
	}
	if k.Sndwnd < 1 || k.Sndwnd > 32768 {
		errors = append(errors, fmt.Errorf("KCP sndwnd must be between 1-32768"))
	}

	// Encryption validation
	validBlocks := []string{
		"none",
		"aes",
		"blowfish",
		"cast5",
		"sm4",
		"salsa20",
		"simplexor",
		"tea",
		"tripledes",
		"twofish",
		"xtea",
	}
	if !slices.Contains(validBlocks, k.Block) {
		errors = append(errors, fmt.Errorf("KCP encryption block must be one of: %v", validBlocks))
	}

	if k.Smuxbuf < 1024 {
		errors = append(errors, fmt.Errorf("KCP smuxbuf must be >= 1024 bytes"))
	}
	if k.Streambuf < 1024 {
		errors = append(errors, fmt.Errorf("KCP streambuf must be >= 1024 bytes"))
	}

	if k.Block != "none" && len(k.Kkey) == 0 {
		errors = append(errors, fmt.Errorf("KCP encryption key is required"))
	}
	if decoded, err := hex.DecodeString(k.Kkey); err == nil && len(decoded) == 32 {
		k.Key = decoded
	} else {
		hash := sha256.Sum256([]byte(k.Kkey))
		k.Key = hash[:]
	}

	return errors
}
