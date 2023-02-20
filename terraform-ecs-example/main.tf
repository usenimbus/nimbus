terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
    }
  }
}

provider "aws" {
  region  = "eu-west-2"
}

provider "cloudflare" {
  api_token = var.cf_api_token
}

variable "license_key" {
  type = string
}

variable "host" {
  type = string
}

variable "nimbus_version" {
  type = string
}

variable "vpc_cidr" {
  description = "CIDR block for main"
  type        = string
  default     = "10.0.0.0/16"
}

# availability zones variable
variable "availability_zones" {
  type    = string
  default = "eu-west-2a"
}

# availability zones variable
variable "cf_zone_id" {
  type    = string
}

# availability zones variable
variable "installation_name" {
  type    = string
  default = "nimbus"
}

variable "cf_api_token" {
  type    = string
}

variable "rds_username" {
  description = "RDS database username"
  default     = "foo"
}

variable "rds_instance_class" {
  description = "RDS instance type"
  default     = "db.m5.large"
}

variable "nimbus_org_name" {
  description = "Init name for Nimbus Organisation"
}


resource "aws_lb" "nlb" {
  load_balancer_type = "network"
  subnets            = [aws_default_subnet.default_subnet_a.id, aws_default_subnet.default_subnet_b.id]
  name               = "${var.installation_name}-loadbalancer"
}

resource "aws_alb_target_group" "http_tg" {
  name = "${var.installation_name}-http-targets"

  port     = "8080"
  protocol = "TCP"
  vpc_id   = aws_default_vpc.default_vpc.id

  health_check {
    enabled = true
    path    = "/playground"
  }

  target_type = "ip"
}

resource "aws_acm_certificate" "cert" {
  domain_name       = var.host
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_alb_listener" "https" {
  load_balancer_arn = aws_lb.nlb.id
  port              = "443"
  protocol          = "TLS"

  certificate_arn = aws_acm_certificate.cert.arn

  default_action {
    target_group_arn = aws_alb_target_group.http_tg.id
    type             = "forward"
  }
}

resource "aws_lb_target_group" "dns_tg" {
  name = "${var.installation_name}-dns-targets"

  port     = "53"
  protocol = "TCP_UDP"
  vpc_id   = aws_default_vpc.default_vpc.id

  health_check {
    enabled = true
    path    = "/playground"
    port    = 8080
    matcher = "200"
  }

  target_type = "ip"
}

resource "aws_lb_listener" "dns" {
  load_balancer_arn = aws_lb.nlb.id
  port              = "53"
  protocol          = "TCP_UDP"

  default_action {
    target_group_arn = aws_lb_target_group.dns_tg.id
    type             = "forward"
  }
}

resource "aws_iam_policy" "nimbus" {
  name = "Nimbus"
  policy = jsonencode(
    {
      Statement = [
        {
          Action = [
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
            "ec2-instance-connect:SendSSHPublicKey",
          ]
          Effect   = "Allow"
          Resource = "*"
        },
      ]
      Version = "2012-10-17"
    }
  )
}

resource "aws_iam_role" "nimbus" {
  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "ec2.amazonaws.com"
          }
        },
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "ecs-tasks.amazonaws.com"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )
  description = "Allow Nimbus Server to manage AWS resources"
  managed_policy_arns = [
    aws_iam_policy.nimbus.arn,
    "arn:aws:iam::aws:policy/AdministratorAccess",
  ]
  max_session_duration = 3600
  name                 = "${var.installation_name}-ecs-server"
  path                 = "/"
}

resource "aws_default_vpc" "default_vpc" {
}

resource "aws_default_subnet" "default_subnet_a" {
  availability_zone = "eu-west-2a"
}

resource "aws_default_subnet" "default_subnet_b" {
  availability_zone = "eu-west-2b"
}

