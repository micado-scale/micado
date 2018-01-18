#!/bin/bash

curl --header "Content-Type: application/json" --data @/etc/grafana/jqueuer/datasource.json http://admin:f4c85f99a0f97a5402e2c0faeefc2355e3df785b62f6254e89074b880a682b19@127.0.0.1:3000/api/datasources/
curl --header "Content-Type: application/json" --data @/etc/grafana/jqueuer/dashboard.json http://admin:f4c85f99a0f97a5402e2c0faeefc2355e3df785b62f6254e89074b880a682b19@127.0.0.1:3000/api/dashboards/db