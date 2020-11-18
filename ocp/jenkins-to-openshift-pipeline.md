### RHTR 2020
## jenkins pipeline
jenkins pipeline in lab
```
pipeline {
  agent {
      label 'maven'
  }
  environment {
    devProjectIsNew  = "false"
    prodProjectIsNew = "false"
  }
  stages {
    stage('Build App') {
      steps {
        withCredentials([usernamePassword(credentialsId: env.GITSECRET, usernameVariable: 'username', passwordVariable: 'password')]) {
          git branch: 'main', url: env.REPO, credentialsId: env.GITSECRET
        }
        sh "mvn install -DskipTests=true"
      }
    }
    stage('Test') {
      steps {
        sh "mvn test"
        step([$class: 'JUnitResultArchiver', testResults: '**/target/surefire-reports/TEST-*.xml'])
      }
    }           
    stage('Create Builder') {
      when {
        expression {
          openshift.withCluster() {
            openshift.withProject(env.DEV_PROJECT) {
              return !openshift.selector("bc","petclinic").exists();
            }
          }
        }
      }
      steps {
        script {
          openshift.withCluster() {
            openshift.withProject(env.DEV_PROJECT) {
              openshift.newBuild("--name=petclinic", "--image-stream=openshift/redhat-openjdk18-openshift:1.8", "--binary")
            }
          }
        }
      }
    }
    stage('Build Image') {
      steps {
        sh "cp target/*.jar target/petclinic.jar"
        script {
          openshift.withCluster() {
            openshift.withProject(env.DEV_PROJECT) {
              openshift.selector("bc", "petclinic").startBuild("--from-file=target/petclinic.jar", "--wait=true")
            }
          }
        }
      }
    }
    stage('Create DeploymentConfig for DEV') {
      when {
        expression {
          openshift.withCluster() {
            openshift.withProject(env.DEV_PROJECT) {
              return !openshift.selector("deploymentconfig","petclinic").exists();
            }
          }
        }
      }
      steps {
        script {
          openshift.withCluster() {
            openshift.withProject(env.DEV_PROJECT) {
              def app = openshift.newApp("petclinic:latest", "--as-deployment-config=true")
              app.narrow("svc").expose();
  
              def dc = openshift.selector("dc", "petclinic")
              while (dc.object().spec.replicas != dc.object().status.readyReplicas) {
                sleep 10
              }
              openshift.set("triggers", "dc/petclinic", "--manual")
              devProjectIsNew = "true"
            }
          }
        }
      }
    }
    stage('Deploy DEV') {
      when {
        expression {
          return devProjectIsNew == "false"
        }
      }
      steps {
        script {
          openshift.withCluster() {
            openshift.withProject(env.DEV_PROJECT) {
              openshift.selector("deploymentconfig", "petclinic").rollout().latest();
            }
          }
        }
      }
    }
    stage('Promote to PROD?') {
      steps {
        script {
          openshift.withCluster() {
            openshift.tag("${env.DEV_PROJECT}/petclinic:latest", "${env.PROD_PROJECT}/petclinic:prod")
          }
        }
      }
    }
    stage('Create DeploymentConfig for PROD') {
      when {
        expression {
          openshift.withCluster() {
            openshift.withProject(env.PROD_PROJECT) {
             return !openshift.selector("deploymentconfig","petclinic").exists();
            }
          }
        }
      }
      steps {
        script {
          openshift.withCluster() {
            openshift.withProject(env.PROD_PROJECT) {
              def app = openshift.newApp("petclinic:prod", "--as-deployment-config=true")
              app.narrow("svc").expose();
  
              def dc = openshift.selector("dc", "petclinic")
              while (dc.object().spec.replicas != dc.object().status.availableReplicas) {
                sleep 10
              }
              openshift.set("triggers", "dc/petclinic", "--manual")

              prodProjectIsNew = "true"
            }
          }
        }
      }
    }
    stage('Deploy PROD') {
      when {
        expression {
          return prodProjectIsNew == "false"
        }
      }
      steps {
        script {
          openshift.withCluster() {
            openshift.withProject(env.PROD_PROJECT) {
              openshift.selector("deploymentconfig", "petclinic").rollout().latest();
            }
          }
        }
      }
    }
  }
}

```

## openshift pipeline task

### task s2i-java-11-binary-ns
https://raw.githubusercontent.com/redhat-gpte-labs/rhtr2020_pipelines/master/workshop/content/tekton/tasks/s2i-java-11-binary-ns.yaml
```
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: s2i-java-11-binary-namespace
spec:
  params:
    - name: PATH_CONTEXT
      description: The location of the path to run s2i from
      default: .
      type: string
    - name: TLSVERIFY
      description: Verify the TLS on the registry endpoint (for push/pull to a non-TLS registry)
      default: "false"
      type: string
    - name: OUTPUT_IMAGE_STREAM
      type: string
      description: The application image url in registry
    - name: NAMESPACE
      type: string
      description: Namespace where to push the image
  workspaces:
    - name: source
  steps:
    - name: generate
      image: registry.redhat.io/ocp-tools-43-tech-preview/source-to-image-rhel8
      workingdir: $(workspaces.source.path)/target
      command:
        - 's2i'
        - 'build'
        - '$(params.PATH_CONTEXT)'
        - 'registry.access.redhat.com/openjdk/openjdk-11-rhel7'
        - '--image-scripts-url'
        - 'image:///usr/local/s2i'
        - '--as-dockerfile'
        - '/gen-source/Dockerfile.gen'
      volumeMounts:
        - name: envparams
          mountPath: /env-params
        - name: gen-source
          mountPath: /gen-source
    - name: build
      image: registry.redhat.io/rhel8/buildah
      workingdir: /gen-source
      command: 
        - buildah
        - bud
        - --tls-verify=$(params.TLSVERIFY)
        - --layers
        - -f
        - /gen-source/Dockerfile.gen
        - -t
        - image-registry.openshift-image-registry.svc:5000/$(params.NAMESPACE)/$(params.OUTPUT_IMAGE_STREAM)
        - .
      volumeMounts:
        - name: varlibcontainers
          mountPath: /var/lib/containers
        - name: gen-source
          mountPath: /gen-source
      securityContext:
        privileged: true
    - name: push
      image: registry.redhat.io/rhel8/buildah
      command:
        - buildah
        - push
        - --tls-verify=$(params.TLSVERIFY)
        - image-registry.openshift-image-registry.svc:5000/$(params.NAMESPACE)/$(params.OUTPUT_IMAGE_STREAM)
        - docker://image-registry.openshift-image-registry.svc:5000/$(params.NAMESPACE)/$(params.OUTPUT_IMAGE_STREAM)
      volumeMounts:
        - name: varlibcontainers
          mountPath: /var/lib/containers
      securityContext:
        privileged: true
  volumes:
    - name: varlibcontainers
      emptyDir: {}
    - name: gen-source
      emptyDir: {}
    - name: envparams
      emptyDir: {}
```

### task promote-to-project
https://raw.githubusercontent.com/redhat-gpte-labs/rhtr2020_pipelines/master/workshop/content/tekton/tasks/promote-to-project.yaml
```
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: promote-to-prod
spec:
  params:
    - name: IMAGE_STREAM
      type: string
    - name: DEPLOYMENT
      type: string
    - name: DEV_NAMESPACE
      type: string
    - name: PROD_NAMESPACE
      type: string
  steps:
    - image: 'image-registry.openshift-image-registry.svc:5000/openshift/cli:latest'
      name: deploy
      resources: {}
      script: >
        #!/usr/bin/env bash


        set -x

        oc tag $(params.DEV_NAMESPACE)/$(params.IMAGE_STREAM)  $(params.PROD_NAMESPACE)/$(params.DEPLOYMENT):prod   
```

### task deploy-to-project
https://raw.githubusercontent.com/redhat-gpte-labs/rhtr2020_pipelines/master/workshop/content/tekton/tasks/deploy-to-project.yaml
```
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  name: deploy-to-project
spec:
  params:
    - name: DEPLOYMENT
      type: string 
    - name: IMAGE_STREAM
      type: string
    - name: NAMESPACE
      type: string
  steps:
    - image: 'image-registry.openshift-image-registry.svc:5000/openshift/cli:latest'
      name: deploy
      resources: {}
      script: >
        #!/usr/bin/env bash


        set -x

        image_ref="image-registry.openshift-image-registry.svc:5000/$(params.NAMESPACE)/$(params.IMAGE_STREAM)"

        echo "Deploying $image_ref"

        deployment=`oc get deployment $(params.DEPLOYMENT) -n $(params.NAMESPACE)`

        if [ $? -ne 0 ]; then
          oc new-app $(params.IMAGE_STREAM) --name $(params.DEPLOYMENT) -n $(params.NAMESPACE)
          oc expose svc/$(params.DEPLOYMENT) -n $(params.NAMESPACE)
        else
          oc set image deployment/$(params.DEPLOYMENT) $(params.DEPLOYMENT)=$image_ref -n $(params.NAMESPACE)
          oc patch deployment $(params.DEPLOYMENT) -p "{\"spec\": {\"template\": {\"metadata\": { \"labels\": {  \"redeploy\": \"$(date +%s)\"}}}}}" -n $(params.NAMESPACE)
          oc rollout status deployment/$(params.DEPLOYMENT) -n $(params.NAMESPACE)
        fi
```

