/**
 * # AWS Load Balancing Module
 *
 * Este módulo cria um Application Load Balancer (ALB) na AWS com suporte a:
 * - Tráfego HTTP/HTTPS
 * - Health checks personalizáveis
 * - Distribuição de tráfego entre múltiplos serviços
 * - Configurações de segurança adequadas
 * - Logs de acesso
 */

# Security Group para o Load Balancer
resource "aws_security_group" "alb" {
  name        = "${var.name_prefix}-alb-sg"
  description = "Security Group para o Application Load Balancer"
  vpc_id      = var.vpc_id

  # Regra de entrada para HTTP
  dynamic "ingress" {
    for_each = var.enable_http ? [1] : []
    content {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidr_blocks
      description = "Acesso HTTP"
    }
  }

  # Regra de entrada para HTTPS
  dynamic "ingress" {
    for_each = var.enable_https ? [1] : []
    content {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidr_blocks
      description = "Acesso HTTPS"
    }
  }

  # Regra de saída para todo o tráfego
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Permite todo o tráfego de saída"
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-alb-sg"
    }
  )
}

# S3 Bucket para logs do ALB (opcional)
resource "aws_s3_bucket" "alb_logs" {
  count  = var.enable_access_logs ? 1 : 0
  bucket = "${var.name_prefix}-alb-logs-${random_string.suffix[0].result}"

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-alb-logs"
    }
  )
}

resource "random_string" "suffix" {
  count   = var.enable_access_logs ? 1 : 0
  length  = 8
  special = false
  upper   = false
}

resource "aws_s3_bucket_policy" "alb_logs" {
  count  = var.enable_access_logs ? 1 : 0
  bucket = aws_s3_bucket.alb_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_elb_service_account.main.id}:root"
        }
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.alb_logs[0].arn}/*"
      }
    ]
  })
}

# Obter a conta de serviço ELB para permissões do bucket de logs
data "aws_elb_service_account" "main" {}

# Application Load Balancer
resource "aws_lb" "main" {
  name               = "${var.name_prefix}-alb"
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = var.subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
  idle_timeout               = var.idle_timeout

  dynamic "access_logs" {
    for_each = var.enable_access_logs ? [1] : []
    content {
      bucket  = aws_s3_bucket.alb_logs[0].bucket
      prefix  = var.access_logs_prefix
      enabled = true
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-alb"
    }
  )
}

# Target Group para o ALB
resource "aws_lb_target_group" "main" {
  count       = length(var.target_groups)
  name        = "${var.name_prefix}-tg-${var.target_groups[count.index].name}"
  port        = var.target_groups[count.index].port
  protocol    = var.target_groups[count.index].protocol
  target_type = var.target_groups[count.index].target_type
  vpc_id      = var.vpc_id

  health_check {
    enabled             = true
    interval            = var.target_groups[count.index].health_check.interval
    path                = var.target_groups[count.index].health_check.path
    port                = var.target_groups[count.index].health_check.port
    protocol            = var.target_groups[count.index].health_check.protocol
    timeout             = var.target_groups[count.index].health_check.timeout
    healthy_threshold   = var.target_groups[count.index].health_check.healthy_threshold
    unhealthy_threshold = var.target_groups[count.index].health_check.unhealthy_threshold
    matcher             = var.target_groups[count.index].health_check.matcher
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.name_prefix}-tg-${var.target_groups[count.index].name}"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# HTTP Listener
resource "aws_lb_listener" "http" {
  count             = var.enable_http ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  # Redirecionar para HTTPS se ambos estiverem habilitados
  dynamic "default_action" {
    for_each = var.enable_https && var.redirect_http_to_https ? [1] : []
    content {
      type = "redirect"

      redirect {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  # Encaminhar para o target group padrão se não houver redirecionamento
  dynamic "default_action" {
    for_each = !(var.enable_https && var.redirect_http_to_https) ? [1] : []
    content {
      type             = "forward"
      target_group_arn = aws_lb_target_group.main[0].arn
    }
  }
}

# HTTPS Listener
resource "aws_lb_listener" "https" {
  count             = var.enable_https ? 1 : 0
  load_balancer_arn = aws_lb.main.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main[0].arn
  }
}

# Regras de roteamento adicionais (se path_patterns for fornecido)
resource "aws_lb_listener_rule" "path_based" {
  count        = var.enable_https && length(var.path_based_routing) > 0 ? length(var.path_based_routing) : 0
  listener_arn = aws_lb_listener.https[0].arn
  priority     = 100 + count.index

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main[var.path_based_routing[count.index].target_group_index].arn
  }

  condition {
    path_pattern {
      values = var.path_based_routing[count.index].path_patterns
    }
  }
}

# Regras adicionais para o listener HTTP (se HTTP estiver habilitado sem redirecionamento)
resource "aws_lb_listener_rule" "http_path_based" {
  count        = var.enable_http && !(var.enable_https && var.redirect_http_to_https) && length(var.path_based_routing) > 0 ? length(var.path_based_routing) : 0
  listener_arn = aws_lb_listener.http[0].arn
  priority     = 100 + count.index

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main[var.path_based_routing[count.index].target_group_index].arn
  }

  condition {
    path_pattern {
      values = var.path_based_routing[count.index].path_patterns
    }
  }
}

