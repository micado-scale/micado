#!/bin/bash

set -e

result="0"
while [ $result -eq "0" ]; do
	(echo > /dev/tcp/localhost/3000) >/dev/null 2>&1  && result=1 || result=0
	echo "Checking Grafana port"
  	sleep 1
done

echo "Grafana is up - executing command"
curl --header "Content-Type: application/json" --data @/etc/grafana/jqueuer/datasource.json http://admin:f4c85f99a0@127.0.0.1:3000/api/datasources/
curl --header "Content-Type: application/json" --data @/etc/grafana/jqueuer/dashboard.json http://admin:f4c85f99a0@127.0.0.1:3000/api/dashboards/db