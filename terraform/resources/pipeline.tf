resource "harness_platform_pipeline" "podinfoprpipeline" {
  identifier = "podinfoprpipeline"
  org_id     = var.org_id
  project_id = var.project_id
  name       = "podinfoprpipeline"
  depends_on = [harness_platform_gitops_applications.podinfo, harness_platform_service.gitops_service]
  yaml = <<-EOT
pipeline:
  name: podinfoprpipeline
  identifier: podinfoprpipeline
  projectIdentifier: default_project
  orgIdentifier: default
  tags: {}
  stages:
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
EOT
}
