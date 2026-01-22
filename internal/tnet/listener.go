package tnet

import "net"

type Listener interface {
	Accept() (Conn, error)
	Close() error
	Addr() net.Addr
}
