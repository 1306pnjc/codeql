/**
 * @name Enviroment Variable built from user-controlled sources
 * @description Building an environment variable from user-controlled sources may alter the execution of following system commands
 * @kind path-problem
 * @problem.severity error
 * @security-severity 9
 * @precision very-high
 * @id actions/envvar-injection/critical
 * @tags actions
 *       security
 *       external/cwe/cwe-077
 *       external/cwe/cwe-020
 */

import actions
import codeql.actions.security.EnvVarInjectionQuery
import EnvVarInjectionFlow::PathGraph

from EnvVarInjectionFlow::PathNode source, EnvVarInjectionFlow::PathNode sink
where
  EnvVarInjectionFlow::flowPath(source, sink) and
  inPrivilegedContext(sink.getNode().asExpr()) and
  // exclude paths to file read sinks from non-artifact sources
  (
    not source.getNode().(RemoteFlowSource).getSourceType() = "artifact"
    or
    source.getNode().(RemoteFlowSource).getSourceType() = "artifact" and
    sink.getNode() instanceof EnvVarInjectionFromFileReadSink
  )
select sink.getNode(), source, sink,
  "Potential environment variable injection in $@, which may be controlled by an external user.",
  sink, sink.getNode().toString()
