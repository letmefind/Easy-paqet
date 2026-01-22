package iface

import (
	"fmt"
	"net"

	"github.com/spf13/cobra"
)

var Cmd = &cobra.Command{
	Use:   "iface",
	Short: "Prints available interfaces",
	Run: func(cmd *cobra.Command, args []string) {
		interfaces, err := net.Interfaces()
		if err != nil {
			fmt.Printf("Error listing interfaces: %v", err)
			return
		}

		fmt.Println("Available network interfaces:")
		for _, iface := range interfaces {
			fmt.Printf("  %s: %s\n", iface.Name, iface.HardwareAddr)

			addrs, err := iface.Addrs()
			if err != nil {
				continue
			}

			for _, addr := range addrs {
				fmt.Printf("    %s\n", addr.String())
			}
		}
		fmt.Println()
	},
}
