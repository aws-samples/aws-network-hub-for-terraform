/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: MIT-0 */

resource "aws_vpc_ipam" "org_ipam" {
  operating_regions {
    region_name = var.aws_region
  }
}

resource "aws_vpc_ipam_scope" "private_org_ipam_scope" {
  ipam_id     = aws_vpc_ipam.org_ipam.id
  description = "Org Scope"
}

resource "aws_vpc_ipam_pool" "private_org_ipam_pool" {
  address_family = "ipv4"
  ipam_scope_id  = aws_vpc_ipam_scope.private_org_ipam_scope.id
  locale         = var.aws_region
}

resource "aws_vpc_ipam_pool_cidr" "private_org_ipam_pool" {
  ipam_pool_id = aws_vpc_ipam_pool.private_org_ipam_pool.id
  cidr         = var.ipam_cidr
}

resource "aws_ram_resource_share" "main" {
  name                      = "ipam-org-share"
  allow_external_principals = false

  tags = {
    Name = "org-ipam-ram-share"
  }
}

# Requires RAM enabled to share with AWS org:
# enable in org master account with 'aws ram enable-sharing-with-aws-organization'
resource "aws_ram_principal_association" "org" {
  principal          = var.org_arn
  resource_share_arn = aws_ram_resource_share.main.arn
}

# Requires RAM enabled to share with AWS org
resource "aws_ram_resource_association" "ipam" {
  resource_arn       = aws_vpc_ipam_pool.private_org_ipam_pool.arn
  resource_share_arn = aws_ram_resource_share.main.arn
}

resource "aws_ssm_parameter" "ipam_pool_id" {
  name        = "/ipam/pool/id"
  description = "IPAM pool ID in central account for corresponding enviornment"
  type        = "SecureString"
  value       = aws_vpc_ipam_pool.private_org_ipam_pool.id

  tags = {
    automation = true
  }
}