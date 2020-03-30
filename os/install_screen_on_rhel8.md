## 在RHEL8上安装screen

Install EPEL on RHEL8

```
dnf install https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm

dnf install -y screen
```

Disable repo on RHEL8 https://access.redhat.com/solutions/265523
```
yum-config-manager --disable epel
```