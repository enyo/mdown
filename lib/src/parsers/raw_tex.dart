library md_proc.src.parsers.raw_tex;

import 'package:md_proc/definitions.dart';
import 'package:md_proc/src/parse_result.dart';
import 'package:md_proc/src/parsers/abstract.dart';
import 'package:md_proc/src/parsers/container.dart';

/// Parses raw TeX blocks.
class RawTexParser extends AbstractParser<Iterable<Block>> {
  /// Constructor.
  RawTexParser(ParsersContainer container) : super(container);

  static final RegExp _startRegExp =
      new RegExp(r'^ {0,3}\\begin\{([A-Za-z0-9_\-+*]+)\}');

  static String _escapeReplacement(Match match) => r'\' + match[0];

  @override
  ParseResult<Iterable<Block>> parse(String text, int offset) {
    final ParseResult<String> lineRes =
        container.lineParser.parse(text, offset);
    assert(lineRes.isSuccess);

    final Match startMatch = _startRegExp.firstMatch(lineRes.value);
    if (startMatch == null) {
      return new ParseResult<Iterable<Block>>.failure();
    }

    String enviroment = startMatch[1];
    enviroment =
        enviroment.replaceAllMapped(new RegExp(r'[+*]'), _escapeReplacement);
    final RegExp endTest =
        new RegExp(r'^ {0,3}\\end\{' + enviroment + r'\}[ \t]*$');

    final StringBuffer result = new StringBuffer();
    result.writeln(lineRes.value);

    offset = lineRes.offset;
    final int length = text.length;
    bool found = false;
    while (offset < length) {
      final ParseResult<String> lineRes =
          container.lineParser.parse(text, offset);
      assert(lineRes.isSuccess);

      offset = lineRes.offset;
      result.writeln(lineRes.value);

      if (endTest.hasMatch(lineRes.value)) {
        found = true;
        break;
      }
    }

    if (!found) {
      return new ParseResult<Iterable<Block>>.failure();
    }

    return new ParseResult<Iterable<Block>>.success(
        <Block>[new TexRawBlock(result.toString())], offset);
  }
}
