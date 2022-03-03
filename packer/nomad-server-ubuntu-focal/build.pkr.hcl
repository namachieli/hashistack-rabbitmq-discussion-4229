# ------------------------------------------------------------------------------------------------
# Packer
# https://www.packer.io/docs/templates/hcl_templates/blocks/packer
# ------------------------------------------------------------------------------------------------

packer {
  required_plugins {
    amazon = {
      version = ">= 0.0.2"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

# ------------------------------------------------------------------------------------------------
# Source
# https://www.packer.io/docs/templates/hcl_templates/blocks/source
# ------------------------------------------------------------------------------------------------

# https://www.packer.io/docs/builders/amazon/ebs
source "amazon-ebs" "nomad-server" {
  skip_create_ami         = var.skip_create_ami         # Can take 5-15minutes to package the AMI, waste of time when testing
  shared_credentials_file = var.shared_credentials_file # https://www.packer.io/docs/builders/amazon#shared-credentials-file
  profile                 = var.shared_credentials_profile
  region                  = var.region
  vpc_id                  = var.vpc_id
  ssh_username            = "ubuntu" # https://www.packer.io/docs/communicators/ssh
  ssh_timeout             = "5m"     # Time to wait for SSH to become available
  security_group_ids      = [var.ec2_sg_id]

  # https://www.packer.io/docs/builders/amazon/ebs#subnet_filter
  subnet_filter {
    filters = {
      "tag:Environment" : "test"
    }
    most_free = true
    random    = true
  }
  ami_name      = "${var.ami_prefix}-${local.timestamp}"
  instance_type = var.instance_type

  # https://www.packer.io/docs/datasources/amazon/ami
  source_ami_filter {
    most_recent = true
    owners      = ["099720109477"] # Ubuntu Official Account
    filters = {
      name                = "ubuntu/images/*ubuntu-focal-20.04-amd64-server-*" # ami-0892d3c7ee96c0bf7
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
  }

  # Added to the instance used to create the AMI. The resulting AMI will also inherit these tags.
  # https://www.packer.io/docs/builders/amazon/ebs#run_tags
  run_tags = {
    consul_server = true # Used by ../scripts/nomad_self_provision.sh
  }

  # Added to the temporary volumes used to create AMI
  # https://www.packer.io/docs/builders/amazon/ebs#run_volume_tags
  # run_volume_tags = {}

  # Added to the final AMI when created
  # https://www.packer.io/docs/builders/amazon/ebs#tags
  tags = {
    "Name"          = var.ami_prefix
    "OS_Version"    = "Ubuntu"
    "Base_AMI_Name" = "{{ .SourceAMIName }}"
    "Extra"         = "{{ .SourceAMITags.TagName }}"
  }
}

# ------------------------------------------------------------------------------------------------
# Build
# https://www.packer.io/docs/templates/hcl_templates/blocks/build
# ------------------------------------------------------------------------------------------------

build {
  name = "nomad-server"
  sources = [
    "source.amazon-ebs.nomad-server"
  ]

  # https://www.packer.io/docs/provisioners/shell
  provisioner "shell" {
    inline = [
      "sudo mkdir -p /opt/provisioning",
      "sudo chmod 777 /opt/provisioning" # Yes, 777. This is basically a persistent /tmp
    ]
  }

  # https://www.packer.io/docs/templates/hcl_templates/blocks/build/provisioner
  # https://www.packer.io/docs/provisioners/file
  # https://www.packer.io/docs/provisioners/file#uploading-files-that-don-t-exist-before-packer-starts
  provisioner "file" {
    source      = "../scripts/"
    destination = "/opt/provisioning/"
  }

  # https://www.packer.io/docs/provisioners/shell
  provisioner "shell" {
    inline = [
      "/bin/bash /opt/provisioning/nomad_ami_install.sh -e '${var.gossip_key}'"
    ]
  }
}
