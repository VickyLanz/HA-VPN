terraform {
  backend "gcs" {
    bucket = "triple-baton-337806"
    prefix = "triple-baton-337806/ha-vpn-state"
    credentials = "sa-key.json"
  }
}