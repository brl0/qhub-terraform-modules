variable "dependencies" {
  description = "A list of module dependencies to be injected in the module"
  type        = list(any)
  default     = []
}

variable "overrides" {
  description = "Overrides for values.yaml in helm configuration"
  type        = list(string)
  default     = []
}
