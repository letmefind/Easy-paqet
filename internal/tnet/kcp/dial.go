package kcp

import (
	"fmt"
	"net"
	"paqet/internal/conf"
	"paqet/internal/flog"
	"paqet/internal/socket"
	"paqet/internal/tnet"

	"github.com/xtaci/kcp-go/v5"
	"github.com/xtaci/smux"
)

func Dial(addr *net.UDPAddr, cfg *conf.KCP, pConn *socket.PacketConn) (tnet.Conn, error) {
	block, err := newBlock(cfg.Block, cfg.Key)
	if err != nil {
		return nil, err
	}

	conn, err := kcp.NewConn(addr.String(), block, cfg.Dshard, cfg.Pshard, pConn)
	if err != nil {
		return nil, fmt.Errorf("connection attempt failed: %v", err)
	}
	aplConf(conn, cfg)
	flog.Debugf("KCP connection established, creating smux session")

	sess, err := smux.Client(conn, smuxConf(cfg))
	if err != nil {
		return nil, fmt.Errorf("failed to create smux session: %w", err)
	}
	// go func() {
	// 	for {
	// 		fmt.Println(sess.NumStreams())
	// 		time.Sleep(1 * time.Second)
	// 	}
	// }()
	flog.Debugf("smux session established successfully")
	return &Conn{conn, sess}, nil
}