### OpenShift objects 内容
```
$ oc get task s2i-java-11-binary-namespace -o yaml -n pipeline-mzpll
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  creationTimestamp: "2020-11-18T06:15:53Z"
  generation: 1
  managedFields:
  - apiVersion: tekton.dev/v1beta1
    fieldsType: FieldsV1
    fieldsV1:
      f:spec:
        .: {}
        f:params: {}
        f:steps: {}
        f:volumes: {}
        f:workspaces: {}
    manager: oc
    operation: Update
    time: "2020-11-18T06:15:53Z"
  name: s2i-java-11-binary-namespace
  namespace: pipeline-mzpll
  resourceVersion: "8211662"
  selfLink: /apis/tekton.dev/v1beta1/namespaces/pipeline-mzpll/tasks/s2i-java-11-binary-namespa
ce
  uid: 5345733c-6f79-459f-aeff-8c6440a6648a
spec:
  params:
  - default: .
    description: The location of the path to run s2i from
    name: PATH_CONTEXT
    type: string
  - default: "false"
    description: Verify the TLS on the registry endpoint (for push/pull to a non-TLS
      registry)
    name: TLSVERIFY
    type: string
  - description: The application image url in registry
    name: OUTPUT_IMAGE_STREAM
    type: string
  - description: Namespace where to push the image
    name: NAMESPACE
    type: string
  steps:
  - command:
    - s2i
    - build
    - $(params.PATH_CONTEXT)
    - registry.access.redhat.com/openjdk/openjdk-11-rhel7
    - --image-scripts-url
    - image:///usr/local/s2i
    - --as-dockerfile
    - /gen-source/Dockerfile.gen
    image: registry.redhat.io/ocp-tools-43-tech-preview/source-to-image-rhel8
    name: generate
    resources: {}
    volumeMounts:
    - mountPath: /env-params
      name: envparams
    - mountPath: /gen-source
      name: gen-source
    workingDir: $(workspaces.source.path)/target
  - command:
    - buildah
    - bud
    - --tls-verify=$(params.TLSVERIFY)
    - --layers
    - -f
    - /gen-source/Dockerfile.gen
    - -t
    - image-registry.openshift-image-registry.svc:5000/$(params.NAMESPACE)/$(params.OUTPUT_IMAG
E_STREAM)
    - .
    image: registry.redhat.io/rhel8/buildah
    name: build
    resources: {}
    securityContext:
      privileged: true
    volumeMounts:
    - mountPath: /var/lib/containers
      name: varlibcontainers
    - mountPath: /gen-source
      name: gen-source
    workingDir: /gen-source
  - command:
    - buildah
    - push
    - --tls-verify=$(params.TLSVERIFY)
    - image-registry.openshift-image-registry.svc:5000/$(params.NAMESPACE)/$(params.OUTPUT_IMAG
E_STREAM)
    - docker://image-registry.openshift-image-registry.svc:5000/$(params.NAMESPACE)/$(params.OU
TPUT_IMAGE_STREAM)
    image: registry.redhat.io/rhel8/buildah
    name: push
    resources: {}
    securityContext:
      privileged: true
    volumeMounts:
    - mountPath: /var/lib/containers
      name: varlibcontainers
  volumes:
  - emptyDir: {}
    name: varlibcontainers
  - emptyDir: {}
    name: gen-source
  - emptyDir: {}
    name: envparams
  workspaces:
  - name: source

oc get task promote-to-prod -o yaml -n pipeline-mzpll
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  creationTimestamp: "2020-11-18T06:16:05Z"
  generation: 1
  managedFields:
  - apiVersion: tekton.dev/v1beta1
    fieldsType: FieldsV1
    fieldsV1:
      f:spec:
        .: {}
        f:params: {}
        f:steps: {}
    manager: oc
    operation: Update
    time: "2020-11-18T06:16:05Z"
  name: promote-to-prod
  namespace: pipeline-mzpll
  resourceVersion: "8211923"
  selfLink: /apis/tekton.dev/v1beta1/namespaces/pipeline-mzpll/tasks/promote-to-prod
  uid: 02b7f062-e875-434f-b59f-d20dc141d791
spec:
  params:
  - name: IMAGE_STREAM
    type: string
  - name: DEPLOYMENT
    type: string
  - name: DEV_NAMESPACE
    type: string
  - name: PROD_NAMESPACE
    type: string
  steps:
  - image: image-registry.openshift-image-registry.svc:5000/openshift/cli:latest
    name: deploy
    resources: {}
    script: "#!/usr/bin/env bash\n\nset -x\noc tag $(params.DEV_NAMESPACE)/$(params.IMAGE_STREA
M)
      \ $(params.PROD_NAMESPACE)/$(params.DEPLOYMENT):prod   \n"

oc get task deploy-to-project -o yaml -n pipeline-mzpll
apiVersion: tekton.dev/v1beta1
kind: Task
metadata:
  creationTimestamp: "2020-11-18T06:16:07Z"
  generation: 1
  managedFields:
  - apiVersion: tekton.dev/v1beta1
    fieldsType: FieldsV1
    fieldsV1:
      f:spec:
        .: {}
        f:params: {}
        f:steps: {}
    manager: oc
    operation: Update
    time: "2020-11-18T06:16:07Z"
  name: deploy-to-project
  namespace: pipeline-mzpll
  resourceVersion: "8211932"
  selfLink: /apis/tekton.dev/v1beta1/namespaces/pipeline-mzpll/tasks/deploy-to-project
  uid: fbf59b0a-9108-4f75-ab22-5a2f115efe72
spec:
  params:
  - name: DEPLOYMENT
    type: string
  - name: IMAGE_STREAM
    type: string
  - name: NAMESPACE
    type: string
  steps:
  - image: image-registry.openshift-image-registry.svc:5000/openshift/cli:latest
    name: deploy
    resources: {}
    script: |
      #!/usr/bin/env bash

      set -x
      image_ref="image-registry.openshift-image-registry.svc:5000/$(params.NAMESPACE)/$(params.
IMAGE_STREAM)"
      echo "Deploying $image_ref"
      deployment=`oc get deployment $(params.DEPLOYMENT) -n $(params.NAMESPACE)`
      if [ $? -ne 0 ]; then
        oc new-app $(params.IMAGE_STREAM) --name $(params.DEPLOYMENT) -n $(params.NAMESPACE)
        oc expose svc/$(params.DEPLOYMENT) -n $(params.NAMESPACE)
      else
        oc set image deployment/$(params.DEPLOYMENT) $(params.DEPLOYMENT)=$image_ref -n $(param
s.NAMESPACE)
        oc patch deployment $(params.DEPLOYMENT) -p "{\"spec\": {\"template\": {\"metadata\": {
 \"labels\": {  \"redeploy\": \"$(date +%s)\"}}}}}" -n $(params.NAMESPACE)
        oc rollout status deployment/$(params.DEPLOYMENT) -n $(params.NAMESPACE)
      fi

oc get clustertasks git-clone -o yaml -n pipeline-mzpll
apiVersion: tekton.dev/v1beta1
kind: ClusterTask
metadata:
  annotations:
    manifestival: new
  creationTimestamp: "2020-11-05T00:24:38Z"
  generation: 1
  labels:
    operator.tekton.dev/provider-type: community
  managedFields:
  - apiVersion: tekton.dev/v1beta1
    fieldsType: FieldsV1
    fieldsV1:
      f:metadata:
        f:annotations:
          .: {}
          f:manifestival: {}
        f:labels:
          .: {}
          f:operator.tekton.dev/provider-type: {}
        f:ownerReferences: {}
      f:spec:
        .: {}
        f:params: {}
        f:results: {}
        f:steps: {}
        f:workspaces: {}
    manager: openshift-pipelines-operator
    operation: Update
    time: "2020-11-05T00:24:38Z"
  name: git-clone
  ownerReferences:
  - apiVersion: operator.tekton.dev/v1alpha1
    blockOwnerDeletion: true
    controller: true
    kind: Config
    name: cluster
    uid: 41e207c7-227f-4baf-bdd9-f36ca160bbfe
  resourceVersion: "25424"
  selfLink: /apis/tekton.dev/v1beta1/clustertasks/git-clone
  uid: b3c93074-4a7d-4e31-a9a5-6c94d898d9fe
spec:
  params:
  - description: git url to clone
    name: url
    type: string
  - default: master
    description: git revision to checkout (branch, tag, sha, ref…)
    name: revision
    type: string
  - default: ""
    description: (optional) git refspec to fetch before checking out revision
    name: refspec
    type: string
  - default: "true"
    description: defines if the resource should initialize and fetch the submodules
    name: submodules
    type: string
  - default: "1"
    description: performs a shallow clone where only the most recent commit(s) will
      be fetched
    name: depth
    type: string
  - default: "true"
    description: defines if http.sslVerify should be set to true or false in the global
      git config
    name: sslVerify
    type: string
  - default: ""
    description: subdirectory inside the "output" workspace to clone the git repo
      into
    name: subdirectory
    type: string
  - default: "false"
    description: clean out the contents of the repo's destination directory (if it
      already exists) before trying to clone the repo there
    name: deleteExisting
    type: string
  - default: ""
    description: git HTTP proxy server for non-SSL requests
    name: httpProxy
    type: string
  - default: ""
    description: git HTTPS proxy server for SSL requests
    name: httpsProxy
    type: string
  - default: ""
    description: git no proxy - opt out of proxying HTTP/HTTPS requests
    name: noProxy
    type: string
  results:
  - description: The precise commit SHA that was fetched by this Task
    name: commit
  steps:
  - image: gcr.io/tekton-releases/github.com/tektoncd/pipeline/cmd/git-init:v0.12.1
    name: clone
    resources: {}
    script: |
      CHECKOUT_DIR="$(workspaces.output.path)/$(params.subdirectory)"

      cleandir() {
        # Delete any existing contents of the repo directory if it exists.
        #
        # We don't just "rm -rf $CHECKOUT_DIR" because $CHECKOUT_DIR might be "/"
        # or the root of a mounted volume.
        if [[ -d "$CHECKOUT_DIR" ]] ; then
          # Delete non-hidden files and directories
          rm -rf "$CHECKOUT_DIR"/*
          # Delete files and directories starting with . but excluding ..
          rm -rf "$CHECKOUT_DIR"/.[!.]*
          # Delete files and directories starting with .. plus any other character
          rm -rf "$CHECKOUT_DIR"/..?*
        fi
      }

      if [[ "$(params.deleteExisting)" == "true" ]] ; then
        cleandir
      fi

      test -z "$(params.httpProxy)" || export HTTP_PROXY=$(params.httpProxy)
      test -z "$(params.httpsProxy)" || export HTTPS_PROXY=$(params.httpsProxy)
      test -z "$(params.noProxy)" || export NO_PROXY=$(params.noProxy)

      /ko-app/git-init \
        -url "$(params.url)" \
        -revision "$(params.revision)" \
        -refspec "$(params.refspec)" \
        -path "$CHECKOUT_DIR" \
        -sslVerify="$(params.sslVerify)" \
        -submodules="$(params.submodules)" \
        -depth "$(params.depth)"
      cd "$CHECKOUT_DIR"
      RESULT_SHA="$(git rev-parse HEAD | tr -d '\n')"
      EXIT_CODE="$?"
      if [ "$EXIT_CODE" != 0 ]
      then
        exit $EXIT_CODE
      fi
      # Make sure we don't add a trailing newline to the result!
      echo -n "$RESULT_SHA" > $(results.commit.path)
  workspaces:
  - description: The git repo will be cloned onto the volume backing this workspace
    name: output


oc get clustertasks maven -o yaml -n pipeline-mzpll
apiVersion: tekton.dev/v1beta1
kind: ClusterTask
metadata:
  annotations:
    manifestival: new
  creationTimestamp: "2020-11-05T00:24:38Z"
  generation: 1
  labels:
    operator.tekton.dev/provider-type: community
  managedFields:
  - apiVersion: tekton.dev/v1beta1
    fieldsType: FieldsV1
    fieldsV1:
      f:metadata:
        f:annotations:
          .: {}
          f:manifestival: {}
        f:labels:
          .: {}
          f:operator.tekton.dev/provider-type: {}
        f:ownerReferences: {}
      f:spec:
        .: {}
        f:params: {}
        f:steps: {}
        f:workspaces: {}
    manager: openshift-pipelines-operator
    operation: Update
    time: "2020-11-05T00:24:38Z"
  name: maven
  ownerReferences:
  - apiVersion: operator.tekton.dev/v1alpha1
    blockOwnerDeletion: true
    controller: true
    kind: Config
    name: cluster
    uid: 41e207c7-227f-4baf-bdd9-f36ca160bbfe
  resourceVersion: "25426"
  selfLink: /apis/tekton.dev/v1beta1/clustertasks/maven
  uid: 26aaa16b-8450-44c5-9c6c-3e8b0d912690
spec:
  params:
  - default:
    - package
    description: maven goals to run
    name: GOALS
    type: array
  - default: ""
    description: The Maven repository mirror url
    name: MAVEN_MIRROR_URL
    type: string
  - default: ""
    description: The username for the proxy server
    name: PROXY_USER
    type: string
  - default: ""
    description: The password for the proxy server
    name: PROXY_PASSWORD
    type: string
  - default: ""
    description: Port number for the proxy server
    name: PROXY_PORT
    type: string
  - default: ""
    description: Proxy server Host
    name: PROXY_HOST
    type: string
  - default: ""
    description: Non proxy server host
    name: PROXY_NON_PROXY_HOSTS
    type: string
  - default: http
    description: Protocol for the proxy ie http or https
    name: PROXY_PROTOCOL
    type: string
  steps:
  - image: registry.access.redhat.com/ubi8/ubi-minimal:latest
    name: mvn-settings
    resources: {}
    script: |
      #!/usr/bin/env bash

      [[ -f $(workspaces.maven-settings.path)/settings.xml ]] && \
      echo 'using existing $(workspaces.maven-settings.path)/settings.xml' && \
      cat $(workspaces.maven-settings.path)/settings.xml && exit 0

      cat > $(workspaces.maven-settings.path)/settings.xml <<EOF
      <settings>
        <mirrors>
          <!-- The mirrors added here are generated from environment variables. Don't change. -
->
          <!-- ### mirrors from ENV ### -->
        </mirrors>
        <proxies>
          <!-- The proxies added here are generated from environment variables. Don't change. -
->
          <!-- ### HTTP proxy from ENV ### -->
        </proxies>
      </settings>
      EOF

      xml=""
      if [ -n "$(params.PROXY_HOST)" -a -n "$(params.PROXY_PORT)" ]; then
        xml="<proxy>\
          <id>genproxy</id>\
          <active>true</active>\
          <protocol>$(params.PROXY_PROTOCOL)</protocol>\
          <host>$(params.PROXY_HOST)</host>\
          <port>$(params.PROXY_PORT)</port>"
        if [ -n "$(params.PROXY_USER)" -a -n "$(params.PROXY_PASSWORD)" ]; then
          xml="$xml\
              <username>$(params.PROXY_USER)</username>\
              <password>$(params.PROXY_PASSWORD)</password>"
        fi
        if [ -n "$(params.PROXY_NON_PROXY_HOSTS)" ]; then
          xml="$xml\
              <nonProxyHosts>$(params.PROXY_NON_PROXY_HOSTS)</nonProxyHosts>"
        fi
        xml="$xml\
            </proxy>"
        sed -i "s|<!-- ### HTTP proxy from ENV ### -->|$xml|" $(workspaces.maven-settings.path)
/settings.xml
      fi

      if [ -n "$(params.MAVEN_MIRROR_URL)" ]; then
        xml="    <mirror>\
          <id>mirror.default</id>\
          <url>$(params.MAVEN_MIRROR_URL)</url>\
          <mirrorOf>central</mirrorOf>\
        </mirror>"
        sed -i "s|<!-- ### mirrors from ENV ### -->|$xml|" $(workspaces.maven-settings.path)/se
ttings.xml
      fi

      [[ -f $(workspaces.maven-settings.path)/settings.xml ]] && cat $(workspaces.maven-setting
s.path)/settings.xml
      [[ -f $(workspaces.maven-settings.path)/settings.xml ]] || echo skipping settings
  - args:
    - -s
    - $(workspaces.maven-settings.path)/settings.xml
    - $(params.GOALS)
    command:
    - /usr/bin/mvn
    image: gcr.io/cloud-builders/mvn
    name: mvn-goals
    resources: {}
    workingDir: $(workspaces.source.path)
  workspaces:
  - name: source
  - name: maven-settings

```

