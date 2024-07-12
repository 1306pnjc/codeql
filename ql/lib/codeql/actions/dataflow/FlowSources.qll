private import codeql.actions.security.ArtifactPoisoningQuery
private import codeql.actions.config.Config
private import codeql.actions.dataflow.ExternalFlow

/**
 * A data flow source.
 */
abstract class SourceNode extends DataFlow::Node {
  /**
   * Gets a string that represents the source kind with respect to threat modeling.
   */
  abstract string getThreatModel();
}

/** A data flow source of remote user input. */
abstract class RemoteFlowSource extends SourceNode {
  /** Gets a string that describes the type of this remote flow source. */
  abstract string getSourceType();

  override string getThreatModel() { result = "remote" }
}

class GitHubCtxSource extends RemoteFlowSource {
  string flag;

  GitHubCtxSource() {
    exists(Expression e, string context, string context_prefix |
      this.asExpr() = e and
      context = e.getExpression() and
      normalizeExpr(context) = "github.head_ref" and
      contextTriggerDataModel(e.getEnclosingWorkflow().getATriggerEvent().getName(), context_prefix) and
      normalizeExpr(context).matches("%" + context_prefix + "%") and
      flag = "branch"
    )
  }

  override string getSourceType() { result = flag }
}

class GitHubEventCtxSource extends RemoteFlowSource {
  string flag;

  GitHubEventCtxSource() {
    exists(Expression e, string context, string regexp |
      this.asExpr() = e and
      context = e.getExpression() and
      (
        // the context is available for the job trigger events
        exists(string context_prefix |
          contextTriggerDataModel(e.getEnclosingWorkflow().getATriggerEvent().getName(),
            context_prefix) and
          normalizeExpr(context).matches("%" + context_prefix + "%")
        )
        or
        exists(e.getEnclosingCompositeAction())
      ) and
      untrustedEventPropertiesDataModel(regexp, flag) and
      not flag = "json" and
      normalizeExpr(context).regexpMatch("(?i)\\s*" + wrapRegexp(regexp) + ".*")
    )
  }

  override string getSourceType() { result = flag }
}

class GitHubEventJsonSource extends RemoteFlowSource {
  string flag;

  GitHubEventJsonSource() {
    exists(Expression e, string context, string regexp |
      this.asExpr() = e and
      context = e.getExpression() and
      untrustedEventPropertiesDataModel(regexp, _) and
      (
        // only contexts for the triggering events are considered tainted.
        // eg: for `pull_request`, we only consider `github.event.pull_request`
        exists(string context_prefix |
          contextTriggerDataModel(e.getEnclosingWorkflow().getATriggerEvent().getName(),
            context_prefix) and
          normalizeExpr(context).matches("%" + context_prefix + "%")
        ) and
        normalizeExpr(context).regexpMatch("(?i).*" + wrapJsonRegexp(regexp) + ".*")
        or
        // github.event is taintes for all triggers
        contextTriggerDataModel(e.getEnclosingWorkflow().getATriggerEvent().getName(), _) and
        normalizeExpr(context).regexpMatch("(?i).*" + wrapJsonRegexp("\\bgithub.event\\b") + ".*")
      ) and
      flag = "json"
    )
  }

  override string getSourceType() { result = flag }
}

/**
 * A Source of untrusted data defined in a MaD specification
 */
class MaDSource extends RemoteFlowSource {
  string sourceType;

  MaDSource() { madSource(this, sourceType, _) }

  override string getSourceType() { result = sourceType }
}

/**
 * A downloaded artifact.
 */
private class ArtifactSource extends RemoteFlowSource {
  ArtifactSource() { this.asExpr() instanceof UntrustedArtifactDownloadStep }

  override string getSourceType() { result = "artifact" }
}

/**
 * A list of file names returned by dorny/paths-filter.
 */
class DornyPathsFilterSource extends RemoteFlowSource {
  DornyPathsFilterSource() {
    exists(UsesStep u |
      u.getCallee() = "dorny/paths-filter" and
      u.getArgument("list-files") = ["csv", "json"] and
      this.asExpr() = u
    )
  }

