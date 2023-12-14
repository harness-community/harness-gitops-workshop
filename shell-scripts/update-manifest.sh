export IMAGE_TAG="<+pipeline.variables.imageRepo>:<+pipeline.variables.imageTag>"
rm -rf harness-gitops-workshop
git config --global user.email ci-bot@argocd.com && git config --global user.name ci-bot
echo "cloning repo..."
GITHUBPAT=<+secrets.getValue("github_pat")>
git clone https://oauth2:$GITHUBPAT@github.com/GITHUB_USERNAME/harness-gitops-workshop.git
cd harness-gitops-workshop
ls
FILE_PATH="configs/git-generator-files-discovery/apps/podinfo/deployment.yaml"

# Detect OS and set the sed in-place edit command accordingly
if [[ "$OSTYPE" == "darwin"* ]]; then
    SED_COMMAND="sed -i ''"
else
    SED_COMMAND="sed -i"
fi

echo "Updating image tag in deployment YAML"
$SED_COMMAND "s|image: .*|image: $IMAGE_TAG|g" "$FILE_PATH"

echo "Committing and pushing"
git add .
git commit -m "Update latest deployment artifact"
git push
