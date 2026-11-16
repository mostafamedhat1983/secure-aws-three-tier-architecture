variable "identifier" {
  description = "Name of the RDS instance"
  type        = string
}

variable "multi_az" {
  description = "whether the DB is multi az or no"
  type        = bool
}

variable "allocated_storage" {
  description = "allocated storage for the database"
  type        = number
}

variable "storage_type" {
  description = "database storage type"
  type        = string
}

variable "db_name" {
  description = "database name"
  type        = string
}

variable "engine" {
  description = "database engine"
  type        = string
}

variable "engine_version" {
  description = "database engine version"
  type        = string
}

variable "instance_class" {
  description = "database instance class"
  type        = string
}

variable "username" {
  description = "database username"
  type        = string
}

variable "backup_retention_period" {
  description = "backup retention period in days"
  type        = number

  validation {
    condition = (
      var.backup_retention_period >= 0 &&
      var.backup_retention_period <= 35
    )
    error_message = "The backup retention period must be between 0 and 35."
  }
}

variable "subnet_group_name" {
  description = "database subnet group name"
  type        = string
}

variable "subnet_ids" {
  description = "database subnet ids"
  type        = set(string)
}

variable "db_parameter_group_name_prefix" {
  description = "parameter group name prefix"
  type        = string
}

variable "db_parameter_group_family" {
  description = "parameter group name family"
  type        = string
}
