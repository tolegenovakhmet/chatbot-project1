provider "yandex" {
  token     = var.yc_token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = "ru-central1-a"
}

# VPC
resource "yandex_vpc_network" "vpc" {
  name = "chatbot-vpc"
}

resource "yandex_vpc_subnet" "subnet" {
  name           = "chatbot-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.vpc.id
  v4_cidr_blocks = ["10.0.0.0/24"]
}

# Lockbox Secret
resource "yandex_lockbox_secret" "gpt_key" {
  name = "yandex-gpt-key"
  payload_entry {
    key   = "API_KEY"
    value = var.gpt_api_key
  }
}

# PostgreSQL
resource "yandex_mdb_postgresql_cluster" "db" {
  name        = "chatbot-db"
  environment = "development"
  network_id  = yandex_vpc_network.vpc.id

  user {
    name     = "botuser"
    password = var.db_password
  }

  host {
    zone        = "ru-central1-a"
    subnet_id   = yandex_vpc_subnet.subnet.id
    assign_public_ip = true
  }

  database {
    name = "chatbot"
  }
}

# Cloud Function
resource "yandex_function_function" "chatbot" {
  name        = "chatbot-function"
  description = "AI Chatbot Function"
  runtime     = "python39"
  entrypoint  = "handler.handler"
  memory      = 128

  environment {
    variables = {
      GPT_KEY    = yandex_lockbox_secret.gpt_key.payload_entry[0].value
      DB_HOST    = yandex_mdb_postgresql_cluster.db.host[0].fqdn
      DB_USER    = "botuser"
      DB_PASS    = var.db_password
      DB_NAME    = "chatbot"
    }
  }

  folder_id = var.folder_id
}

# API Gateway
resource "yandex_apigateway_api" "api" {
  name      = "chatbot-api"
  folder_id = var.folder_id
}

resource "yandex_apigateway_api_gateway" "gateway" {
  name   = "chatbot-gateway"
  api_id = yandex_apigateway_api.api.id
}

