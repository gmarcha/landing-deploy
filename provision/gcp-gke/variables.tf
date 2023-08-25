variable "project" {}

variable "credentials_file" {}

variable "name" {
  default = "terraform"
}

variable "service_account" {
  default = "serviceaccount"
}

variable "region" {
  default = "europe-west1"
}

variable "zone" {
  default = "europe-west1-b"
}

variable "zones" {
  default = ["europe-west1-b", "europe-west1-c", "europe-west1-d"]
}

variable "machine_type" {
  # default = "e2-micro"
  # default = "e2-small"
  default = "e2-medium"
}

variable "image_type" {
  default = "COS_CONTAINERD"
}

variable "disk_type" {
  default = "pd-standard"
}

variable "repository_user" {
  default = "gmarcha"
}

variable "repository_password" {
  default = "password"
}

variable "repository_host" {
  default = "github.com"
}

variable "repository_name" {
  default = "gmarcha/landing-deploy"
}
