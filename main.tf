provider "aws" {
  region  = "eu-central-1"
  profile = "rozaydin"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "test-ecs-vpc"
  cidr = "10.58.0.0/16"

  azs             = ["eu-central-1a"]  
  public_subnets  = ["10.58.1.0/24"]

  enable_nat_gateway  = false  
  tags = var.tags
}

# ECS Cluster Definition


## Security Group for ECS Cluster

resource "aws_security_group" "allow_http" {
  
  name = "allow_http"
  depends_on = [ module.vpc ]
  description = "Allow HTTP inbound traffic"
  vpc_id = module.vpc.vpc_id

   ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]    
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

}


resource "aws_ecs_cluster" "foo" {
  name = "foo"  
}

resource "aws_ecs_cluster_capacity_providers" "foo_capacity_providers" {
  cluster_name = aws_ecs_cluster.foo.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

resource "aws_ecs_service" "foo_service" {

  depends_on = [
    aws_ecs_task_definition.foo_task_definition
  ]

  name            = "foo"
  cluster         = aws_ecs_cluster.foo.id
  task_definition = aws_ecs_task_definition.foo_task_definition.arn
  desired_count   = 1  

  launch_type = "FARGATE"

  network_configuration {
    subnets = module.vpc.public_subnets
    security_groups = [aws_security_group.allow_http.id]
    assign_public_ip = true
  }
  
}

resource "aws_ecs_task_definition" "foo_task_definition" {
  family = "foo_service"
  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = "nginx:bullseye"
      cpu       = 1024
      memory    = 2048
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    },    
  ])

  # task_role_arn = ""
  # execution_role_arn = ""  

  requires_compatibilities = [ "FARGATE" ]
  cpu = "1024"
  memory = "2GB"
  network_mode = "awsvpc"
  runtime_platform {
    cpu_architecture = "ARM64"
    operating_system_family = "LINUX"
  }  
}