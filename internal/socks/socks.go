package socks

import (
	"context"
	"net"
	"paqet/internal/client"
	"paqet/internal/flog"

	"github.com/txthinking/socks5"
)

type SOCKS5 struct {
	handle *Handler
}

func New(client *client.Client) (*SOCKS5, error) {
	return &SOCKS5{
		handle: &Handler{client: client},
	}, nil
}

func (s *SOCKS5) Start(ctx context.Context, addr string) error {
	s.handle.ctx = ctx
	go s.listen(ctx, addr)
	return nil
}

func (s *SOCKS5) listen(ctx context.Context, addr string) error {
	listenAddr, _ := net.ResolveTCPAddr("tcp", addr)
	server, err := socks5.NewClassicServer(listenAddr.String(), listenAddr.IP.String(), "", "", 10, 10)
	if err != nil {
		flog.Fatalf("SOCKS5 server failed to create on %s: %v", addr, err)
	}

	go func() {
		if err := server.ListenAndServe(s.handle); err != nil {
			flog.Debugf("SOCKS5 server failed to listen on %s: %v", addr, err)
		}
	}()
	flog.Infof("SOCKS5 server listening on %s", addr)

	<-ctx.Done()
	if err := server.Shutdown(); err != nil {
		flog.Debugf("SOCKS5 server shutdown with: %v", err)
	}
	return nil
}
