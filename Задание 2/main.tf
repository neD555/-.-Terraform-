terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.130"
    }
  }
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = "ru-central1-a"
}

resource "yandex_vpc_network" "net" {
  name = "docker-net"
}

resource "yandex_vpc_subnet" "subnet" {
  name           = "docker-subnet"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["10.0.0.0/24"]
}

resource "yandex_compute_instance" "vm" {
  name = "docker-vm"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd8k4kq7v0d9p5h7q2k9"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat       = true
  }

  metadata = {
    user-data = file("${path.module}/user-data.yaml")
  }
}
