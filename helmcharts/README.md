# Helm Charts
Helm charts are available in the [github pages hosted repository](https://rossvideo.github.io/Catena-deployments). To use, add the repository and install.

## TL;DR
```
helm repo add catena-deployments https://rossvideo.github.io/Catena-deployments
helm install --namespace catena catena catena-deployments/catena
```

This will start the gRPC one-of-everything example.
## Helm Values
See the comments in [values.yaml](catena/values.yaml) for details of all values. Edit values.yaml and start with the overriden values.
```
helm install --namespace catena --values values.yaml catena catena-deployments/catena
```