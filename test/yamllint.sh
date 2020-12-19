#!/bin/bash

readonly base_dir=$(dirname $(cd $(dirname $0); pwd))

docker run --rm -it -v ${base_dir}:/data cytopia/yamllint:1.23 .
