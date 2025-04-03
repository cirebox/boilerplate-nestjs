/**
 * Módulo de Banco de Dados AWS (RDS)
 * 
 * Este módulo cria uma instância de banco de dados RDS com configurações
 * otimizadas para controle de custos.
 */

# Gerar senha aleatória para o banco de dados
resource "random_password" "db_password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Grupo de parâmetros para o RDS
resource "aws_db_parameter_group" "default" {
  name   = "${var.project_name}-${var.environment}-pg"
  family = "${var.engine}${var.engine_version}"

  # Otimizações de performance e custos
  parameter {
    name         = "autovacuum"
    value        = "1"
    apply_method = "immediate"
  }

  parameter {
    name         = "client_encoding"
    value        = "utf8"
    apply_method = "immediate"
  }

  tags = var.tags
}

# Grupo de segurança para o RDS
resource "aws_security_group" "db" {
  name        = "${var.project_name}-${var.environment}-db-sg"
  description = "Security group for ${var.project_name} database in ${var.environment}"
  vpc_id      = var.vpc_id

  # Permitir acesso ao banco somente da VPC
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.selected.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-db-sg"
  })
}

# Obter dados da VPC
data "aws_vpc" "selected" {
  id = var.vpc_id
}

# Subnet group para o RDS
resource "aws_db_subnet_group" "default" {
  name       = "${var.project_name}-${var.environment}-db-subnet"
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-db-subnet"
  })
}

# Instância RDS
resource "aws_db_instance" "default" {
  identifier            = "${var.project_name}-${var.environment}"
  engine                = var.engine
  engine_version        = var.engine_version
  instance_class        = var.instance_type
  db_name               = var.database_name != "" ? var.database_name : "${replace(var.project_name, "-", "_")}_${var.environment}"
  username              = var.database_user != "" ? var.database_user : "app_user"
  password              = random_password.db_password.result
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  # Configurações de backup e manutenção
  backup_retention_period = var.backup_retention_days
  backup_window           = "03:00-04:00"
  maintenance_window      = "mon:04:00-mon:05:00"

  # Configurações de rede
  db_subnet_group_name   = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  multi_az               = var.multi_az

  # Configurações de proteção
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.project_name}-${var.environment}-final-${formatdate("YYYYMMDDhhmmss", timestamp())}"

  # Configurações de performance
  parameter_group_name = aws_db_parameter_group.default.name

  # Configurações de monitoramento
  monitoring_interval = var.environment == "prod" ? 60 : 0
  monitoring_role_arn = var.environment == "prod" ? aws_iam_role.rds_monitoring[0].arn : null

  # Configurações de performance insights
  performance_insights_enabled          = var.environment == "prod"
  performance_insights_retention_period = var.environment == "prod" ? 7 : 0

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-db"
  })

  # Não substituir o banco se apenas a senha mudar
  lifecycle {
    ignore_changes = [password]
  }
}

# Réplica de leitura (opcional para produção)
resource "aws_db_instance" "read_replica" {
  count               = var.enable_replicas ? var.replica_count : 0
  identifier          = "${var.project_name}-${var.environment}-replica-${count.index + 1}"
  replicate_source_db = aws_db_instance.default.id
  instance_class      = var.replica_instance_type != "" ? var.replica_instance_type : var.instance_type

  # Não precisamos definir usuário, senha, etc. porque são herdados da instância principal

  # Configurações de rede
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false

  # Configurações de backup
  backup_retention_period = 0 # Não é necessário fazer backup das réplicas

  # Configurações de proteção
  deletion_protection = var.deletion_protection
  skip_final_snapshot = true # Não é necessário snapshot final das réplicas

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-db-replica-${count.index + 1}"
  })
}

# IAM Role para monitoramento do RDS (para produção)
resource "aws_iam_role" "rds_monitoring" {
  count = var.environment == "prod" ? 1 : 0
  name  = "${var.project_name}-${var.environment}-rds-monitoring"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      },
    ]
  })

  tags = var.tags
}

# Anexar política de monitoramento para o RDS
resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count      = var.environment == "prod" ? 1 : 0
  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# Secret Manager para armazenar credenciais do banco
resource "aws_secretsmanager_secret" "db_credentials" {
  name        = "${var.project_name}/${var.environment}/db"
  description = "Credenciais do banco de dados para ${var.project_name} em ${var.environment}"

  tags = var.tags
}

# Versão do segredo com credenciais
resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id

  secret_string = jsonencode({
    username = aws_db_instance.default.username
    password = random_password.db_password.result
    engine   = var.engine
    host     = aws_db_instance.default.address
    port     = aws_db_instance.default.port
    dbname   = aws_db_instance.default.db_name
  })
}