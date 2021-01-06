### workshop introduction
In this tutorial, you will:<br>
* Install the OpenShift Pipelines operator;
* Deploy a partial application;
* Create reusable Tekton Tasks;
* Create a Tekton Pipeline;
* Create PipelineResources;
* Trigger the created Pipeline to finish your application deployment.

OpenShift Pipelines features:<br>
* Standard CI/CD pipeline definition based on Tekton
* Build container images with tools such as Source-to-Image (S2I) and Buildah
* Deploy applications to multiple platforms such as Kubernetes, serverless, and VMs
* Easy to extend and integrate with existing tools
* Scale pipelines on-demand
* Portable across any Kubernetes platform
* Designed for microservices and decentralized teams
* Integrated with the OpenShift Developer Console

Tekton CRDs<br>
Tekton defines some Kubernetes custom resources as building blocks to standardize pipeline concepts and provide terminology that is consistent across CI/CD solutions. These custom resources are an extension of the Kubernetes API that lets users create and interact with these objects using the OpenShift CLI (oc), kubectl, and other Kubernetes tools.

The custom resources needed to define a pipeline are listed below<br>
|Name|Comments|
|---|---|
|Task| a reusable, loosely coupled number of steps that perform a specific task (e.g. building a container image)|
|Pipeline|the definition of the pipeline and the tasks that it should perform|
|PipelineResource|inputs (e.g. git repository) and outputs (e.g. image registry) to and out of a pipeline or task|
|TaskRun|the execution and result (i.e. success or failure) of running an instance of a task|
|PipelineRun|the execution and result (i.e. success or failure) of running a pipeline|

In short, to create a pipeline, one does the following:<br>
* Create custom or install existing reusable Tasks
* Create a Pipeline and PipelineResources to define your application’s delivery Pipeline
* Create a PipelineRun to instantiate and invoke the pipeline.

For further details on pipeline concepts, refer to the Tekton documentation that provides an excellent guide for understanding various parameters and attribut

### Install OpenShift Pipelines Operator
OpenShift Pipelines is provided as an OpenShift add-on that can be installed via an operator that is available in the OpenShift OperatorHub.

Operators may be installed into a single namespace and only monitor resources in that namespace, but the OpenShift Pipelines Operator installs globally on the cluster and monitors and manage pipelines for every single user in the cluster.

To install the operator globally, you need to be a cluster administrator user. In this workshop environment, the operator has already been installed for you. Nevertheless, this is the process we followed in order to install the operator. These instructions are for reference, as you will not be able to see these screens in the embedded console in the workshop due to your user’s lack of the required privileges.

**Install process**<br>
To install the OpenShift Pipelines operator on an OpenShift 4 cluster, you would go to the Catalog > OperatorHub tab in the OpenShift web console. You can see the list of available operators for OpenShift provided by Red Hat as well as a community of partners and open-source projects.

Next, you would click on the Integration & Delivery category to find the OpenShift Pipeline Operator as shown below:

Click on OpenShift Pipelines Operator, Continue, and then Install as shown below:

Leave the default values after clicking Install. The operator will install globally and it will run in the openshift-operators project, as this is the pre-configured project for all global operators. Click on Subscribe in order to subscribe to the installation and update channels as shown below:

The operator is installed when you see the status updated from 1 installing to 1 installed as shown in the photo below:

This operator automates installation and updates of OpenShift Pipelines on the cluster as well as applying all configurations needed.

**Verify installation**<br>
The OpenShift Pipelines Operator provides all its resources under a single API group: tekton.dev. You can see the new resources by running:
```
oc api-resources --api-group=tekton.dev
```

**Verify user roles**<br>
To validate that your user has the appropriate roles, you can use the oc auth can-i command to see whether you can create Kubernetes custom resources of the kind needed by the OpenShift Pipelines Operator.

The custom resource you need to create an OpenShift Pipelines pipeline is a resource of the kind pipeline.tekton.dev in the tekton.dev API group. To check that you can create this, run:
```
oc auth can-i create pipeline.tekton.dev
```

Or you can use the simplified version:
```
oc auth can-i create Pipeline
```
When run, if the response is yes, you have the appropriate access.

Verify that you can create the rest of the Tekton custom resources needed for this workshop by running the commands below. All of the commands should respond with yes.
```
oc auth can-i create Task
oc auth can-i create PipelineResource
oc auth can-i create PipelineRun
```
Now that we have verified that you can create the required resources let’s start the workshop.


