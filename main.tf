terraform {
  required_version = ">= 1.5.0"
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.120.0"
    }
  }
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.zone
  token     = var.yc_token
}

data "yandex_lockbox_secret_version" "mysql_pwd" {
  secret_id = var.lockbox_secret_id
}

locals {
  mysql_password = one([
    for e in data.yandex_lockbox_secret_version.mysql_pwd.entries :
    e.text_value if e.key == "mysql_password"
  ])
}

resource "yandex_vpc_network" "main" {
  name = "main-vpc"
}

resource "yandex_vpc_subnet" "subnet_a" {
  name           = "subnet-a"
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = ["10.0.0.0/24"]
}

resource "yandex_vpc_security_group" "web_sg" {
  name       = "web-sg"
  network_id = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_mdb_mysql_cluster" "mysql" {
  name        = "mysql-cluster"
  environment = "PRESTABLE"
  network_id  = yandex_vpc_network.main.id
  version     = "8.0"

  resources {
    resource_preset_id = "c3-c2-m4"
    disk_type_id       = "network-ssd"
    disk_size          = 10
  }

  host {
    zone      = var.zone
    subnet_id = yandex_vpc_subnet.subnet_a.id
  }

  security_group_ids = [yandex_vpc_security_group.web_sg.id]
}

resource "yandex_mdb_mysql_database" "app_db" {
  cluster_id = yandex_mdb_mysql_cluster.mysql.id
  name       = "app_db"
}

resource "yandex_mdb_mysql_user" "app_user" {
  cluster_id = yandex_mdb_mysql_cluster.mysql.id
  name       = "app_user"
  password   = local.mysql_password

  permission {
    database_name = yandex_mdb_mysql_database.app_db.name
    roles         = ["ALL_PRIVILEGES"]
  }
}
