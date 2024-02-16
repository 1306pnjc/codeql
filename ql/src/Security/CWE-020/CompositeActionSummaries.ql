/**
 * @name Composite Action Summaries
 * @description Actions that pass user-controlled data to their output variables.
 * @kind path-problem
 * @problem.severity warning
 * @security-severity 9.3
 * @precision high
 * @id actions/composite-action-summaries
 * @tags actions
 *       model-generator
 *       external/cwe/cwe-020
 */

import actions
import codeql.actions.TaintTracking
import codeql.actions.dataflow.FlowSources
import codeql.actions.dataflow.ExternalFlow

private module MyConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node source) {
    exists(CompositeActionStmt c | c.getInputsStmt().getInputExpr(_) = source.asExpr())
  }

  predicate isSink(DataFlow::Node sink) {
    exists(CompositeActionStmt c | c.getOutputsStmt().getOutputExpr(_) = sink.asExpr())
  }
}

module MyFlow = TaintTracking::Global<MyConfig>;

import MyFlow::PathGraph

from MyFlow::PathNode source, MyFlow::PathNode sink
where MyFlow::flowPath(source, sink)
select sink.getNode(), source, sink, "Summary"
