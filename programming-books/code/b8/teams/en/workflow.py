import yaml

# The workflow parses, and its steps are what the chapter says they are.
flow = yaml.safe_load(open(".github/workflows/claude-review.yml"))
job = flow["jobs"]["review"]
print("on:", list(flow[True]), "| permissions:", flow["permissions"], "| timeout:", job["timeout-minutes"])
for step in job["steps"]:
    print(" -", step.get("uses") or step.get("run"), "(secret)" if "env" in step else "")