### pvc app-source 内容
https://raw.githubusercontent.com/redhat-gpte-labs/rhtr2020_pipelines/master/workshop/content/tekton/pvc/workspace-pvc.yaml
```
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-source-pvc
spec:
  resources:
    requests:
      storage: 1Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Recycle 
```

### create openshift pipeline
```
cat <<'EOF' | oc apply -n pipeline-mzpll -f -
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: petclinic-pipeline
spec:
  params:
  - default: petclinic
    description: The application deployment name
    name: APP_NAME
    type: string
  - default: >-
      https://gitea-gitea.apps.cluster-bscng.bscng.sandbox302.opentlc.com/jwang-redhat.com/spring-petclinic
    description: The application git repository url
    name: APP_GIT_URL
    type: string
  - default: main
    description: The application git repository revision
    name: APP_GIT_REVISION
    type: string
  - default: 'petclinic:latest'
    description: The application image stream
    name: APP_IMAGE_STREAM
    type: string
  - default: petclinic-mzpll-dev
    name: DEV_NAMESPACE
    type: string
  - default: petclinic-mzpll-prod
    name: PROD_NAMESPACE
    type: string
  - default: http://nexus.nexus.svc:8081/repository/maven-all-public/
    name: MAVEN_MIRROR_URL
    type: string

  tasks:
  - name: git-clone
    params:
    - name: url
      value: $(params.APP_GIT_URL)
    - name: revision
      value: $(params.APP_GIT_REVISION)
    - name: deleteExisting
      value: 'true'
    taskRef:
      kind: ClusterTask
      name: git-clone
    workspaces:
    - name: output
      workspace: app-source

  - name: build
    params:
    - name: GOALS
      value:
      - -DskipTests
      - clean
      - package
    - name: MAVEN_MIRROR_URL
      value: $(params.MAVEN_MIRROR_URL)
    runAfter:
    - git-clone
    taskRef:
      kind: ClusterTask
      name: maven
    workspaces:
    - name: source
      workspace: app-source
    - name: maven-settings
      workspace: maven-settings

  - name: run-test
    params:
    - name: GOALS
      value:
      - test
    - name: MAVEN_MIRROR_URL
      value: $(params.MAVEN_MIRROR_URL)
    runAfter:
    - build
    taskRef:
      kind: ClusterTask
      name: maven
    workspaces:
    - name: source
      workspace: app-source
    - name: maven-settings
      workspace: maven-settings

  - name: build-image
    params:
    - name: TLSVERIFY
      value: 'false'
    - name: OUTPUT_IMAGE_STREAM
      value: $(params.APP_IMAGE_STREAM)
    - name: NAMESPACE
      value: $(params.DEV_NAMESPACE)
    runAfter:
    - run-test
    taskRef:
      kind: Task
      name: s2i-java-11-binary-namespace
    workspaces:
    - name: source
      workspace: app-source
  - name: deploy-to-dev
    params:
    - name: DEPLOYMENT
      value: $(params.APP_NAME)
    - name: IMAGE_STREAM
      value: $(params.APP_IMAGE_STREAM)
    - name: NAMESPACE
      value: $(params.DEV_NAMESPACE)
    runAfter:
    - build-image
    taskRef:
      kind: Task
      name: deploy-to-project

  - name: promote-to-prod
    params:
    - name: IMAGE_STREAM
      value: $(params.APP_IMAGE_STREAM)
    - name: DEPLOYMENT
      value: $(params.APP_NAME)
    - name: DEV_NAMESPACE
      value: $(params.DEV_NAMESPACE)
    - name: PROD_NAMESPACE
      value: $(params.PROD_NAMESPACE)
    runAfter:
    - deploy-to-dev
    taskRef:
      kind: Task
      name: promote-to-prod

  - name: deploy-to-prod
    params:
    - name: DEPLOYMENT
      value: $(params.APP_NAME)
    - name: IMAGE_STREAM
      value: '$(params.APP_NAME):prod'
    - name: NAMESPACE
      value: $(params.PROD_NAMESPACE)
    runAfter:
    - promote-to-prod
    taskRef:
      kind: Task
      name: deploy-to-project

  workspaces:
  - name: app-source
  - name: maven-settings
EOF
```

