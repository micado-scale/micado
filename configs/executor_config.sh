#!/bin/bash
        

        VM_over_loaded() {
            curl -X POST http://hostIP:5000/infrastructures/$1/scaleup/$2
            }

        VM_under_loaded() {
            curl -X POST http://hostIP:5000/infrastructures/$1/scaledown/$2
            }

        containerscale() {

            echo "scale $1 by $2"
            curl -X GET http://hostIP:2375/v1.27/services/$1 > get.json
            # to pretty json
            jq '.' get.json > getservice.json
            # we neet the version for updating later
            index=$(cat getservice.json | jq '.Version.Index')
            #  current number of replicas
            replicas=$(cat getservice.json | jq '.Spec.Mode.Replicated.Replicas')
            service_cpulimit=$(jq '.Spec.TaskTemplate.Resources.Limits.NanoCPUs' getservice.json | cut -c 1-2)
            if [ "$service_cpulimit" = "nu" ]; then
              service_cpulimit=80
            fi
            echo " number of replicas before scaling" $replicas
            # make sure that we don't go bellow 1 container
            if [ "$replicas" -gt "1" ] || [ $2 -eq "1" ];
            then
            cat getservice.json | jq '.Spec.Mode.Replicated.Replicas'+$2 > replicas.json
            cat getservice.json | jq --slurpfile newvalue replicas.json '.Spec.Mode.Replicated.Replicas = $newvalue[0]' > input.json
            # save parts of json
            cat input.json | jq '.Spec' >> spec.json
            cat input.json | jq '. | del(.ID) | del(.Version) | del(.CreatedAt) | del(.UpdatedAt) | del(.Spec)' > remaining.json
            # recreate json
            jq -s '.[0] + .[1]' spec.json remaining.json > output.json


            echo "update_service call if possible"


            curl -g 'http://hostIP:9090/api/v1/query?query=rate(node_cpu{mode="idle",group="worker_cluster"}[1m])' > available_nodes_forscale.json
            curl -g 'http://hostIP:9090/api/v1/query?query=rate(node_cpu{mode="idle"}[1m])' | jq '. | length' > node_counter
            num_nodes=$(cat node_counter)
            ((num_nodes-=1))
            for i in $(seq 0 $num_nodes); do
              echo "${i}" > counter

               # if we find at least one node that have enough cpu space than scale up otherwise don't. downscale dosn't matter
               actual_free_cpu=$(jq -r --slurpfile newvalue counter '.data.result[$newvalue[0]].value[1]' available_nodes_forscale.json | sed 's/^..//'  | cut -c 1-2) 
             echo "$actual_free_cpu"
             echo "$service_cpulimit"
             if [ "$actual_free_cpu" = "ll" ]; then
             actual_free_cpu=0
             echo "correct cpu limit is " $actual_free_cpu
             fi
              if [ $actual_free_cpu -gt $service_cpulimit ] || [ $2 -ne "1" ]; then
              echo "true scale"
              curl -X POST --header "Content-Type: application/json" http://hostIP:2375/v1.27/services/$1/update?version=$index -d @output.json
              break
              else
              echo "no space"
              fi
            done
            fi
            }


        
        
        main() {
          for i in $(seq 1 "$AMX_ALERT_LEN"); do
            alert="AMX_ALERT_${i}_LABEL_alert"
            infra="AMX_ALERT_${i}_LABEL_infra_id"
            node="AMX_ALERT_${i}_LABEL_node"
            level="AMX_ALERT_${i}_LABEL_type"
            application="AMX_ALERT_${i}_LABEL_application"
            alertstatus="AMX_ALERT_${i}_STATUS"
        
            if [ "${!level}" = "docker" ] && [ "${!alertstatus}" = "firing" ]
            then
                rm -f input.json getservice.json remaining.json spec.json output.json get.json replicas.json
        	if [ "${!alert}" = "overloaded" ]
            then
            scaleparameter=1
            containerscale "${!application}" "$scaleparameter"
        	elif [ "${!alert}" = "underloaded" ]
            then
            scaleparameter=-1
            containerscale "${!application}" "$scaleparameter"
        	fi
            fi
        
        
            if [ "${!alert}" = "overloaded" ] && [ "${!level}" = "VM" ] && [ "${!alertstatus}" = "firing" ];
           		then
                    VM_over_loaded "${!infra}" "${!node}"
            fi
            if [ "${!alert}" = "underloaded" ] && [ "${!level}" = "VM" ] && [ "${!alertstatus}" = "firing" ]; 
            then
                    VM_under_loaded "${!infra}" "${!node}"
            fi
          done
          wait
        }
        main "$@"