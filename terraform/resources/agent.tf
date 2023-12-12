resource "harness_platform_gitops_agent" "gitops_agent" {
  identifier = var.agent_identifier
  account_id = var.account_id
  project_id = var.project_id
  org_id     = var.org_id
  name       = var.agent_name
  type       = "MANAGED_ARGO_PROVIDER"
  metadata {
    namespace         = var.agent_namespace
    high_availability = false
  }
}

data "harness_platform_gitops_agent_deploy_yaml" "gitops_agent_yaml" {
  identifier = "${harness_platform_gitops_agent.gitops_agent.identifier}"
  account_id = var.account_id
  project_id = var.project_id
  org_id     = var.org_id
  namespace  = var.agent_namespace
}

resource "local_file" "gitops_agent_yaml_file" {
  filename = "gitops_agent.yaml"
  content  = jsondecode(data.harness_platform_gitops_agent_deploy_yaml.gitops_agent_yaml.yaml)["value"]
  depends_on = [harness_platform_gitops_agent.gitops_agent]
}

resource "null_resource" "deploy_agent_resources_to_cluster" {
  triggers = {
    content = local_file.gitops_agent_yaml_file.content
  }
  provisioner "local-exec" {
    when = create
    command = "kubectl apply -f gitops_agent.yaml; sleep 60"
  }
  depends_on = [local_file.gitops_agent_yaml_file]
}

resource "null_resource" "remove_agent_resources_from_cluster" {
  provisioner "local-exec" {
    when = destroy
    command = "kubectl delete -f gitops_agent.yaml"
  }
  depends_on = [local_file.gitops_agent_yaml_file]
}
