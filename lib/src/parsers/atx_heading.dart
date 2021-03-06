library mdown.src.parsers.atx_heading;

import 'package:mdown/ast/ast.dart';
import 'package:mdown/ast/standard_ast_factory.dart';
import 'package:mdown/src/ast/ast.dart';
import 'package:mdown/src/ast/unparsed_inlines.dart';
import 'package:mdown/src/code_units.dart';
import 'package:mdown/src/parse_result.dart';
import 'package:mdown/src/parsers/abstract.dart';
import 'package:mdown/src/parsers/common.dart';
import 'package:mdown/src/parsers/container.dart';

/// Parser for ATX-headings.
class AtxHeadingParser extends AbstractParser<BlockNodeImpl> {
  /// Constructor.
  AtxHeadingParser(ParsersContainer container) : super(container);

  static const int _stateOpen = 0;
  static const int _stateSpaces = 1;
  static const int _stateText = 2;
  static const int _stateClose = 3;
  static const int _stateAfterClose = 4;

  @override
  ParseResult<BlockNodeImpl> parse(String text, int offset) {
    final ParseResult<String> lineResult =
        container.lineParser.parse(text, offset);

    assert(lineResult.isSuccess);

    final String line = lineResult.value;
    final int length = line.length;

    int level = 1;
    int state = _stateOpen;
    int startOffset = -1;
    int endOffset = -1;

    int i = skipIndent(line, 0) + 1;

    // Finite Automata
    while (i < length) {
      final int code = line.codeUnitAt(i);

      switch (state) {
        case _stateOpen:
          if (code == sharpCodeUnit) {
            level++;
            if (level > 6) {
              return const ParseResult<BlockNodeImpl>.failure();
            }
          } else if (code == spaceCodeUnit || code == tabCodeUnit) {
            state = _stateSpaces;
          } else {
            return const ParseResult<BlockNodeImpl>.failure();
          }

          break;

        case _stateSpaces:
          if (code != spaceCodeUnit && code != tabCodeUnit) {
            startOffset = startOffset != -1 ? startOffset : i;
            if (code == sharpCodeUnit) {
              endOffset = i;
              state = _stateClose;
            } else {
              state = _stateText;
            }
          }
          break;

        case _stateText:
          if (code == spaceCodeUnit || code == tabCodeUnit) {
            endOffset = i;
            state = _stateSpaces;
          } else if (code == backslashCodeUnit) {
            i++;
          }
          break;

        case _stateClose:
          if (code == spaceCodeUnit || code == tabCodeUnit) {
            state = _stateAfterClose;
          } else if (code != sharpCodeUnit) {
            state = _stateText;
            endOffset = -1;
          }
          break;

        case _stateAfterClose:
          if (code != spaceCodeUnit && code != tabCodeUnit) {
            state = _stateText;
            endOffset = -1;
            continue;
          }
          break;
      }

      i++;
    }

    endOffset = state != _stateText ? endOffset : length;

    BaseInline inlines;
    ExtendedAttributes attr;
    if (startOffset != -1 && endOffset != -1) {
      String content = line.substring(startOffset, endOffset);
      if (container.options.headingAttributes) {
        final int contentLength = content.length;
        if (contentLength > 0 &&
            content.codeUnitAt(contentLength - 1) == closeBraceCodeUnit) {
          final int attributesStart = content.lastIndexOf('{');
          final ParseResult<Attributes> attributesResult =
              container.attributesParser.parse(content, attributesStart);
          if (attributesResult.isSuccess) {
            content = content.substring(0, attributesStart);
            attr = attributesResult.value;
          }
        }
      }
      inlines = new UnparsedInlinesImpl(content);
    } else {
      inlines = astFactory.baseCompositeInline(<InlineNodeImpl>[]);
    }

    return new ParseResult<BlockNodeImpl>.success(
        new HeadingImpl(inlines, level, attr), lineResult.offset);
  }
}
