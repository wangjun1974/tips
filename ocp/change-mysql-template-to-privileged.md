```
# 保存 template 到文件
oc get template mysql-ephemeral -n openshift -o yaml > new-mysql-ephemeral-template.yaml

# 修改 template 内容
--- new-mysql-ephemeral-template.yaml.orig      2020-12-03 10:12:06.000000000 +0800
+++ new-mysql-ephemeral-template.yaml   2020-12-03 10:04:05.000000000 +0800
@@ -1,7 +1,7 @@
 apiVersion: template.openshift.io/v1
 kind: Template
 labels:
-  template: mysql-ephemeral-template
+  template: new-mysql-ephemeral-template

@@ -18,7 +18,7 @@
 
       WARNING: Any data stored will be lost upon pod destruction. Only use this template for testing
     iconClass: icon-mysql-database
-    openshift.io/display-name: MySQL (Ephemeral)
+    openshift.io/display-name: New MySQL (Ephemeral)
     openshift.io/documentation-url: https://docs.okd.io/latest/using_images/db_images/mysql.html
     openshift.io/long-description: This template provides a standalone MySQL server
       with a database created.  The database is not stored on persistent storage,

# 删除 creationTimestamp
-  creationTimestamp: "2020-11-25T12:59:40Z"

# 删除 managedFields
-  managedFields:
-  - apiVersion: template.openshift.io/v1
-    fieldsType: FieldsV1
-    fieldsV1:
-      f:labels:
-        .: {}
-        f:template: {}
-      f:message: {}
-      f:metadata:
-        f:annotations:
-          .: {}
-          f:description: {}
-          f:iconClass: {}
-          f:openshift.io/display-name: {}
-          f:openshift.io/documentation-url: {}
-          f:openshift.io/long-description: {}
-          f:openshift.io/provider-display-name: {}
-          f:openshift.io/support-url: {}
-          f:samples.operator.openshift.io/version: {}
-          f:tags: {}
-        f:labels:
-          .: {}
-          f:samples.operator.openshift.io/managed: {}
-      f:objects: {}
-      f:parameters: {}
-    manager: cluster-samples-operator
-    operation: Update
-    time: "2020-11-25T12:59:40Z"

# 修改名字
-  name: mysql-ephemeral
+  name: new-mysql-ephemeral

# 删除 resourceVersion, selfLink, uid
-  resourceVersion: "14772"
-  selfLink: /apis/template.openshift.io/v1/namespaces/openshift/templates/mysql-ephemeral
-  uid: cbf63e81-73e5-40dd-99d3-118b05583e42

# 删除 containers capabilities: {}
@@ -117,8 +85,7 @@
           name: ${DATABASE_SERVICE_NAME}
       spec:
         containers:
-        - capabilities: {}
-          env:
+        - env:

# 修改 containers 的 securityContext
@@ -167,8 +135,7 @@
             limits:
               memory: ${MEMORY_LIMIT}
           securityContext:
-            capabilities: {}
-            privileged: false
+            privileged: true
```