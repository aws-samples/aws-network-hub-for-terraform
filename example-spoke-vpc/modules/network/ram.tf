resource "aws_ram_principal_association" "org_vpc_share_invite" {
  count              = var.enable_ingress ? 1 : 0
  provider           = aws.network_hub
  principal          = data.aws_caller_identity.current.account_id
  resource_share_arn = data.aws_ram_resource_share.org_vpc_share.arn
}
