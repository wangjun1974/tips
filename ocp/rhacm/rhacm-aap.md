### ACM 与 AAP 的集成
```
### 安装 AAP Operator 2.2.1 - cluster scope 
### 创建 Automation Controller
### 输入 manifest 完成安装
### 登陆 admin/password
### 获取管理员口令
PASSWORD=$(oc get secret -n ansible-automation-platform example-admin-password -o jsonpath='{.data.password}')

### 创建 git 仓库 rhacm-workshop
### 仓库内容来自 链接: https://pan.baidu.com/s/1GWWaDijNJzSOKtcVwEdNLg?pwd=jxcd 提取码: jxcd
$ git remote add neworigin https://gitea-with-admin-openshift-operators.apps.ocp4-1.example.com/lab-user-2/rhacm-workshop.git
$ git push neworigin --all
$ git push neworigin --tags

### 创建Token
### Access -> Users -> admin -> Tokens -> Add -> Description: 'Personal access token'; Scope: 'Write'
### 记录生成的 Token

### 创建Inventory
### Resources -> Inventories -> Add -> Add Inventory -> Name: 'rhacm-workshop' -> Hosts -> Add -> Name: '192.168.122.12'

### 创建Credentials
### Resources -> Credentials -> Add -> Name: '192.168.122.12'; Organization: 'Default'; Credential Type: 'Machine'

### Ansible Tower 设置 Ignore SSL Verification - Git
https://www.techbeatly.com/connecting-ansible-tower-to-git-server-with-self-signed-certificates/
Settings -> Jobs -> EXTRA ENVIRONMENT VARIABLES
{
  "GIT_SSL_NO_VERIFY": "True"
}

### 创建Project
### Resources -> Projects -> Add -> Name: 'rhacm-workshop'; Organization: 'Default'; Source Control Type: 'Git'; Source Control Url: 'https://gitea-with-admin-openshift-operators.apps.ocp4-1.example.com/lab-user-2/rhacm-workshop.git'

### 创建Template
### Resources -> Templates -> Add -> Name: 'Logger'; Job Type: 'Run'; Inventory: 'rhacm-workshop'; Project: 'rhacm-workshop'; Playbook: '07.*logger-playbook.yml'; Credential: '192.168.122.12'; Variable: Check 'Prompt on Launch'; Inventory: Check 'Prompt on Launch'

### 在 book-import 例子里
### 进入到 book-import
### 创建目录 prehook
cat > pre_log.yaml <<EOF
---
apiVersion: tower.ansible.com/v1alpha1
kind: AnsibleJob
metadata:
  name: prejob
spec:
  tower_auth_secret: ansible-controller
  job_template_name: Logger
  extra_vars:
    trigger_name: jwang
    hook_type: prehook
    log_file_name: rhacm.log
EOF

### 在 ACM 下创建 Credential ansible-controller
### Name: ansible-controller
### Namespace: open-cluster-management
### host: https://$(oc get route example -n ansible-automation-platform -o jsonpath='{.spec.host}')
### token: 选择前面记录的 Token

### 编辑 book-import 应用
### Configure automation for prehook and posthook
### Ansible Automation Platform Credential: ansible-controller
```