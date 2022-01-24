/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: MIT-0 */

variable "environment" {
  description = "Deployment environment passed as argument or environment variable"
  type        = string
}

variable "vpc_id" {
  description = "vpc id to associate delegated subdomain to"
  type        = string
}

variable "root_domain" {
  description = "rootdomain for the delegated private hosted zone"
  type        = string
}

variable "aws_region" {
  type        = string
  description = "AWS region being deployed to"
}

variable "tags" {
  type        = map(string)
  description = "default provider tags"
}

variable "network_hub_account_number" {
  type        = string
  description = "Network Hub account ID"
}

variable "centralised_vpc_endpoints" {
  description = "Which centralised VPC endpoints to consume"
  type        = map(string)
}
