resource "kubernetes_namespace" "dev" {
  metadata {
    annotations = {
      name = "dev"
    }
    name = "dev"
  }
}

resource "kubernetes_namespace" "prod" {
  metadata {
    annotations = {
      name = "prod"
    }
    name = "prod"
  }
}
