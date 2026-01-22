package buffer

import (
	"io"
	"net"
)

func CopyU(dst io.ReadWriter, src *net.UDPConn, addr *net.UDPAddr) error {
	bufp := uPool.Get().(*[]byte)
	defer uPool.Put(bufp)
	buf := *bufp

	n, err := dst.Read(buf)
	if err != nil {
		return err
	}

	_, err = src.WriteToUDP(buf[:n], addr)
	if err != nil {
		return err
	}

	return nil
}
