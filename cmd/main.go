package main

import (
	"os"
	"paqet/cmd/dump"
	"paqet/cmd/iface"
	"paqet/cmd/ping"
	"paqet/cmd/run"
	"paqet/cmd/secret"
	"paqet/cmd/version"
	"paqet/internal/flog"

	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "paqet",
	Short: "KCP transport over raw TCP packet.",
	Long:  `paqet is a bidirectional packet-level proxy using KCP and raw socket transport with encryption.`,
}

func main() {
	rootCmd.AddCommand(run.Cmd)
	rootCmd.AddCommand(dump.Cmd)
	rootCmd.AddCommand(ping.Cmd)
	rootCmd.AddCommand(secret.Cmd)
	rootCmd.AddCommand(iface.Cmd)
	rootCmd.AddCommand(version.Cmd)

	if err := rootCmd.Execute(); err != nil {
		flog.Errorf("%v", err)
		os.Exit(1)
	}
}
