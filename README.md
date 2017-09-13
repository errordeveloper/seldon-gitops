# GitOps demo for Tensorflow/Seldon meetup

> *Note:* _this is work-in-progress_

Import manifests from `seldon-server` (need to have it checked-out in this dir):
```
./scripts/import-infra
git add infra
git commit -m 'Add the Seldon stack to my GKE cluster!'
git push
```

Run setup finaliser script:
```
./scripts/finilise-setup
```

Add the Deep MNIST jobs:
```
./scripts/import-app seldon-server/kubernetes/conf/examples/tensorflow_deep_mnist/train-tensorflow-deep-mnist.json
./scripts/import-app seldon-server/kubernetes/conf/examples/tensorflow_deep_mnist/load-model-tensorflow-deep-mnist.json
git add apps
git commit -m 'Deploy some app workloads!'
git push
kubectl get jobs -w -o wide
```

Create Seldon client:
```
./scripts/seldon-cli client --action setup --db-name ClientDB --client-name deep_mnist_client
```