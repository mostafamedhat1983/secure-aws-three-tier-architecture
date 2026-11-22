resource "random_id" "fernet_key" {
  byte_length = 32
}

resource "random_id" "session_key" {
  byte_length = 32
}

resource "aws_secretsmanager_secret" "this" {
  name                    = var.secret_name
  description             = var.description
  recovery_window_in_days = var.recovery_window_in_days

  tags = {
    Name = var.secret_name
  }
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id = aws_secretsmanager_secret.this.id

  secret_string = jsonencode({
    fernet_key  = "${random_id.fernet_key.b64_url}="
    session_key = random_id.session_key.hex
  })
}
