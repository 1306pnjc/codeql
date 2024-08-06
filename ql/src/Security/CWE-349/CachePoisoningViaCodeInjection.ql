/**
 * @name Cache Poisoning via low-privileged code injection
 * @description The cache can be poisoned by untrusted code, leading to a cache poisoning attack.
 * @kind path-problem
 * @problem.severity error
 * @precision high
 * @security-severity 7.5
 * @id actions/cache-poisoning/code-injection
 * @tags actions
 *       security
 *       external/cwe/cwe-349
 *       external/cwe/cwe-094
 */

import actions
import codeql.actions.security.CodeInjectionQuery
import codeql.actions.security.CachePoisoningQuery
import CodeInjectionFlow::PathGraph
import codeql.actions.security.ControlChecks

from CodeInjectionFlow::PathNode source, CodeInjectionFlow::PathNode sink, LocalJob j, Event e
where
  CodeInjectionFlow::flowPath(source, sink) and
  j = sink.getNode().asExpr().getEnclosingJob() and
  j.getATriggerEvent() = e and
  // job can be triggered by an external user
  e.isExternallyTriggerable() and
  // the checkout is not controlled by an access check
  not exists(ControlCheck check | check.protects(source.getNode().asExpr(), j.getATriggerEvent())) and
  // excluding privileged workflows since they can be exploited in easier circumstances
  not j.isPrivileged() and
  (
    // the workflow runs in the context of the default branch
    runsOnDefaultBranch(e)
    or
    // the workflow caller runs in the context of the default branch
    e.getName() = "workflow_call" and
    exists(ExternalJob caller |
      caller.getCallee() = j.getLocation().getFile().getRelativePath() and
      runsOnDefaultBranch(caller.getATriggerEvent())
    )
  )
select sink.getNode(), source, sink,
  "Unprivileged code injection in $@, which may lead to cache poisoning.", sink,
  sink.getNode().asExpr().(Expression).getRawExpression()
