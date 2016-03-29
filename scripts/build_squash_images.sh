#!/bin/bash

command -v foo >/dev/null 2>&1 || { echo >&2 "Missing docker-scripts. 'pip install docker-scripts'"; exit 1; }

oardocker build
for image_id in $(oardocker status | grep oardocker |  awk '{print $2}'); do
    image_tag=$( oardocker status | grep $image_id |  awk '{print $1}' )
    docker-scripts squash $image_tag -t $image_tag
done
oardocker build --no-rebuild
