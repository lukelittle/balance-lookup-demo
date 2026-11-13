variable "team_name" {
  description = "Your consultancy's name, lowercase letters/numbers/hyphens (e.g. \"fault-tolerant-five\"). Used to keep resource names unique."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,22}[a-z0-9]$", var.team_name))
    error_message = "team_name must be 3-24 chars of lowercase letters, numbers and hyphens, starting and ending with a letter or number."
  }
}

variable "region" {
  description = "AWS region. AWS Academy Learner Lab supports us-east-1 and us-west-2."
  type        = string
  default     = "us-east-1"
}

variable "use_lab_role" {
  description = "true in AWS Academy (you cannot create IAM roles there, so we reuse the pre-created LabRole). Set false in a normal AWS account."
  type        = bool
  default     = true
}

# --- Failure injection knobs -------------------------------------------------
# These are deliberately Terraform variables so that "breaking production" is a
# reviewed, version-controlled change - just like a real config push gone bad.

variable "failure_rate" {
  description = "Fraction of requests (0.0-1.0) that will throw an error. 0 = healthy."
  type        = number
  default     = 0

  validation {
    condition     = var.failure_rate >= 0 && var.failure_rate <= 1
    error_message = "failure_rate must be between 0 and 1."
  }
}

variable "added_latency_ms" {
  description = "Extra latency injected into every request. Above the Lambda timeout = timeouts."
  type        = number
  default     = 0
}

variable "lambda_timeout_seconds" {
  description = "Lambda timeout. Keep it short: a balance lookup that takes 3s is already broken."
  type        = number
  default     = 3
}

variable "alarm_email" {
  description = "Optional email address to receive alarm notifications (you must confirm the subscription email). Leave empty to skip."
  type        = string
  default     = ""
}
