variable "region" {
  type    = string
  default = "us-east-1"
}

variable "cluster_name" {
  type    = string
  default = "cost-per-commit"
}

variable "kubernetes_version" {
  type        = string
  default     = "1.31"
  description = "Check which EKS versions are currently supported and bump this."
}

variable "budget_usd" {
  type        = number
  default     = 60
  description = "Monthly AWS budget alert threshold for the lab account."
}

variable "budget_email" {
  type        = string
  default     = ""
  description = "Email for budget alerts. Leave empty to skip creating the budget."
}
