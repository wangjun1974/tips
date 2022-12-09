### ACM 与 AAP 的集成
```
### 安装 AAP Operator 2.2.1 - cluster scope 
### 创建 Automation Controller
### 输入 manifest 完成安装
### 登陆 admin/password
### 获取管理员口令
PASSWORD=$(oc get secret -n ansible-automation-platform example-admin-password -o jsonpath='{.data.password}')

```