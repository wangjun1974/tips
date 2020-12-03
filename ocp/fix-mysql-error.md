### OpenShift 下通过 template mysql-ephemeral 创建的容器里的日志里记录 
```
报错信息：
2020-12-03T03:07:08.454518Z 259471 [Note] Got an error reading communication packets
```

处理方法参考：https://bugzilla.redhat.com/show_bug.cgi?id=1767393 
```
# 尝试重现问题
# 设置 mysql 的 global 变量 log_error_verbosity
oc rsh pod/$(oc get pods -n test -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep -v deploy) mysql -u root -e "set global log_error_verbosity=3;"

# 查询 mysql 的 log_err 位置
oc rsh pod/$(oc get pods -n test -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep -v deploy) mysql -u root -e "select @@GLOBAL.log_error;"
+--------------------+
| @@GLOBAL.log_error |
+--------------------+
| stderr             |
+--------------------+

# 查询 mysql 的 log_error_verbosity 级别
oc rsh pod/$(oc get pods -n test -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep -v deploy) mysql -u root -e "select @@GLOBAL.log_error_verbosity;"
+------------------------------+
| @@GLOBAL.log_error_verbosity |
+------------------------------+
|                            3 |
+------------------------------+

# 查看 mysql pod 日志
oc logs pod/$(oc get pods -n test -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep -v deploy) 

# 查看 mysql pod 的 yaml 文件
oc get pod/$(oc get pods -n test -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep -v deploy) -o yaml > $(oc get pods -n test -o jsonpath='{ range .items[*]}{.metadata.name}{"\n"}{end}' | grep -v deploy).yaml

# 根据需要修改 dc/mysql
oc get dc/mysql -o yaml > dc-mysql.yaml

# dc 的 livenessProbe 和 readinessProbe

        imagePullPolicy: IfNotPresent
        livenessProbe:
          exec:
            command:
            - /bin/sh
            - -i
            - -c
            - MYSQL_PWD="$MYSQL_PASSWORD" mysqladmin -u $MYSQL_USER ping
          failureThreshold: 3
          initialDelaySeconds: 30
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 1
        name: mysql
        ports:
        - containerPort: 3306
          protocol: TCP
        readinessProbe:
          exec:
            command:
            - /bin/sh
            - -i
            - -c
            - MYSQL_PWD="$MYSQL_PASSWORD" mysqladmin -u $MYSQL_USER ping
          failureThreshold: 3
          initialDelaySeconds: 5
          periodSeconds: 10
          successThreshold: 1
          timeoutSeconds: 1
        resources:
        
# pod 的 livenessProbe 和 readinessProbe
    imagePullPolicy: IfNotPresent
    livenessProbe:
      exec:
        command:
        - /bin/sh
        - -i
        - -c
        - MYSQL_PWD="$MYSQL_PASSWORD" mysqladmin -u $MYSQL_USER ping
      failureThreshold: 3
      initialDelaySeconds: 30
      periodSeconds: 10
      successThreshold: 1
      timeoutSeconds: 1
    name: mysql
    ports:
    - containerPort: 3306
      protocol: TCP
    readinessProbe:
      exec:
        command:
        - /bin/sh
        - -i
        - -c
        - MYSQL_PWD="$MYSQL_PASSWORD" mysqladmin -u $MYSQL_USER ping
      failureThreshold: 3
      initialDelaySeconds: 5
      periodSeconds: 10
      successThreshold: 1
      timeoutSeconds: 1

```