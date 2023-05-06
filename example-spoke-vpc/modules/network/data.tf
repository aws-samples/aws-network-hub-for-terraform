/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: MIT-0 */

data "aws_ssm_parameter" "ipam_pool" {
  provider = aws.network_hub
  name     = "/ipam/pool/id"
}

data "aws_ram_resource_share" "org_vpc_share" {
  provider       = aws.network_hub
  name           = "vpc-org-share"
  resource_owner = "SELF"
}

data "aws_caller_identity" "current" {}