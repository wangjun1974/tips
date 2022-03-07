### 安装 image builder

参考：https://developers.redhat.com/blog/2019/05/08/red-hat-enterprise-linux-8-image-builder-building-custom-system-images/

更新的内容参见以下链接： https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html-single/composing_installing_and_managing_rhel_for_edge_images/index

```
# 安装 image builder on rhel8
yum install osbuild-composer composer-cli cockpit-composer bash-completion

# 开启防火墙
firewall-cmd --add-service=cockpit && firewall-cmd --add-service=cockpit --permanent
firewall-cmd --list-services

# 启用并且启动服务 
# 有些步骤并不准确，需要进一步检验
systemctl enable --now osbuild-composer.socket
systemctl enable cockpit.socket

# 配置 composer-cli bash 补齐
source  /etc/bash_completion.d/composer-cli
```