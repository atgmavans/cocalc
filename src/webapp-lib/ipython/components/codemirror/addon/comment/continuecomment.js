/* 
 *  This file is part of CoCalc: Copyright © 2020 Sagemath, Inc.
 *  License: AGPLv3 s.t. "Commons Clause" – see LICENSE.md for details
 */

(function() {
  var modes = ["clike", "css", "javascript"];

  for (var i = 0; i < modes.length; ++i)
    CodeMirror.extendMode(modes[i], {blockCommentContinue: " * "});

  function continueComment(cm) {
    var pos = cm.getCursor(), token = cm.getTokenAt(pos);
    if (token.type != "comment" || cm.getOption("disableInput")) return CodeMirror.Pass;
    var mode = CodeMirror.innerMode(cm.getMode(), token.state).mode;

    var insert;
    if (mode.blockCommentStart && mode.blockCommentContinue) {
      var end = token.string.indexOf(mode.blockCommentEnd);
      var full = cm.getRange(CodeMirror.Pos(pos.line, 0), CodeMirror.Pos(pos.line, token.end)), found;
      if (end != -1 && end == token.string.length - mode.blockCommentEnd.length && pos.ch >= end) {
        // Comment ended, don't continue it
      } else if (token.string.indexOf(mode.blockCommentStart) == 0) {
        insert = full.slice(0, token.start);
        if (!/^\s*$/.test(insert)) {
          insert = "";
          for (var i = 0; i < token.start; ++i) insert += " ";
        }
      } else if ((found = full.indexOf(mode.blockCommentContinue)) != -1 &&
                 found + mode.blockCommentContinue.length > token.start &&
                 /^\s*$/.test(full.slice(0, found))) {
        insert = full.slice(0, found);
      }
      if (insert != null) insert += mode.blockCommentContinue;
    }
    if (insert == null && mode.lineComment && continueLineCommentEnabled(cm)) {
      var line = cm.getLine(pos.line), found = line.indexOf(mode.lineComment);
      if (found > -1) {
        insert = line.slice(0, found);
        if (/\S/.test(insert)) insert = null;
        else insert += mode.lineComment + line.slice(found + mode.lineComment.length).match(/^\s*/)[0];
      }
    }

    if (insert != null)
      cm.replaceSelection("\n" + insert, "end");
    else
      return CodeMirror.Pass;
  }

  function continueLineCommentEnabled(cm) {
    var opt = cm.getOption("continueComments");
    if (opt && typeof opt == "object")
      return opt.continueLineComment !== false;
    return true;
  }

  CodeMirror.defineOption("continueComments", null, function(cm, val, prev) {
    if (prev && prev != CodeMirror.Init)
      cm.removeKeyMap("continueComment");
    if (val) {
      var key = "Enter";
      if (typeof val == "string")
        key = val;
      else if (typeof val == "object" && val.key)
        key = val.key;
      var map = {name: "continueComment"};
      map[key] = continueComment;
      cm.addKeyMap(map);
    }
  });
})();
