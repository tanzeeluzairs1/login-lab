variable "admin_cidr" {
  description = "Your public IPv4 address with a /32 suffix"
  type        = string

  validation {
    condition = (
      can(cidrnetmask(var.admin_cidr)) &&
      endswith(var.admin_cidr, "/32")
    )
    error_message = "Enter one IPv4 address followed by /32."
  }
}