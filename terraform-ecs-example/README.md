# Deploying Nimbus to Amazon ECS using Terraform

View the full example in [main.tf](./main.tf)

This example provides a referance on how to deploy a functioning ECS cluster utilising RDS as the database provider, and Cloudflare as the domain DNS provider.

## Prerequisites

Setup AWS authentication for the target account on your local machine so the Terraform provider has access.

Use the following references for more details on how to do this:
- https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication-and-configuration
- https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html#cli-configure-quickstart-precedence


## Required configuration

| Key               | Description                                                                                                                   |
| ----------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `cf_zone_id`      | The Id of your Cloudflare domain zone                                                                                         |
| `cf_api_token`    | API token to allow Terraform to modify the given zone                                                                         |
| `license_key`     | The license key provided to you by Nimbus                                                                                     |
| `host`            | The host you wish to deploy your application to. For example nimbus.mycompany.dev                                             |
| `nimbus_org_name` | The name you want to display for your Nimbus org. For example 'My Company'. This can be changed later in the app.             |
| `nimbus_version`  | version of Nimbus to deploy. For example v0.6.0. See the latest versions [here](https://github.com/usenimbus/nimbus/releases) |



### Installing

These command can be used to apply the terraform after you have setup your AWS authentication.

```bash
# clone the template repo
git clone git@github.com:usenimbus/nimbus.git
cd nimbus/terraform-ecs/example

# verify your AWS account. This should be the account that you want to deploy Nimbus to
aws sts get-caller-identity

# initialise the terraform repo
terraform -init

# apply the terraform infrastructure
terraform apply \
    -var="license_key=$YOUR_NIMBUS_LICENSE" \
    -var="host=$YOUR_NIMBUS_DOMAIN" \
    -var="cf_zone_id=$YOUR_CLOUDFLARE_ZONE_ID" \
    -var="cf_api_token=$YOUR_CLOUDFLARE_APITOKEN" \
    -var="nimbus_org_name='$YOUR_ORG_NAME'" \
    -var="nimbus_version=$NIMBUS_VERSION"
```