### test openshift pipeline tasks
```
# create secret git-secret
[~] $ oc create secret generic git-secret --from-literal=username=jwang-redhat.com --from-liter
al=password=rhtr2020 --type "kubernetes.io/basic-auth" -n pipeline-mzpll
secret/git-secret created

# Annotate the secret with the URL of the git server we are using
[~] $ oc annotate secret git-secret "tekton.dev/git-0=https://gitea-gitea.apps.cluster-bscng.bs
cng.sandbox302.opentlc.com/jwang-redhat.com/spring-petclinic" -n pipeline-mzpll
secret/git-secret annotated

# Finally attach that secret to pipeline service account that will be used by Tekton to execute our tasks
[~] $ oc secrets link pipeline git-secret -n pipeline-mzpll

# Verify that the secret has been linked
[~] $ oc describe sa pipeline -n pipeline-mzpll
Name:                pipeline
Namespace:           pipeline-mzpll
Labels:              <none>
Annotations:         <none>
Image pull secrets:  pipeline-dockercfg-2x9nh
Mountable secrets:   pipeline-token-784hl
                     pipeline-dockercfg-2x9nh
                     git-secret
Tokens:              pipeline-token-784hl
                     pipeline-token-dfc77
Events:              <none>

# Ensure that pipeline-mzpll project is the active project
[~] $ oc project pipeline-mzpll
Already on project "pipeline-mzpll" on server "https://api.cluster-bscng.bscng.sandbox302.opent
lc.com:6443".

# Add the edit role in petclinic-mzpll-dev to all service accounts in project pipeline-mzpll
[~] $ oc policy add-role-to-group edit system:serviceaccounts:pipeline-mzpll -n petclinic-mzpll
-dev
clusterrole.rbac.authorization.k8s.io/edit added: "system:serviceaccounts:pipeline-mzpll"

# And add the edit role for project petclinic-mzpll-prod
[~] $ oc policy add-role-to-group edit system:serviceaccounts:pipeline-mzpll -n petclinic-mzpll
-prod
clusterrole.rbac.authorization.k8s.io/edit added: "system:serviceaccounts:pipeline-mzpll"

# To run a single task create a new TaskRun called git-clone-taskrun.

cat <<'EOF' | oc apply -n pipeline-mzpll -f -
apiVersion: tekton.dev/v1beta1
kind: TaskRun
metadata:
  name: git-clone-taskrun
spec:
  params:
  - name: url
    value: https://gitea-gitea.apps.cluster-bscng.bscng.sandbox302.opentlc.com/jwang-redhat.com/spring-petclinic
  - name: revision
    value: main
  - name: deleteExisting
    value: 'true'
  taskRef:
    kind: ClusterTask
    name: git-clone
  workspaces:
  - name: output
    persistentVolumeClaim:
      claimName: app-source-pvc
EOF

taskrun.tekton.dev/git-clone-taskrun created

# Using the tkn command follow the log
[~] $ tkn taskrun logs -f git-clone-taskrun
[clone] + CHECKOUT_DIR=/workspace/output/
[clone] + '[[' true '==' true ]]
[clone] + cleandir
[clone] + '[[' -d /workspace/output/ ]]
[clone] + rm -rf /workspace/output//lost+found
[clone] + rm -rf '/workspace/output//.[!.]*'
[clone] + rm -rf '/workspace/output//..?*'
[clone] + test -z
[clone] + test -z
[clone] + test -z
[clone] + /ko-app/git-init -url https://gitea-gitea.apps.cluster-bscng.bscng.sandbox302.opentlc
.com/jwang-redhat.com/spring-petclinic -revision main -refspec  -path /workspace/output/ '-sslV
erify=true' '-submodules=true' -depth 1
[clone] {"level":"info","ts":1605681642.9741805,"caller":"git/git.go:136","msg":"Successfully c
loned https://gitea-gitea.apps.cluster-bscng.bscng.sandbox302.opentlc.com/jwang-redhat.com/spri
ng-petclinic @ 8b1ac6736e3347f34d79620170983fc4c99746cb (grafted, HEAD, origin/main) in path /w
orkspace/output/"}
[clone] {"level":"info","ts":1605681643.0006237,"caller":"git/git.go:177","msg":"Successfully i
nitialized and updated submodules in path /workspace/output/"}
[clone] + cd /workspace/output/
[clone] + git rev-parse HEAD
[clone] + tr -d '\n'
[clone] + RESULT_SHA=8b1ac6736e3347f34d79620170983fc4c99746cb
[clone] + EXIT_CODE=0
[clone] + '[' 0 '!=' 0 ]
[clone] + echo -n 8b1ac6736e3347f34d79620170983fc4c99746cb

# Test maven build Task
# Create a TaskRun called maven-build-taskrun:

cat <<'EOF' | oc apply -n pipeline-mzpll -f -
apiVersion: tekton.dev/v1beta1
kind: TaskRun
metadata:
  name: maven-build-taskrun
spec:
  params:
  - name: GOALS
    value:
    - -DskipTests
    - clean
    - package
  - name: MAVEN_MIRROR_URL
    value: http://nexus.nexus.svc:8081/repository/maven-all-public/
  taskRef:
    kind: ClusterTask
    name: maven
  workspaces:
  - name: source
    persistentVolumeClaim:
      claimName: app-source-pvc
  - name: maven-settings
    emptyDir: {}
EOF

taskrun.tekton.dev/maven-build-taskrun created

# Using the tkn command follow the log
[~] $ tkn taskrun logs -f maven-build-taskrun

[mvn-settings] <settings>
[mvn-settings]   <mirrors>
[mvn-settings]     <!-- The mirrors added here are generated from environment variables. Don't
change. -->
[mvn-settings]         <mirror>    <id>mirror.default</id>    <url>http://nexus.nexus.svc:8081/
repository/maven-all-public/</url>    <mirrorOf>central</mirrorOf>  </mirror>
[mvn-settings]   </mirrors>
[mvn-settings]   <proxies>
[mvn-settings]     <!-- The proxies added here are generated from environment variables. Don't
change. -->
[mvn-settings]     <!-- ### HTTP proxy from ENV ### -->
[mvn-settings]   </proxies>
[mvn-settings] </settings>

[mvn-goals] [INFO] Scanning for projects...
[mvn-goals] Downloading from spring-snapshots: https://repo.spring.io/snapshot/org/springframew
ork/boot/spring-boot-starter-parent/2.3.5.RELEASE/spring-boot-starter-parent-2.3.5.RELEASE.pom
[mvn-goals] Downloading from spring-milestones: https://repo.spring.io/milestone/org/springfram
ework/boot/spring-boot-starter-parent/2.3.5.RELEASE/spring-boot-starter-parent-2.3.5.RELEASE.po
m
Downloaded from spring-milestones: https://repo.spring.io/milestone/org/springframework/boot/sp
ring-boot-starter-parent/2.3.5.RELEASE/spring-boot-starter-parent-2.3.5.RELEASE.pom (8.6 kB at
37 kB/s)
[mvn-goals] Downloading from spring-snapshots: https://repo.spring.io/snapshot/org/springframew
ork/boot/spring-boot-dependencies/2.3.5.RELEASE/spring-boot-dependencies-2.3.5.RELEASE.pom
...
[mvn-goals] Downloaded from mirror.default: http://nexus.nexus.svc:8081/repository/maven-all-pu
blic/org/apache/maven/maven-compat/3.0/maven-compat-3.0.jar (285 kB at 7.9 MB/s)
[mvn-goals] Downloaded from mirror.default: http://nexus.nexus.svc:8081/repository/maven-all-pu
blic/org/tukaani/xz/1.8/xz-1.8.jar (109 kB at 3.1 MB/s)
[mvn-goals] [INFO] Building jar: /workspace/source/target/spring-petclinic-2.3.0.BUILD-SNAPSHOT
.jar
[mvn-goals] [INFO]
[mvn-goals] [INFO] --- spring-boot-maven-plugin:2.3.5.RELEASE:repackage (repackage) @ spring-pe
tclinic ---
[mvn-goals] [INFO] Replacing main artifact with repackaged archive
[mvn-goals] [INFO] ------------------------------------------------------------------------
[mvn-goals] [INFO] BUILD SUCCESS
[mvn-goals] [INFO] ------------------------------------------------------------------------
[mvn-goals] [INFO] Total time:  03:26 min
[mvn-goals] [INFO] Finished at: 2020-11-18T06:46:52Z
[mvn-goals] [INFO] ------------------------------------------------------------------------

# Test maven test Task
# Create a TaskRun called maven-test-taskrun

cat <<'EOF' | oc apply -n pipeline-mzpll -f -
apiVersion: tekton.dev/v1beta1
kind: TaskRun
metadata:
  name: maven-test-taskrun
spec:
  params:
  - name: GOALS
    value:
    - test
  - name: MAVEN_MIRROR_URL
    value: http://nexus.nexus.svc:8081/repository/maven-all-public/
  taskRef:
    kind: ClusterTask
    name: maven
  workspaces:
  - name: source
    persistentVolumeClaim:
      claimName: app-source-pvc
  - name: maven-settings
    emptyDir: {}
EOF

taskrun.tekton.dev/maven-test-taskrun created

# Using the tkn command follow the log
tkn taskrun logs -f maven-test-taskrun
...
[mvn-goals] [INFO]
[mvn-goals] [INFO] -------------------------------------------------------
[mvn-goals] [INFO]  T E S T S
[mvn-goals] [INFO] -------------------------------------------------------
[mvn-goals] java.lang.instrument.IllegalClassFormatException: Error while instrumenting sun/uti
l/resources/cldr/provider/CLDRLocaleDataMetaInfo.
[mvn-goals]     at org.jacoco.agent.rt.internal_43f5073.CoverageTransformer.transform(CoverageT
ransformer.java:94)
[mvn-goals]     at java.instrument/java.lang.instrument.ClassFileTransformer.transform(ClassFil
eTransformer.java:246)
[mvn-goals]     at java.instrument/sun.instrument.TransformerManager.transform(TransformerManag
er.java:188)
[mvn-goals]     at java.instrument/sun.instrument.InstrumentationImpl.transform(Instrumentation
Impl.java:563)
[mvn-goals]     at java.base/java.lang.ClassLoader.defineClass2(Native Method)
[mvn-goals]     at java.base/java.lang.ClassLoader.defineClass(ClassLoader.java:1108)
[mvn-goals]     at java.base/java.security.SecureClassLoader.defineClass(SecureClassLoader.java
:183)
[mvn-goals]     at java.base/jdk.internal.loader.BuiltinClassLoader.defineClass(BuiltinClassLoa
der.java:784)
[mvn-goals]     at java.base/jdk.internal.loader.BuiltinClassLoader.findClassInModuleOrNull(Bui
ltinClassLoader.java:705)
[mvn-goals]     at java.base/jdk.internal.loader.BuiltinClassLoader.findClass(BuiltinClassLoade
r.java:586)
[mvn-goals]     at java.base/java.lang.ClassLoader.loadClass(ClassLoader.java:634)
[mvn-goals]     at java.base/java.lang.Class.forName(Class.java:546)
[mvn-goals]     at java.base/java.util.ServiceLoader.loadProvider(ServiceLoader.java:854)
[mvn-goals]     at java.base/java.util.ServiceLoader$ModuleServicesLookupIterator.hasNext(Servi
ceLoader.java:1078)
[mvn-goals]     at java.base/java.util.ServiceLoader$2.hasNext(ServiceLoader.java:1301)
[mvn-goals]     at java.base/java.util.ServiceLoader$3.hasNext(ServiceLoader.java:1386)
[mvn-goals]     at java.base/sun.util.cldr.CLDRLocaleProviderAdapter$1.run(CLDRLocaleProviderAd
apter.java:89)
[mvn-goals]     at java.base/sun.util.cldr.CLDRLocaleProviderAdapter$1.run(CLDRLocaleProviderAd
apter.java:86)
[mvn-goals]     at java.base/java.security.AccessController.doPrivileged(AccessController.java:
554)
[mvn-goals]     at java.base/sun.util.cldr.CLDRLocaleProviderAdapter.<init>(CLDRLocaleProviderA
dapter.java:86)
[mvn-goals]     at java.base/jdk.internal.reflect.NativeConstructorAccessorImpl.newInstance0(Na
tive Method)
[mvn-goals]     at java.base/jdk.internal.reflect.NativeConstructorAccessorImpl.newInstance(Nat
iveConstructorAccessorImpl.java:64)
[mvn-goals]     at java.base/jdk.internal.reflect.DelegatingConstructorAccessorImpl.newInstance
(DelegatingConstructorAccessorImpl.java:45)
[mvn-goals]     at java.base/java.lang.reflect.Constructor.newInstanceWithCaller(Constructor.ja
va:500)
[mvn-goals]     at java.base/java.lang.reflect.Constructor.newInstance(Constructor.java:481)
[mvn-goals]     at java.base/sun.util.locale.provider.LocaleProviderAdapter.forType(LocaleProvi
derAdapter.java:188)
[mvn-goals]     at java.base/sun.util.locale.provider.LocaleProviderAdapter.findAdapter(LocaleP
roviderAdapter.java:287)
[mvn-goals]     at java.base/sun.util.locale.provider.LocaleProviderAdapter.getAdapter(LocalePr
oviderAdapter.java:258)
[mvn-goals]     at java.base/java.text.DecimalFormatSymbols.getInstance(DecimalFormatSymbols.ja
va:180)
[mvn-goals]     at java.base/java.util.Formatter.getZero(Formatter.java:2437)
[mvn-goals]     at java.base/java.util.Formatter.<init>(Formatter.java:1956)
[mvn-goals]     at java.base/java.util.Formatter.<init>(Formatter.java:1978)
[mvn-goals]     at java.base/java.lang.String.format(String.java:3292)
[mvn-goals]     at org.junit.platform.engine.UniqueIdFormat.<init>(UniqueIdFormat.java:74)
[mvn-goals]     at org.junit.platform.engine.UniqueIdFormat.<clinit>(UniqueIdFormat.java:42)
[mvn-goals]     at org.junit.platform.engine.UniqueId.root(UniqueId.java:80)
[mvn-goals]     at org.junit.platform.engine.UniqueId.forEngine(UniqueId.java:68)
[mvn-goals]     at org.junit.platform.launcher.core.DefaultLauncher.discoverEngineRoot(DefaultL
auncher.java:166)
[mvn-goals]     at org.junit.platform.launcher.core.DefaultLauncher.discoverRoot(DefaultLaunche
r.java:155)
[mvn-goals]     at org.junit.platform.launcher.core.DefaultLauncher.discover(DefaultLauncher.ja
va:120)
[mvn-goals]     at org.apache.maven.surefire.junitplatform.TestPlanScannerFilter.accept(TestPla
nScannerFilter.java:56)
[mvn-goals]     at org.apache.maven.surefire.util.DefaultScanResult.applyFilter(DefaultScanResu
lt.java:102)
[mvn-goals]     at org.apache.maven.surefire.junitplatform.JUnitPlatformProvider.scanClasspath(
JUnitPlatformProvider.java:143)
[mvn-goals]     at org.apache.maven.surefire.junitplatform.JUnitPlatformProvider.invoke(JUnitPl
atformProvider.java:124)
[mvn-goals]     at org.apache.maven.surefire.booter.ForkedBooter.invokeProviderInSameClassLoade
r(ForkedBooter.java:384)
[mvn-goals]     at org.apache.maven.surefire.booter.ForkedBooter.runSuitesInProcess(ForkedBoote
r.java:345)
[mvn-goals]     at org.apache.maven.surefire.booter.ForkedBooter.execute(ForkedBooter.java:126)
[mvn-goals]     at org.apache.maven.surefire.booter.ForkedBooter.main(ForkedBooter.java:418)
[mvn-goals] Caused by: java.io.IOException: Error while instrumenting sun/util/resources/cldr/p
rovider/CLDRLocaleDataMetaInfo.
[mvn-goals]     at org.jacoco.agent.rt.internal_43f5073.core.instr.Instrumenter.instrumentError
(Instrumenter.java:159)
[mvn-goals]     at org.jacoco.agent.rt.internal_43f5073.core.instr.Instrumenter.instrument(Inst
rumenter.java:109)
[mvn-goals]     at org.jacoco.agent.rt.internal_43f5073.CoverageTransformer.transform(CoverageT
ransformer.java:92)
[mvn-goals]     ... 47 more
[mvn-goals] Caused by: java.lang.IllegalArgumentException: Unsupported class file major version
 59
[mvn-goals]     at org.jacoco.agent.rt.internal_43f5073.asm.ClassReader.<init>(ClassReader.java
:195)
[mvn-goals]     at org.jacoco.agent.rt.internal_43f5073.asm.ClassReader.<init>(ClassReader.java
:176)
[mvn-goals]     at org.jacoco.agent.rt.internal_43f5073.asm.ClassReader.<init>(ClassReader.java
:162)
[mvn-goals]     at org.jacoco.agent.rt.internal_43f5073.core.internal.instr.InstrSupport.classR
eaderFor(InstrSupport.java:280)
[mvn-goals]     at org.jacoco.agent.rt.internal_43f5073.core.instr.Instrumenter.instrument(Inst
rumenter.java:75)
[mvn-goals]     at org.jacoco.agent.rt.internal_43f5073.core.instr.Instrumenter.instrument(Inst
rumenter.java:107)
[mvn-goals]     ... 48 more
[mvn-goals] [INFO]
[mvn-goals] [INFO] Results:
[mvn-goals] [INFO]
[mvn-goals] [INFO] Tests run: 0, Failures: 0, Errors: 0, Skipped: 0
[mvn-goals] [INFO]
[mvn-goals] [INFO] ------------------------------------------------------------------------
[mvn-goals] [INFO] BUILD FAILURE
[mvn-goals] [INFO] ------------------------------------------------------------------------
[mvn-goals] [INFO] Total time:  03:23 min
[mvn-goals] [INFO] Finished at: 2020-11-18T07:08:14Z
[mvn-goals] [INFO] ------------------------------------------------------------------------
[mvn-goals] [ERROR] Failed to execute goal org.apache.maven.plugins:maven-surefire-plugin:2.22.
2:test (default-test) on project spring-petclinic: There are test failures.
[mvn-goals] [ERROR]
[mvn-goals] [ERROR] Please refer to /workspace/source/target/surefire-reports for the individua
l test results.
[mvn-goals] [ERROR] Please refer to dump files (if any exist) [date].dump, [date]-jvmRun[N].dum
p and [date].dumpstream.
[mvn-goals] [ERROR] There was an error in the forked process
[mvn-goals] [ERROR] Locale provider adapter "CLDR"cannot be instantiated.
[mvn-goals] [ERROR] org.apache.maven.surefire.booter.SurefireBooterForkException: There was an
error in the forked process
[mvn-goals] [ERROR] Locale provider adapter "CLDR"cannot be instantiated.
[mvn-goals] [ERROR]     at org.apache.maven.plugin.surefire.booterclient.ForkStarter.fork(ForkS
tarter.java:656)
[mvn-goals] [ERROR]     at org.apache.maven.plugin.surefire.booterclient.ForkStarter.run(ForkSt
arter.java:282)
[mvn-goals] [ERROR]     at org.apache.maven.plugin.surefire.booterclient.ForkStarter.run(ForkSt
arter.java:245)
[mvn-goals] [ERROR]     at org.apache.maven.plugin.surefire.AbstractSurefireMojo.executeProvide
r(AbstractSurefireMojo.java:1183)
[mvn-goals] [ERROR]     at org.apache.maven.plugin.surefire.AbstractSurefireMojo.executeAfterPr
econditionsChecked(AbstractSurefireMojo.java:1011)
[mvn-goals] [ERROR]     at org.apache.maven.plugin.surefire.AbstractSurefireMojo.execute(Abstra
ctSurefireMojo.java:857)
[mvn-goals] [ERROR]     at org.apache.maven.plugin.DefaultBuildPluginManager.executeMojo(Defaul
tBuildPluginManager.java:137)
[mvn-goals] [ERROR]     at org.apache.maven.lifecycle.internal.MojoExecutor.execute(MojoExecuto
r.java:210)
[mvn-goals] [ERROR]     at org.apache.maven.lifecycle.internal.MojoExecutor.execute(MojoExecuto
r.java:156)
[mvn-goals] [ERROR]     at org.apache.maven.lifecycle.internal.MojoExecutor.execute(MojoExecuto
r.java:148)
[mvn-goals] [ERROR]     at org.apache.maven.lifecycle.internal.LifecycleModuleBuilder.buildProj
ect(LifecycleModuleBuilder.java:117)
[mvn-goals] [ERROR]     at org.apache.maven.lifecycle.internal.LifecycleModuleBuilder.buildProj
ect(LifecycleModuleBuilder.java:81)
[mvn-goals] [ERROR]     at org.apache.maven.lifecycle.internal.builder.singlethreaded.SingleThr
eadedBuilder.build(SingleThreadedBuilder.java:56)
[mvn-goals] [ERROR]     at org.apache.maven.lifecycle.internal.LifecycleStarter.execute(Lifecyc
leStarter.java:128)
[mvn-goals] [ERROR]     at org.apache.maven.DefaultMaven.doExecute(DefaultMaven.java:305)
[mvn-goals] [ERROR]     at org.apache.maven.DefaultMaven.doExecute(DefaultMaven.java:192)
[mvn-goals] [ERROR]     at org.apache.maven.DefaultMaven.execute(DefaultMaven.java:105)
[mvn-goals] [ERROR]     at org.apache.maven.cli.MavenCli.execute(MavenCli.java:957)
[mvn-goals] [ERROR]     at org.apache.maven.cli.MavenCli.doMain(MavenCli.java:289)
[mvn-goals] [ERROR]     at org.apache.maven.cli.MavenCli.main(MavenCli.java:193)
[mvn-goals] [ERROR]     at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke0(Nati
ve Method)
[mvn-goals] [ERROR]     at java.base/jdk.internal.reflect.NativeMethodAccessorImpl.invoke(Nativ
eMethodAccessorImpl.java:64)
[mvn-goals] [ERROR]     at java.base/jdk.internal.reflect.DelegatingMethodAccessorImpl.invoke(D
elegatingMethodAccessorImpl.java:43)
[mvn-goals] [ERROR]     at java.base/java.lang.reflect.Method.invoke(Method.java:564)
[mvn-goals] [ERROR]     at org.codehaus.plexus.classworlds.launcher.Launcher.launchEnhanced(Lau
ncher.java:282)
[mvn-goals] [ERROR]     at org.codehaus.plexus.classworlds.launcher.Launcher.launch(Launcher.ja
va:225)
[mvn-goals] [ERROR]     at org.codehaus.plexus.classworlds.launcher.Launcher.mainWithExitCode(L
auncher.java:406)
[mvn-goals] [ERROR]     at org.codehaus.plexus.classworlds.launcher.Launcher.main(Launcher.java
:347)
[mvn-goals] [ERROR]
[mvn-goals] [ERROR] -> [Help 1]
[mvn-goals] [ERROR]
[mvn-goals] [ERROR] To see the full stack trace of the errors, re-run Maven with the -e switch.
[mvn-goals] [ERROR] Re-run Maven using the -X switch to enable full debug logging.
[mvn-goals] [ERROR]
[mvn-goals] [ERROR] For more information about the errors and possible solutions, please read t
he following articles:
[mvn-goals] [ERROR] [Help 1] http://cwiki.apache.org/confluence/display/MAVEN/MojoExecutionExce
ption


# Test build-image Task
tkn task start s2i-java-11-binary-namespace  \
    -p TLSVERIFY=false  \
    -p OUTPUT_IMAGE_STREAM=petclinic:latest  \
    -p NAMESPACE=petclinic-mzpll-dev \
    -w name=source,claimName=app-source-pvc \
    --showlog \
    -n pipeline-mzpll
Taskrun started: s2i-java-11-binary-namespace-run-4pf2j
Waiting for logs to be available...
[generate] Application dockerfile generated in /gen-source/Dockerfile.gen

[build] STEP 1: FROM registry.access.redhat.com/openjdk/openjdk-11-rhel7
[build] Getting image source signatures
[build] Copying blob sha256:d252267006aaf9eb630427e5d1848210382d0bdd965b9f3b16839a1e5607fc8e
[build] Copying blob sha256:88b5f8ffd2972499a708722fa5298f572f01ae2e47b90a070cc1bf44027c56e4
[build] Copying blob sha256:d4095a8ffba5513019bbee2e2630b7ee885f09812b77b57c1285503f3bc915e4
[build] Copying config sha256:a0032b11e590f806d7d3389067922dc82a7781dd0539b7daac317d9b9597e0ac
[build] Writing manifest to image destination
[build] Storing signatures
[build] STEP 2: LABEL "io.openshift.s2i.build.image"="registry.access.redhat.com/openjdk/openjd
k-11-rhel7"       "io.openshift.s2i.build.source-location"="."
[build] --> f8a9db4fd91
[build] STEP 3: USER root
[build] --> 744c62eead6
[build] STEP 4: COPY upload/src /tmp/src
[build] --> 9d19afcd955
[build] STEP 5: RUN chown -R 1001:0 /tmp/src
[build] --> 59530a43900
[build] STEP 6: USER 1001
[build] --> 7bb6aead933
[build] STEP 7: RUN /usr/local/s2i/assemble
[build] INFO S2I source build with plain binaries detected
[build] INFO Copying binaries from /tmp/src to /deployments ...
[build] checkstyle-cachefile
[build] checkstyle-checker.xml
[build] checkstyle-result.xml
[build] checkstyle-suppressions.xml
[build] jacoco.exec
[build] spring-petclinic-2.3.0.BUILD-SNAPSHOT.jar
[build] spring-petclinic-2.3.0.BUILD-SNAPSHOT.jar.original
[build] .wro4j/
[build] .wro4j/buildContext.properties
[build] classes/
[build] classes/application-mysql.properties
[build] classes/application.properties
[build] classes/banner.txt
[build] classes/git.properties
[build] classes/META-INF/
[build] classes/META-INF/build-info.properties
[build] classes/db/
[build] classes/db/h2/
[build] classes/db/h2/data.sql
[build] classes/db/h2/schema.sql
[build] classes/db/hsqldb/
[build] classes/db/hsqldb/data.sql
[build] classes/db/hsqldb/schema.sql
[build] classes/db/mysql/
[build] classes/db/mysql/data.sql
[build] classes/db/mysql/petclinic_db_setup_mysql.txt
[build] classes/db/mysql/schema.sql
[build] classes/db/mysql/user.sql
[build] classes/messages/
[build] classes/messages/messages.properties
[build] classes/messages/messages_de.properties
[build] classes/messages/messages_en.properties
[build] classes/messages/messages_es.properties
[build] classes/org/
[build] classes/org/springframework/
[build] classes/org/springframework/samples/
[build] classes/org/springframework/samples/petclinic/
[build] classes/org/springframework/samples/petclinic/PetClinicApplication.class
[build] classes/org/springframework/samples/petclinic/model/
[build] classes/org/springframework/samples/petclinic/model/BaseEntity.class
[build] classes/org/springframework/samples/petclinic/model/NamedEntity.class
[build] classes/org/springframework/samples/petclinic/model/Person.class
[build] classes/org/springframework/samples/petclinic/owner/
[build] classes/org/springframework/samples/petclinic/owner/Owner.class
[build] classes/org/springframework/samples/petclinic/owner/OwnerController.class
[build] classes/org/springframework/samples/petclinic/owner/OwnerRepository.class
[build] classes/org/springframework/samples/petclinic/owner/Pet.class
[build] classes/org/springframework/samples/petclinic/owner/PetController.class
[build] classes/org/springframework/samples/petclinic/owner/PetRepository.class
[build] classes/org/springframework/samples/petclinic/owner/PetType.class
[build] classes/org/springframework/samples/petclinic/owner/PetTypeFormatter.class
[build] classes/org/springframework/samples/petclinic/owner/PetValidator.class
[build] classes/org/springframework/samples/petclinic/owner/VisitController.class
[build] classes/org/springframework/samples/petclinic/system/
[build] classes/org/springframework/samples/petclinic/system/CacheConfiguration.class
[build] classes/org/springframework/samples/petclinic/system/CrashController.class
[build] classes/org/springframework/samples/petclinic/system/WelcomeController.class
[build] classes/org/springframework/samples/petclinic/vet/
[build] classes/org/springframework/samples/petclinic/vet/Specialty.class
[build] classes/org/springframework/samples/petclinic/vet/Vet.class
[build] classes/org/springframework/samples/petclinic/vet/VetController.class
[build] classes/org/springframework/samples/petclinic/vet/VetRepository.class
[build] classes/org/springframework/samples/petclinic/vet/Vets.class
[build] classes/org/springframework/samples/petclinic/visit/
[build] classes/org/springframework/samples/petclinic/visit/Visit.class
[build] classes/org/springframework/samples/petclinic/visit/VisitRepository.class
[build] classes/static/
[build] classes/static/resources/
[build] classes/static/resources/css/
[build] classes/static/resources/css/petclinic.css
[build] classes/static/resources/fonts/
[build] classes/static/resources/fonts/montserrat-webfont.eot
[build] classes/static/resources/fonts/montserrat-webfont.svg
[build] classes/static/resources/fonts/montserrat-webfont.ttf
[build] classes/static/resources/fonts/montserrat-webfont.woff
[build] classes/static/resources/fonts/varela_round-webfont.eot
[build] classes/static/resources/fonts/varela_round-webfont.svg
[build] classes/static/resources/fonts/varela_round-webfont.ttf
[build] classes/static/resources/fonts/varela_round-webfont.woff
[build] classes/static/resources/images/
[build] classes/static/resources/images/favicon.png
[build] classes/static/resources/images/pets.png
[build] classes/static/resources/images/platform-bg.png
[build] classes/static/resources/images/spring-logo-dataflow-mobile.png
[build] classes/static/resources/images/spring-logo-dataflow.png
[build] classes/static/resources/images/spring-pivotal-logo.png
[build] classes/templates/
[build] classes/templates/error.html
[build] classes/templates/welcome.html
[build] classes/templates/fragments/
[build] classes/templates/fragments/inputField.html
[build] classes/templates/fragments/layout.html
[build] classes/templates/fragments/selectField.html
[build] classes/templates/owners/
[build] classes/templates/owners/createOrUpdateOwnerForm.html
[build] classes/templates/owners/findOwners.html
[build] classes/templates/owners/ownerDetails.html
[build] classes/templates/owners/ownersList.html
[build] classes/templates/pets/
[build] classes/templates/pets/createOrUpdatePetForm.html
[build] classes/templates/pets/createOrUpdateVisitForm.html
[build] classes/templates/vets/
[build] classes/templates/vets/vetList.html
[build] generated-sources/
[build] generated-sources/annotations/
[build] generated-test-sources/
[build] generated-test-sources/test-annotations/
[build] maven-archiver/
[build] maven-archiver/pom.properties
[build] maven-status/
[build] maven-status/maven-compiler-plugin/
[build] maven-status/maven-compiler-plugin/compile/
[build] maven-status/maven-compiler-plugin/compile/default-compile/
[build] maven-status/maven-compiler-plugin/compile/default-compile/createdFiles.lst
[build] maven-status/maven-compiler-plugin/compile/default-compile/inputFiles.lst
[build] maven-status/maven-compiler-plugin/testCompile/
[build] maven-status/maven-compiler-plugin/testCompile/default-testCompile/
[build] maven-status/maven-compiler-plugin/testCompile/default-testCompile/createdFiles.lst
[build] maven-status/maven-compiler-plugin/testCompile/default-testCompile/inputFiles.lst
[build] surefire-reports/
[build] surefire-reports/2020-11-18T06-55-48_689-jvmRun1.dump
[build] surefire-reports/2020-11-18T07-08-11_539-jvmRun1.dump
[build] test-classes/
[build] test-classes/org/
[build] test-classes/org/springframework/
[build] test-classes/org/springframework/samples/
[build] test-classes/org/springframework/samples/petclinic/
[build] test-classes/org/springframework/samples/petclinic/PetclinicIntegrationTests.class
[build] test-classes/org/springframework/samples/petclinic/model/
[build] test-classes/org/springframework/samples/petclinic/model/ValidatorTests.class
[build] test-classes/org/springframework/samples/petclinic/owner/
[build] test-classes/org/springframework/samples/petclinic/owner/OwnerControllerTests$1.class
[build] test-classes/org/springframework/samples/petclinic/owner/OwnerControllerTests.class
[build] test-classes/org/springframework/samples/petclinic/owner/PetControllerTests.class
[build] test-classes/org/springframework/samples/petclinic/owner/PetTypeFormatterTests$1.class
[build] test-classes/org/springframework/samples/petclinic/owner/PetTypeFormatterTests$2.class
[build] test-classes/org/springframework/samples/petclinic/owner/PetTypeFormatterTests.class
[build] test-classes/org/springframework/samples/petclinic/owner/VisitControllerTests.class
[build] test-classes/org/springframework/samples/petclinic/service/
[build] test-classes/org/springframework/samples/petclinic/service/ClinicServiceTests.class
[build] test-classes/org/springframework/samples/petclinic/service/EntityUtils.class
[build] test-classes/org/springframework/samples/petclinic/system/
[build] test-classes/org/springframework/samples/petclinic/system/CrashControllerTests.class
[build] test-classes/org/springframework/samples/petclinic/vet/
[build] test-classes/org/springframework/samples/petclinic/vet/VetControllerTests.class
[build] test-classes/org/springframework/samples/petclinic/vet/VetTests.class
[build] --> be0c0c623e0
[build] STEP 8: CMD /usr/local/s2i/run
[build] STEP 9: COMMIT image-registry.openshift-image-registry.svc:5000/petclinic-mzpll-dev/pet
clinic:latest
[build] --> 7b8920118b2
[build] 7b8920118b26a3a3326a9e560912e5a79d840ef41b790d467dd1021c3e59bf9b

[push] Getting image source signatures
[push] Copying blob sha256:0c057cc87efe2f3d5746c0182113c1727197200cb83e7598a90793abc472772d
[push] Copying blob sha256:326117dcc194dc226033afa9beab1ad4573fa1312431b75239dd6611da7fb2f2
[push] Copying blob sha256:02ff5ceaada20d6100284db98470a479cc14777d8be7c4ac5e77463a6ff812fe
[push] Copying blob sha256:c03e591085b9579ef1b834f319339de17547f646b5a4dd96eb10d731260f6f57
[push] Copying blob sha256:aaa011c10e6cb17ecf40af415492c303988080de28a5b25f934fe1afcde95219
[push] Copying blob sha256:0e270d27988f6484f3b78564dbd9fc6701a818ea06546982cb87f3202a49eea2
[push] Copying config sha256:7b8920118b26a3a3326a9e560912e5a79d840ef41b790d467dd1021c3e59bf9b
[push] Writing manifest to image destination
[push] Copying config sha256:7b8920118b26a3a3326a9e560912e5a79d840ef41b790d467dd1021c3e59bf9b
[push] Writing manifest to image destination
[push] Storing signatures

# Test deploy-to-dev Task
tkn task start deploy-to-project  \
    -p DEPLOYMENT=petclinic  \
    -p IMAGE_STREAM=petclinic:latest  \
    -p NAMESPACE=petclinic-mzpll-dev \
    --showlog \
    -n pipeline-mzpll

Taskrun started: deploy-to-project-run-xrlf7
Waiting for logs to be available...
[deploy] + image_ref=image-registry.openshift-image-registry.svc:5000/petclinic-mzpll-dev/petcl
inic:latest
[deploy] Deploying image-registry.openshift-image-registry.svc:5000/petclinic-mzpll-dev/petclin
ic:latest
[deploy] + echo 'Deploying image-registry.openshift-image-registry.svc:5000/petclinic-mzpll-dev
/petclinic:latest'
[deploy] ++ oc get deployment petclinic -n petclinic-mzpll-dev
[deploy] Error from server (NotFound): deployments.apps "petclinic" not found
[deploy] + deployment=
[deploy] + '[' 1 -ne 0 ']'
[deploy] + oc new-app petclinic:latest --name petclinic -n petclinic-mzpll-dev
[deploy] warning: Cannot find git. Ensure that it is installed and in your path. Git is require
d to work with git repositories.
[deploy] --> Found image 7b89201 (About a minute old) in image stream "petclinic-mzpll-dev/petc
linic" under tag "latest" for "petclinic:latest"
[deploy]
[deploy]     Java Applications
[deploy]     -----------------
[deploy]     Platform for building and running plain Java applications (fat-jar and flat classp
ath)
[deploy]
[deploy]     Tags: builder, java
[deploy]
[deploy]
[deploy] --> Creating resources ...
[deploy]     deployment.apps "petclinic" created
[deploy]     service "petclinic" created
[deploy] --> Success
[deploy]     Application is not exposed. You can expose services to the outside world by execut
ing one or more of the commands below:
[deploy]      'oc expose svc/petclinic'
[deploy]     Run 'oc status' to view your app.
[deploy] + oc expose svc/petclinic -n petclinic-mzpll-dev
[deploy] route.route.openshift.io/petclinic exposed

# Test promote-to-prod Task
tkn task start promote-to-prod  \
    -p DEPLOYMENT=petclinic  \
    -p IMAGE_STREAM=petclinic:latest  \
    -p DEV_NAMESPACE=petclinic-mzpll-dev \
    -p PROD_NAMESPACE=petclinic-mzpll-prod \
    --showlog \
    -n pipeline-mzpll

Taskrun started: promote-to-prod-run-fpt4m
Waiting for logs to be available...
[deploy] + oc tag petclinic-mzpll-dev/petclinic:latest petclinic-mzpll-prod/petclinic:prod
[deploy] Tag petclinic-mzpll-prod/petclinic:prod set to petclinic-mzpll-dev/petclinic@sha256:f6
e61bb76e0053a2606cb0631cd53d2fab5906d0a54e6dda9847c4154e02c9db.

# Test deploy-to-prod Task
tkn task start deploy-to-project  \
    -p DEPLOYMENT=petclinic  \
    -p IMAGE_STREAM=petclinic:prod  \
    -p NAMESPACE=petclinic-mzpll-prod \
    --showlog \
    -n pipeline-mzpll

Taskrun started: deploy-to-project-run-jsdtf
Waiting for logs to be available...
[deploy] + image_ref=image-registry.openshift-image-registry.svc:5000/petclinic-mzpll-prod/petc
linic:prod
[deploy] + echo 'Deploying image-registry.openshift-image-registry.svc:5000/petclinic-mzpll-pro
d/petclinic:prod'
[deploy] Deploying image-registry.openshift-image-registry.svc:5000/petclinic-mzpll-prod/petcli
nic:prod
[deploy] ++ oc get deployment petclinic -n petclinic-mzpll-prod
[deploy] Error from server (NotFound): deployments.apps "petclinic" not found
[deploy] + deployment=
[deploy] + '[' 1 -ne 0 ']'
[deploy] + oc new-app petclinic:prod --name petclinic -n petclinic-mzpll-prod
[deploy] warning: Cannot find git. Ensure that it is installed and in your path. Git is require
d to work with git repositories.
[deploy] --> Found image 7b89201 (2 minutes old) in image stream "petclinic-mzpll-prod/petclini
c" under tag "prod" for "petclinic:prod"
[deploy]
[deploy]     Java Applications
[deploy]     -----------------
[deploy]     Platform for building and running plain Java applications (fat-jar and flat classp
ath)
[deploy]
[deploy]     Tags: builder, java
[deploy]
[deploy]
[deploy] --> Creating resources ...
[deploy]     deployment.apps "petclinic" created
[deploy]     service "petclinic" created
[deploy] --> Success
[deploy]     Application is not exposed. You can expose services to the outside world by execut
ing one or more of the commands below:
[deploy]      'oc expose svc/petclinic'
[deploy]     Run 'oc status' to view your app.
[deploy] + oc expose svc/petclinic -n petclinic-mzpll-prod
[deploy] route.route.openshift.io/petclinic exposed
```

