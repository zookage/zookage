#!/bin/bash
set -eu

read -p "Clean working directories? [Y/n]: " clean
case "$clean" in
  y|Y|yes|"" ) clean=clean;;
  n|N|no ) clean=;;
  * ) echo "Please input y or n"; exit 1;;
esac
