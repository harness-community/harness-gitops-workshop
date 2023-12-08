rm -rf harness-gitops-workshop
git config --global user.email ci-bot@argocd.com && git config --global user.name ci-bot
echo "cloning repo..."
git clone https://oauth2:<+secrets.getValue("gh-pat")>@github.com/dewandemo/pharness-gitops-workshop.git
cd podinfo
echo "checkout source branch"
git checkout master
echo "updating image tag in values file"
sed -i "s,tag:.*,tag:\ <+trigger.commitSha>," charts/podinfo/values.yaml
git add . && git commit -m "update image tag"
git push