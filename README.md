# MiCADO V4 for Batch Processing Applications

This version launches JQueuer Manager and JQueuer Agent with MiCADO Infra.

# Step by Step

1- Modify micado_cloud_init.yaml to add your cloud credentials.

2- Use micado_cloud_init.yaml to create a new server.

3- When the server is Up, visit the link http://SERVER_IP_ADDRESS:8081 to submit a new experiment.

4- The experiment should be formatted as a JSON file according to experiment.json.

5- Select your experiment JSON file from the local drive and start the experiment. 

6- Visit Grafana on the link http://SERVER_IP_ADDRESS:3000 to view the status of the experiment (Username: admin, Password: jqueuer).

7- Use the link http://SERVER_IP_ADDRESS:5000/infrastructures/micado_worker_infra to delete all MiCADO workers.

8- All JQueuer componenets send their log to three logging containers on MiCADO master. In roder to deubg the JQueuer, COnnect via SSH to your server and show the log of the the syslog containers using docker log command. 
