# jupyterhub-for-workshops
Script to setup Jupyterhub for workshops

The script creates a Kubernetes Cluster and runs the Jupyterhub helm chart (0.10.6). This setup does not allow users to connect to GCP resources. 

The Dockerfile for the Jupyterlab single user with gcloud can be [obtained here](https://github.com/snamburi3/gcloud-jupyterhub).

## Steps to build the cluster and install jupyterhub
```
# authenticate to Google Cloud
gcloud auth login

# set project
gcloud config set project {PROJECT_ID}

# gcloud components update to get the latest version (including beta versions)
gcloud components update

# Install helm (The minimum supported version of Helm in Z2JH is 3.2.0.)
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# add the JupyterHub Helm chart repository 
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
helm repo update

# modify the singularity.image.name in the config.yaml to a custom image. here is the [Example Dockerfile](https://github.com/snamburi3/gcloud-jupyterhub). The config pulls the image from Dockerhub

# create a Kubernetes Cluster, Kubernetes namespace, and install Jupyterhub. 
# make changes to the parameters in the Makefile
make deploy

# Delete the cluster
make delete
```

## Individual make commands to build the cluster, install jupyterhub, and debug
```
# deploy
    make create-cluster  # Create GKE Cluster
    make connect-cluster  # Connect to Cluster / Get Credentials
    make create-namespace # Create cluster namespace
    make install-jupyterhub # Install jupyterhub
    make get-ip # Get external IP of the hub
# debug
    make get-pods # get pods in a namespace
    make get-namespaces # get namespaces
    make get-pods-by-release # lists the container images used for particular pods
    make get_status # get status
# delete
    make delete-release # delete helm release
    make delete # Delete GKE Cluster
```
