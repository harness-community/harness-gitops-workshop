resource "harness_platform_gitops_repository" "gitops_repo" {
  identifier = var.repo_identifier
  account_id = var.account_id
  project_id = var.project_id
  org_id     = var.org_id
  agent_id   = var.agent_identifier
  repo {
    repo            = var.repo_url
    name            = var.repo_name
    insecure        = true
    connection_type = "HTTPS_ANONYMOUS"
  }
  upsert = true
  gen_type = "UNSET"
  depends_on = [null_resource.deploy_agent_resources_to_cluster]
}

resource "harness_platform_gitops_cluster" "gitops_cluster" {
  identifier = var.cluster_identifier
  account_id = var.account_id
  project_id = var.project_id
  org_id     = var.org_id
  agent_id   = var.agent_identifier

  request {
    upsert = false
    cluster {
      server = "https://kubernetes.default.svc"
      name   = var.cluster_name
      config {
        tls_client_config {
          insecure = true
        }
        cluster_connection_type = "IN_CLUSTER"
      }

    }
  }
  depends_on = [harness_platform_gitops_repository.gitops_repo]
}

resource "harness_platform_service" "gitops_service" {
  identifier  = var.service_name
  name        = var.service_name
  description = var.service_name
  org_id      = var.org_id
  project_id  = var.project_id
  yaml = <<-EOT
         service:
           name: podinfoservice
           identifier: podinfoservice
           orgIdentifier: default
           projectIdentifier: default_project
           serviceDefinition:
             spec:
               manifests:
                 - manifest:
                     identifier: configjson
                     type: ReleaseRepo
                     spec:
                       store:
                         type: Github
                         spec:
                           connectorRef: account.github_appset_repo_connector
                           gitFetchType: Branch
                           paths:
                             - examples/git-generator-files-discovery/cluster-config/engineering/<+env.name>/config.json
                           branch: master
                 - manifest:
                     identifier: podinfodeployment
                     type: DeploymentRepo
                     spec:
                       store:
                         type: Github
                         spec:
                           connectorRef: account.github_appset_repo_connector
                           gitFetchType: Branch
                           paths:
                             - examples/git-generator-files-discovery/apps/podinfo/deployment.yaml
                           branch: master
             type: Kubernetes
           gitOpsEnabled: true
         EOT
  depends_on = [harness_platform_connector_github.github_appset_repo_connector, harness_platform_gitops_cluster.gitops_cluster]
}

resource "harness_platform_environment" "gitops_dev_env" {
  identifier = "dev"
  name       = "dev"
  org_id     = var.org_id
  project_id = var.project_id
  type       = "PreProduction"
  yaml = <<-EOT
         environment:
           name: "dev"
           identifier: "dev"
           description: ""
           tags: {}
           type: PreProduction
           orgIdentifier: default
           projectIdentifier: default_project
           variables: []
       EOT
  depends_on = [harness_platform_gitops_cluster.gitops_cluster]
}

resource "harness_platform_environment_clusters_mapping" "dev_env_cluster_mapping" {
  identifier = var.cluster_identifier
  env_id     = "dev"
  org_id     = var.org_id
  project_id = var.project_id
  clusters {
    identifier = var.cluster_identifier
    name = var.cluster_identifier
  }
  depends_on = [harness_platform_environment.gitops_dev_env]
}

resource "harness_platform_environment" "gitops_prod_env" {
  identifier = "prod"
  name       = "prod"
  org_id     = var.org_id
  project_id = var.project_id
  type       = "Production"
  yaml = <<-EOT
         environment:
           name: "prod"
           identifier: "prod"
           description: ""
           tags: {}
           type: Production
           orgIdentifier: default
           projectIdentifier: default_project
           variables: []
       EOT
  depends_on = [harness_platform_gitops_cluster.gitops_cluster]
}

resource "harness_platform_environment_clusters_mapping" "dev_prod_cluster_mapping" {
  identifier = var.cluster_identifier
  env_id     = "prod"
  org_id     = var.org_id
  project_id = var.project_id
  clusters {
    identifier = var.cluster_identifier
    name = var.cluster_identifier
  }
  depends_on = [harness_platform_environment.gitops_prod_env]
}

resource "harness_platform_secret_text" "github_pat" {
  identifier  = "github_pat"
  name        = "github_pat"
  description = ""
  tags        = [] 
  secret_manager_identifier = "harnessSecretManager"
  value_type                = "Inline"
  value                     = var.github_pat
}

resource "harness_platform_secret_text" "dockerhub_pat" {
  identifier = "dockerhub_pat"
  name = "dockerhub_pat"
  description = ""
  tags = []
  secret_manager_identifier = "harnessSecretManager"
  value_type                = "Inline"
  value                     = var.dockerhub_pat
}

resource "harness_platform_connector_github" "github_appset_repo_connector" {
  identifier  = "github_appset_repo_connector"
  name        = "github_appset_repo_connector"
  description = ""
  tags        = []

  url                = var.repo_url
  connection_type    = "Repo"
  credentials {
    http {
      username  = var.github_username
      token_ref = "account.github_pat"
    }
  }
  api_authentication {
    token_ref = "account.github_pat"
  }
  execute_on_delegate = false
  depends_on = [harness_platform_secret_text.github_pat]
}

resource "harness_platform_connector_docker" "dockerhub_connector" {
  identifier  = "dockerhub_connector"
  name        = "dockerhub_connector"
  description = ""
  tags        = [""]

  type               = "DockerHub"
  url                = "https://hub.docker.com"
  execute_on_delegate = false
  credentials {
    username     = var.dockerhub_username
    password_ref = "account.dockerhub_pat"
  }
  depends_on = [harness_platform_secret_text.dockerhub_pat]
}

resource "helm_release" "podinfodelegate" {
  name       = "podinfodelegate"
  repository = "https://app.harness.io/storage/harness-download/delegate-helm-chart/"
  chart      = "harness-delegate-ng"
  values = [
    "${file("values.yaml")}"
  ] 
  set {
    name  = "delegateName"
    value = "podinfodelegate"
    type  = "string"
  }
  set {
    name = "accountId"
    value = var.account_id
    type = "string"
  }
  set {
    name = "delegateToken"
    value = var.delegate_token
    type = "string"
  }
  set {
    name = "managerEndpoint"
    value = "https://app.harness.io/gratis"
    type = "string"
  }
  set {
    name = "delegateDockerImage"
    value = "harness/delegate:23.11.81601"
    type = "string"
  }
  set {
    name = "replicas"
    value = 1
  }
  set {
    name = "upgrader.enabled"
    value = true
  }
}
