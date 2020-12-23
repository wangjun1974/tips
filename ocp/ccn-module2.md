### walkthrough
```

# 选择 user1-coolstore-prod 名字空间
# 为 dc/coolstore-prod-postgresql 和 dc/coolstore-prod 设置 label 和 annotate
oc project user1-coolstore-prod && \
oc label dc/coolstore-prod-postgresql app.openshift.io/runtime=postgresql --overwrite && \
oc label dc/coolstore-prod app.openshift.io/runtime=jboss --overwrite && \
oc label dc/coolstore-prod-postgresql app.kubernetes.io/part-of=coolstore-prod --overwrite && \
oc label dc/coolstore-prod app.kubernetes.io/part-of=coolstore-prod --overwrite && \
oc annotate dc/coolstore-prod app.openshift.io/connects-to=coolstore-prod-postgresql --overwrite && \
oc annotate dc/coolstore-prod app.openshift.io/vcs-uri=https://github.com/RedHat-Middleware-Workshops/cloud-native-workshop-v2m2-labs.git --overwrite && \
oc annotate dc/coolstore-prod app.openshift.io/vcs-ref=ocp-4.5 --overwrite

# 在使用 template 部署完 jenkins 之后，为 dc/jenkins 设置 label
oc label dc/jenkins app.openshift.io/runtime=jenkins --overwrite

# 查看 buildconfig monolith-pipeline
oc describe bc/monolith-pipeline -n user1-coolstore-prod
...
[jboss@workspace8hzk3wljwspv5vom cloud-native-workshop-v2m2-labs]$ oc describe bc/monolith-pipeline -n user1-coolstore-prod
Name:           monolith-pipeline
Namespace:      user1-coolstore-prod
Created:        24 minutes ago
Labels:         build=monolith-pipeline
                template=coolstore-monolith-pipeline-build
                template.openshift.io/template-instance-owner=9dc77256-b4a1-4d37-82b4-8251ef7a191b
Annotations:    <none>
Latest Version: Never built

Strategy:       JenkinsPipeline
Jenkinsfile contents:
  pipeline { 
    agent {
      label 'maven'
    }
    stages {
      stage ('Build') {
        steps {
          sleep 5
        }
      }
      stage ('Run Tests in DEV') {
        steps {
          sleep 10
        }
      }
      stage ('Deploy to PROD') {
        steps {
          script {
            openshift.withCluster() {
              openshift.tag("user1-coolstore-dev/coolstore:latest", "user1-coolstore-prod/coolstore:prod")
            }
          }
        }
      }
      stage ('Run Tests in PROD') {
        steps {
          sleep 30
        }
      }
    }
  }
Empty Source:   no input source provided

Build Run Policy:       Serial
Triggered by:           <none>
Webhook GitHub:
        URL:    https://172.30.0.1:443/apis/build.openshift.io/v1/namespaces/user1-coolstore-prod/buildconfigs/monolith-pipeline/webhooks/<secret>/github
Webhook Generic:
        URL:            https://172.30.0.1:443/apis/build.openshift.io/v1/namespaces/user1-coolstore-prod/buildconfigs/monolith-pipeline/webhooks/<secret>/generic
        AllowEnv:       false
Builds History Limit:
        Successful:     5
        Failed:         5

Events: <none>



JSPATH="$CHE_PROJECTS_ROOT/cloud-native-workshop-v2m2-labs/monolith/src/main/webapp/app/services/catalog.js"
CATALOGHOST=$(oc get route -n user1-catalog catalog-springboot -o jsonpath="{.spec.host}")
sed -i 's/REPLACEURL/'$CATALOGHOST'/' "$JSPATH"

mvn clean package -Popenshift -DskipTests -f $CHE_PROJECTS_ROOT/cloud-native-workshop-v2m2-labs/monolith

oc start-build -n user1-coolstore-dev coolstore --from-file=$CHE_PROJECTS_ROOT/cloud-native-workshop-v2m2-labs/monolith/deployments/ROOT.war --follow

oc -n user1-coolstore-dev rollout status -w dc/coolstore

```