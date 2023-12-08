cd podinfo
echo "checkout source branch"
git checkout master
echo "updating image tag in values file"
sed -i "s,tag:.*,tag:\ <+trigger.commitSha>," charts/podinfo/values.yaml
git add . && git commit -m "update image tag"
git push

export IMAGE_TAG=dewandemo/podinfo/cc41f26197249153820b3971fbb5f21f6d3e3c3b
rm -rf harness-gitops-workshop
git config --global user.email ci-bot@argocd.com && git config --global user.name ci-bot
echo "cloning repo..."
git clone https://oauth2:<+secrets.getValue("gh-pat")>@github.com/dewan-ahmed/harness-gitops-workshop.git
cd harness-gitops-workshop
FILE_PATH="configs/git-generator-files-discovery/apps/podinfo/deployment.yaml"

# Detect OS and set the sed in-place edit command accordingly
if [[ "$OSTYPE" == "darwin"* ]]; then
    SED_COMMAND="sed -i ''"
else
    SED_COMMAND="sed -i"
fi

echo "Updating image tag in deployment YAML"
$SED_COMMAND "s|image: .*|image: $IMAGE_TAG|g" "$FILE_PATH"