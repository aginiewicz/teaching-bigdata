#!/bin/bash

if [ ! -d "/opt/hadoop/data/nameNode/current" ]; then
  hdfs namenode -format -force -nonInteractive
fi

hdfs namenode

