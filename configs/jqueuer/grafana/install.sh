#!/bin/bash

curl --header "Content-Type: application/json" --data @/etc/grafana/jqueuer/datasource.json http://admin:f4c85f99a0@127.0.0.1:3000/api/datasources/
curl --header "Content-Type: application/json" --data @/etc/grafana/jqueuer/dashboard.json http://admin:f4c85f99a0@127.0.0.1:3000/api/dashboards/db