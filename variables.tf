/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: MIT-0 */

variable "environment" {
  description = "Deployment environment passed as argument or environment variable"
  type        = string
}

variable "env_config" {
  description = "Map of objects for per environment configuration"
  type = map(object({
    ipam_cidr        = string
    tgw_route_tables = list(string)
    root_domain      = string
  }))
}

variable "aws_region" {
  description = "AWS region being deployed to"
  type        = string
}

variable "vpc_endpoints" {
  description = "Which VPC endpoints to use"
  type        = list(string)
}

variable "tags" {
  description = "Default tags to apply to all resources"
  type        = map(string)
}
