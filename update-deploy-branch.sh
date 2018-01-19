#!/bin/sh -eux

image_tag="$(git rev-parse @)"

image_name="gcr.io/dx-general/seldon-core-python-example/model"

gcloud container images list-tags --format=json "${image_name}" \
  | jq -r '.[].tags | .[]' \
  | grep -c "${image_tag}" \
  || exit 2

image="${image_name}:${image_tag}"

git checkout flux-deploy

cat > seldon-deployment.yaml <<EOF
apiVersion: machinelearning.seldon.io/v1alpha1
kind: SeldonDeployment
metadata:
  name: seldon-deployment-example
  labels:
    app: seldon
spec:
  name: sklearn-iris-deployment
  annotations:
    deployment_version: "${image_tag}"
    project_name: 'Iris classification'
  oauth_key: oauth-key
  oauth_secret: oauth-secret
  predictors:
  - annotations:
      predictor_version: "${image_tag}"
    componentSpec:
      metadata:
        labels:
          seldon-app: sklearn-iris-deployment
      spec:
        containers:
        - name: sklearn-iris-classifier
          image: "${image}"
          env:
          - name: PREDICTIVE_UNIT_SERVICE_PORT
            value: '9000'
          - name: PREDICTIVE_UNIT_PARAMETERS
            value: '[]'
          ports:
          - containerPort: 9000
            name: http
          readinessProbe:
            handler:
              tcpSocket:
                port: http
            initialDelaySeconds: 10
            periodSeconds: 5
          lifecycle:
            preStop:
              exec:
                command:
                - '/bin/sh'
                - '-c'
                - '/bin/sleep 5'
          livenessProbe:
            handler:
              tcpSocket:
                port: http
            initialDelaySeconds: 10
            periodSeconds: 5
          resources:
            requests:
              memory: 1Mi
        terminationGracePeriodSeconds: 20
    graph:
      endpoint:
        service_host: 0.0.0.0
        service_port: 9000
        type: REST
      name: sklearn-iris-classifier
      type: MODEL
    name: sklearn-iris-predictor
    replicas: 1
EOF

git add seldon-deployment.yaml
rc=0
git commit -m "Update image to ${image}" && git push origin flux-deploy || rc=1
git checkout master
exit $rc
