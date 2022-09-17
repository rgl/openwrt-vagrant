variable "disk_size" {
  type        = number
  default     = 1*1024
  description = "disk size in GiB"
}

variable "img_url" {
  type = string
}

variable "img_checksum" {
  type = string
}

variable "vagrant_box" {
  type = string
}

source "qemu" "openwrt-amd64" {
  accelerator  = "kvm"
  machine_type = "q35"
  boot_wait    = "30s"
  boot_command = [
    "<enter>",
    "uci delete network.lan<enter>",
    "uci set network.mgt=interface<enter>",
    "uci set network.mgt.ifname=eth0<enter>",
    "uci set network.mgt.proto=dhcp<enter>",
    "uci commit<enter>",
    "/etc/init.d/network restart<enter><wait3s>",
    "ip addr<enter>",
    "printf 'vagrant\\nvagrant\\n' | passwd<enter>",
    "exit<enter>",
  ]
  disk_cache     = "unsafe"
  disk_discard   = "unmap"
  disk_interface = "virtio-scsi"
  disk_size      = var.disk_size
  format         = "qcow2"
  headless       = true
  net_device     = "virtio-net"
  disk_image     = true
  iso_checksum   = var.img_checksum
  iso_url        = var.img_url
  cpus           = 2
  memory         = 2048
  qemuargs = [
    ["-cpu", "host"],
  ]
  ssh_username     = "root"
  ssh_password     = "vagrant"
  ssh_timeout      = "60m"
  shutdown_command = "poweroff"
}

build {
  sources = [
    "source.qemu.openwrt-amd64",
  ]

  provisioner "shell" {
    scripts = [
      "provision.sh",
    ]
  }

  post-processor "vagrant" {
    output               = var.vagrant_box
    vagrantfile_template = "Vagrantfile.template"
  }
}
