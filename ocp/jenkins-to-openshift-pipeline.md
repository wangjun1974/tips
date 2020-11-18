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
