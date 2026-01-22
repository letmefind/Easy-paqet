package kcp

import (
	"github.com/xtaci/kcp-go/v5"
)

func newBlock(block string, key []byte) (kcp.BlockCrypt, error) {
	switch block {
	case "none":
		return kcp.NewNoneBlockCrypt(nil)
	case "aes":
		return kcp.NewAESBlockCrypt(key)
	case "blowfish":
		return kcp.NewBlowfishBlockCrypt(key)
	case "cast5":
		return kcp.NewCast5BlockCrypt(key)
	case "sm4":
		return kcp.NewSM4BlockCrypt(key)
	case "salsa20":
		return kcp.NewSalsa20BlockCrypt(key)
	case "simplexor":
		return kcp.NewSimpleXORBlockCrypt(key)
	case "tea":
		return kcp.NewTEABlockCrypt(key)
	case "tripledes":
		return kcp.NewTripleDESBlockCrypt(key)
	case "twofish":
		return kcp.NewTwofishBlockCrypt(key)
	case "xtea":
		return kcp.NewXTEABlockCrypt(key)
	}
	return nil, nil
}