## Run in the Web Console
```
# You can also follow the logs from the terminal with tkn
tkn pipeline logs -f

```

## Add Webhook
```
# TriggerTemplate
apiVersion: triggers.tekton.dev/v1alpha1
kind: TriggerTemplate
metadata:
  name: petclinic
spec:
  params:
  - name: git-revision
  - name: git-commit-message
  - name: git-repo-url
  - name: git-repo-name
  - name: content-type
  - name: pusher-name
  resourcetemplates:
  - apiVersion: tekton.dev/v1beta1
    kind: PipelineRun
    metadata:
      labels:
        tekton.dev/pipeline: petclinic-pipeline
      name: petclinic-deploy-$(uid)
    spec:
      params:
      - name: APP_NAME
        value: petclinic
      - name: APP_GIT_URL
        value: $(params.git-repo-url)
      - name: APP_GIT_REVISION
        value: $(params.git-revision)
      pipelineRef:
        name: petclinic-pipeline
      workspaces:
      - name: app-source
        persistentVolumeClaim:
          claimName: app-source-pvc
      - name: maven-settings
        emptyDir: {}

# Trigger Binding
apiVersion: triggers.tekton.dev/v1alpha1
kind: TriggerBinding
metadata:
  name: petclinic
spec:
  params:
  - name: git-repo-url
    value: $(body.repository.clone_url)
  - name: git-repo-name
    value: $(body.repository.name)
  - name: git-revision
    value: $(body.after)

# EventListener
apiVersion: triggers.tekton.dev/v1alpha1
kind: EventListener
metadata:
  name: petclinic
spec:
  serviceAccountName: pipeline
  triggers:
  - bindings:
    - name: petclinic
    template:
      name: petclinic

# EventListener Route
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  labels:
    app.kubernetes.io/managed-by: EventListener
    app.kubernetes.io/part-of: Triggers
    eventlistener: petclinic
  name: el-petclinic
spec:
  port:
    targetPort: 8080
  to:
    kind: Service
    name: el-petclinic
    weight: 100


# Create all these objects using a provided YAML manifest
# See: https://raw.githubusercontent.com/redhat-gpte-labs/rhtr2020_pipelines/master/workshop/content/tekton/triggers/petclinic-triggers.yaml
oc create -f https://raw.githubusercontent.com/redhat-gpte-labs/rhtr2020_pipelines/master/workshop/content/tekton/triggers/petclinic-triggers.yaml -n pipeline-mzpll

triggertemplate.triggers.tekton.dev/petclinic created
triggerbinding.triggers.tekton.dev/petclinic created
eventlistener.triggers.tekton.dev/petclinic created
route.route.openshift.io/el-petclinic created

# You should see that a new Deployment for the EventListener el-petclinic has been created
[~] $ oc get deployment -n pipeline-mzpll
NAME           READY   UP-TO-DATE   AVAILABLE   AGE
el-petclinic   1/1     1            1           81s

# Retrieve the route to the event listener
[~] $ oc get route el-petclinic -n pipeline-mzpll
NAME           HOST/PORT                                                                     PA
TH   SERVICES       PORT   TERMINATION   WILDCARD
el-petclinic   el-petclinic-pipeline-mzpll.apps.cluster-bscng.bscng.sandbox302.opentlc.com
     el-petclinic   8080                 None

# Login Gitea 
# 配置 Webhook 指向 EventListenerRoute

# Go back to the terminal and verify that the pipeline is running
[~] $ tkn pipeline ls -n pipeline-mzpll
NAME                 AGE          LAST RUN                 STARTED         DURATION   STATUS
petclinic-pipeline   1 hour ago   petclinic-deploy-x8vkb   2 minutes ago   ---        Running

# Get the logs from the latest running pipeline

[~] $ tkn pipeline logs -f -n pipeline-mzpll
? Select pipelinerun: petclinic-deploy-x8vkb started 3 minutes ago
[git-clone : clone] + CHECKOUT_DIR=/workspace/output/
[git-clone : clone] + '[[' true '==' true ]]
[git-clone : clone] + cleandir
[git-clone : clone] + '[[' -d /workspace/output/ ]]
[git-clone : clone] + rm -rf /workspace/output//docker-compose.yml /workspace/output//mvnw /wor
kspace/output//mvnw.cmd /workspace/output//pom.xml /workspace/output//readme.md /workspace/outp
ut//src /workspace/output//target
[git-clone : clone] + rm -rf /workspace/output//.editorconfig /workspace/output//.git /workspac
e/output//.gitignore /workspace/output//.mvn /workspace/output//.travis.yml /workspace/output//
.vscode
[git-clone : clone] + rm -rf '/workspace/output//..?*'
[git-clone : clone] + test -z
[git-clone : clone] + test -z
[git-clone : clone] + test -z
[git-clone : clone] + /ko-app/git-init -url https://gitea-gitea.apps.cluster-bscng.bscng.sandbo
x302.opentlc.com/jwang-redhat.com/spring-petclinic.git -revision 0189373c6eca2dfa6fd1139ebb9eb7
9bad8f1fd1 -refspec  -path /workspace/output/ '-sslVerify=true' '-submodules=true' -depth 1
[git-clone : clone] {"level":"info","ts":1605687137.3891516,"caller":"git/git.go:136","msg":"Su
ccessfully cloned https://gitea-gitea.apps.cluster-bscng.bscng.sandbox302.opentlc.com/jwang-red
hat.com/spring-petclinic.git @ 0189373c6eca2dfa6fd1139ebb9eb79bad8f1fd1 (grafted, HEAD) in path
 /workspace/output/"}
...
[deploy-to-prod : deploy] + oc rollout status deployment/petclinic -n petclinic-mzpll-prod
[deploy-to-prod : deploy] Waiting for deployment "petclinic" rollout to finish: 1 old replicas
are pending termination...
[deploy-to-prod : deploy] Waiting for deployment "petclinic" rollout to finish: 1 old replicas
are pending termination...
[deploy-to-prod : deploy] deployment "petclinic" successfully rolled out
```