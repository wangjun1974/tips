### CODESYS Gateway 设置
https://blog.csdn.net/weixin_44112083/article/details/122283497<br>
```
# 双击 'Device' 
# 网关 -> 添加网关 -> 名称:'Gateway-2' -> 驱动:'TCP/IP' -> 输入 IP 地址 -> 确定
# 在 CODESYS Runtime for Linux 所在的机器上
$ /etc/init.d/codesysedge status
$ /etc/init.d/codesysedge start
$ /etc/init.d/codesysedge status
$ /etc/init.d/codesyscontrol status
$ /etc/init.d/codesyscontrol start
$ /etc/init.d/codesyscontrol status

# 扫描网络，找到 CODESYS Runtime for Linux 机器
# 选择工具栏'登陆'
# 激活下位机
# 选择工具栏'启动‘，下发程序到下位机
# 双击 'Visualization' - 可以在可视化界面里查看
```

### CODESYS 安装 Addon
https://blog.csdn.net/goo__gle/article/details/117018937<br>
```
# 运行 CODESYS Installer 
# 选择 Change
# 选择 Install File
# 选择扩展名为 package 的 Addon
```
