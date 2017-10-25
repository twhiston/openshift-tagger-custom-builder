# Tagger Custom Builder

Support multiple tags for a build output

This can be hacked together today by:

1) create a custom builder image that pulls the built image and re-tags it with the commit found in the image label and pushes it
2) define a custom build config with an image change trigger such that it gets run whenever the "real" build pushes a new image.

cf https://trello.com/c/nOX8FTRq/686-5-support-multiple-tags-for-a-build-output

## How it works

### TOKEN

If you don't explicitly add a token to connect to your openshift instance then it will connect as the builder
and you will need to ensure that the builder can see and edit your project
`oc policy add-role-to-user edit system:serviceaccount:drupal-module-tester:builder`

### BUILD_NAMESPACE

The namespace that the image build was done in. If not set then this will try to get the namespace of the service account
`BUILD_NAMESPACE=$(eval cat /var/run/secrets/kubernetes.io/serviceaccount/namespace)`

### BUILD_IMAGE

BUILD_IMAGE is the part of your namespace before the tag eg `my-openshift-project/my-image-name`

### PUSH_IMAGE

If true tries to push the image to the final repo name after tagging so, for example, you could publish your image on docker hub

## Run it locally

```
docker run -it -e TOKEN=$(oc whoami -t) \
               -e BUILD_NAMESPACE=<…> \
               -e BUILD_IMAGE=<…> \
               yamo/openshift-tagger-custom-builder
```

## Use it on openshift

To use it, you just have to add a BuildConfig that will be triggered after your build

```
- kind: BuildConfig
  apiVersion: v1
  metadata:
    name: ${APPLICATION_NAME}-tagger
    labels:
      application: ${APPLICATION_NAME}
  spec:
    strategy:
      type: Custom
      customStrategy:
        from:
          # this is the builder image
          kind: DockerImage
          name: yamo/openshift-tagger-custom-builder
        pullSecret:
          name: dockercfg
        forcePull: true
        env:
        - name: OPENSHIFT_INSTANCE
          value: ${OPENSHIFT_SERVER}
        - name: BUILD_NAMESPACE
          value: ${APPLICATION_NAME}
        - name: BUILD_IMAGE
          value: ${APPLICATION_NAME}
    triggers:
    - type: ImageChange
    - type: ImageChange
      imageChange:
        from:
          kind: ImageStreamTag
          name: ${APPLICATION_NAME}:latest
```
