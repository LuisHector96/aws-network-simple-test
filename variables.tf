variable "sg_ports" {
  type        = list(number)
  description = "list of ingress and egress ports"
  default     = [22, 80, 443, 8080]
}
