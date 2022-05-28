/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: MIT-0 */

variable "environment" {
  description = "Deployment environment passed as argument or environment variable"
  type        = string
}

variable "az_names" {
  description = "A list of the Availability Zone names available to the account"
  type        = list(string)
}

variable "interface_endpoints" {
  description = "object representing the region and services to create interface endpoints for"
  type        = map(string)
}

variable "tgw_route_table" {
  description = "TGW route tables for VPC association and propagation"
  type        = map(string)
}

variable "tgw" {
  description = "TGW ID"
  type        = string
}

variable "aws_region" {
  type        = string
  description = "AWS region being deployed to"
}

variable "tgw_association" {
  type        = string
  description = "tgw route table to associate to"
}

variable "network_hub_account_number" {
  type        = string
  description = "Network Hub account ID"
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
  default     = "spoke"
}
