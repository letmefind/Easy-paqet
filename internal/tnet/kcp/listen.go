package kcp

import (
	"paqet/internal/conf"
	"paqet/internal/socket"
	"paqet/internal/tnet"

	"github.com/xtaci/kcp-go/v5"
	"github.com/xtaci/smux"
)

type Listener struct {
	cfg *conf.KCP
	*kcp.Listener
}

func Listen(cfg *conf.KCP, pConn *socket.PacketConn) (tnet.Listener, error) {
	block, err := newBlock(cfg.Block, cfg.Key)
	if err != nil {
		return nil, err
	}
	l, err := kcp.ServeConn(block, cfg.Dshard, cfg.Pshard, pConn)
	if err != nil {
		return nil, err
	}

	return &Listener{cfg: cfg, Listener: l}, nil
}

func (l *Listener) Accept() (tnet.Conn, error) {
	conn, err := l.Listener.AcceptKCP()
	if err != nil {
		return nil, err
	}
	aplConf(conn, l.cfg)
	sess, err := smux.Server(conn, smuxConf(l.cfg))
	if err != nil {
		return nil, err
	}
	return &Conn{conn, sess}, nil
}
