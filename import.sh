#!/bin/bash -eux

json_src=(
  "${SELDON_SERVER:-".."}/kubernetes/conf/hostpath.json"
  "${SELDON_SERVER:-".."}/kubernetes/conf/mysql.json"
  "${SELDON_SERVER:-".."}/kubernetes/conf/memcache.json"
  "${SELDON_SERVER:-".."}/kubernetes/conf/redis.json"
  "${SELDON_SERVER:-".."}/kubernetes/conf/zookeeper.json"
  "${SELDON_SERVER:-".."}/kubernetes/conf/control.json"
  "${SELDON_SERVER:-".."}/kubernetes/conf/influxdb-grafana.json"
  "${SELDON_SERVER:-".."}/kubernetes/conf/kafka.json"
  "${SELDON_SERVER:-".."}/kubernetes/conf/td-agent-server.json"
  "${SELDON_SERVER:-".."}/kubernetes/conf/spark-master.json"
  "${SELDON_SERVER:-".."}/kubernetes/conf/spark-workers.json"
  "${SELDON_SERVER:-".."}/kubernetes/conf/spark-ui.json"
  "${SELDON_SERVER:-".."}/kubernetes/conf/server.json"
  "${SELDON_SERVER:-".."}/kubernetes/conf/analytics/impressions-kafka-stream.json"
  "${SELDON_SERVER:-".."}/kubernetes/conf/analytics/predictions-kafka-stream.json"
)

echo > output.json

for file in "${json_src[@]}" ; do
  for data in "$(jq -c 'select(.kind != "List")' $file)" ; do
     [ -n "${data}" ] && echo "${data}" >> output.json
  done
  for data in "$(jq -c 'select(.kind == "List") | .items[]' $file)" ; do
     [ -n "${data}" ] && echo "${data}" >> output.json
  done
done

for name in $(jq -c '[.metadata.name,.kind]' < output.json) ; do
  file="$(jq -r -n --argjson name "${name}" '$name | join(".")').yaml"
  jq --argjson name "${name}" 'select(.metadata.name == $name[0]) | select(.kind == $name[1])' < output.json | json2yaml > "${file}"
done

rm -f output.json