  override string getSourceType() { result = "filename" }
}

/**
 * A list of file names returned by tj-actions/changed-files.
 */
class TJActionsChangedFilesSource extends RemoteFlowSource {
  TJActionsChangedFilesSource() {
    exists(UsesStep u |
      u.getCallee() = "tj-actions/changed-files" and
      (
        u.getArgument("safe_output") = "false" or
        u.getMajorVersion() < 41 or
        u.getVersion()
            .matches([
                  "56284d8", "9454999", "1c93849", "da093c1", "25ef392", "18c8a4e", "4052680",
                  "bfc49f4", "af292f1", "56284d8", "fea790c", "95690f9", "408093d", "db153ba",
                  "8238a41", "4196030", "a21a533", "8e79ba7", "76c4d81", "6ee9cdc", "246636f",
                  "48566bb", "fea790c", "1aee362", "2f7246c", "0fc9663", "c860b5c", "2f8b802",
                  "b7f1b73", "1c26215", "17f3fec", "1aee362", "a0585ff", "87697c0", "85c8b82",
                  "a96679d", "920e7b9", "de0eba3", "3928317", "68b429d", "2a968ff", "1f20fb8",
                  "87e23c4", "54849de", "bb33761", "ec1e14c", "2106eb4", "e5efec4", "5817a9e",
                  "a0585ff", "54479c3", "e1754a4", "9bf0914", "c912451", "174a2a6", "fb20f4d",
                  "07e0177", "b137868", "1aae160", "5d2fcdb", "9ecc6e7", "8c9ee56", "5978e5a",
                  "17c3e9e", "3f7b5c9", "cf4fe87", "043929e", "4e2535f", "652648a", "9ad1a5b",
                  "c798a4e", "25eaddf", "abef388", "1c2673b", "53c377a", "54479c3", "039afcd",
                  "b2d17f5", "4a0aac0", "ce810b2", "7ecfc67", "b109d83", "79adacd", "6e426e6",
                  "5e2d64b", "e9b5807", "db5dd7c", "07f86bc", "3a3ec49", "ee13744", "cda2902",
                  "9328bab", "4e680e1", "bd376fb", "84ed30e", "74b06ca", "5ce975c", "04124ef",
                  "3ee6abf", "23e3c43", "5a331a4", "7433886", "d5414fd", "7f2aa19", "210cc83",
                  "db3ea27", "57d9664", "0953088", "0562b9f", "487675b", "9a6dabf", "7839ede",
                  "c2296c1", "ea251d4", "1d1287f", "392359f", "7f33882", "1d8a2f9", "0626c3f",
                  "a2b1e5d", "110b9ba", "039afcd", "ce4b8e3", "3b6c057", "4f64429", "3f1e44a",
                  "74dc2e8", "8356a01", "baaf598", "8a4cc4f", "8a7336f", "3996bc3", "ef0a290",
                  "3ebdc42", "94e6fba", "3dbb79f", "991e8b3", "72d3bb8", "72d3bb8", "5f89dc7",
                  "734bb16", "d2e030b", "6ba3c59", "d0e4477", "b91acef", "1263363", "7184077",
                  "cbfb0fd", "932dad3", "9f28968", "c4d29bf", "ce4b8e3", "aa52cfc", "aa52cfc",
                  "1d6e210", "8953e85", "8de562e", "7c640bd", "2706452", "1d6e210", "dd7c814",
                  "528984a", "75af1a4", "5184a75", "dd7c814", "402f382", "402f382", "f7a5640",
                  "df4daca", "602081b", "6e12407", "c5c9b6f", "c41b715", "60f4aab", "82edb42",
                  "18edda7", "bec82eb", "f7a5640", "28ac672", "602cf94", "5e56dca", "58ae566",
                  "7394701", "36e65a1", "bf6ddb7", "6c44eb8", "b2ee165", "34a865a", "fb1fe28",
                  "ae90a0b", "bc1dc8f", "3de1f9a", "0edfedf", "2054502", "944a8b8", "581eef0",
                  "e55f7fb", "07b38ce", "d262520", "a6d456f", "a59f800", "a2f1692", "72aab29",
                  "e35d0af", "081ee9c", "1f30bd2", "227e314", "ffd30e8", "f5a8de7", "0bc7d40",
                  "a53d74f", "9335416", "4daffba", "4b1f26a", "09441d3", "e44053b", "c0dba81",
                  "fd2e991", "2a8a501", "a8ea720", "88edda5", "be68c10", "b59431b", "68bd279",
                  "2c85495", "f276697", "00f80ef", "f56e736", "019a09d", "3b638a9", "b42f932",
                  "8dfe0ee", "aae164d", "09a8797", "b54a7ae", "902e607", "2b51570", "040111b",
                  "3b638a9", "1d34e69", "b86b537", "2a771ad", "75933dc", "2c0d12b", "7abdbc9",
                  "675ab58", "8c6f276", "d825b1f", "0bd70b7", "0fe67a1", "7bfa539", "d679de9",
                  "1e10ed4", "0754fda", "d290bdd", "15b1769", "2ecd06d", "5fe8e4d", "7c66aa2",
                  "2ecd06d", "e95bba8", "7852058", "81f32e2", "450eadf", "0e956bb", "300e935",
                  "fcb2ab8", "271bbd6", "e8ace01", "473984b", "032f37f", "3a35bdf", "c2216f6",
                  "0f16c26", "271468e", "fb063fc", "a05436f", "c061ef1", "489e2d5", "8d5a33c",
                  "fbfaba5", "1980f55", "a86b560", "f917cc3", "e18ccae", "e1d275d", "00f80ef",
                  "9c1a181", "5eaa2d8", "188487d", "3098891", "467d26c", "d9eb683", "09a8797",
                  "8e7cc77", "81ad4b8", "5e2a2f1", "1af9ab3", "55a857d", "62a9200", "b915d09",
                  "f0751de", "eef9423"
                ] + "%")
      ) and
      this.asExpr() = u
    )
  }