resource "aws_security_group" "sg" {
  name   = "${var.installation_name}-ecs"
  vpc_id = aws_default_vpc.default_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    self        = "false"
    cidr_blocks = ["0.0.0.0/0"]
    description = "http"
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    self        = "false"
    cidr_blocks = ["0.0.0.0/0"]
    description = "http_internal"
  }

  ingress {
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    self        = "false"
    cidr_blocks = ["0.0.0.0/0"]
    description = "dns"
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    self        = "true"
    description = "rds"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
############CREATING A ECS CLUSTER#############

resource "aws_ecs_cluster" "cluster" {
  name = "${var.installation_name}-cluster"
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_task_definition" "task" {
  family                   = "service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE", "EC2"]
  cpu                      = 512
  task_role_arn            = aws_iam_role.nimbus.arn
  execution_role_arn       = aws_iam_role.nimbus.arn
  memory                   = 2048
  depends_on               = [aws_db_instance.nimbus_database]
  container_definitions    = <<DEFINITION
  [
    {
      "name"      : "nimbus-server",
      "image": "ghcr.io/usenimbus/nimbus:${var.nimbus_version}",
      "memory"    : 2048,
      "essential" : true,
      "environment": [
        {
          "name": "ENT_DATASOURCE",
          "value": "${local.nimbus_db_datasource}"
        },
        {
          "name": "LICENSE_KEY",
          "value": "${var.license_key}"
        },
        {
          "name": "HOST",
          "value": "${var.host}"
        },
        {
          "name": "HOST_INTERNAL",
          "value": "https://${var.host}"
        },
        {
          "name": "HOST_IP",
          "value": "${aws_lb.nlb.dns_name}"
        },
        {
          "name": "ORG_NAME",
          "value": "${var.nimbus_org_name}"
        },
        {
          "name": "HOST_CNAME",
          "value": "true"
        },
        {
          "name": "OIDC_ISSUER_URL",
          "value": "https://${var.host}/"
        },
        {
          "name": "OIDC_REDIRECT_URL",
          "value": "https://${var.host}/auth/callback"
        },
        {
          "name": "ECS_AVAILABLE_LOGGING_DRIVERS",
          "value": "['json-file','awslogs']"
        }
      ],
      "logConfiguration": {
          "logDriver": "awslogs",
          "options": {
              "awslogs-group": "nimbus-server",
              "awslogs-region": "eu-west-2",
              "awslogs-stream-prefix": "nimbus"
          }
      },
      "portMappings" : [
        {
          "containerPort" : 53,
          "hostPort"      : 53,
          "protocol"      : "udp"
        },
        {
          "containerPort" : 8080,
          "hostPort"      : 8080
        }
      ]
    }
  ]
  DEFINITION
}

resource "aws_ecs_service" "service" {
  name             = "${var.installation_name}-service"
  cluster          = aws_ecs_cluster.cluster.id
  task_definition  = aws_ecs_task_definition.task.id
  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "LATEST"

  load_balancer {
    target_group_arn = aws_alb_target_group.http_tg.id
    container_name   = "nimbus-server"
    container_port   = "8080"
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.dns_tg.id
    container_name   = "nimbus-server"
    container_port   = "53"
  }

  network_configuration {
    assign_public_ip = true
    security_groups  = [aws_security_group.sg.id]
    subnets          = [aws_default_subnet.default_subnet_a.id, aws_default_subnet.default_subnet_b.id]
  }
  lifecycle {
    ignore_changes = [desired_count]
  }
}

resource "cloudflare_record" "cert-validations" {
  count = length(aws_acm_certificate.cert.domain_validation_options)

  zone_id = var.cf_zone_id

  name  = element(aws_acm_certificate.cert.domain_validation_options.*.resource_record_name, count.index)
  type  = element(aws_acm_certificate.cert.domain_validation_options.*.resource_record_type, count.index)
  value = element(aws_acm_certificate.cert.domain_validation_options.*.resource_record_value, count.index)

  ttl = 1
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn

  depends_on = [
    cloudflare_record.cert-validations
  ]
}

resource "cloudflare_record" "nimbus_ecs" {
  zone_id = var.cf_zone_id
  name    = split(".", var.host)[0] # use first segment of the host
  value   = aws_lb.nlb.dns_name
  type    = "NS"
  ttl     = 1

  # wait for certification before DNS update
  depends_on = [
    aws_acm_certificate_validation.cert
  ]
}

resource "random_password" "rds_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_db_subnet_group" "nimbus_database" {
  name       = "main"
  subnet_ids = [aws_default_subnet.default_subnet_a.id, aws_default_subnet.default_subnet_b.id]
}


resource "aws_db_instance" "nimbus_database" {
  identifier              = "production"
  db_name                 = "${var.installation_name}_database"
  username                = "${var.installation_name}_user"
  password                = random_password.rds_password.result
  port                    = "5432"
  engine                  = "postgres"
  engine_version          = "14"
  instance_class          = var.rds_instance_class
  allocated_storage       = "20"
  storage_encrypted       = false
  vpc_security_group_ids  = [aws_security_group.sg.id]
  db_subnet_group_name    = aws_db_subnet_group.nimbus_database.id
  multi_az                = false
  storage_type            = "gp2"
  publicly_accessible     = false
  backup_retention_period = 7
  skip_final_snapshot     = true
}

locals {
  nimbus_db_datasource = "postgresql://${var.installation_name}_user:${random_password.rds_password.result}@${aws_db_instance.nimbus_database.endpoint}/${var.installation_name}_database"
}
