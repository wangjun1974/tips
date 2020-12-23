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

# 看看这些脚本的内容
sh /projects/cloud-native-workshop-v2m2-labs/monolith/scripts/deploy-inventory.sh user1 && \
sh /projects/cloud-native-workshop-v2m2-labs/monolith/scripts/deploy-catalog.sh user1 && \
sh /projects/cloud-native-workshop-v2m2-labs/monolith/scripts/deploy-coolstore.sh user1

# deploy-inventory.sh 脚本内容如下
cat /projects/cloud-native-workshop-v2m2-labs/monolith/scripts/deploy-inventory.sh
#!/bin/bash

USERXX=$1
DELAY=$2

if [ -z $USERXX ]
  then
    echo "Usage: Input your username like deploy-inventory.sh user1"
    exit;
fi

echo Your username is $USERXX

echo Deploy Inventory service........

oc project $USERXX-inventory || oc new-project $USERXX-inventory
oc delete dc,deployment,bc,build,svc,route,pod,is --all

echo "Waiting 30 seconds to finialize deletion of resources..."
sleep 30

oc new-app --as-deployment-config -e POSTGRESQL_USER=inventory \
  -e POSTGRESQL_PASSWORD=mysecretpassword \
  -e POSTGRESQL_DATABASE=inventory openshift/postgresql:latest \
  --name=inventory-database

mvn clean package -DskipTests -f $CHE_PROJECTS_ROOT/cloud-native-workshop-v2m2-labs/inventory

oc label dc/inventory-database app.openshift.io/runtime=postgresql --overwrite && \
oc label dc/inventory app.kubernetes.io/part-of=inventory --overwrite && \
oc label dc/inventory-database app.kubernetes.io/part-of=inventory --overwrite && \
oc annotate dc/inventory app.openshift.io/connects-to=inventory-database --overwrite && \
oc annotate dc/inventory app.openshift.io/vcs-uri=https://github.com/RedHat-Middleware-Workshops/cloud-native-workshop-v2m2-labs.git --overwrite && \
oc annotate dc/inventory app.openshift.io/vcs-ref=ocp-4.5 --overwrite


# deploy-catalog.sh 脚本内容如下
cat /projects/cloud-native-workshop-v2m2-labs/monolith/scripts/deploy-catalog.sh
#!/bin/bash

USERXX=$1
DELAY=$2

if [ -z $USERXX ]
  then
    echo "Usage: Input your username like deploy-catalog.sh user1"
    exit;
fi

echo Your username is $USERXX

echo Deploy Catalog service........

oc project $USERXX-catalog || oc new-project $USERXX-catalog
oc delete dc,deployment,bc,build,svc,route,pod,is --all

echo "Waiting 30 seconds to finialize deletion of resources..."
sleep 30

sed -i "s/userXX/${USERXX}/g" /projects/cloud-native-workshop-v2m2-labs/catalog/src/main/resources/application-openshift.properties

oc new-app --as-deployment-config -e POSTGRESQL_USER=catalog \
             -e POSTGRESQL_PASSWORD=mysecretpassword \
             -e POSTGRESQL_DATABASE=catalog \
             openshift/postgresql:latest \
             --name=catalog-database

mvn clean package install spring-boot:repackage -DskipTests -f $CHE_PROJECTS_ROOT/cloud-native-workshop-v2m2-labs/catalog/

oc new-build registry.access.redhat.com/ubi8/openjdk-11 --binary --name=catalog-springboot -l app=catalog-springboot

if [ ! -z $DELAY ]
  then
    echo Delay is $DELAY
    sleep $DELAY
fi

oc start-build catalog-springboot --from-file $CHE_PROJECTS_ROOT/cloud-native-workshop-v2m2-labs/catalog/target/catalog-1.0.0-SNAPSHO
T.jar --follow
oc new-app catalog-springboot --as-deployment-config -e JAVA_OPTS_APPEND='-Dspring.profiles.active=openshift'
oc expose service catalog-springboot

REPLACEURL=$(oc get route -n $USERXX-catalog catalog-springboot -o jsonpath="{.spec.host}")
sed -i "s/REPLACEURL/${REPLACEURL}/g" /projects/cloud-native-workshop-v2m2-labs/monolith/src/main/webapp/app/services/catalog.js

oc label dc/catalog-database app.openshift.io/runtime=postgresql --overwrite && \
oc label dc/catalog-springboot app.openshift.io/runtime=spring --overwrite && \
oc label dc/catalog-springboot app.kubernetes.io/part-of=catalog --overwrite && \
oc label dc/catalog-database app.kubernetes.io/part-of=catalog --overwrite && \
oc annotate dc/catalog-springboot app.openshift.io/connects-to=catalog-database --overwrite && \
oc annotate dc/catalog-springboot app.openshift.io/vcs-uri=https://github.com/RedHat-Middleware-Workshops/cloud-native-workshop-v2m2-
labs.git --overwrite && \
oc annotate dc/catalog-springboot app.openshift.io/vcs-ref=ocp-4.5 --overwrite


# deploy-coolstore.sh 脚本内容如下
# 
cat /projects/cloud-native-workshop-v2m2-labs/monolith/scripts/deploy-coolstore.sh
#!/bin/bash

USERXX=$1

if [ -z $USERXX ]
  then
    echo "Usage: Input your username like deploy-boolstore.sh user1"
    exit;
fi

echo Your username is $USERXX

echo Deploy coolstore project........

oc project $USERXX-coolstore-dev || oc new-project $USERXX-coolstore-dev
oc delete dc,deployment,bc,build,svc,route,pod,is --all

echo "Waiting 30 seconds to finialize deletion of resources..."
sleep 30

oc new-app coolstore-monolith-binary-build --as-deployment-config -p USER_ID=$USERXX

mvn clean package -Popenshift -f $CHE_PROJECTS_ROOT/cloud-native-workshop-v2m2-labs/monolith/
oc start-build coolstore --from-file $CHE_PROJECTS_ROOT/cloud-native-workshop-v2m2-labs/monolith/deployments/ROOT.war

oc label dc/coolstore-postgresql app.openshift.io/runtime=postgresql --overwrite && \
oc label dc/coolstore app.openshift.io/runtime=jboss --overwrite && \
oc label dc/coolstore-postgresql app.kubernetes.io/part-of=coolstore --overwrite && \
oc label dc/coolstore app.kubernetes.io/part-of=coolstore --overwrite && \
oc annotate dc/coolstore app.openshift.io/connects-to=coolstore-postgresql --overwrite && \
oc annotate dc/coolstore app.openshift.io/vcs-uri=https://github.com/RedHat-Middleware-Workshops/cloud-native-workshop-v2m2-labs.git --overwrite && \
oc annotate dc/coolstore app.openshift.io/vcs-ref=ocp-4.5 --overwrite


# 
```