# Manuka

This is a project for deploying and monitoring an ssh honeypot. This project consists of the following:

- Terraform for provisioning Infrastructure on AWS or Azure
- Vagrant for local testing and development
- Ansible for provisioning the deployment
- Docker / docker-compose to run the services
- The [Elastic Stack](https://github.com/elastic) for monitoring and analysis
    - Elasticsearch
    - Logstash
    - Kibana
- [Traefik](https://github.com/traefik/traefik) reverse proxy for kibana access
- [Cowrie](https://github.com/cowrie/cowrie) SSH Honeypot

## Terraform Deployment (AWS/Azure)

- Install Terraform
- Install AWS Cli / Azure Cli
- Setup credentials
- Clone the repo
- Open a terminal in the `./terraform/aws` or `./terraform/azure` directory and run `terraform init`
- Update passwords in the terraform.tfvars file
```
    traefik_kibana_proxy_password = "changeme"
    elastic_password = "changeme"
    logstash_system_password = "changeme"
    logstash_internal_password = "changeme"
    kibana_system_password = "changeme"
```
traefik_kibana_proxy_password and elastic_password variables are for passwords for services that are exposed to the web (these are however limited to access from your IP only by default)
- run `terraform apply`
    - SSH private and public keys are automatically created and outputted to "./keys/" in the relative terraform folder
    - Terraform deploys all infrastructure
    - Ansible provisions the deployed instance
    - The real SSH port is changed from `22` to a non default value
    - The instance is signalled to restart
    - docker-compose is started to build the services after restart
    - Access for SSH, and Kibana is provided in the output
- Have a coffee (Wait around 10 mins for the deployment to complete)
- Access Kibana at the outputted url
    - The first login screen is for the Traefik proxy with the user being `kibana` and password being the value defined for `traefik_kibana_proxy_password` (This hides the kibana service if the firewall rules are opened up)
    - The second login is for kibana itself, the user is `elastic` and the password is the value defined for `elastic_password`
- Navigate to Stack Management -> Saved Objects -> Import and load cowrie.ndjson located at the root of the repo
- View the Cowrie Dashboard and watch the attacks come in

## Vagrant Deployment  (Development and Testing)

Vagrant deployment is largely the same as with Terraform but only creates the deployment for access on your local machine.

- Install Vagrant
- Install providers
- Clone the repo
- Open a terminal in the root directory and run `vagrant init`
- Update the password variables in ./ansible/main.yml
- Build the box with `vagrant up`
    -   `vagrant up --provider=virtualbox` for virtualbox only
    -   `vagrant up --provider=vmware_desktop` for vmware only
- Have a coffee (Wait around 10 mins for the deployment to complete)
- SSH remains on the default port 22
- Cowrie is bound to ports 2222 (SSH) and 2223 (Telnet) on the box, Vagrant maps these services to localhost at ports 5222 (SSH) and 5223 (Telnet)
- Traefik is bound to https port 443 on the box, Vagrant maps this service to localhost at port 8443
- Once everything is up and running create some honeypot activity with attempts to localhost port 5222 (SSH) and 5223 (Telnet)
- Access Kibana at `https://localhost:8443/xyz` and load the saved objects as described in the Terraform deployment

## Troubleshooting

  - Check progress by sshing into the instance
    - Run 'sudo systemctl status manuka' to check the service status
    - Run 'docker ps' to check docker status
    - Once 'docker ps' shows the Traefik container as running wait a couple of minutes.
