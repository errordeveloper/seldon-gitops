#!/bin/bash -eux

echo > output.json

for file in in/*.json ; do
  for data in "$(jq -c 'select(.kind != "List")' $file)" ; do
     [ -n "${data}" ] && echo "${data}" >> output.json
  done
  for data in "$(jq -c 'select(.kind == "List") | .items[]' $file)" ; do
     [ -n "${data}" ] && echo "${data}" >> output.json
  done
done

for name in $(jq -c '[.metadata.name,.kind]' < output.json) ; do
  file="$(jq -r -n --argjson name "${name}" '$name | join("-")').yaml"
  jq --argjson name "${name}" 'select(.metadata.name == $name[0]) | select(.kind == $name[1])' < output.json | json2yaml > "${file}"
done

rm -f output.json
