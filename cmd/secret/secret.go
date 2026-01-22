package secret

import (
	"crypto/rand"
	"fmt"
	"paqet/internal/flog"

	"github.com/spf13/cobra"
)

var Cmd = &cobra.Command{
	Use:   "secret",
	Short: "Generates a secure, random 32-byte secret key.",
	Long:  `This command generates a cryptographically secure 32-byte (256-bit) key and prints it. Use this key for the 'encryption.key' field in your config.yaml.`,
	Run: func(cmd *cobra.Command, args []string) {
		length := 32
		key := make([]byte, length)
		if _, err := rand.Read(key); err != nil {
			flog.Fatalf("Failed to generate random key: %v", err)
		}
		fmt.Printf("%x\n", key)
	},
}
