# Tagger Custom Builder

Tested with

- Docker Hub

## How it works

### TOKEN

If you don't explicitly add a token to connect to your openshift instance then it will connect as the builder user
and you will need to ensure that the builder can see and edit your project for this image to work by running
`oc policy add-role-to-user edit system:serviceaccount:<my-project-name>:builder`

### BUILD_NAMESPACE

The namespace that the image build was done in. If not set then this will try to get the namespace of the service account
`BUILD_NAMESPACE=$(eval cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)`

### BUILD_IMAGE

BUILD_IMAGE is the part of your namespace before the tag eg `my-openshift-project/my-image-name`

### PUSH_IMAGE

If true tries to push the image to the final repo name after tagging so, for example, you could publish your image on docker hub


## Use it on openshift

To use it, you just have to add a BuildConfig that will be triggered after your build