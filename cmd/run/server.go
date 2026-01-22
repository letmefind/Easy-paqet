package run

import (
	"paqet/internal/conf"
	"paqet/internal/flog"
	"paqet/internal/server"
)

func startServer(cfg *conf.Conf) {
	flog.Infof("Starting server...")

	server, err := server.New(cfg)
	if err != nil {
		flog.Fatalf("Failed to initialize server: %v", err)
	}
	if err := server.Start(); err != nil {
		flog.Fatalf("Server encountered an error: %v", err)
	}
}
