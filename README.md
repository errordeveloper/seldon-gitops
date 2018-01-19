# GitOps demo for Seldon Core

> *Note:* _this is work-in-progress_

The repo has 2 branches – `master` and `flux-deploy`. Code lives in `master`, and GCB builds images of master.
While `flux-deploy` is where config lives, and that is the branch is hooked up to Flux, any changes to config get deployed to Kubernetes cluster where Flux instance is running.

The `update-deploy-branch.sh` script is designed to update the config in `flux-deploy` branch once new image is found in GCR.
This is needed for Seldon CRD object, otherwise Flux would update any Kubernetes config object (e.g. Deployment or DaemonSet) automatically.

1. Make a code change `./model`, commit and push it to `master`
2. GCB should start a new build
3. Run `until ./update-deploy-branch.sh; do sleep 20; done`
4. Once `until` loop exists, chages made by the script on `flux-deploy` branch will be pick up by Flux agent in the cluster
