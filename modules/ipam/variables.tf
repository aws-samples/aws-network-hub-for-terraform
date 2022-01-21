/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: MIT-0 */

variable "ipam_cidr" {
  description = "CIDR block assigned to IPAM pool"
  type        = string
}

variable "org_arn" {
  description = "The ARN of the AWS Organization this account belongs to"
  type        = string
}

variable "aws_region" {
  description = "AWS region being deployed to"
  type        = string
}
