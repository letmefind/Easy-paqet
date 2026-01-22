package socks

import (
	"context"
	"paqet/internal/client"
	"sync"
)

var rPool = sync.Pool{
	New: func() any {
		b := make([]byte, 0, 4+1+255+2) // header + addr + port (max domain length 255)
		return &b
	},
}

type Handler struct {
	client *client.Client
	ctx    context.Context
}
