/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: MIT-0 */

variable "environment" {
  description = "Deployment environment passed as argument or environment variable"
  type        = string
}

variable "aws_region" {
  description = "AWS region being deployed to"
  type        = string
}

variable "az_names" {
  description = "A list of the Availability Zone names available to the account"
  type        = list(string)
}

variable "cidr" {
  description = "corporate cidr range for use with blackholing traffic between production and development environments"
  type        = string
}

variable "org_ipam_pool" {
  description = "IPAM pool ID to allocate CIDR space"
  type        = string
}

variable "tgw_route_tables" {
  description = "TGW route tables for VPC association and propagation"
  type        = map(string)
}

variable "tgw" {
  description = "TGW route tables for VPC attachment"
  type        = string
}

variable "kms_key_id" {
  description = "vpc flow logs kms key to encrypt logs"
  type        = string
}

variable "iam_role_arn" {
  description = "iam role to allow vpc flow logs to write to cloudwatch"
  type        = string
}