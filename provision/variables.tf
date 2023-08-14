variable "project" {}

variable "credentials_file" {}

variable "name" {
  default = "terraform"
}

variable "region" {
  default = "europe-west1"
}

variable "zone" {
  default = "europe-west1-b"
}

variable "machine_type" {
  # default = "e2-micro"
  # default = "e2-small"
  default = "e2-medium"
}

variable "image" {
  default = "rocky-linux-9-optimized-gcp-v20230711"
  # https://cloud.google.com/blog/products/application-modernization/introducing-rocky-linux-optimized-for-google-cloud?hl=en
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
