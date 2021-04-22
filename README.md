 # Manuka

 This is a project for deploying and monitoring honeypots on AWS and Azure with terraform. This project currently consists of the following:

- Elastic Stack (https://github.com/elastic)
   - Elasticsearch
   - Logstash
   - Kibana

- Traefik reverse proxy for kibana access (https://github.com/traefik/traefik)

- Cowrie SSH Honeypot (https://github.com/cowrie/cowrie)

# Deployment

This application stack uses docker compose and is intended to be deployed with Terraform on AWS or Azure. Manual installation is however possible.

## Terraform (AWS/Azure)

- Install Terraform
- Install AWS Cli / Azure Cli
- Setup credentials
- Clone manuka repo
- Open terminal in directory "./Manuka/terraform/aws" or "./Manuka/terraform/azure" and run 'terraform init'
- Run 'terraform apply' and supply variables or alternatively create .tfvars file beforehand

  Sample terraform.tfvars
  ```
  traefikUser = "user_for_proxy_to_traefik_dashboard"
  traefikPassword = "password_for_proxy_to_traefik_dashboard"
  kibanaUser = "user_for_kibana"
  kibanaPassword = "password_for_kibana"
  ```
- On apply:
  - SSH private and public keys are automatically created and outputted to "./keys/"
  - Access for SSH, Kibana and the Traefik dashboard is provided in output
- Have a coffee (Wait around 10 mins for setup to complete)
  - Check progress by sshing into the instance with the created private key file
    - Run 'sudo systemctl status manuka' to check the service status
    - Run 'docker ps' to check docker status
    - Once 'docker ps' shows the containers are running wait a couple of minutes for elasticsearch to finish starting.
- Access Kibana with the kibana user and the password variables provided and the outputted url
- Navigate to Stack Management -> Saved Objects -> Import and load cowrie.ndjson located in the imports folder.
- View the Cowrie Dashboard and watch the attacks come in.

## Manual Installation

Manual installation is available for ubuntu 20.04 systems (other ubuntu/debian versions are untested). SSH port is automatically changed to 50220 (can be changed by modifying setup script), port 80 needs opening up to the world with the host setup within a dmz. Cloud installation through terraform is recommended.

- git clone --depth=1 https://github.com/lluked/manuka ~/manuka
- cd ~/manuka
- sudo ./bin/setup.sh
