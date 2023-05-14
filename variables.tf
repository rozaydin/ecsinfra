# variable "public_subnet_cidrs" {
#   type        = list(string)
#   description = "Public Subnet CIDR values"
#   default     = ["10.58.1.0/24", "10.58.2.0/24", "10.58.3.0/24", "10.58.4.0/24"]
# }

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  default     = ["10.58.1.0/24"]
}

variable "public_subnets" {
  description = "Public Subnets"
  default = {
    public-subnet-2a = {
      cidr_block        = "10.58.1.0/24"
      availability_zone = "us-west-2a"
    }
    public-subnet-2b = {
      cidr_block        = "10.58.2.0/24"
      availability_zone = "us-west-2b"
    }
    public-subnet-2c = {
      cidr_block        = "10.58.3.0/24"
      availability_zone = "us-west-2c"
    }
    public-subnet-2d = {
      cidr_block        = "10.58.4.0/24"
      availability_zone = "us-west-2d"
    }
  }
}

# variable "private_subnet_cidrs" {
#   type        = list(string)
#   description = "Private Subnet CIDR values"
#   default     = ["10.58.5.0/24", "10.58.6.0/24", "10.58.7.0/24", "10.58.8.0/24"]
# }

variable "private_subnet_cidrs" {
   type        = list(string)
   description = "Private Subnet CIDR values"
   default     = ["10.58.5.0/24"]
 }

variable "private_subnets" {
  description = "Private Subnets"
  default = {
    private-subnet-2a = {
      cidr_block        = "10.58.5.0/24"
      availability_zone = "us-west-2a"
    }
    private-subnet-2b = {
      cidr_block        = "10.58.6.0/24"
      availability_zone = "us-west-2b"
    }
    private-subnet-2c = {
      cidr_block        = "10.58.7.0/24"
      availability_zone = "us-west-2c"
    }
    private-subnet-2d = {
      cidr_block        = "10.58.8.0/24"
      availability_zone = "us-west-2d"
    }
  }
}

# variable "azs" {
#   type        = list(string)
#   description = "Availability Zones"
#   default     = ["us-west-2a", "us-west-2b", "us-west-2c", "us-west-2d"]
# }

variable "azs" {
  type        = list(string)
  description = "Availability Zones"
  default     = ["us-west-2a"]
}

variable "tags" {
  type = map(string)
  description = "tags"
  default = {
    Terraform   = "true"
    Environment = "dev"
    Project     = "ECS-Test"
  }  
}
