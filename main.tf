/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: MIT-0 */

module "ipam" {
  source     = "./modules/ipam"
  ipam_cidr  = local.config.ipam_cidr
  org_arn    = local.aws_org_arn
  aws_region = var.aws_region
}

module "tgw" {
  source                = "./modules/tgw"
  inspection_attachment = module.network_firewall_vpc.inspection_attachment
  tgw_route_tables      = local.config.tgw_route_tables
  cidr                  = local.config.ipam_cidr
  az_names              = local.availability_zone_names
  org_arn               = local.aws_org_arn
  environment           = var.environment
}

module "vpc_endpoints" {
  source              = "./modules/vpc_endpoints"
  kms_key_id          = aws_kms_key.log_key.arn
  iam_role_arn        = aws_iam_role.flow_logs.arn
  tgw_route_tables    = module.tgw.tgw_route_table
  tgw                 = module.tgw.tgw
  org_ipam_pool       = module.ipam.org_ipam_pool
  cidr                = local.config.ipam_cidr
  interface_endpoints = local.endpoints
  az_names            = local.availability_zone_names
  environment         = var.environment
  depends_on = [
    module.ipam,
    module.tgw
  ]
}

module "dns" {
  source              = "./modules/dns"
  kms_key_id          = aws_kms_key.log_key.arn
  iam_role_arn        = aws_iam_role.flow_logs.arn
  tgw_route_tables    = module.tgw.tgw_route_table
  tgw                 = module.tgw.tgw
  org_ipam_pool       = module.ipam.org_ipam_pool
  cidr                = local.config.ipam_cidr
  root_domain         = local.config.root_domain
  interface_endpoints = local.endpoints
  az_names            = local.availability_zone_names
  org_arn             = local.aws_org_arn
  environment         = var.environment
  depends_on = [
    module.ipam,
    module.tgw
  ]
}

module "network_firewall_vpc" {
  source           = "./modules/network_firewall_vpc"
  kms_key_id       = aws_kms_key.log_key.arn
  iam_role_arn     = aws_iam_role.flow_logs.arn
  tgw_route_tables = module.tgw.tgw_route_table
  tgw              = module.tgw.tgw
  org_arn          = local.aws_org_arn
  org_ipam_pool    = module.ipam.org_ipam_pool
  cidr             = local.config.ipam_cidr
  az_names         = local.availability_zone_names
  environment      = var.environment
  aws_region       = var.aws_region
  depends_on = [
    module.ipam
  ]
}

resource "aws_iam_role" "central_network" {
  #checkov:skip=CKV_AWS_60: Automation role - requires Org perm with additional tag based condition for sample only
  name               = "${var.environment}_network_automation_role"
  assume_role_policy = data.aws_iam_policy_document.central_network_role_assume_role_policy.json
  tags = {
    automation = "true"
  }
}

data "aws_iam_policy_document" "central_network_role_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [data.aws_organizations_organization.main.id]
    }

    condition {
      test     = "StringNotEqualsIgnoreCase"
      variable = "aws:RequestTag/automation"
      values   = ["true"]
    }

    principals {
      identifiers = ["*"]
      type        = "AWS"
    }
  }
}

#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_policy" "central_network" {
  name        = "${var.environment}_central_network_automation_policy"
  path        = "/"
  description = "${var.environment} Central network automation policy to allow TGW association, propagation and route53 private hosted zone association"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ec2:DescribeTransitGateway*",
          "ec2:GetTransitGateway*",
          "ec2:SearchTransitGateway*",
          "ec2:AssociateTransitGatewayRouteTable",
          "ec2:DisassociateTransitGatewayRouteTable",
          "ec2:EnableTransitGatewayRouteTablePropagation",
          "ec2:ModifyTransitGateway",
          "ec2:DescribeVpcs",
          "ec2:DescribeVpcAttribute",
          "ec2:ReplaceTransitGatewayRoute",
          "ec2:DisableTransitGatewayRouteTablePropagation"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ssm:GetParameters",
          "ssm:GetParameter",
          "kms:Decrypt"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "route53:GetHostedZone",
          "route53:ListHostedZonesByVPC",
          "route53:DisassociateVPCFromHostedZone",
          "route53:AssociateVPCWithHostedZone",
          "route53:CreateVPCAssociationAuthorization",
          "route53:ChangeResourceRecordSets",
          "route53:ListResourceRecordSets",
          "route53:DeleteVPCAssociationAuthorization",
          "route53:ListHostedZones",
          "route53:ListTagsForResource",
          "route53:ListVPCAssociationAuthorizations",
          "route53:GetChange"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action = [
          "ram:*"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "central_network" {
  name       = "central_network"
  roles      = [aws_iam_role.central_network.name]
  policy_arn = aws_iam_policy.central_network.arn
}

resource "aws_iam_role" "flow_logs" {
  name = "${var.environment}_endpoint_vpc_flow_logs"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

#tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_role_policy" "flow_logs" {
  name = "endpoint_vpc_flow_logs"
  role = aws_iam_role.flow_logs.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

# Create a KMS key for CloudWatch Log encryption
resource "aws_kms_key" "log_key" {
  description             = "KMS Logs Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.policy_kms_logs_document.json
  tags = {
    Name = "vpc-flow-logs-${var.environment}"
  }
}

data "aws_iam_policy_document" "policy_kms_logs_document" {
  #checkov:skip=CKV_AWS_109: KMS key policy to delegate permissions to IAM
  #checkov:skip=CKV_AWS_111: KMS key policy to delegate permissions to IAM
  statement {
    sid       = "Enable IAM User Permissions"
    actions   = ["kms:*"]
    resources = ["*"]
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
    }
  }

  statement {
    sid = "Enable KMS to be used by CloudWatch Logs"
    actions = [
      "kms:Encrypt*",
      "kms:Decrypt*",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:Describe*"
    ]
    resources = ["*"]
    principals {
      type        = "Service"
      identifiers = ["logs.${var.aws_region}.amazonaws.com"]
    }
  }
}
