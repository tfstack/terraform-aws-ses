terraform {
  required_version = ">= 1.5.0"

  required_providers {
    random = {
      source = "hashicorp/random"
    }
  }
}

resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

output "suffix" {
  value = random_string.suffix.result
}
