variable "AWS_REGION" {
  default = "eu-central-1"
}

variable "MY_IP" {
  default = "87.210.175.220/32"
}

variable "FOUNDRY_SSH_PUBLIC_KEY_PATH" {
  default = "../keys/foundry-ssh.pub"
}

variable "FOUNDRY_SSH_PRIVATE_KEY_PATH" {
  default = "../keys/foundry-ssh"
}

variable "foundryVTT-static-assets-bucket-name" {
  default = "foundryvtt-static-assets-bucket"
}

variable "FOUNDRY_FILENAME" {
  default = "FoundryVTT-9.245.zip"
}

variable "FOUNDRY_PATH" {
  default = "../foundry"
}