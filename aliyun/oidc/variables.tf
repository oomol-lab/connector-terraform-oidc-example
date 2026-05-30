variable "alicloud_region" {
  description = "Alibaba Cloud region used by the provider."
  type        = string
  default     = "cn-hangzhou"
}

variable "alicloud_profile" {
  description = "Optional local Alibaba Cloud CLI profile."
  type        = string
  default     = null
}
