/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: MIT-0 */

# https://www.terraform.io/language/settings/backends/configuration

# HTTP backend

# terraform {
#   backend "http" {}
# }

#Consul backend

# terraform {
#   backend "consul" {}
# }

# s3 + DynamoDB

# terraform {
#   backend "s3" {
#     bucket         = "<bucket_name>"
#     key            = "<path/terraform.tfstate>"
#     region         = "<region>"
#     encrypt        = true
#     kms_key_id     = "<kms_key_id>"
#     dynamodb_table = "<dynamodb_table>"
#   }
# }