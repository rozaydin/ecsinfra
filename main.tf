provider "aws" {
  region  = "eu-central-1"
  profile = "rozaydin"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "apollo"
  cidr = "10.58.0.0/16"

  azs             = ["eu-central-1a", "eu-central-1b"]  
  public_subnets  = ["10.58.1.0/24", "10.58.2.0/24"]
  private_subnets = ["10.58.3.0/24", "10.58.4.0/24"]

  enable_nat_gateway  = true
  tags = var.tags
}

# ECS Cluster Definition

## Security Group for ECS Cluster

resource "aws_security_group" "allow_https" {
  
  name = "allow_https"
  depends_on = [ module.vpc ]
  description = "Allow HTTPS inbound traffic"
  vpc_id = module.vpc.vpc_id

   ingress {
    description      = "HTTP from anywhere"
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

resource "aws_security_group" "ecs_tasks" {
  name        = "ecs-tasks-sg"
  description = "allow inbound access from the ALB only"
  vpc_id = module.vpc.vpc_id

  ingress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80    
    security_groups = [aws_security_group.allow_https.id]
    # cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# data "aws_iam_role" "ecs_service_role" {
#   name = "AWSServiceRoleForECS"
# }

# resource "aws_lb_target_group" "ecs_foo_tg" {
#   name        = "ecs-foo-tg"
#   port        = 80
#   protocol    = "HTTP"
#   target_type = "ip"
#   vpc_id      = module.vpc.vpc_id
# }


output "vpc_public_subnets" {
  value = module.vpc.public_subnets
}

resource "aws_lb" "ecs_lb" {
  name               = "alb"
  subnets            = module.vpc.public_subnets
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_https.id]

  tags = var.tags
}

resource "aws_lb_listener" "http_forward" {
  load_balancer_arn = aws_lb.ecs_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_alb_tg.arn
  }
}

# resource "aws_acm_certificate" "example" { }

# resource "aws_lb_listener_certificate" "" {
#   listener_arn    = aws_lb_listener.https_forward.arn
#   certificate_arn = aws_acm_certificate.apollodev.arn
# }

resource "aws_lb_target_group" "ecs_alb_tg" {
  name        = "ecs-alb-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  # health_check {
  #   healthy_threshold   = "3"
  #   interval            = "90"
  #   protocol            = "HTTP"
  #   matcher             = "200-299"
  #   timeout             = "20"
  #   path                = "/"
  #   unhealthy_threshold = "2"
  # }
}

resource "aws_ecs_cluster" "apollo_ecs_cluster" {
  name = "apollo-backend"  
}

resource "aws_ecs_cluster_capacity_providers" "foo_capacity_providers" {
  cluster_name = aws_ecs_cluster.apollo_ecs_cluster.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

resource "aws_ecs_service" "apollo_backend_ecs_service" {

  depends_on = [
    aws_ecs_task_definition.apollo_backend_task_definition,
    aws_lb_target_group.ecs_alb_tg
  ]

  name            = "apollo-backend-ecs-service"
  cluster         = aws_ecs_cluster.apollo_ecs_cluster.id
  task_definition = aws_ecs_task_definition.apollo_backend_task_definition.arn
  desired_count   = 1  
  # iam_role        = data.aws_iam_role.ecs_service_role.arn

  launch_type = "FARGATE"

  network_configuration {
    subnets = module.vpc.private_subnets
    security_groups = [aws_security_group.ecs_tasks.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_alb_tg.arn
    container_name   = "nginx"
    container_port   = 80
  }
  
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  ]
  tags = var.tags
}

resource "aws_ecs_task_definition" "apollo_backend_task_definition" {
  family = "apollo_backend_service"
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
      logConfiguration = {
        logDriver: "awslogs",
        options: {
          awslogs-group: "filestorage",
          awslogs-region: "eu-central-1",
          awslogs-create-group: "true",
          awslogs-stream-prefix: "filestorage"
        }
      }
    },    
  ])

  # task_role_arn = "arn:aws:iam::221148627084:role/ecsTaskFullAccess"
  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn

  requires_compatibilities = [ "FARGATE" ]
  cpu = "1024"
  memory = "2GB"
  network_mode = "awsvpc"
  runtime_platform {
    cpu_architecture = "ARM64"
    operating_system_family = "LINUX"
  }  
}