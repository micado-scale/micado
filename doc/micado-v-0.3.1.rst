.. _micado_v_0.3.1:

MiCADO V 0.3.1
==============================

This tutorial will guide you through how to install MiCADO and try it out with an example application. The tutorial builds a scalable architecture framework and performs the automatic scaling of the application based on Occopus, Docker Swarm and Prometheus.
MiCADO is a framework that enables you to create scalable cloud-based infrastructures in the most generic way, where user applications can be interchanged in the framework. We developed MiCADO in a way that is user-friendly and highly customizable.

  .. note::

    We advise you to use CloudSigma as a target cloud!

**Limitations of MiCADO V 0.3.1:**
 - scaling decisions are performed based on CPU load
 - new virtual machines can be launch in every 5 minutes and new containers in every minute
 - Docker containers will utilize newly launched Swarm node when a Docker service is scaled up
 - Docker service upscaling happens only in case of free resources; new VM allocation is applied when average CPU load of the VMs reaches certain threshold 

**Developments compared to MiCADO V 0.3.0:**

**features:** 
    - list of individual Docker services to be scaled can be defined by the user 
    - upscale and downscale thresholds of each Docker services can be defined by the user
    - default threshold settings can be applied for services not defined individually

**bugfixes:**
 
 - applying fixed versions instead of "latest" versions of the Docker images
 - undefined Docker service resource requirement is now considered unlimited instead of a fixed default value
 - fixing too frequent upscaling, which caused unnecessary resource allocation
 - code refactoring

**1. Prerequisites**

Generally, MiCADO requires the following requirements. Please make sure you provided these for the virtual machines where we will deploy MiCADO.

 **1.1. Target cloud**

  You will need an account for a cloud which provides you an “Ubuntu 16.04” OS image with cloud-init support.

  - Accessing a cloud through an Occopus-compatible interface (e.g. EC2, OCCI, Nova, etc.)
  - Target cloud contains a base 16.04 LTS Ubuntu OS image with cloud-init support (image id, instance type)

 **1.2. Port ranges**

  While most of the clouds don’t require you to configure which ports you want to open (like CloudSigma), it is still important to make sure that the following ports are open for MiCADO:

   .. code::

    
    TCP:22,53,80,443,2375,2377,7946,8300,8301,8302,8400,8500,8600,9090,9093,9095,9100,9200

    UDP:7946,8301,8302,8600


 **1.3. Internet access for the VM’s**

  MiCADO needs to pull some files from GitHub and Docker Hub. Make sure that the virtual machines have internet access and also reach each other.

