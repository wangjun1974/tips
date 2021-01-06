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