terraform {
  source = "github.com/yegorovev/tf_aws_instance.git"
}


locals {
  common      = read_terragrunt_config(find_in_parent_folders("common.hcl")).common
  env         = local.common.env
  profile     = local.common.profile
  region      = local.common.region
  bucket_name = local.common.bucket_name
  lock_table  = local.common.lock_table
  key         = join("/", [local.common.key, "ec2/terraform.tfstate"])
  common_tags = jsonencode(local.common.tags)

  ec2        = read_terragrunt_config(find_in_parent_folders("common.hcl")).es2
  ec2_ami_id = try(local.ec2.ec2_instance_type, "")

  ec2_instance_type          = local.ec2.ec2_instance_type
  ec2_hostname               = local.ec2.ec2_hostname
  ec2_key_name               = try(local.ec2.ec2_key_name, "")
  ec2_vpc_security_group_ids = local.ec2.ec2_vpc_security_group_ids
  ec2_subnet_id              = local.ec2.ec2_subnet_id
  ec2_monitoring             = try(local.ec2.ec2_monitoring, false)
}

remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = local.bucket_name
    key            = local.key
    region         = local.region
    encrypt        = true
    dynamodb_table = local.lock_table
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
  env                        = local.env
  ec2_ami_id                 = local.ec2_ami_id
  ec2_instance_type          = local.ec2_instance_type
  ec2_hostname               = local.ec2_hostname
  ec2_key_name               = local.ec2_ami_id
  ec2_vpc_security_group_ids = local.ec2_vpc_security_group_ids
  ec2_subnet_id              = local.ec2_subnet_id
}