**2. Deployment of MiCADO**

 **2.1. Download MiCADO**

  Please download the installation file of MiCADO from the `following link <https://raw.githubusercontent.com/micado-scale/micado/0.3.1/micado_cloud_init.yaml>`_ .

 **2.2. Insert user inputs**

  Now you have to modify the file that you downloaded. In the beginning of the file you will see a section called “USER DATA” as shown in this code:

    .. code::

     write_files:
     USER DATA - Cloudsigma
     - path: /var/lib/micado/occopus/temp_user_data.yaml
       content: |
         user_data:
           auth_data:
             type: cloudsigma
             email: YOUR_EMAIL
             password: YOUR_PASSWORD
 
           resource:
             type: cloudsigma
             endpoint: YOUR_ENDPOINT
             libdrive_id: UBUNTU_16.04_IMAGE_ID
             description:
                 cpu: 1000
                 mem: 1073741824
                 vnc_password: secret
                 pubkeys:
                     -
                         KEY_UUID
                 nics:
                     -
                          ip_v4_conf:
                             conf: dhcp
                             conf: dhcp

           scaling:
             min: 1
             max: 10


  This file specifies the user credentials for the target cloud, the resource IDs that will be used for the virtual machines and a scaling section which specifies the scaling ranges. We provided you multiple configurations for the CloudSigma, Openstack and Amazon cloud. 

  User can choose from these different configurations depending on the target cloud. Please uncomment the one you will use and fill out the parameters!
    
  .. note::
 
   You can find further explanation about the attributes (keywords) which are listed and which can be used for the different resource handlers on the `Occopus website <http://www.lpds.sztaki.hu/occo/user/html/createinfra.html#resource>`_ .

 **2.3 Set scaling policy**

  **2.3.1 Container scaling policy**

  Set the scaling policy of the Docker containers in the “scaling_policy.yaml” file. This file specifies which Docker services will be auto-scaled and their scaling thresholds. You have to uncomment this section and specify the Docker service name (like service_name1) and scaling thresholds (scale down and scale up parameters).

  .. code::

   Scaling policy
   - path: /var/lib/MICADO/alert-generator/scaling_policy.yaml
     content: |
       services:
         service_name1:
           scaledown: 20
           scaleup: 80

         service_name2:
           scaledown: 10
           scaleup: 90

  Use the same service name when you run your application within the MiCADO framework. 

  Create Docker service with specified name:

  .. code::

    $ docker service create --name=service_name1 [docker image]

  Get the Docker service name from docker stack deploy:

  .. code::

    $ docker stack deploy --compose-file docker-compose.yml [stack name]

  The service name will be: [stack name]_[service name in compose file]

  **2.3.2 Set default container scaling policy (optional)**

   You can scale up/down all of the Docker services, by setting the default container scaling policy, at the end of the cloud-init file. To active the default scaling policy, edit the last command in the runcmd section:

   .. code::

    $ docker run -d -v /var/run/docker.sock:/var/run/docker.sock -v /etc/prometheus/:/etc/prometheus -v /var/lib/micado/alert-generator/:/var/lib/micado/alert-generator/ -e CONTAINER_SCALING_FILE=/var/lib/micado/alert-generator/scaling_policy.yaml -e ALERTS_FILE_PATH=/etc/prometheus/ -e AUTO_GENERATE_ALERT=False -e DEFAULT_SCALEUP=90 -e DEFAULT_SCALEDOWN=10 -e PROMETHEUS="$IP" micado/alert-generator:1.2

   Set the “AUTO_GENERATE_ALERT” variable to “True”, and the “DEFAULT_SCALEUP” and the “DEFAULT_SCALEDOWN” to configure the scaling thresholds. These scaling parameters will be applied to all of the Docker services. 

  **2.3.3 VM scaling policy**

   You can find the VM scaling policies in the prometheus.rules file.

   By default Prometheus will make alert if the CPU utilization of the worker VM is more than 60%, and if the CPU utilization of the worker VM is under 20%. 

   If you want to update the threshold value for upscaling and downscaling please find the arithmetic expressions related to the parameter called “worker_cpu_utilization” under the alert definitions for “worker_overloaded” and “worker_underloaded”. These values must be between 0 and 100. 

   By default the number of the virtual machines will be scaled up/down, if the alert is active for more than 5 minutes, but new containers can be started or deleted in every minute. 

 **2.4. Check the syntax**

  Before deploying MiCADO we advise you to check the syntax of your file. Since it is a yaml formatted file you should make sure of the syntax. To do so just copy paste your MiCADO file to an `online yaml checker <http://www.yamllint.com/>`_ .


 **2.5. Start MiCADO**

  To start MiCADO click on the “Wizard” button on the compute tab if you use CloudSigma.

  - Choose the favour type “small-2” 
  - Choose an Ubuntu 16.04 LTS image
  - Attach your ssh key
  - Paste the previously downloaded file to the cloud-init box and activate it
  - Click on “Create”

  .. note::

    If you wish to use another cloud, the steps should be almost the same.

**3. Application deployment**

This part will guide you have to start an example application. We will use a stress testing application. It will stress test the cluster and the application will be overloaded automatically. MiCADO will automatically adjust the resources and scale up both the number of application services running as Docker services, and also the number virtual machines on the cloud.

SSH inside your MiCADO virtual machine on the cloud, and run the following command as root.

  .. code::

    $ ssh cloudsigma@[ipaddress_of_micado]

    $ docker service create progrium/stress --cpu 2 --io 1 --vm 2 --vm-bytes 128M

**4. Testing**

 **4.1. Test if the system is operational**

 In your browser enter the following URL: 

  .. code::

   http://ip_address_of_MiCADO_VM:8500

 You should see the web page of Consul. Also on the “nodes” tab you should see at least one node (MiCADO + minimum number of scaling ranges you specified).

 **4.2. Test if scaling working properly**

 The stress testing application should automatically generates load on the worker cluster. To check out the number of nodes after the scale up event in MiCADO, check Prometheus on the following link:
  
  .. code::

   http://ip_address_of_MiCADO_VM:9090/targets

 To test the scaling down mechanism, stop running the stress testing application and this way delete the load on the cluster. After a few minutes, the number of nodes in the cluster should be go back to its minimum value (specified in the user_data, scaling part). 

**5. Delete infrastructure**

 **5.1 Delete worker nodes**

 Delete the MiCADO worker nodes with the following command on the MiCADO master node:

 .. code::

  $ curl -X DELETE http://[micado_master_ip]:5000/infrastructures/micado_worker_infra

 **5.2 Delete master node**

 Delete the MiCADO master node on your cloud's web UI.



For more information and help visit the `COLA website <https://project-cola.eu/>`_  or the `MiCADO GitHub page <https://github.com/micado-scale>`_ . 

 .. important::
   
  As a result of an unsuccessful deletion, resources may remain on the target cloud, which will have financial consequences. Please be careful! 
