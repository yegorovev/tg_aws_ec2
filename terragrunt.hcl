terraform {
  source = "github.com/yegorovev/tf_aws_instance.git"
}


locals {
  parameters_file = get_env("TG_PARAMS_FILE", "common_default.hcl")
  common          = read_terragrunt_config(find_in_parent_folders(local.parameters_file)).inputs.common
  env             = local.common.env
  profile         = local.common.profile
  region          = local.common.region

  common_tags = jsonencode(local.common.tags)

  net                     = read_terragrunt_config(find_in_parent_folders(local.parameters_file)).inputs.net
  net_backet_remote_state = local.net.net_backet_remote_state
  net_key_remote_state    = local.net.net_key_remote_state
  net_remote_state_region = local.net.net_remote_state_region

  ec2                         = read_terragrunt_config(find_in_parent_folders(local.parameters_file)).inputs.ec2
  ec2_lock_table_remote_state = local.ec2.ec2_lock_table_remote_state
  ec2_key_remote_state        = local.ec2.ec2_key_remote_state
  ec2_backet_remote_state     = local.ec2.ec2_backet_remote_state
  ec2_ami_id                  = try(local.ec2.ec2_ami_id, "")
  ec2_default_ami             = try(local.ec2.ec2_default_ami, "")
  ec2_instance_type           = local.ec2.ec2_instance_type
  ec2_hostname                = local.ec2.ec2_hostname
  ec2_key_name                = try(local.ec2.ec2_key_name, "")
  ec2_vpc_security_groups     = local.ec2.ec2_vpc_security_groups
  ec2_subnet_name             = local.ec2.ec2_subnet_name
  ec2_monitoring              = try(local.ec2.ec2_monitoring, false)
  ec2_source_dest_check       = try(local.ec2.ec2_source_dest_check, true)
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = local.ec2_backet_remote_state
    key            = local.ec2_key_remote_state
    region         = local.region
    encrypt        = true
    dynamodb_table = local.ec2_lock_table_remote_state
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  profile = "${local.profile}"
  region  = "${local.region}"
  default_tags {
    tags = jsondecode(<<INNEREOF
${local.common_tags}
INNEREOF
)
  }
}
EOF
}

inputs = {
  net_backet_remote_state = local.net_backet_remote_state
  net_key_remote_state    = local.net_key_remote_state
  net_remote_state_region = local.net_remote_state_region

  env                     = local.env
  ec2_ami_id              = local.ec2_ami_id
  ec2_default_ami         = local.ec2_default_ami
  ec2_instance_type       = local.ec2_instance_type
  ec2_hostname            = local.ec2_hostname
  ec2_key_name            = local.ec2_key_name
  ec2_vpc_security_groups = local.ec2_vpc_security_groups
  ec2_subnet_name         = local.ec2_subnet_name
  ec2_source_dest_check   = local.ec2_source_dest_check
}
