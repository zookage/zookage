#!/bin/bash
set -eu

readonly WIDTH=80
readonly headline=$1
readonly headline_length=${#headline}
readonly padding=$(( headline_length % 2 ))
readonly half_divider_length=$(( (WIDTH - headline_length - padding - 2) / 2 ))

printf "=%.0s"  $(seq 1 ${half_divider_length})
echo -n " ${headline} "
printf "=%.0s"  $(seq 1 $(( half_divider_length + padding )))
echo
