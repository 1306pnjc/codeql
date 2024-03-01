/**
 * @name Unpinned tag for 3rd party Action in workflow
 * @description Using a tag for a 3rd party Action that is not pinned to a commit can lead to executing an untrusted Action through a supply chain attack.
 * @kind problem
 * @security-severity 5.0
 * @problem.severity warning
 * @precision high
 * @id actions/unpinned-tag
 * @tags security
 *       actions
 *       external/cwe/cwe-829
 */

import actions

bindingset[version]
private predicate isPinnedCommit(string version) { version.regexpMatch("^[A-Fa-f0-9]{40}$") }

bindingset[repo]
private predicate isTrustedOrg(string repo) {
  exists(string org | org in ["actions", "github", "advanced-security"] | repo.matches(org + "/%"))
}

from StepUses uses, string repo, string version, Workflow workflow, string name
where
  uses.getCallee() = repo and
  uses.getEnclosingWorkflow() = workflow and
  (
    workflow.getName() = name
    or
    not exists(workflow.getName()) and workflow.getLocation().getFile().getBaseName() = name
  ) and
  uses.getVersion() = version and
  not isTrustedOrg(repo) and
  not isPinnedCommit(version)
select uses,
  "Unpinned 3rd party Action '" + name + "' step $@ uses '" + repo + "' with ref '" + version +
    "', not a pinned commit hash", uses, uses.toString()
