resource "k3d_cluster" "gitops_cluster" {
  name    = "gitopscluster"
  kubeconfig {
    update_default_kubeconfig = true
    switch_current_context    = true
  }
}
