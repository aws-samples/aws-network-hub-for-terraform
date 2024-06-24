/* Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
   SPDX-License-Identifier: MIT-0 */

module "network" {
  providers = {
    aws.network_hub = aws.network_hub
  }

  source                     = "./modules/network"
  az_names                   = local.availability_zone_names
  tgw                        = data.aws_ec2_transit_gateway.org_env.id
  interface_endpoints        = local.endpoints
  tgw_route_table            = local.tgw_route_table
  tgw_association            = data.aws_ec2_transit_gateway_route_table.associate.id
  network_hub_account_number = local.config.network_hub_account_number
  aws_region                 = var.aws_region
  environment                = var.environment
  vpc_name                   = var.vpc_name
  enable_ingress             = var.enable_ingress
}

module "dns" {
  providers = {
    aws.network_hub = aws.network_hub
  }

  source                     = "./modules/dns"
  environment                = var.environment
  centralised_vpc_endpoints  = local.centralised_endpoints
  vpc_id                     = module.network.vpc_id
  root_domain                = local.config.root_domain
  network_hub_account_number = local.config.network_hub_account_number
  aws_region                 = var.aws_region
}
