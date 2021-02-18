SHELL=/bin/bash

# Export variables
#TODO check the project id is set and is set properly
PROJECT_ID=$(shell gcloud config get-value core/project)
CLUSTER_ID=cluster-1
ZONE=us-east1-b
REGION=us-east1
KUBE_NAMESPACE=workshop
HELM_RELEASE=jhub
INSTANCE_TYPE=e2-medium
NUM_NODES=4
JUPYTERHUB_VERSION=0.10.6
NETWORK="projects/${PROJECT_ID}/global/networks/default"
SUBNETWORK="projects/${PROJECT_ID}/regions/${REGION}/subnetworks/default"

deploy: vars create-cluster connect-cluster create-namespace install-jupyterhub get-ip

vars: # Display variables
	@echo "PROJECT ID: $(PROJECT_ID)"
	@echo "CLUSTER ID: $(CLUSTER_ID)"
	@echo "ZONE: $(ZONE)"
	@echo "REGION: $(REGION)"
	@echo "INSTANCE TYPE: $(INSTANCE_TYPE)"
	@echo "NUM NODES: $(NUM_NODES)"
	@echo "NAMESPACE: $(KUBE_NAMESPACE)"
	@echo "HELM RELEASE: $(HELM_RELEASE)"

create-cluster:
	@echo ""
	@echo "Create GKE Cluster"
	gcloud beta container --project ${PROJECT_ID} clusters create ${CLUSTER_ID} \
        --zone ${ZONE} \
        --no-enable-basic-auth --cluster-version "1.17.15-gke.800" \
        --release-channel "regular" \
        --machine-type ${INSTANCE_TYPE} \
        --image-type "COS" \
        --disk-type "pd-standard" --disk-size "100" --metadata disable-legacy-endpoints=true \
        --scopes "https://www.googleapis.com/auth/logging.write","https://www.googleapis.com/auth/monitoring","https://www.googleapis.com/auth/servicecontrol","https://www.googleapis.com/auth/service.management.readonly","https://www.googleapis.com/auth/trace.append" \
        --num-nodes ${NUM_NODES} \
        --enable-stackdriver-kubernetes \
        --enable-ip-alias \
        --network ${NETWORK} \
        --subnetwork ${SUBNETWORK} \
        --default-max-pods-per-node "10" --no-enable-master-authorized-networks \
        --addons HorizontalPodAutoscaling,HttpLoadBalancing --enable-autoupgrade --enable-autorepair \
        --max-surge-upgrade 1 --max-unavailable-upgrade 0 --node-locations ${ZONE}

## connect to cluster
connect-cluster:
	@echo ""
	@echo "Connect to Cluster"
	gcloud container clusters get-credentials ${CLUSTER_ID} --zone=${ZONE} --project ${PROJECT_ID}

# create cluster namespace
create-namespace:
	@echo ""
	@echo "Create Namespace"
	kubectl create namespace ${KUBE_NAMESPACE}

# Install jupyterhub
install-jupyterhub:
	@echo ""
	@echo "Install Jupyterhub"
	helm upgrade --cleanup-on-fail \
	--install ${HELM_RELEASE} \
	jupyterhub/jupyterhub \
	--namespace ${KUBE_NAMESPACE} \
        --version=${JUPYTERHUB_VERSION} \
        --values config.yaml

get-ip:
	@echo "Get IP"
	@echo "You can find the public IP of the JupyterHub by doing. The hub and IP address might take a few minutes to be provisioned"
	kubectl --namespace=workshop get svc proxy-public

get-pods:
	kubectl --namespace=${KUBE_NAMESPACE} get pod

get-namespaces:
	kubectl get deployments -o wide --namespace ${KUBE_NAMESPACE}

# get_versions: ## lists the container images used for particular pods
get-pods-by-release:
	kubectl get pods -l release=${HELM_RELEASE} -n ${KUBE_NAMESPACE} -o jsonpath="{range .items[*]}{.metadata.name}{'\n'}{range .spec.containers[*]}{.name}{'\t'}{.image}{'\n\n'}{end}{'\n'}{end}{'\n'}"

get_status:
	kubectl get pod,svc,deployments,pv,pvc,ingress -n ${KUBE_NAMESPACE}

delete-release:
	helm delete ${HELM_RELEASE} --namespace ${KUBE_NAMESPACE}

delete:
	@echo ""
	@echo "Delete GKE Cluster"
	gcloud container clusters delete ${CLUSTER_ID} --project ${PROJECT_ID} --zone=${ZONE}
