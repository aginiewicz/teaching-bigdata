#!/bin/bash

if [ -f "/opt/hadoop/data/dataNode/in_use.lock" ]; then
  rm /opt/hadoop/data/dataNode/in_use.lock
fi

hdfs datanode

