package buffer

import (
	"sync"
)

var (
	tPool sync.Pool
	uPool sync.Pool
)

func Initialize() {
	tPool = sync.Pool{
		New: func() any {
			b := make([]byte, 64*1024)
			return &b
		},
	}
	uPool = sync.Pool{
		New: func() any {
			b := make([]byte, 32*1024)
			return &b
		},
	}
}
