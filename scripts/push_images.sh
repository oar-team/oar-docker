#!/bin/bash

oardocker status | grep oardocker | awk '{print $1}' | xargs -I {} docker push {}
