import codeql.actions.ast.internal.Actions
import codeql.actions.Ast
import codeql.actions.Cfg as Cfg
import codeql.actions.DataFlow
import codeql.Locations
import codeql.actions.dataflow.ExternalFlow

query predicate files(File f) { any() }

query predicate yamlNodes(YamlNode n) { any() }

query predicate jobNodes(JobStmt s) { any() }

query predicate stepNodes(StepStmt s) { any() }

query predicate allUsesNodes(UsesExpr s) { any() }

query predicate stepUsesNodes(StepUsesExpr s) { any() }

query predicate jobUsesNodes(JobUsesExpr s) { any() }

query predicate usesSteps(UsesExpr call, string argname, Expression arg) {
  call.getArgumentExpr(argname) = arg
}

query predicate runSteps1(RunExpr run, string body) { run.getScript() = body }

query predicate runSteps2(RunExpr run, Expression bodyExpr) { run.getScriptExpr() = bodyExpr }

query predicate runStepChildren(RunExpr run, AstNode child) { child.getParentNode() = run }

query predicate varAccesses(ExprAccessExpr ea, string expr) { expr = ea.getExpression() }

query predicate outputAccesses(StepOutputAccessExpr va, string id, string var) {
  id = va.getStepId() and var = va.getVarName()
}

query predicate orphanVarAccesses(ExprAccessExpr va, string var) {
  var = va.getExpression() and
  not exists(AstNode n | n = va.getParentNode())
}

query predicate nonOrphanVarAccesses(ExprAccessExpr va, string var, AstNode parent) {
  var = va.getExpression() and
  parent = va.getParentNode()
}

query predicate parentNodes(AstNode child, AstNode parent) { child.getParentNode() = parent }

query predicate cfgNodes(Cfg::Node n) {
  //any()
  n.getAstNode() instanceof ReusableWorkflowOutputsStmt
}

query predicate dfNodes(DataFlow::Node e) {
  e.getLocation().getFile().getBaseName() = "simple1.yml"
}

query predicate exprNodes(DataFlow::ExprNode e) { any() }

query predicate argumentNodes(DataFlow::ArgumentNode e) { any() }

query predicate localFlow(StepUsesExpr s, StepOutputAccessExpr o) { s.getId() = o.getStepId() }

query predicate usesIds(StepUsesExpr s, string a) { s.getId() = a }

query predicate varIds(StepOutputAccessExpr s, string a) { s.getStepId() = a }

query predicate nodeLocations(DataFlow::Node n, Location l) { n.getLocation() = l }

query predicate scopes(Cfg::CfgScope c) { any() }

query predicate sources(string action, string version, string output, string kind) {
  sourceModel(action, version, output, kind)
}

query predicate summaries(string action, string version, string input, string output, string kind) {
  summaryModel(action, version, input, output, kind)
}
