#!/usr/bin/env bash

SPARK_DIST_CLASSPATH=$("${HADOOP_HOME}/bin/hadoop" classpath)
export SPARK_DIST_CLASSPATH
