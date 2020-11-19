### lab 

```

# Take a look at the ODH deployment file:
[/opt/app-root/workshop/files] $ cat 01_odh.yaml
kind: ConfigMap
apiVersion: v1
metadata:
  name: additional-profiles
  labels:
    jupyterhub: singleuser-profiles
data:
  jupyterhub-singleuser-profiles.yaml: |-
    profiles:
    - name: preload repos
      env:
        - name: JUPYTER_PRELOAD_REPOS
          value: https://github.com/guimou/xraylab_notebooks.git
    - name: globals
      resources:
        requests:
          memory: 500m
          cpu: 500m
        limits:
          memory: 1Gi
          cpu: 1
---
apiVersion: kfdef.apps.kubeflow.org/v1
kind: KfDef
metadata:
  annotations:
    kfctl.kubeflow.io/force-delete: 'false'
  name: opendatahub
spec:
  applications:
    - kustomizeConfig:
        repoRef:
          name: manifests
          path: odh-common
      name: odh-common
    - kustomizeConfig:
        parameters:
          - name: s3_endpoint_url
            value: rook-ceph-rgw-s3a.openshift-storage.svc.cluster.local
        repoRef:
          name: manifests
          path: jupyterhub/jupyterhub
      name: jupyterhub
    - kustomizeConfig:
        overlays:
          - additional
        repoRef:
          name: manifests
          path: jupyterhub/notebook-images
      name: notebook-images
  repos:
    - name: kf-manifests
      uri: >-
        https://github.com/opendatahub-io/manifests/tarball/v1.0-branch-openshift
    - name: manifests
      uri: 'https://github.com/opendatahub-io/odh-manifests/tarball/v0.7.0'
  version: v0.8.0

Warning: oc apply should be used on resource created by either oc create --save-config or oc ap
ply
configmap/additional-profiles configured
kfdef.kfdef.apps.kubeflow.org/opendatahub created


# 查看 02_config-maps.yaml
[/opt/app-root/workshop/files] $ cat 02_config-maps.yaml
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: buckets-config
data:
  bucket-base-name: 'bucket-base-name_replace_me'
  bucket-source: 'https://s3.us-east-1.amazonaws.com/com.redhat.csds.guimou.xray-source'
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: service-point
data:
  url-external: 'url-external_replace_me' # No trailing /
  url: 'http://rook-ceph-rgw-s3a.openshift-storage.svc.cluster.local' # No trailing /
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: database-host
data:
  url: xraylabdb

[/opt/app-root/workshop/files] $ sed -i 's/bucket-base-name_replace_me/xraylab-qbzxx/g' 02_conf
ig-maps.yaml

[/opt/app-root/workshop/files] $ sed -i 's/url-external_replace_me/https:\/\/rgw-openshift-stor
age.apps.cluster-nvkkk.nvkkk.sandbox1663.opentlc.com/g' 02_config-maps.yaml

[/opt/app-root/workshop/files] $ oc apply -f 02_config-maps.yaml
configmap/buckets-config created
configmap/service-point created
configmap/database-host created

[/opt/app-root/workshop/files] $ cat 03_secrets.yaml
---
apiVersion: v1
kind: Secret
metadata:
  name: s3-secret
stringData:
    AWS_ACCESS_KEY_ID: AWS_ACCESS_KEY_ID_replace_me
    AWS_SECRET_ACCESS_KEY: AWS_SECRET_ACCESS_KEY_replace_me
---
apiVersion: v1
kind: Secret
metadata:
  name: db-secret
stringData:
    database-user: xraylab
    database-password: xraylab
    database-root-password: xraylab
    database-host: xraylabdb
    database-db: xraylabdb [/opt/app-root/workshop/files] $

[/opt/app-root/workshop/files] $ sed -i 's/AWS_SECRET_ACCESS_KEY_replace_me/CiBeDC5u9OuFn2cP6Lg
gmS8iH5cWV0u3TsAcFdDX/g' 03_secrets.yaml
[/opt/app-root/workshop/files] $ sed -i 's/AWS_ACCESS_KEY_ID_replace_me/Z9PKV4XUUGQATF33F7JQ/g'
 03_secrets.yaml
[/opt/app-root/workshop/files] $

[/opt/app-root/workshop/files] $ oc apply -f 03_secrets.yaml
secret/s3-secret created
secret/db-secret created
[/opt/app-root/workshop/files] $

[/opt/app-root/workshop/files] $ cat 04_dc-xrayedgedb.yaml
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: xraylabdb
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: ocs-storagecluster-ceph-rbd
  volumeMode: Filesystem
---
kind: DeploymentConfig
apiVersion: apps.openshift.io/v1
metadata:
  name: xraylabdb
  labels:
    app: xraylabdb
spec:
  strategy:
    type: Recreate
    recreateParams:
      timeoutSeconds: 600
    resources: {}
    activeDeadlineSeconds: 21600
  triggers:
    - type: ImageChange
      imageChangeParams:
        automatic: true
        containerNames:
          - mariadb
        from:
          kind: ImageStreamTag
          namespace: openshift
          name: 'mariadb:10.2'
    - type: ConfigChange
  replicas: 1
  revisionHistoryLimit: 3
  test: false
  selector:
    app: xraylabdb
  template:
    metadata:
      labels:
        app: xraylabdb
    spec:
      containers:
        - resources:
            limits:
              memory: 512Mi
          readinessProbe:
            exec:
              command:
                - /bin/sh
                - '-i'
                - '-c'
                - >-
                  MYSQL_PWD="$MYSQL_PASSWORD" mysql -h 127.0.0.1 -u $MYSQL_USER
                  -D $MYSQL_DATABASE -e 'SELECT 1'
            initialDelaySeconds: 5
            timeoutSeconds: 1
            periodSeconds: 10
            successThreshold: 1
            failureThreshold: 3
          terminationMessagePath: /dev/termination-log
          name: mariadb
          livenessProbe:
            tcpSocket:
              port: 3306
            initialDelaySeconds: 30
            timeoutSeconds: 1
            periodSeconds: 10
            successThreshold: 1
            failureThreshold: 3
          env:
            - name: MYSQL_USER
              valueFrom:
                secretKeyRef:
                  name: db-secret
                  key: database-user
            - name: MYSQL_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-secret
                  key: database-password
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-secret
                  key: database-root-password
            - name: MYSQL_DATABASE
              valueFrom:
                secretKeyRef:
                  name: db-secret
                  key: database-db
          ports:
            - containerPort: 3306
              protocol: TCP
          imagePullPolicy: IfNotPresent
          volumeMounts:
            - name: xraylabdb-data
              mountPath: /var/lib/mysql/data
          terminationMessagePolicy: File
          image: >-
            image-registry.openshift-image-registry.svc:5000/openshift/mariadb:10.2
      volumes:
        - name: xraylabdb-data
          persistentVolumeClaim:
            claimName: xraylabdb
            storageClassName:
      restartPolicy: Always
      terminationGracePeriodSeconds: 30
      dnsPolicy: ClusterFirst
      securityContext: {}
      schedulerName: default-scheduler
---
kind: Service
apiVersion: v1
metadata:
  name: xraylabdb
spec:
  ports:
    - name: mariadb
      protocol: TCP
      port: 3306
      targetPort: 3306
  selector:
    app: xraylabdb


[/opt/app-root/workshop/files] $ oc apply -f 04_dc-xrayedgedb.yaml
persistentvolumeclaim/xraylabdb created
deploymentconfig.apps.openshift.io/xraylabdb created
service/xraylabdb created

[/opt/app-root/workshop/files] $ oc rsh $(oc get pods | grep xraylabdb | grep Running | awk '{p
rint $1}')
sh-4.2$ mysql -u root
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 14
Server version: 10.2.22-MariaDB MariaDB Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> USE xraylabdb;
Database changed
MariaDB [xraylabdb]> DROP TABLE images_uploaded;
ERROR 1051 (42S02): Unknown table 'xraylabdb.images_uploaded'
MariaDB [xraylabdb]> DROP TABLE images_processed;
ERROR 1051 (42S02): Unknown table 'xraylabdb.images_processed'
MariaDB [xraylabdb]> DROP TABLE images_anonymized;
ERROR 1051 (42S02): Unknown table 'xraylabdb.images_anonymized'
MariaDB [xraylabdb]>
MariaDB [xraylabdb]> CREATE TABLE images_uploaded(time TIMESTAMP, name VARCHAR(255));
Query OK, 0 rows affected (0.06 sec)

MariaDB [xraylabdb]> CREATE TABLE images_processed(time TIMESTAMP, name VARCHAR(255), model VAR
CHAR(10), label VARCHAR(20));
Query OK, 0 rows affected (0.05 sec)

MariaDB [xraylabdb]> CREATE TABLE images_anonymized(time TIMESTAMP, name VARCHAR(255));
Query OK, 0 rows affected (0.07 sec)

MariaDB [xraylabdb]>
MariaDB [xraylabdb]> INSERT INTO images_uploaded(time,name) SELECT CURRENT_TIMESTAMP(), '';
Query OK, 1 row affected (0.01 sec)
Records: 1  Duplicates: 0  Warnings: 0

MariaDB [xraylabdb]> INSERT INTO images_processed(time,name,model,label) SELECT CURRENT_TIMESTA
MP(), '', '','';
Query OK, 1 row affected (0.01 sec)
Records: 1  Duplicates: 0  Warnings: 0

MariaDB [xraylabdb]> INSERT INTO images_anonymized(time,name) SELECT CURRENT_TIMESTAMP(), '';
Query OK, 1 row affected (0.01 sec)
Records: 1  Duplicates: 0  Warnings: 0

MariaDB [xraylabdb]> exit;
Bye
sh-4.2$ exit
exit

[/opt/app-root/workshop/files] $ cat 05_image-streams.yaml
---
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
  name: risk-assessment
spec:
  lookupPolicy:
    local: true
  tags:
    - name: latest
      from:
        kind: DockerImage
        name: 'quay.io/guimou/xraylab-risk-assessment:rhtr_v1.4'
      importPolicy: {}
      referencePolicy:
        type: Source
---
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
  name: image-generator
spec:
  lookupPolicy:
    local: true
  tags:
    - name: latest
      from:
        kind: DockerImage
        name: 'quay.io/guimou/xraylab-image-generator:rhtr_v1.4'
      importPolicy: {}
      referencePolicy:
        type: Source
---
apiVersion: image.openshift.io/v1
kind: ImageStream
metadata:
  name: image-server
spec:
  lookupPolicy:
    local: true
  tags:
    - name: latest
      from:
        kind: DockerImage
        name: 'quay.io/guimou/xraylab-image-server:rhtr_v1.4'
      importPolicy: {}
      referencePolicy:
        type: Source

[/opt/app-root/workshop/files] $ oc apply -f 05_image-streams.yaml
imagestream.image.openshift.io/risk-assessment created
imagestream.image.openshift.io/image-generator created
imagestream.image.openshift.io/image-server created

[/opt/app-root/workshop/files] $ cat 06_kafka_cluster.yaml
apiVersion: kafka.strimzi.io/v1beta1
kind: Kafka
metadata:
  name: my-cluster
spec:
  entityOperator:
    topicOperator:
      reconciliationIntervalSeconds: 90
    userOperator:
      reconciliationIntervalSeconds: 120
  kafka:
    config:
      log.message.format.version: '2.5'
      offsets.topic.replication.factor: 1
      transaction.state.log.min.isr: 1
      transaction.state.log.replication.factor: 1
    listeners:
      plain: {}
    replicas: 1
    resources:
      limits:
        cpu: 500m
        memory: 1Gi
      requests:
        cpu: 100m
        memory: 256Mi
    storage:
      type: ephemeral
    version: 2.5.0
  zookeeper:
    replicas: 1
    storage:
      type: ephemeral

[/opt/app-root/workshop/files] $ oc apply -f 06_kafka_cluster.yaml
kafka.kafka.strimzi.io/my-cluster created

[/opt/app-root/workshop/files] $ cat 07_topics.yaml
apiVersion: kafka.strimzi.io/v1beta1
kind: KafkaTopic
metadata:
  name: xray-images
  labels:
    strimzi.io/cluster: my-cluster
spec:
  partitions: 5
  replicas: 1
  config:
    retention.ms: 604800000
    segment.bytes: 1073741824

[/opt/app-root/workshop/files] $ oc apply -f 07_topics.yaml
kafkatopic.kafka.strimzi.io/xray-images created

[/opt/app-root/workshop/files] $ cat 08_kafdrop.yaml
apiVersion: apps.openshift.io/v1
kind: DeploymentConfig
metadata:
  name: kafdrop
spec:
  selector:
    app: kafdrop
  replicas: 1
  template:
    metadata:
      labels:
        app: kafdrop
    spec:
      containers:
        - name: kafdrop
          image: obsidiandynamics/kafdrop:latest
          ports:
            - containerPort: 9000
          env:
          - name: KAFKA_BROKERCONNECT
            value: "my-cluster-kafka-bootstrap:9092"
          - name: JVM_OPTS
            value: "-Xms32M -Xmx64M"
          - name: SERVER_SERVLET_CONTEXTPATH
            value: "/"
---
apiVersion: v1
kind: Service
metadata:
  name: kafdrop
spec:
  selector:
    app: kafdrop
  ports:
    - protocol: TCP
      port: 9000
      targetPort: 9000
---
kind: Route
apiVersion: route.openshift.io/v1
metadata:
  name: kafdrop
spec:
  subdomain: ''
  to:
    kind: Service
    name: kafdrop
    weight: 100
  port:
    targetPort: 9000
  wildcardPolicy: None

[/opt/app-root/workshop/files] $ oc apply -f 08_kafdrop.yaml
deploymentconfig.apps.openshift.io/kafdrop created
service/kafdrop created
route.route.openshift.io/kafdrop created

[/opt/app-root/workshop/files] $ cat 09_dc-image-server.yaml
kind: DeploymentConfig
apiVersion: apps.openshift.io/v1
metadata:
  name: image-server
spec:
  triggers:
    - type: ImageChange
      imageChangeParams:
        automatic: true
        containerNames:
        - image-server
        from:
          kind: ImageStreamTag
          name: image-server:latest
    - type: ConfigChange
  replicas: 1
  revisionHistoryLimit: 3
  template:
    metadata:
      labels:
        name: image-server
    spec:
      containers:
        - name: image-server
          image: image-server:latest
          env:
            - name: database-user
              valueFrom:
                secretKeyRef:
                  name: db-secret
                  key:  database-user
            - name: database-password
              valueFrom:
                secretKeyRef:
                  name: db-secret
                  key:  database-password
            - name: database-host
              valueFrom:
                secretKeyRef:
                  name: db-secret
                  key:  database-host
            - name: database-db
              valueFrom:
                secretKeyRef:
                  name: db-secret
                  key:  database-db
            - name: service_point
              valueFrom:
                configMapKeyRef:
                  name: service-point
                  key: url-external
            - name: bucket-base-name
              valueFrom:
                configMapKeyRef:
                  name: buckets-config
                  key: bucket-base-name
          ports:
            - containerPort: 5000
          resources:
            limits:
                cpu: 500m
                memory: 100M
            requests:
              cpu: 200m
              memory: 50M
          imagePullPolicy: IfNotPresent
      restartPolicy: Always
      terminationGracePeriodSeconds: 30
      dnsPolicy: ClusterFirst
      securityContext: {}
      schedulerName: default-scheduler
---
apiVersion: v1
kind: Service
metadata:
  name: image-server
spec:
  ports:
    - protocol: TCP
      port: 80
      targetPort: 5000
  selector:
    name: image-server
---
kind: Route
apiVersion: route.openshift.io/v1
metadata:
  name: image-server
spec:
  to:
    kind: Service
    name: image-server
    weight: 100
  port:
    targetPort: 5000
  tls:
    termination: edge
  wildcardPolicy: None

[/opt/app-root/workshop/files] $ oc apply -f 09_dc-image-server.yaml
deploymentconfig.apps.openshift.io/image-server created
service/image-server created
route.route.openshift.io/image-server created

[/opt/app-root/workshop/files] $ cat 10_service-risk-assessment.yaml
apiVersion: serving.knative.dev/v1
kind: Service
metadata:
  name: risk-assessment
spec:
  template:
    metadata:
        annotations:
          autoscaling.knative.dev/maxScale: '2'
          autoscaling.knative.dev/target: '2'
          revisionTimestamp: ''
    spec:
      timeoutSeconds: 30
      containers:
      - image: 'quay.io/guimou/xraylab-risk-assessment:rhtr_v1.4'
        ports:
              - containerPort: 5000
        env:
        - name: model_version
          value: 'v1'
        - name: AWS_ACCESS_KEY_ID
          valueFrom:
            secretKeyRef:
              name: s3-secret
              key: AWS_ACCESS_KEY_ID
        - name: AWS_SECRET_ACCESS_KEY
          valueFrom:
            secretKeyRef:
              name: s3-secret
              key: AWS_SECRET_ACCESS_KEY
        - name: service_point
          valueFrom:
            configMapKeyRef:
              name: service-point
              key: url
        - name: database-user
          valueFrom:
            secretKeyRef:
              name: db-secret
              key:  database-user
        - name: database-password
          valueFrom:
            secretKeyRef:
              name: db-secret
              key:  database-password
        - name: database-host
          valueFrom:
            secretKeyRef:
              name: db-secret
              key:  database-host
        - name: database-db
          valueFrom:
            secretKeyRef:
              name: db-secret
              key:  database-db
        - name: bucket-base-name
          valueFrom:
            configMapKeyRef:
              name: buckets-config
              key: bucket-base-name
        resources:
          limits:
            cpu: 600m
            memory: 600M
          requests:
            cpu: 400m
            memory: 500M

[/opt/app-root/workshop/files] $ oc apply -f 10_service-risk-assessment.yaml
service.serving.knative.dev/risk-assessment created

[/opt/app-root/workshop/files] $ cat 11_kafkasource-risk-assessment.yaml
apiVersion: sources.knative.dev/v1beta1
kind: KafkaSource
metadata:
  name: xray-images
spec:
  consumerGroup: risk-assessment
  bootstrapServers:
    - my-cluster-kafka-bootstrap:9092
  topics:
    - xray-images
  sink:
    ref:
      apiVersion: serving.knative.dev/v1
      kind: Service
      name: risk-assessment

[/opt/app-root/workshop/files] $ oc apply -f 11_kafkasource-risk-assessment.yaml
kafkasource.sources.knative.dev/xray-images created

[/opt/app-root/workshop/files] $ cat 12_dc-image-generator.yaml
kind: DeploymentConfig
apiVersion: apps.openshift.io/v1
metadata:
  name: image-generator
spec:
  triggers:
    - type: ImageChange
      imageChangeParams:
        automatic: true
        containerNames:
        - image-generator
        from:
          kind: ImageStreamTag
          name: image-generator:latest
    - type: ConfigChange
  replicas: 1
  revisionHistoryLimit: 3
  template:
    metadata:
      labels:
        name: image-generator
    spec:
      containers:
        - name: image-generator
          image: image-generator:latest
          env:
            - name: SECONDS_WAIT
              value: '0'
            - name: AWS_ACCESS_KEY_ID
              valueFrom:
                secretKeyRef:
                  name: s3-secret
                  key: AWS_ACCESS_KEY_ID
            - name: AWS_SECRET_ACCESS_KEY
              valueFrom:
                secretKeyRef:
                  name: s3-secret
                  key: AWS_SECRET_ACCESS_KEY
            - name: SERVICE_POINT
              valueFrom:
                configMapKeyRef:
                  name: service-point
                  key: url
            - name: DATABASE_USER
              valueFrom:
                secretKeyRef:
                  name: db-secret
                  key:  database-user
            - name: DATABASE_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: db-secret
                  key:  database-password
            - name: DATABASE_HOST
              valueFrom:
                secretKeyRef:
                  name: db-secret
                  key:  database-host
            - name: DATABASE_DB
              valueFrom:
                secretKeyRef:
                  name: db-secret
                  key:  database-db
            - name: BUCKET_BASE_NAME
              valueFrom:
                configMapKeyRef:
                  name: buckets-config
                  key: bucket-base-name
            - name: BUCKET_SOURCE
              valueFrom:
                configMapKeyRef:
                  name: buckets-config
                  key: bucket-source
          resources:
            limits:
                cpu: 500m
                memory: 100M
            requests:
              cpu: 200m
              memory: 50M
          imagePullPolicy: IfNotPresent
      restartPolicy: Always
      terminationGracePeriodSeconds: 30
      dnsPolicy: ClusterFirst
      securityContext: {}
      schedulerName: default-scheduler

[/opt/app-root/workshop/files] $ oc apply -f 12_dc-image-generator.yaml
deploymentconfig.apps.openshift.io/image-generator created

[/opt/app-root/workshop/files] $ cat 13_grafana-mysql-datasource.yaml
apiVersion: integreatly.org/v1alpha1
kind: GrafanaDataSource
metadata:
  name: mysql-grafana-datasource
spec:
  datasources:
    - type: mysql
      name: MySQL
      access: proxy
      url: xraylabdb
      database: xraylabdb
      user: xraylab
      password: xraylab
  name: grafana-mysql-datasource.yaml

[/opt/app-root/workshop/files] $ oc apply -f 13_grafana-my
sql-datasource.yaml
grafanadatasource.integreatly.org/mysql-grafana-datasource created


[/opt/app-root/workshop/files] $ cat 14_grafana-xraylab-images-dashboard-template.yaml
apiVersion: v1
kind: Template
metadata:
  name: grafana-xraylab-dashboard-template
  annotations: {}
objects:
- apiVersion: integreatly.org/v1alpha1
  kind: GrafanaDashboard
  metadata:
    labels:
      app: grafana
    name: xraylab-images-dashboard
    uid: lastimagesdashboard
  spec:
    json: |
      {
        "annotations": {
          "list": [
            {
              "builtIn": 1,
              "datasource": "-- Grafana --",
              "enable": true,
              "hide": true,
              "iconColor": "rgba(0, 211, 255, 1)",
              "name": "Annotations & Alerts",
              "type": "dashboard"
            }
          ]
        },
        "editable": true,
        "gnetId": null,
        "graphTooltip": 0,
        "links": [
          {
            "asDropdown": false,
            "icon": "external link",
            "includeVars": false,
            "keepTime": true,
            "tags": [],
            "type": "dashboards"
          }
        ],
        "panels": [
          {
            "gridPos": {
              "h": 15,
              "w": 8,
              "x": 0,
              "y": 0
            },
            "header_js": "{}",
            "id": 2,
            "links": [],
            "method": "iframe",
            "mode": "html",
            "options": {},
            "params_js": "{\n __now:Date.now(),\n}",
            "request": "http",
            "responseType": "text",
            "showErrors": true,
            "showTime": true,
            "showTimeFormat": "LTS",
            "showTimePrefix": null,
            "showTimeValue": "request",
            "skipSameURL": false,
            "templateResponse": true,
            "timeFrom": null,
            "timeShift": null,
            "title": "Last uploaded image",
            "type": "ryantxu-ajax-panel",
            "url": "${image_server_url}/last_image_big/${bucket_base_name}",
            "withCredentials": false
          },
          {
            "gridPos": {
              "h": 15,
              "w": 8,
              "x": 8,
              "y": 0
            },
            "header_js": "{}",
            "id": 3,
            "links": [],
            "method": "iframe",
            "mode": "html",
            "options": {},
            "params_js": "{\n __now:Date.now(),\n}",
            "request": "http",
            "responseType": "text",
            "showErrors": true,
            "showTime": true,
            "showTimeFormat": "LTS",
            "showTimePrefix": null,
            "showTimeValue": "request",
            "skipSameURL": false,
            "templateResponse": true,
            "timeFrom": null,
            "timeShift": null,
            "title": "Last processed image",
            "type": "ryantxu-ajax-panel",
            "url": "${image_server_url}/last_image_big/${bucket_base_name}-processed",
            "withCredentials": false
          },
          {
            "gridPos": {
              "h": 15,
              "w": 8,
              "x": 16,
              "y": 0
            },
            "header_js": "{}",
            "id": 4,
            "links": [],
            "method": "iframe",
            "mode": "html",
            "options": {},
            "params_js": "{\n __now:Date.now(),\n}",
            "request": "http",
            "responseType": "text",
            "showErrors": true,
            "showTime": true,
            "showTimeFormat": "LTS",
            "showTimePrefix": null,
            "showTimeValue": "request",
            "skipSameURL": false,
            "templateResponse": true,
            "timeFrom": null,
            "timeShift": null,
            "title": "Last anonymized image",
            "type": "ryantxu-ajax-panel",
            "url": "${image_server_url}/last_image_big/${bucket_base_name}-anonymized",
            "withCredentials": false
          }
        ],
        "refresh": "5s",
        "schemaVersion": 18,
        "style": "dark",
        "tags": [],
        "templating": {
          "list": []
        },
        "time": {
          "from": "now-5m",
          "to": "now"
        },
        "timepicker": {
          "refresh_intervals": [
            "5s",
            "10s",
            "30s",
            "1m",
            "5m",
            "15m",
            "30m",
            "1h",
            "2h",
            "1d"
          ],
          "time_options": [
            "5m",
            "15m",
            "1h",
            "6h",
            "12h",
            "24h",
            "2d",
            "7d",
            "30d"
          ]
        },
        "timezone": "utc",
        "title": "Last Images",
        "uid": "lastimagesdashboard",
        "version": 6
      }
    name: xraylab-images-dashboard.json
    plugins:
    - name: ryantxu-ajax-panel
      version: 0.0.7-dev
parameters:
- description: Route to the image server
  name: image_server_url
- description: Bucket base name
  name: bucket_base_name
labels:
  grafana: dashboard

[/opt/app-root/workshop/files] $ oc process -f 14_grafana-xraylab-images-dashboard-template.yam
l -p image_server_url=https://image-server-xraylab-qbzxx.apps.cluster-nvkkk.nvkkk.sandbox1663.o
pentlc.com -p bucket_base_name=xraylab-qbzxx | oc apply -f -
grafanadashboard.integreatly.org/xraylab-images-dashboard created

[/opt/app-root/workshop/files] $ cat 15_grafana-xraylab-dashboard-template.yaml
apiVersion: v1
kind: Template
metadata:
  name: grafana-xraylab-dashboard-template
  annotations: {}
objects:
- apiVersion: integreatly.org/v1alpha1
  kind: GrafanaDashboard
  metadata:
    labels:
      app: grafana
    name: xraylab-dashboard
    uid: xraylabdashboard
  spec:
    json: |
      {
        "annotations": {
          "list": [
            {
              "builtIn": 1,
              "datasource": "-- Grafana --",
              "enable": true,
              "hide": true,
              "iconColor": "rgba(0, 211, 255, 1)",
              "name": "Annotations & Alerts",
              "type": "dashboard"
            }
          ]
        },
        "editable": true,
        "gnetId": null,
        "graphTooltip": 0,
        "id": 2,
        "iteration": 1600370863081,
        "links": [],
        "panels": [
          {
            "bgColor": null,
            "bgURL": "https://github.com/guimou/datapipelines/raw/main/demos/xray-pipeline-lab/
grafana/xraylab-dashboard-panel.png",
            "boxes": [
              {
                "angle": "0",
                "color": "#1F60C4",
                "colorHigh": "#f00",
                "colorLow": "#0f0",
                "colorMedium": "#fa1",
                "decimal": 1,
                "fontsize": "30",
                "hasOrb": false,
                "isBlinking": false,
                "orbHideText": false,
                "orbLocation": "Left",
                "orbSize": "10",
                "prefixSize": 10,
                "serie": "images_uploaded",
                "suffixSize": 10,
                "text": "N/A",
                "thresholds": "20,60",
                "usingThresholds": false,
                "xpos": "60",
                "ypos": "75"
              },
              {
                "angle": 0,
                "color": "#1F60C4",
                "colorHigh": "#f00",
                "colorLow": "#0f0",
                "colorMedium": "#fa1",
                "decimal": 1,
                "fontsize": "30",
                "hasOrb": false,
                "isBlinking": false,
                "orbHideText": false,
                "orbLocation": "Left",
                "orbSize": "10",
                "prefixSize": 10,
                "serie": "images_processed",
                "suffixSize": 10,
                "text": "N/A",
                "thresholds": "20,60",
                "usingThresholds": false,
                "xpos": "250",
                "ypos": "75"
              },
              {
                "angle": 0,
                "color": "#1F60C4",
                "colorHigh": "#f00",
                "colorLow": "#0f0",
                "colorMedium": "#fa1",
                "decimal": 1,
                "fontsize": "30",
                "hasOrb": false,
                "isBlinking": false,
                "orbHideText": false,
                "orbLocation": "Left",
                "orbSize": "10",
                "prefixSize": 10,
                "serie": "images_anonymized",
                "suffixSize": 10,
                "text": "N/A",
                "thresholds": "20,60",
                "usingThresholds": false,
                "xpos": "470",
                "ypos": "298"
              }
            ],
            "datasource": "MySQL",
            "fieldConfig": {
              "defaults": {
                "custom": {}
              },
              "overrides": []
            },
            "gridPos": {
              "h": 12,
              "w": 12,
              "x": 0,
              "y": 0
            },
            "id": 14,
            "links": [],
            "targets": [
              {
                "format": "time_series",
                "group": [
                  {
                    "params": [
                      "1h",
                      "none"
                    ],
                    "type": "time"
                  }
                ],
                "metricColumn": "none",
                "rawQuery": true,
                "rawSql": "SELECT time,count(name)-1 AS \"images_uploaded\"\nFROM images_upload
ed",
                "refId": "A",
                "select": [
                  [
                    {
                      "params": [
                        "entry"
                      ],
                      "type": "column"
                    },
                    {
                      "params": [
                        "sum"
                      ],
                      "type": "aggregate"
                    },
                    {
                      "params": [
                        "transactions"
                      ],
                      "type": "alias"
                    }
                  ]
                ],
                "table": "merchant_upload",
                "timeColumn": "time",
                "timeColumnType": "timestamp",
                "where": []
              },
              {
                "format": "time_series",
                "group": [],
                "metricColumn": "none",
                "rawQuery": true,
                "rawSql": "SELECT time,count(name)-1 AS \"images_processed\"\nFROM images_proce
ssed",
                "refId": "B",
                "select": [
                  [
                    {
                      "params": [
                        "entry"
                      ],
                      "type": "column"
                    }
                  ]
                ],
                "table": "merchant_upload",
                "timeColumn": "time",
                "timeColumnType": "timestamp",
                "where": [
                  {
                    "name": "$__timeFilter",
                    "params": [],
                    "type": "macro"
                  }
                ]
              },
              {
                "format": "time_series",
                "group": [],
                "metricColumn": "none",
                "rawQuery": true,
                "rawSql": "SELECT time,count(name)-1 AS \"images_anonymized\"\nFROM images_anon
ymized",
                "refId": "C",
                "select": [
                  [
                    {
                      "params": [
                        "entry"
                      ],
                      "type": "column"
                    }
                  ]
                ],
                "table": "merchant_upload",
                "timeColumn": "time",
                "timeColumnType": "timestamp",
                "where": [
                  {
                    "name": "$__timeFilter",
                    "params": [],
                    "type": "macro"
                  }
                ]
              }
            ],
            "timeFrom": null,
            "timeShift": null,
            "title": "Pipeline progress",
            "type": "larona-epict-panel"
          },
          {
            "columns": [],
            "datasource": "MySQL",
            "fieldConfig": {
              "defaults": {
                "custom": {}
              },
              "overrides": []
            },
            "fontSize": "100%",
            "gridPos": {
              "h": 7,
              "w": 8,
              "x": 12,
              "y": 0
            },
            "id": 18,
            "links": [],
            "pageSize": null,
            "scroll": true,
            "showHeader": true,
            "sort": {
              "col": 0,
              "desc": true
            },
            "styles": [
              {
                "alias": "Time",
                "align": "auto",
                "dateFormat": "YYYY-MM-DD HH:mm:ss",
                "link": false,
                "pattern": "Time",
                "preserveFormat": true,
                "sanitize": false,
                "type": "date",
                "unit": "dateTimeAsIso"
              },
              {
                "alias": "",
                "align": "auto",
                "colorMode": null,
                "colors": [
                  "rgba(245, 54, 54, 0.9)",
                  "rgba(237, 129, 40, 0.89)",
                  "rgba(50, 172, 45, 0.97)"
                ],
                "dateFormat": "YYYY-MM-DD HH:mm:ss",
                "decimals": 2,
                "mappingType": 1,
                "pattern": "Metric",
                "thresholds": [],
                "type": "hidden",
                "unit": "short"
              },
              {
                "alias": "",
                "align": "auto",
                "colorMode": null,
                "colors": [
                  "rgba(245, 54, 54, 0.9)",
                  "rgba(237, 129, 40, 0.89)",
                  "rgba(50, 172, 45, 0.97)"
                ],
                "decimals": 2,
                "pattern": "/.*/",
                "thresholds": [],
                "type": "string",
                "unit": "short"
              }
            ],
            "targets": [
              {
                "format": "table",
                "group": [],
                "metricColumn": "none",
                "rawQuery": true,
                "rawSql": "SELECT * FROM images_uploaded WHERE name != '' ORDER by time DESC LI
MIT 10",
                "refId": "A",
                "select": [
                  [
                    {
                      "params": [
                        "value"
                      ],
                      "type": "column"
                    }
                  ]
                ],
                "timeColumn": "time",
                "where": [
                  {
                    "name": "$__timeFilter",
                    "params": [],
                    "type": "macro"
                  }
                ]
              }
            ],
            "timeFrom": null,
            "timeShift": null,
            "title": "Last 10 uploaded images",
            "transform": "timeseries_to_rows",
            "type": "table"
          },
          {
            "datasource": null,
            "fieldConfig": {
              "defaults": {
                "custom": {}
              },
              "overrides": []
            },
            "gridPos": {
              "h": 7,
              "w": 4,
              "x": 20,
              "y": 0
            },
            "header_js": "{}",
            "id": 24,
            "links": [
              {
                "title": "Last Images",
                "url": "/d/lastimagesdashboard/last-images"
              }
            ],
            "method": "iframe",
            "mode": "html",
            "params_js": "{\n __now:Date.now(),\n}",
            "request": "http",
            "responseType": "text",
            "showErrors": true,
            "showTime": true,
            "showTimeFormat": "LTS",
            "showTimePrefix": null,
            "showTimeValue": "request",
            "skipSameURL": false,
            "templateResponse": true,
            "timeFrom": null,
            "timeShift": null,
            "title": "Last uploaded image",
            "type": "ryantxu-ajax-panel",
            "url": "${image_server_url}/last_image_small/${bucket_base_name}",
            "withCredentials": false
          },
          {
            "columns": [],
            "datasource": "MySQL",
            "fieldConfig": {
              "defaults": {
                "custom": {}
              },
              "overrides": []
            },
            "fontSize": "100%",
            "gridPos": {
              "h": 7,
              "w": 8,
              "x": 12,
              "y": 7
            },
            "id": 19,
            "links": [],
            "pageSize": null,
            "scroll": true,
            "showHeader": true,
            "sort": {
              "col": 0,
              "desc": true
            },
            "styles": [
              {
                "alias": "Time",
                "align": "auto",
                "dateFormat": "YYYY-MM-DD HH:mm:ss",
                "pattern": "Time",
                "type": "date"
              },
              {
                "alias": "",
                "align": "auto",
                "colorMode": null,
                "colors": [
                  "rgba(245, 54, 54, 0.9)",
                  "rgba(237, 129, 40, 0.89)",
                  "rgba(50, 172, 45, 0.97)"
                ],
                "decimals": 2,
                "pattern": "Metric",
                "thresholds": [],
                "type": "hidden",
                "unit": "short"
              }
            ],
            "targets": [
              {
                "format": "table",
                "group": [],
                "metricColumn": "none",
                "rawQuery": true,
                "rawSql": "SELECT time,name FROM images_processed WHERE name != '' ORDER by tim
e DESC LIMIT 10",
                "refId": "A",
                "select": [
                  [
                    {
                      "params": [
                        "value"
                      ],
                      "type": "column"
                    }
                  ]
                ],
                "timeColumn": "time",
                "where": [
                  {
                    "name": "$__timeFilter",
                    "params": [],
                    "type": "macro"
                  }
                ]
              }
            ],
            "timeFrom": null,
            "timeShift": null,
            "title": "Last 10 processed images",
            "transform": "timeseries_to_rows",
            "type": "table"
          },
          {
            "datasource": null,
            "fieldConfig": {
              "defaults": {
                "custom": {}
              },
              "overrides": []
            },
            "gridPos": {
              "h": 7,
              "w": 4,
              "x": 20,
              "y": 7
            },
            "header_js": "{}",
            "id": 25,
            "links": [
              {
                "title": "Last Images",
                "url": "/d/lastimagesdashboard/last-images"
              }
            ],
            "method": "iframe",
            "mode": "html",
            "params_js": "{\n __now:Date.now(),\n}",
            "request": "http",
            "responseType": "text",
            "showErrors": true,
            "showTime": true,
            "showTimeFormat": "LTS",
            "showTimePrefix": null,
            "showTimeValue": "request",
            "skipSameURL": false,
            "templateResponse": true,
            "timeFrom": null,
            "timeShift": null,
            "title": "Last processed image",
            "type": "ryantxu-ajax-panel",
            "url": "${image_server_url}/last_image_small/${bucket_base_name}-processed",
            "withCredentials": false
          },
          {
            "aliasColors": {},
            "bars": false,
            "dashLength": 10,
            "dashes": false,
            "datasource": "$datasource",
            "fieldConfig": {
              "defaults": {
                "custom": {},
                "links": []
              },
              "overrides": []
            },
            "fill": 0,
            "fillGradient": 0,
            "gridPos": {
              "h": 5,
              "w": 4,
              "x": 0,
              "y": 12
            },
            "hiddenSeries": false,
            "id": 10,
            "legend": {
              "avg": false,
              "current": false,
              "max": false,
              "min": false,
              "rightSide": true,
              "show": true,
              "total": false,
              "values": false
            },
            "lines": true,
            "linewidth": 1,
            "links": [],
            "nullPointMode": "null as zero",
            "percentage": false,
            "pluginVersion": "7.1.1",
            "pointradius": 5,
            "points": false,
            "renderer": "flot",
            "seriesOverrides": [
              {
                "alias": "RAM",
                "yaxis": 2
              }
            ],
            "spaceLength": 10,
            "stack": false,
            "steppedLine": false,
            "targets": [
              {
                "expr": "sum(pod:container_cpu_usage:sum{namespace=\"$namespace\"})",
                "format": "time_series",
                "instant": false,
                "intervalFactor": 1,
                "legendFormat": " CPU",
                "legendLink": null,
                "refId": "A",
                "step": 10
              },
              {
                "expr": "sum(container_memory_working_set_bytes{namespace=\"$namespace\"})",
                "format": "time_series",
                "intervalFactor": 1,
                "legendFormat": "RAM",
                "refId": "B"
              }
            ],
            "thresholds": [],
            "timeFrom": null,
            "timeRegions": [],
            "timeShift": null,
            "title": "CPU  and RAM Usage",
            "tooltip": {
              "shared": false,
              "sort": 0,
              "value_type": "individual"
            },
            "type": "graph",
            "xaxis": {
              "buckets": null,
              "mode": "time",
              "name": null,
              "show": true,
              "values": []
            },
            "yaxes": [
              {
                "format": "short",
                "label": "CPU",
                "logBase": 1,
                "max": null,
                "min": 0,
                "show": true
              },
              {
                "format": "bytes",
                "label": "RAM",
                "logBase": 1,
                "max": null,
                "min": "0",
                "show": true
              }
            ],
            "yaxis": {
              "align": false,
              "alignLevel": null
            }
          },
          {
            "cacheTimeout": null,
            "datasource": "prometheus",
            "fieldConfig": {
              "defaults": {
                "custom": {},
                "mappings": [
                  {
                    "id": 0,
                    "op": "=",
                    "text": "N/A",
                    "type": 1,
                    "value": "null"
                  }
                ],
                "max": 10,
                "min": 0,
                "nullValueMode": "connected",
                "thresholds": {
                  "mode": "absolute",
                  "steps": [
                    {
                      "color": "#299c46",
                      "value": null
                    },
                    {
                      "color": "rgba(237, 129, 40, 0.89)",
                      "value": 5
                    },
                    {
                      "color": "#d44a3a",
                      "value": 8
                    }
                  ]
                },
                "unit": "none"
              },
              "overrides": []
            },
            "gridPos": {
              "h": 5,
              "w": 3,
              "x": 4,
              "y": 12
            },
            "id": 2,
            "interval": "",
            "links": [],
            "options": {
              "orientation": "horizontal",
              "reduceOptions": {
                "calcs": [
                  "last"
                ],
                "fields": "",
                "values": false
              },
              "showThresholdLabels": true,
              "showThresholdMarkers": true
            },
            "pluginVersion": "7.1.1",
            "targets": [
              {
                "expr": "sum(kube_pod_container_status_running{pod=~\"risk-assessment.*\",names
pace=~\"$namespace\"})",
                "format": "time_series",
                "instant": true,
                "interval": "",
                "intervalFactor": 1,
                "legendFormat": "{{ deployment }}",
                "refId": "A"
              }
            ],
            "timeFrom": null,
            "timeShift": null,
            "title": "Risk assessment containers running",
            "type": "gauge"
          },
          {
            "aliasColors": {},
            "bars": false,
            "dashLength": 10,
            "dashes": false,
            "datasource": "MySQL",
            "fieldConfig": {
              "defaults": {
                "custom": {},
                "links": []
              },
              "overrides": []
            },
            "fill": 10,
            "fillGradient": 0,
            "gridPos": {
              "h": 5,
              "w": 5,
              "x": 7,
              "y": 12
            },
            "hiddenSeries": false,
            "id": 4,
            "interval": "10s",
            "legend": {
              "alignAsTable": false,
              "avg": false,
              "current": false,
              "max": false,
              "min": false,
              "rightSide": true,
              "show": true,
              "total": false,
              "values": false
            },
            "lines": true,
            "linewidth": 0,
            "links": [],
            "nullPointMode": "null as zero",
            "percentage": false,
            "pluginVersion": "7.1.1",
            "pointradius": 5,
            "points": false,
            "renderer": "flot",
            "seriesOverrides": [],
            "spaceLength": 10,
            "stack": true,
            "steppedLine": false,
            "targets": [
              {
                "format": "time_series",
                "group": [
                  {
                    "params": [
                      "$__interval",
                      "none"
                    ],
                    "type": "time"
                  }
                ],
                "metricColumn": "label",
                "rawQuery": true,
                "rawSql": "SELECT\n  $__timeGroupAlias(time,$__interval),\n  label AS metric,\n
  count(label)\nFROM images_processed\nWHERE\n  $__timeFilter(time)\n  and\n  label != ''\nGROU
P BY 1,2\nORDER BY $__timeGroup(time,$__interval)",
                "refId": "A",
                "select": [
                  [
                    {
                      "params": [
                        "label"
                      ],
                      "type": "column"
                    },
                    {
                      "params": [
                        "count"
                      ],
                      "type": "aggregate"
                    }
                  ]
                ],
                "table": "images_processed",
                "timeColumn": "time",
                "timeColumnType": "timestamp",
                "where": [
                  {
                    "name": "$__timeFilter",
                    "params": [],
                    "type": "macro"
                  }
                ]
              }
            ],
            "thresholds": [],
            "timeFrom": null,
            "timeRegions": [],
            "timeShift": null,
            "title": "Risk distribution",
            "tooltip": {
              "shared": false,
              "sort": 0,
              "value_type": "individual"
            },
            "type": "graph",
            "xaxis": {
              "buckets": null,
              "mode": "time",
              "name": null,
              "show": true,
              "values": []
            },
            "yaxes": [
              {
                "decimals": 0,
                "format": "none",
                "label": null,
                "logBase": 1,
                "max": null,
                "min": 0,
                "show": true
              },
              {
                "format": "short",
                "label": null,
                "logBase": 1,
                "max": null,
                "min": null,
                "show": false
              }
            ],
            "yaxis": {
              "align": false,
              "alignLevel": null
            }
          },
          {
            "columns": [],
            "datasource": "MySQL",
            "fieldConfig": {
              "defaults": {
                "custom": {}
              },
              "overrides": []
            },
            "fontSize": "100%",
            "gridPos": {
              "h": 7,
              "w": 8,
              "x": 12,
              "y": 14
            },
            "id": 20,
            "links": [],
            "pageSize": null,
            "scroll": true,
            "showHeader": true,
            "sort": {
              "col": 0,
              "desc": true
            },
            "styles": [
              {
                "alias": "Time",
                "align": "auto",
                "dateFormat": "YYYY-MM-DD HH:mm:ss",
                "pattern": "Time",
                "type": "date"
              },
              {
                "alias": "",
                "align": "auto",
                "colorMode": null,
                "colors": [
                  "rgba(245, 54, 54, 0.9)",
                  "rgba(237, 129, 40, 0.89)",
                  "rgba(50, 172, 45, 0.97)"
                ],
                "decimals": 2,
                "pattern": "Metric",
                "thresholds": [],
                "type": "hidden",
                "unit": "short"
              }
            ],
            "targets": [
              {
                "format": "table",
                "group": [],
                "metricColumn": "none",
                "rawQuery": true,
                "rawSql": "SELECT * FROM images_anonymized WHERE name != '' ORDER by time DESC
LIMIT 10",
                "refId": "A",
                "select": [
                  [
                    {
                      "params": [
                        "value"
                      ],
                      "type": "column"
                    }
                  ]
                ],
                "timeColumn": "time",
                "where": [
                  {
                    "name": "$__timeFilter",
                    "params": [],
                    "type": "macro"
                  }
                ]
              }
            ],
            "timeFrom": null,
            "timeShift": null,
            "title": "Last 10 anonymized images",
            "transform": "timeseries_to_rows",
            "type": "table"
          },
          {
            "datasource": null,
            "fieldConfig": {
              "defaults": {
                "custom": {}
              },
              "overrides": []
            },
            "gridPos": {
              "h": 7,
              "w": 4,
              "x": 20,
              "y": 14
            },
            "header_js": "{}",
            "id": 26,
            "links": [
              {
                "title": "Last Images",
                "url": "/d/lastimagesdashboard/last-images"
              }
            ],
            "method": "iframe",
            "mode": "html",
            "params_js": "{\n __now:Date.now(),\n}",
            "request": "http",
            "responseType": "text",
            "showErrors": true,
            "showTime": true,
            "showTimeFormat": "LTS",
            "showTimePrefix": null,
            "showTimeValue": "request",
            "skipSameURL": false,
            "templateResponse": true,
            "timeFrom": null,
            "timeShift": null,
            "title": "Last anonymized image",
            "type": "ryantxu-ajax-panel",
            "url": "${image_server_url}/last_image_small/${bucket_base_name}-anonymized",
            "withCredentials": false
          },
          {
            "columns": [
              {
                "text": "Current",
                "value": "current"
              }
            ],
            "datasource": "prometheus",
            "fieldConfig": {
              "defaults": {
                "custom": {}
              },
              "overrides": []
            },
            "fontSize": "100%",
            "gridPos": {
              "h": 4,
              "w": 7,
              "x": 0,
              "y": 17
            },
            "id": 6,
            "links": [],
            "pageSize": null,
            "scroll": true,
            "showHeader": true,
            "sort": {
              "col": 0,
              "desc": true
            },
            "styles": [
              {
                "alias": "Time",
                "align": "auto",
                "dateFormat": "YYYY-MM-DD HH:mm:ss",
                "pattern": "Time",
                "type": "date"
              },
              {
                "alias": "Deployment",
                "align": "auto",
                "colorMode": "row",
                "colors": [
                  "rgba(245, 54, 54, 0.9)",
                  "rgba(237, 129, 40, 0.89)",
                  "rgba(50, 172, 45, 0.97)"
                ],
                "decimals": 0,
                "pattern": "Metric",
                "preserveFormat": false,
                "thresholds": [
                  ""
                ],
                "type": "string",
                "unit": "none"
              },
              {
                "alias": "Replicas",
                "align": "auto",
                "colorMode": "row",
                "colors": [
                  "rgba(245, 54, 54, 0.9)",
                  "rgba(237, 129, 40, 0.89)",
                  "rgba(50, 172, 45, 0.97)"
                ],
                "dateFormat": "YYYY-MM-DD HH:mm:ss",
                "decimals": 0,
                "link": false,
                "pattern": "Value",
                "thresholds": [
                  "0",
                  "0.9"
                ],
                "type": "number",
                "unit": "none"
              }
            ],
            "targets": [
              {
                "expr": "kube_deployment_status_replicas{deployment=~\"risk-assessment.*\",name
space=~\"$namespace\"}",
                "format": "time_series",
                "instant": true,
                "interval": "",
                "intervalFactor": 1,
                "legendFormat": "{{ deployment }}",
                "refId": "A"
              }
            ],
            "title": "Deployments",
            "transform": "timeseries_to_rows",
            "type": "table"
          },
          {
            "aliasColors": {},
            "bars": false,
            "dashLength": 10,
            "dashes": false,
            "datasource": "MySQL",
            "fieldConfig": {
              "defaults": {
                "custom": {}
              },
              "overrides": []
            },
            "fill": 1,
            "fillGradient": 0,
            "gridPos": {
              "h": 4,
              "w": 5,
              "x": 7,
              "y": 17
            },
            "hiddenSeries": false,
            "id": 16,
            "interval": "10s",
            "legend": {
              "avg": false,
              "current": false,
              "max": false,
              "min": false,
              "rightSide": true,
              "show": true,
              "total": false,
              "values": false
            },
            "lines": true,
            "linewidth": 1,
            "links": [],
            "nullPointMode": "null",
            "percentage": false,
            "pluginVersion": "7.1.1",
            "pointradius": 2,
            "points": false,
            "renderer": "flot",
            "seriesOverrides": [],
            "spaceLength": 10,
            "stack": false,
            "steppedLine": false,
            "targets": [
              {
                "format": "time_series",
                "group": [
                  {
                    "params": [
                      "$__interval",
                      "none"
                    ],
                    "type": "time"
                  }
                ],
                "metricColumn": "model",
                "rawQuery": true,
                "rawSql": "SELECT\n  $__timeGroupAlias(time,$__interval),\n  model AS metric,\n
  count(model) AS \"model\"\nFROM images_processed\nWHERE\n  $__timeFilter(time)\n  and\n  mode
l != ''\nGROUP BY 1,2\nORDER BY $__timeGroup(time,$__interval)",
                "refId": "A",
                "select": [
                  [
                    {
                      "params": [
                        "value"
                      ],
                      "type": "column"
                    },
                    {
                      "params": [
                        "sum"
                      ],
                      "type": "aggregate"
                    },
                    {
                      "params": [
                        "value"
                      ],
                      "type": "alias"
                    }
                  ]
                ],
                "table": "images_processed",
                "timeColumn": "time",
                "timeColumnType": "timestamp",
                "where": [
                  {
                    "name": "$__timeFilter",
                    "params": [],
                    "type": "macro"
                  }
                ]
              }
            ],
            "thresholds": [],
            "timeFrom": null,
            "timeRegions": [],
            "timeShift": null,
            "title": "Images processed by model version",
            "tooltip": {
              "shared": true,
              "sort": 0,
              "value_type": "individual"
            },
            "type": "graph",
            "xaxis": {
              "buckets": null,
              "mode": "time",
              "name": null,
              "show": true,
              "values": []
            },
            "yaxes": [
              {
                "decimals": 0,
                "format": "short",
                "label": null,
                "logBase": 1,
                "max": null,
                "min": "0",
                "show": true
              },
              {
                "format": "short",
                "label": null,
                "logBase": 1,
                "max": null,
                "min": null,
                "show": true
              }
            ],
            "yaxis": {
              "align": false,
              "alignLevel": null
            }
          }
        ],
        "refresh": "5s",
        "schemaVersion": 26,
        "style": "dark",
        "tags": [],
        "templating": {
          "list": [
            {
              "current": {
                "selected": false,
                "text": "prometheus",
                "value": "prometheus"
              },
              "hide": 2,
              "includeAll": false,
              "label": "Datasource",
              "multi": false,
              "name": "datasource",
              "options": [],
              "query": "prometheus",
              "refresh": 1,
              "regex": "",
              "skipUrlSync": false,
              "type": "datasource"
            },
            {
              "current": {
                "text": "${namespace}",
                "value": "${namespace}"
              },
              "hide": 2,
              "label": "Namespace",
              "name": "namespace",
              "options": [
                {
                  "selected": true,
                  "text": "${namespace}",
                  "value": "${namespace}"
                }
              ],
              "query": "${namespace}",
              "skipUrlSync": false,
              "type": "constant"
            }
          ]
        },
        "time": {
          "from": "now-5m",
          "to": "now"
        },
        "timepicker": {
          "refresh_intervals": [
            "5s",
            "10s",
            "30s",
            "1m",
            "5m",
            "15m",
            "30m",
            "1h",
            "2h",
            "1d"
          ],
          "time_options": [
            "5m",
            "15m",
            "1h",
            "6h",
            "12h",
            "24h",
            "2d",
            "7d",
            "30d"
          ]
        },
        "timezone": "utc",
        "title": "XRay Lab",
        "uid": "hakbeh9Wz",
        "version": 4
      }
    name: xraylab-dashboard.json
    plugins:
    - name: larona-epict-panel
      version: 1.2.2
    - name: ryantxu-ajax-panel
      version: 0.0.7-dev
parameters:
- description: Route to the image server
  name: image_server_url
- description: Bucket base name
  name: bucket_base_name
- description: Project namespace
  name: namespace
labels:
  grafana: dashboard


[/opt/app-root/workshop/files] $ oc process -f 15_grafana-xraylab-dashboard-template.yaml -p im
age_server_url=https://image-server-xraylab-qbzxx.apps.cluster-nvkkk.nvkkk.sandbox1663.opentlc.
com -p bucket_base_name=xraylab-qbzxx -p namespace=xraylab-qbzxx | oc apply -f -
grafanadashboard.integreatly.org/xraylab-dashboard created

[/opt/app-root/workshop/files] $ cat 16_grafana-xraylab.yaml
apiVersion: integreatly.org/v1alpha1
kind: Grafana
metadata:
  name: xraylab-grafana
spec:
  ingress:
    enabled: true
  config:
    auth:
      disable_signout_menu: true
    auth.anonymous:
      enabled: true
    log:
      level: warn
      mode: console
    security:
      admin_password: secret
      admin_user: root
  dashboardLabelSelector:
    - matchExpressions:
        - key: app
          operator: In
          values:
            - grafana


```