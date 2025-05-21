# Replace with your repo (format: owner/repo)
REPO="Quantum-Tunnel-Design/finefinds-devops-cicd"

# Fetch all workflow run IDs
gh run list --repo "$REPO" --limit 1000 --json databaseId --jq '.[].databaseId' | while read run_id; do
  echo "Deleting run ID $run_id"
  echo "y" | gh run delete "$run_id" --repo "$REPO"
done