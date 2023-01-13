# nimbus server
## AWS Prelim
### Setup EC2
Create an EC2 instance and a security group allow connections to port `:8080` from any source

### Setup Load Balancer and Domain(s)
1. Create a new Route53 Zone for your workspaces (for example, `workspaces.example.com`). Subdomains per workspace are created here.
1. Create an Application Load Balancer with HTTPS enabled.
    1. Route all HTTPS traffic to port `:8080` on your newly created EC2 instance
1. Create a new Route53 Zone for your hosted Nimbus URL (for example `nimbus.example.com`)
    1. Create a CNAME pointing this domain to your newly created Load Balancer

### VPC Setup
In order to access Nimbus Workspaces you need a VPC created under each desired regions.

We advise not using the default VPC for the sake of security.

If you wish to access these publicly, you will also need to create a public subnet and internet gateway.

### Policy Setup
1. Create a new policy called "Nimbus" with the following config:
```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "acm:RequestCertificate",
        "acm:DeleteCertificate",
        "acm:DescribeCertificate",
        "route53:ListResourceRecordSets",
        "route53:ChangeResourceRecordSets",
        "route53:GetChange",
        "ec2:CreateImage",
        "ec2:RegisterImage",
        "ec2:DeregisterImage",
        "ec2:DescribeImages",
        "ec2:CopyImage",
        "ec2:RunInstances",
        "ec2:DescribeRouteTables",
        "ec2:TerminateInstances",
        "ec2:DescribeInstances",
        "ec2:DescribeInstanceStatus",
        "ec2:StartInstances",
        "ec2:RebootInstances",
        "ec2:StopInstances",
        "ec2:CreateTags",
        "ec2:CreateSecurityGroup",
        "ec2:DescribeSecurityGroupRules",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:DeleteSecurityGroup",
        "ec2:DescribeSnapshots",
        "ec2:CreateSnapshots",
        "ec2:DescribeSnapshots",
        "ec2:DeleteSnapshot",
        "ec2:CopySnapshot",
        "ec2:DescribeVolumes",
        "ec2:DescribeVpcs",
        "ec2:DescribeSubnets",
        "ec2:ModifyNetworkInterfaceAttribute",
        "elasticloadbalancing:DeleteRule",
        "elasticloadbalancing:DescribeRules",
        "elasticloadbalancing:ModifyRule",
        "elasticloadbalancing:DescribeListenerCertificates",
        "elasticloadbalancing:AddListenerCertificates",
        "elasticloadbalancing:RemoveListenerCertificates",
        "elasticloadbalancing:CreateRule",
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:CreateListener",
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:CreateTargetGroup",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:DeleteTargetGroup",
        "cloudwatch:GetMetricStatistics",
        "ec2-instance-connect:SendSSHPublicKey"
      ],
      "Resource": "*"
    }
  ]
}
```
1. Create a new role called `nimbus-server` and attach the `Nimbus` policy.
    1. Attach this new role to your Nimbus Server EC2 instance.

---

### Database setup
Any PostgreSQL compatible database can be used.

We suggest CockroachDB as they provide an easy to setup Cloud instance: https://cockroachlabs.cloud/

---

### Download latest server binary
`sudo curl -L https://github.com/usenimbus/nimbus/releases/latest/download/nimbus-linux-amd64 -o /usr/bin/nimbus && sudo chmod 755 /usr/bin/nimbus`
### Download latest service unit
`sudo curl -L https://github.com/usenimbus/nimbus/releases/latest/download/nimbus.service -o /etc/systemd/system/nimbus.service && sudo systemctl daemon-reload`
### setup your config secrets inside of /opt/nimbus/config.yaml
Example config (copy using `sudo curl --create-dirs -L https://github.com/usenimbus/nimbus/releases/latest/download/config.yaml -o /opt/nimbus/config.yaml`):
```
HOST: "nimbus.example.com" # replace nimbus.example.com with your chosen domain
LICENSE_KEY: "my_example_key" # contact Nimbus to obtain your key
NIMBUS_API: "https://summit.usenimbus.com/graphql" # this is the Nimbus platform API
OIDC_ISSUER_URL: "https://nimbus.example.com" # replace nimbus.example.com with your chosen domain
OIDC_REDIRECT_URL: "https://nimbus.example.com/auth/callback" # replace nimbus.example.com with your chosen domain
SSO_PROVIDER: "username_password" # this sets your instance to standard username/password login
ADMIN_PRIVATE_KEY: "" # this will be generated during the `nimbus database init` step. Copy the value into this field
ENT_DATASOURCE: "postgresql://$USER:$PASSWORD@$HOST/$DATABASE?sslmode=verify-full" # any postgres compliant connection string should work here
```
### Initialize the database
`nimbus database init`

Enter `Y` when prompted to proceed with the database setup
### Start server as a service (and enable start on reboot)
`systemctl enable nimbus --now`

---