  override string getSourceType() { result = "filename" }
}

/**
 * A list of file names returned by tj-actions/verify-changed-files.
 */
class TJActionsVerifyChangedFilesSource extends RemoteFlowSource {
  TJActionsVerifyChangedFilesSource() {
    exists(UsesStep u |
      u.getCallee() = "tj-actions/verify-changed-files" and
      (
        u.getArgument("safe_output") = "false" or
        u.getMajorVersion() < 17 or
        u.getVersion()
            .matches([
                  "54e20d3", "a9b6fd3", "30aa174", "7f1b21c", "54e20d3", "0409e18", "7da22d0",
                  "7016858", "0409e18", "7517b83", "bad2f5d", "3b573ac", "7517b83", "f557547",
                  "9ed3155", "f557547", "a3391b5", "a3391b5", "1d7ee97", "c432297", "6e986df",
                  "fa6ea30", "6f40ee1", "1b13d25", "c09bcad", "fda469d", "bd1e271", "367ba21",
                  "9dea97e", "c154cc6", "527ff75", "e8756d5", "bcb4e76", "25267f5", "ea24bfd",
                  "f2a40ba", "197e121", "a8f1b11", "95c26dd", "97ba4cc", "68310bb", "720ba6a",
                  "cedd709", "d68d3d2", "2e1153b", "c3dd635", "81bd1de", "31a9c74", "e981d37",
                  "e7f801c", "e86d0b9", "ad255a4", "3a8aed1", "de910b5", "d31b2a1", "e61c6fc",
                  "380890d", "873cfd6", "b0c60c8", "7183183", "6555389", "9828a95", "8150cee",
                  "48ddf88"
                ] + "%")
      ) and
      this.asExpr() = u
    )
  }

  override string getSourceType() { result = "filename" }
}

class Xt0rtedSlashCommandSource extends RemoteFlowSource {
  Xt0rtedSlashCommandSource() {
    exists(UsesStep u |
      u.getCallee() = "xt0rted/slash-command-action" and
      u.getArgument("permission-level").toLowerCase() = ["read", "none"] and
      this.asExpr() = u
    )
  }

  override string getSourceType() { result = "text" }
}
