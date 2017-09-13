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

Deploy the example TensorFlow app:
```
./scripts/start-microservice --type prediction --client deep_mnist_client -p tensorflow-deep-mnist /seldon-data/seldon-models/tensorflow_deep_mnist/1/ rest 1.0
```

Check service status:
```
kubectl get service,deployment tensorflow-deep-mnist
```

There is no external IP, let's make it happend with GitOps:
```
kubectl get service/tensorflow-deep-mnist --output=yaml --export=true > apps/tensorflow-deep-mnist.Service.yaml
kubectl get deployment/tensorflow-deep-mnist --output=yaml --export=true > apps/tensorflow-deep-mnist.Deployment.yaml
```

Now lets's review this, we certainly need to adjust the service type...
```
$EDITOR apps/tensorflow-deep-mnist.Service.yaml
git add apps
git commit -m 'gitOps := "AWESOME"'
```
