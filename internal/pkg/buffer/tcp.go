package buffer

import (
	"io"
)

func Copy(dst, src io.ReadWriter) error {
	bufp := tPool.Get().(*[]byte)
	defer tPool.Put(bufp)
	buf := *bufp

	_, err := io.CopyBuffer(dst, src, buf)
	return err
}
