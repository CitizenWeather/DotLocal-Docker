# Enable DNS on port 8600 (will be exposed via Traefik? We'll keep internal)
ports {
  dns = 8600
  http = 8500
}

# DNS configuration
dns_config {
  allow_stale = true
  max_stale = "5s"
  enable_truncate = true
}

# ACL disabled for simplicity (enable later with bootstrap token)
acl {
  enabled = false
}

# Enable UI
ui_config {
  enabled = true
}