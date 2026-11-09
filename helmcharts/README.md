# Helm Charts
Helm charts are available in the [github pages hosted repository](https://rossvideo.github.io/Catena-deployments). To use, add the repository and install.

## TL;DR
```
helm repo add catena-deployments https://rossvideo.github.io/Catena-deployments
helm repo update
helm install --namespace catena --create-namespace --set image.develop=true catena catena-deployments/catena-helm
```

This will start the gRPC one-of-everything example. `image.develop=true` selects the `-dev` image tags, which are the only ones currently being published (see [Supported tags](../README.md#supported-tags)).
## Helm Values
See the comments in [values.yaml](catena-helm/values.yaml) for details of all values. Edit values.yaml and start with the overriden values.
```
helm install --namespace catena --create-namespace --values values.yaml catena catena-deployments/catena-helm
```