#!/bin/sh

rev="$(git rev-parse @)"

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
    deployment_version: "${rev}"
    project_name: 'Iris classification'
  oauth_key: oauth-key
  oauth_secret: oauth-secret
  predictors:
  - annotations:
      predictor_version: "${rev}"
    componentSpec:
      metadata:
        labels:
          seldon-app: sklearn-iris-deployment
      spec:
        containers:
        - name: sklearn-iris-classifier
          image: "gcr.io/dx-general/seldon-core-python-model-example:${rev}"
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
