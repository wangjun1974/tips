## 查询支持的Ciphers

```
ssh -Q cipher
3des-cbc
aes128-cbc
aes192-cbc
aes256-cbc
rijndael-cbc@lysator.liu.se
aes128-ctr
aes192-ctr
aes256-ctr
aes128-gcm@openssh.com
aes256-gcm@openssh.com
chacha20-poly1305@openssh.com
```

## scp时指定cipher
```
scp -c chacha20-poly1305@openssh.com <src> <dest>
```

因为ssh/scp/sftp在加解密时是单线程，因此传输文件尽可能用其他传输方式

## 参见
[1] https://access.redhat.com/solutions/393343
[2] https://cinhtau.net/2016/03/21/check-supported-algorithms-in-openssh/


