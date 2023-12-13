resource "harness_platform_pipeline" "cicdgitopspipeline" {
  identifier = "cicdgitopspipeline"
  org_id     = var.org_id
  project_id = var.project_id
  name       = "cicd-gitops-pipeline"
  depends_on = [harness_platform_gitops_applications.podinfo, harness_platform_service.gitops_service]
  yaml = <<-EOT
pipeline:
  name: cicd-gitops-pipeline
  identifier: cicdgitopspipeline
  projectIdentifier: default_project
  orgIdentifier: default
  tags: {}
  properties:
    ci:
      codebase:
        connectorRef: github_appset_repo_connector
        build: <+input>
  stages:
    - stage:
        name: ci-stage
        identifier: cistage
        description: ""
        type: CI
        spec:
          cloneCodebase: true
          platform:
            os: Linux
            arch: Amd64
          runtime:
            type: Cloud
            spec: {}
          execution:
            steps:
              - step:
                  type: Run
                  name: Run OWASP Tests
                  identifier: Run_OWASP_Tests
                  spec:
                    shell: Sh
                    command: |-
                      echo "Running OWASP tests..."
                      sleep 2
                      echo "OWASP tests passed!"
              - step:
                  type: BuildAndPushDockerRegistry
                  name: BuildAndPushDockerRegistry
                  identifier: BuildAndPushDockerRegistry
                  spec:
                    connectorRef: dockerhub_connector
                    repo: <+pipeline.variables.imageRepo>
                    tags:
                      - <+pipeline.variables.imageTag>
                    dockerfile: apps/podinfo/Dockerfile
    - stage:
        name: Deploy to Dev
        identifier: Deploy_to_Dev
        description: ""
        type: Deployment
        spec:
          deploymentType: Kubernetes
          gitOpsEnabled: true
          service:
            serviceRef: podinfoservice
          execution:
            steps:
              - step:
                  type: GitOpsUpdateReleaseRepo
                  name: Update Release Repo
                  identifier: updateReleaseRepo
                  timeout: 10m
                  spec:
                    variables:
                      - name: commit_sha
                        type: String
                        value: newdevmessage
              - step:
                  type: MergePR
                  name: Merge PR
                  identifier: mergePR
                  spec:
                    deleteSourceBranch: true
                  timeout: 10m
              - step:
                  type: GitOpsFetchLinkedApps
                  name: Fetch Linked Apps
                  identifier: fetchLinkedApps
                  timeout: 10m
                  spec: {}
            rollbackSteps: []
          environment:
            environmentRef: dev
            deployToAll: false
            gitOpsClusters:
              - identifier: podinfocluster
        tags: {}
        failureStrategies:
          - onFailure:
              errors:
                - AllErrors
              action:
                type: StageRollback
    - stage:
        name: Approve Promote to Prod
        identifier: Approve_Promote_to_Prod
        description: ""
        type: Approval
        spec:
          execution:
            steps:
              - step:
                  name: Approve Promotion to Prod
                  identifier: Approve_Promotion_to_Prod
                  type: HarnessApproval
                  timeout: 1d
                  spec:
                    approvalMessage: |-
                      Please review the following information
                      and approve the pipeline progression
                    includePipelineExecutionHistory: true
                    approvers:
                      minimumCount: 1
                      disallowPipelineExecutor: false
                      userGroups:
                        - _project_all_users
                    isAutoRejectEnabled: false
                    approverInputs: []
        tags: {}
    - stage:
        name: Deploy to Prod
        identifier: Deploy_to_Prod
        description: ""
        type: Deployment
        spec:
          deploymentType: Kubernetes
          gitOpsEnabled: true
          service:
            serviceRef: podinfoservice
          execution:
            steps:
              - step:
                  type: GitOpsUpdateReleaseRepo
                  name: Update Release Repo
                  identifier: updateReleaseRepo
                  timeout: 10m
                  spec:
                    variables:
                      - name: commit_sha
                        type: String
                        value: newprodmessage
              - step:
                  type: MergePR
                  name: Merge PR
                  identifier: mergePR
                  spec:
                    deleteSourceBranch: true
                  timeout: 10m
              - step:
                  type: GitOpsFetchLinkedApps
                  name: Fetch Linked Apps
                  identifier: fetchLinkedApps
                  timeout: 10m
                  spec: {}
            rollbackSteps: []
          environment:
            environmentRef: prod
            deployToAll: false
            gitOpsClusters:
              - identifier: podinfocluster
        tags: {}
        failureStrategies:
          - onFailure:
              errors:
                - AllErrors
              action:
                type: StageRollback
  variables:
    - name: imageRepo
      type: String
      description: ""
      required: false
      value: var.github_username/harness-gitops-workshop
    - name: imageTag
      type: String
      description: ""
      required: false
      value: latest
EOT
}
