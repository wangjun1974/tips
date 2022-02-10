### 检查证书
```
# 检查证书，可以观察证书是期望的证书，而不是中间设备的证书
openssl s_client -host <ocp-app> -port 443 -prexit -showcerts </dev/null
```