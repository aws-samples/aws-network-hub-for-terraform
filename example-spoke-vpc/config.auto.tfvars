/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: MIT-0 */

aws_region                = "eu-west-2"
vpc_endpoints             = ["s3"]
centralised_vpc_endpoints = ["ec2", "rds", "sqs", "sns", "ssm", "logs", "ssmmessages", "ec2messages", "autoscaling", "ecs", "athena"]

tags = {
  Product    = "Network_Automation"
  Owner      = "WWPS"
  Project_ID = "12345"
}

env_config = {
  dev = {
    network_hub_account_number = ""
    tgw_route_tables           = ["shared", "dev"]
    root_domain                = "network-dev.internal."
  }
  test = {
    network_hub_account_number = ""
    tgw_route_tables           = ["shared", "dev"]
    root_domain                = "network-test.internal."
  }
  preprod = {
    network_hub_account_number = ""
    tgw_route_tables           = ["shared", "dev"]
    root_domain                = "network-preprod.internal."
  }
  prod = {
    network_hub_account_number = ""
    tgw_route_tables           = ["shared", "prod"]
    root_domain                = "network-prod.internal."
  }
}
