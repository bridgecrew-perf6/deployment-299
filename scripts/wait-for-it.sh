#!/bin/bash
while [ $(curl -s -o /dev/null -w "%{http_code}" http://$1:8080) != 200 -a $(curl -s -o /dev/null -w "%{http_code}" http://$1:8080/mercury/services) != 401 ];

do
  sleep 1;

done
