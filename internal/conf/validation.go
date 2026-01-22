package conf

import (
	"fmt"
	"net"
)

func validateAddr(addr string, vPort bool) (*net.UDPAddr, error) {
	if addr == "" {
		return nil, fmt.Errorf("address is required")
	}

	uAddr, err := net.ResolveUDPAddr("udp", addr)
	if err != nil {
		return nil, fmt.Errorf("invalid address '%s': %v", addr, err)
	}

	if vPort {
		if uAddr.Port < 1 || uAddr.Port > 65535 {
			return nil, fmt.Errorf("port must be between 1-65535")
		}
	}

	return uAddr, nil
}

// func validateMAC(mac string) (net.HardwareAddr, error) {
// 	if mac == "" {
// 		return nil, fmt.Errorf("MAC address is required")
// 	}

// 	hwAddr, err := net.ParseMAC(mac)
// 	if err != nil {
// 		return nil, fmt.Errorf("invalid MAC address '%s': %v", mac, err)
// 	}

// 	return hwAddr, nil
// }
