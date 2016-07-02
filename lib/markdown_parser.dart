library md_proc.markdown_parser;

import 'package:parsers/parsers.dart';
import 'package:persistent/persistent.dart';

import 'definitions.dart';
import 'entities.dart';
import 'options.dart';

// TODO make constructors in ParseResult (new ParseResult.success)
// TODO remove
// TODO replace some ParseResult.isSuccess checks with assert
ParseResult<dynamic> /*<E>*/ _success(
    dynamic /*E*/ value, String text, Position position,
    [Expectations expectations, bool committed = false]) {
  final Expectations exps =
      (expectations != null) ? expectations : new Expectations.empty(position);
  return new ParseResult<dynamic> /*<E>*/(
      text, exps, position, true, committed, value);
}

ParseResult<dynamic> _failure(String text, Position position,
    [Expectations expectations, bool committed = false]) {
  final Expectations exps =
      (expectations != null) ? expectations : new Expectations.empty(position);
  return new ParseResult<dynamic>(text, exps, position, false, committed, null);
}

/// Parses char
Parser<String> char(String c1) => new Parser<String>((String s, Position pos) {
      if (pos.offset >= s.length) {
        return _failure(s, pos);
      } else {
        String c = s[pos.offset];
        return c == c1 ? _success(c, s, pos.addChar(c)) : _failure(s, pos);
      }
    });

/// Parses char when it one of 2
Parser<String> oneOf2(String c1, String c2) =>
    new Parser<String>((String s, Position pos) {
      if (pos.offset >= s.length) {
        return _failure(s, pos);
      } else {
        String c = s[pos.offset];
        return c == c1 || c == c2
            ? _success(c, s, pos.addChar(c))
            : _failure(s, pos);
      }
    });

/// Parses char when it one of 3
Parser<String> oneOf3(String c1, String c2, String c3) =>
    new Parser<String>((String s, Position pos) {
      if (pos.offset >= s.length) {
        return _failure(s, pos);
      } else {
        String c = s[pos.offset];
        return c == c1 || c == c2 || c == c3
            ? _success(c, s, pos.addChar(c))
            : _failure(s, pos);
      }
    });

/// Parses char when it in set
Parser<String> oneOfSet(Set<String> set) =>
    new Parser<String>((String s, Position pos) {
      if (pos.offset >= s.length) {
        return _failure(s, pos);
      } else {
        String c = s[pos.offset];
        return set.contains(c)
            ? _success(c, s, pos.addChar(c))
            : _failure(s, pos);
      }
    });

/// Parses char when it not in 1
Parser<String> noneOf1(String c1) =>
    new Parser<String>((String s, Position pos) {
      if (pos.offset >= s.length) {
        return _failure(s, pos);
      } else {
        String c = s[pos.offset];
        return c != c1 ? _success(c, s, pos.addChar(c)) : _failure(s, pos);
      }
    });

/// Parses char when it not in 2
Parser<String> noneOf2(String c1, String c2) =>
    new Parser<String>((String s, Position pos) {
      if (pos.offset >= s.length) {
        return _failure(s, pos);
      } else {
        String c = s[pos.offset];
        return c != c1 && c != c2
            ? _success(c, s, pos.addChar(c))
            : _failure(s, pos);
      }
    });

/// Parses char when it not in 3
Parser<String> noneOf3(String c1, String c2, String c3) =>
    new Parser<String>((String s, Position pos) {
      if (pos.offset >= s.length) {
        return _failure(s, pos);
      } else {
        String c = s[pos.offset];
        return c != c1 && c != c2 && c != c3
            ? _success(c, s, pos.addChar(c))
            : _failure(s, pos);
      }
    });

/// Parses char when it not in 4
Parser<String> noneOf4(String c1, String c2, String c3, String c4) =>
    new Parser<String>((String s, Position pos) {
      if (pos.offset >= s.length) {
        return _failure(s, pos);
      } else {
        String c = s[pos.offset];
        return c != c1 && c != c2 && c != c3 && c != c4
            ? _success(c, s, pos.addChar(c))
            : _failure(s, pos);
      }
    });

/// Parses char when it not from set
Parser<String> noneOfSet(Set<String> set) =>
    new Parser<String>((String s, Position pos) {
      if (pos.offset >= s.length) {
        return _failure(s, pos);
      } else {
        String c = s[pos.offset];
        return !set.contains(c)
            ? _success(c, s, pos.addChar(c))
            : _failure(s, pos);
      }
    });

/// choice without expectations
Parser<dynamic> choiceSimple(List<Parser<dynamic>> ps) {
  return new Parser<dynamic>((String s, Position pos) {
    for (final Parser<dynamic> p in ps) {
      final ParseResult<dynamic> res = p.run(s, pos);
      if (res.isSuccess) {
        return res;
      }
    }
    return _failure(s, pos);
  });
}

Parser<dynamic> _manySimple(Parser<dynamic> p, List<dynamic> acc()) {
  return new Parser<dynamic>((String s, Position pos) {
    final List<dynamic> res = acc();
    Position position = pos;
    while (true) {
      ParseResult<dynamic> o = p.run(s, position);
      if (o.isSuccess) {
        res.add(o.value);
        position = o.position;
      } else {
        return _success(res, s, position);
      }
    }
  });
}

/// many without error processing
Parser<List<dynamic>> manySimple(Parser<dynamic> p) => _manySimple(p, () => []);

/// many1 without error processing
Parser<List<dynamic>> many1Simple(Parser<dynamic> p) =>
    p >> (dynamic x) => _manySimple(p, () => [x]);

/// skipMany without error processing
Parser<dynamic> skipManySimple(Parser<dynamic> p) {
  return new Parser<dynamic>((String s, Position pos) {
    Position index = pos;
    while (true) {
      ParseResult<dynamic> o = p.run(s, index);
      if (o.isSuccess) {
        index = o.position;
      } else {
        return _success(null, s, index);
      }
    }
  });
}

/// skipMany1 without error processing
Parser<dynamic> skipMany1Simple(Parser<dynamic> p) => p > p.skipMany;

/// record without error processing
Parser<String> recordMany(Parser<dynamic> p) => skipManySimple(p).record;

/// record1 without error processing
Parser<String> record1Many(Parser<dynamic> p) => skipMany1Simple(p).record;

/// manyUntil without error processing
Parser<dynamic> manyUntilSimple(Parser<dynamic> p, Parser<dynamic> end) {
  // Imperative version to avoid stack overflows.
  return new Parser<dynamic>((String s, Position pos) {
    List<dynamic> res = [];
    Position index = pos;
    while (true) {
      ParseResult<dynamic> endRes = end.run(s, index);
      if (endRes.isSuccess) {
        return _success(res, s, endRes.position);
      } else {
        ParseResult<dynamic> xRes = p.run(s, index);
        if (xRes.isSuccess) {
          res.add(xRes.value);
          index = xRes.position;
        } else {
          return xRes;
        }
      }
    }
  });
}

/// skipManyUntil without error processing
Parser<dynamic> skipManyUntilSimple(Parser<dynamic> p, Parser<dynamic> end) {
  // Imperative version to avoid stack overflows.
  return new Parser<dynamic>((String s, Position pos) {
    Position index = pos;
    while (true) {
      ParseResult<dynamic> endRes = end.run(s, index);
      if (endRes.isSuccess) {
        return _success(null, s, endRes.position);
      } else {
        ParseResult<dynamic> xRes = p.run(s, index);
        if (xRes.isSuccess) {
          index = xRes.position;
        } else {
          return xRes;
        }
      }
    }
  });
}

class _UnparsedInlines extends Inlines {
  String raw;

  _UnparsedInlines(this.raw);

  @override
  String toString() => raw;

  @override
  bool operator ==(dynamic obj) => obj is _UnparsedInlines && raw == obj.raw;

  @override
  int get hashCode => raw.hashCode;
}

RegExp _trimAndReplaceSpacesRegExp = new RegExp(r'\s+');
String _trimAndReplaceSpaces(String s) {
  return s.trim().replaceAll(_trimAndReplaceSpacesRegExp, ' ');
}

String _normalizeReference(String s) => _trimAndReplaceSpaces(s).toUpperCase();

class _LinkReference extends Block {
  String reference;
  String normalizedReference;
  Target target;

  _LinkReference(this.reference, this.target) {
    normalizedReference = _normalizeReference(reference);
  }
}

class _EscapedSpace extends Inline {
  static final _EscapedSpace _instance = new _EscapedSpace._internal();

  factory _EscapedSpace() {
    return _instance;
  }

  _EscapedSpace._internal();

  @override
  String toString() => "_EscapedSpace";

  @override
  bool operator ==(dynamic obj) => obj is _EscapedSpace;

  @override
  int get hashCode => 0;
}

// TODO make aux parsers private

// TODO make special record classes for every List<dynamic> usage

class _ListStackItem {
  int indent;
  int subIndent;
  ListBlock block;

  _ListStackItem(this.indent, this.subIndent, this.block);
}

class _EmphasisStackItem {
  String char;
  int numDelims;
  Inlines inlines;
  bool cantCloseAnyway;

  _EmphasisStackItem(this.char, this.numDelims, this.inlines,
      {this.cantCloseAnyway: false});
}

/// CommonMark parser
class CommonMarkParser {
  /// Tab stop value
  static const int tabStop = 4;

  Options _options;

  Map<String, Target> _references;

  Set<String> _inlineDelimiters;
  Set<String> _strSpecialChars;
  Set<String> _intrawordDelimiters;

  /// Constructor
  CommonMarkParser(this._options, [this._references]) {
    _inlineDelimiters = new Set<String>.from(["_", "*"]);
    _strSpecialChars = new Set<String>.from(
        [" ", "*", "_", "`", "!", "[", "]", "&", "<", "\\"]);
    _intrawordDelimiters = new Set<String>.from(["*"]);
    if (_options.smartPunctuation) {
      _inlineDelimiters.addAll(["'", "\""]);
      _strSpecialChars.addAll(["'", "\"", ".", "-"]);
    }
    if (_options.strikeout || _options.subscript) {
      _inlineDelimiters.add("~");
      _strSpecialChars.add("~");
      _intrawordDelimiters.add("~");
    }
    if (_options.superscript) {
      _inlineDelimiters.add('^');
      _strSpecialChars.add('^');
      _intrawordDelimiters.add('^');
    }
  }

  /// Parse document from string
  Document parse(String s) {
    // TODO separate preprocess option

    _references = {};

    s = preprocess(s);
    if (!s.endsWith("\n")) {
      s += "\n";
    }
    Document doc = document.parse(s, tabStop: tabStop);

    _inlinesInDocument(doc);
    return doc;
  }

  /// Preprocess input string
  String preprocess(String s) {
    StringBuffer sb = new StringBuffer();

    int i = 0, len = s.length;
    while (i < len) {
      if (s[i] == "\r") {
        if (i + 1 < len && s[i + 1] == "\n") {
          ++i;
        }

        sb.write("\n");
      } else if (s[i] == "\n") {
        if (i + 1 < len && s[i + 1] == "\r") {
          ++i;
        }

        sb.write("\n");
      } else {
        sb.write(s[i]);
      }

      ++i;
    }

    return sb.toString();
  }

  //
  // Inlines search
  //

  void _inlinesInDocument(Document doc) {
    doc.contents.forEach(_inlinesInBlock);
  }

  Block _inlinesInBlock(Block block) {
    if (block is Heading) {
      Inlines contents = block.contents;
      if (contents is _UnparsedInlines) {
        block.contents = _parseInlines(contents.raw);
      }
    } else if (block is Para) {
      Inlines contents = block.contents;
      if (contents is _UnparsedInlines) {
        block.contents = _parseInlines(contents.raw);
      }
    } else if (block is Blockquote) {
      block.contents = block.contents.map(_inlinesInBlock);
    } else if (block is ListBlock) {
      block.items = block.items.map((ListItem item) {
        item.contents = item.contents.map(_inlinesInBlock);
        return item;
      });
    }
    return block;
  }

  Inlines _parseInlines(String raw) {
    return inlines.parse(raw, tabStop: tabStop);
  }

  //
  // Aux methods
  //

  List<Block> _processParsedBlocks(Iterable<dynamic> blocks) {
    List<dynamic> list = _flatten(blocks);
    List<Block> result = [];
    list.forEach((Block block) {
      if (block is _LinkReference) {
        String nr = block.normalizedReference;
        if (!_references.containsKey(nr)) {
          _references[nr] = block.target;
        }
      } else {
        result.add(block);
      }
    });
    return result;
  }

  Inlines _processParsedInlines(Iterable<dynamic> inlines) {
    Inlines result = new Inlines();
    result.addAll(_flatten(inlines));
    return result;
  }

  static List<dynamic> _flatten(Iterable<dynamic> list) {
    List<dynamic> result = [];

    for (dynamic item in list) {
      if (item is Iterable<dynamic>) {
        result.addAll(_flatten(item));
      } else {
        result.add(item);
      }
    }

    return result;
  }

  static String _stripTrailingNewlines(String str) {
    int l = str.length;
    while (l > 0 && str[l - 1] == '\n') {
      --l;
    }
    return str.substring(0, l);
  }

  //
  // Aux parsers
  //

  /// Parses any line (fast version)
  static final Parser<String> anyLine =
      new Parser<String>((String s, Position pos) {
    String result = '';
    int offset = pos.offset, len = s.length;
    if (offset >= len) {
      return _failure(s, pos);
    }
    while (offset < len && s[offset] != '\n') {
      result += s[offset];
      ++offset;
    }
    Position newPos;
    if (offset < len && s[offset] == '\n') {
      newPos = new Position(offset + 1, pos.line + 1, 1, tabStop: tabStop);
    } else {
      newPos = new Position(offset, pos.line, pos.character + result.length,
          tabStop: tabStop);
    }
    return _success(result, s, newPos);
  });

  /// Parses space or tab
  static final Parser<String> whitespaceChar = oneOf2(" ", "\t");

  /// Parses one space char
  static final Parser<String> space = char(' ');

  /// Parses not space
  static final Parser<String> nonSpaceChar = noneOf4("\t", "\n", " ", "\r");

  /// Skips spaces
  static final Parser<dynamic> skipSpaces = skipManySimple(space);

  /// Skips whitespace (space or tab)
  static final Parser<dynamic> skipWhitespace = skipManySimple(whitespaceChar);

  /// Skips one blankline
  static final Parser<String> blankline = skipWhitespace > newline;

  /// Parses 1+ blanklines
  static final Parser<List<String>> blanklines = many1Simple(blankline);

  // All indent and spaces parsers accepts spaces to skip, and returns spaces
  // that were actually skipped.
  static final Parser<int> _skipNonindentChars =
      atMostIndent(tabStop - 1).notFollowedBy(whitespaceChar);
  static final Parser<int> _skipNonindentCharsFromAnyPosition =
      atMostIndent(tabStop - 1, fromLineStart: false)
          .notFollowedBy(whitespaceChar);

  static Parser<int> _skipListIndentChars(int max) =>
      (atMostIndent(max - 1) | atMostIndent(tabStop - 1, fromLineStart: false))
          .notFollowedBy(whitespaceChar);

  /// Indent parser
  static final Parser<int> indent = _waitForIndent(tabStop);

  static Map<int, Parser<int>> _atMostIndentCache = {};
  static Map<int, Parser<int>> _atMostIndentStartCache = {};

  /// Parses maximum indent, could be less
  static Parser<int> atMostIndent(int indent, {bool fromLineStart: true}) {
    if (fromLineStart && _atMostIndentStartCache[indent] != null) {
      return _atMostIndentStartCache[indent];
    }
    if (!fromLineStart && _atMostIndentCache[indent] != null) {
      return _atMostIndentCache[indent];
    }

    Parser<int> p = new Parser<int>((String s, Position pos) {
      if (fromLineStart && pos.character != 1) {
        return _failure(s, pos);
      }
      int startCharacter = pos.character;
      int maxEndCharacter = indent + startCharacter;
      Position position = pos;
      while (position.character <= maxEndCharacter) {
        ParseResult<String> res = whitespaceChar.run(s, position);
        if (!res.isSuccess || res.position.character > maxEndCharacter) {
          return _success(position.character - startCharacter, s, position);
        }
        position = res.position;
      }
      return _success(position.character - startCharacter, s, position);
    });
    if (fromLineStart) {
      _atMostIndentStartCache[indent] = p;
    } else {
      _atMostIndentCache[indent] = p;
    }
    return p;
  }

  static Map<int, Parser<int>> _waitForIndentCache = {};
  static Parser<int> _waitForIndent(int length) {
    if (_waitForIndentCache[length] == null) {
      _waitForIndentCache[length] = new Parser<int>((String s, Position pos) {
        if (pos.character != 1) {
          return _failure(s, pos);
        }
        Position position = pos;
        Position prevPosition = pos;
        while (position.character <= length) {
          ParseResult<String> res = whitespaceChar.run(s, position);
          if (!res.isSuccess) {
            return res;
          }
          prevPosition = position;
          position = res.position;
        }

        int endLength = position.character - 1;
        if (endLength == length) {
          return _success(endLength, s, position);
        }

        // It was tab and we get to far. So we split tab to spaces and
        // return partial result.

        s = s.replaceRange(
            prevPosition.offset, prevPosition.offset + 1, '    ');

        return _success(
            length,
            s,
            prevPosition.copy(
                offset:
                    prevPosition.offset + length - (prevPosition.character - 1),
                character: length + 1));
      });
    }

    return _waitForIndentCache[length];
  }

  /// Parses exactly l occurrences of parser
  static Parser<List<dynamic> /*<A>*/ > count(
          int l, Parser<dynamic> /*<A>*/ p) =>
      countBetween(l, l, p);

  /// Parses min...max occurrences of a parser
  static Parser<List<dynamic> /*<A>*/ > countBetween(
          int min, int max, Parser<dynamic> /*<A>*/ p) =>
      new Parser<List<dynamic> /*<A>*/ >((String s, Position pos) {
        Position position = pos;
        List<dynamic> /*<A>*/ value = [];
        ParseResult<dynamic> /*<A>*/ res;
        for (int i = 0; i < max; ++i) {
          res = p.run(s, position);
          if (res.isSuccess) {
            value.add(res.value);
            position = res.position;
          } else if (i < min) {
            return _failure(s, pos);
          } else {
            return _success(value, s, position);
          }
        }

        return _success(value, s, position);
      });

  //
  // HTML
  //

  // TODO move to utils
  static final String _lowerChars = "abcdefghijklmnopqrstuvwxyz";
  static final Set<String> _lower = new Set<String>.from(_lowerChars.split(""));
  static final Set<String> _upper =
      new Set<String>.from(_lowerChars.toUpperCase().split(""));
  static final Set<String> _alpha = new Set<String>.from(_lower)
    ..addAll(_upper);
  static final String _digitChars = "1234567890";
  static final Set<String> _digit = new Set<String>.from(_digitChars.split(""));
  static final Set<String> _alphanum = new Set<String>.from(_alpha)
    ..addAll(_digit);

  /// Parses tab char
  static final Parser<String> tab = char('\t');

  /// Parses new line char
  static final Parser<String> newline = char('\n');

  /// Parses uppercase letter
  static final Parser<String> upper = oneOfSet(_upper);

  /// Parses lowercase letter
  static final Parser<String> lower = oneOfSet(_lower);

  /// Parses alphanumeric char
  static final Parser<String> alphanum = oneOfSet(_alphanum);

  /// Parses single letter
  static final Parser<String> letter = oneOfSet(_alpha);

  /// Parses single digit
  static final Parser<String> digit = oneOfSet(_digit);

  static final Set<String> _allowedTags = new Set<String>.from([
    "address",
    "article",
    "aside",
    "base",
    "basefont",
    "blockquote",
    "body",
    "caption",
    "center",
    "col",
    "colgroup",
    "dd",
    "details",
    "dialog",
    "dir",
    "div",
    "dl",
    "dt",
    "fieldset",
    "figcaption",
    "figure",
    "footer",
    "form",
    "frame",
    "frameset",
    "h1",
    "head",
    "header",
    "hr",
    "html",
    "iframe",
    "legend",
    "li",
    "link",
    "main",
    "menu",
    "menuitem",
    "meta",
    "nav",
    "noframes",
    "ol",
    "optgroup",
    "option",
    "p",
    "param",
    "section",
    "source",
    "summary",
    "table",
    "tbody",
    "td",
    "tfoot",
    "th",
    "thead",
    "title",
    "tr",
    "track",
    "ul"
  ]);

  static final Parser<String> _spaceOrNL = oneOf3(" ", "\t", "\n");

  static final Parser<String> _htmlTagName = (letter >
          skipManySimple(oneOfSet(new Set<String>.from(_alphanum)..add("-"))))
      .record;
  static final Parser<String> _htmlAttributeName =
      (oneOfSet(new Set<String>.from(_alpha)..addAll(["_", ":"])) >
              skipManySimple(oneOfSet(new Set<String>.from(_alphanum)
                ..addAll(["_", ".", ":", "-"]))))
          .record;
  // TODO generic parser that takes everything in order (replace + + .list.record)
  static final Parser<String> _htmlAttributeValue = (manySimple(_spaceOrNL) +
          char('=') +
          manySimple(_spaceOrNL) +
          choiceSimple([
            _htmlUnquotedAttributeValue,
            _htmlSingleQuotedAttributeValue,
            _htmlDoubleQuotedAttributeValue
          ]))
      .list
      .record;
  static final Parser<String> _htmlUnquotedAttributeValue =
      record1Many(noneOfSet(new Set<String>.from(" \t\n\"'=<>`".split(""))));
  static final Parser<String> _htmlSingleQuotedAttributeValue =
      ((char("'") > skipManySimple(noneOf1("'"))) < char("'")).record;
  static final Parser<String> _htmlDoubleQuotedAttributeValue =
      ((char('"') > skipManySimple(noneOf1('"'))) < char('"')).record;
  static final Parser<String> _htmlAttribute =
      (_spaceOrNL.many1 + _htmlAttributeName + _htmlAttributeValue.maybe)
          .list
          .record;
  static final Parser<String> _htmlOpenTag =
      (((((char("<") > _htmlTagName) < skipManySimple(_htmlAttribute)) <
                      skipManySimple(_spaceOrNL)) <
                  char('/').maybe) <
              char('>'))
          .record;
  static final Parser<String> _htmlCloseTag =
      (((string("</") > _htmlTagName) < skipManySimple(_spaceOrNL)) < char('>'))
          .record;
  static final Parser<String> _htmlCompleteComment2 =
      (string('<!--').notFollowedBy(char('>') | string('->')) >
              skipManyUntilSimple(anyChar, string('--')))
          .record;
  static final Parser<String> _htmlCompleteComment =
      new Parser<String>((String s, Position pos) {
    ParseResult<String> res = _htmlCompleteComment2.run(s, pos);
    if (!res.isSuccess) {
      return res;
    }

    ParseResult<String> res2 = char('>').run(s, res.position);
    if (res2.isSuccess) {
      return _success(res.value + '>', s, res2.position);
    }
    return res2;
  });
  static final Parser<String> _htmlCompletePI =
      (string('<?') > skipManyUntilSimple(anyChar, string('?>'))).record;
  static final Parser<String> _htmlDeclaration = (string('<!') +
          skipMany1Simple(upper) +
          skipMany1Simple(_spaceOrNL) +
          skipManyUntilSimple(anyChar, char('>')))
      .list
      .record;
  static final Parser<String> _htmlCompleteCDATA =
      (string('<![CDATA[') > skipManyUntilSimple(anyChar, string(']]>')))
          .record;

  //
  // Links aux parsers
  //

  // Can't be static because of str
  Parser<List<Inline>> _linkTextChoiceCache;
  Parser<List<Inline>> get _linkTextChoice {
    if (_linkTextChoiceCache == null) {
      _linkTextChoiceCache = choiceSimple([
        whitespace,
        htmlEntity,
        inlineCode,
        autolink,
        rawInlineHtml,
        escapedChar,
        rec(() => _linkText),
        str
      ]);
    }
    return _linkTextChoiceCache;
  }

  Parser<String> _linkTextCache;
  Parser<String> get _linkText {
    if (_linkTextCache == null) {
      _linkTextCache = (char('[') >
              (_linkTextChoice >
                      skipManyUntilSimple(_linkTextChoice, char(']')))
                  .record) ^
          (String label) => label.substring(0, label.length - 1);
    }
    return _linkTextCache;
  }

  Parser<String> _imageTextCache;
  Parser<String> get _imageText {
    if (_imageTextCache == null) {
      _imageTextCache =
          (char('[') > skipManyUntilSimple(_linkTextChoice, char(']')).record) ^
              (String label) => label.substring(0, label.length - 1);
    }
    return _imageTextCache;
  }

  static final Set<String> _linkLabelStrSpecialChars =
      new Set<String>.from(" *_`!<\\".split(""));
  static final Parser<List<Inline>> _linkLabelStr = choiceSimple([
    record1Many(noneOfSet(new Set<String>.from(_linkLabelStrSpecialChars)
          ..addAll(["[", "]", "\n"]))) ^
        (String str) => _transformString(str),
    oneOfSet(_linkLabelStrSpecialChars) ^
        (String char) => _transformString(char),
    char("\n").notFollowedBy(blankline) ^ (_) => [new Str("\n")]
  ]);

  static final Parser<String> _linkLabel = (char('[') >
          skipManyUntilSimple(
                  choiceSimple([
                    whitespace,
                    htmlEntity,
                    inlineCode,
                    autolink,
                    rawInlineHtml,
                    escapedChar,
                    _linkLabelStr
                  ]),
                  char(']'))
              .record) ^
      (String label) => label.substring(0, label.length - 1);

  static final Set<String> _linkStopChars =
      new Set<String>.from(['&', '\\', '\n', ' ', '(', ')']);
  static final Set<String> _linkStopCharsPointed =
      new Set<String>.from([' ', '\n', '<', '>']);
  static final Parser<String> _linkBalancedParenthesis = ((char("(") >
              many1Simple(choiceSimple([
                noneOfSet(_linkStopChars),
                _escapedChar1,
                _htmlEntity1,
                oneOf2('&', '\\')
              ]))) <
          char(')')) ^
      (List<String> i) => "(${i.join()})";

  // manySimple(noneOf3("<", ">", "\n"))
  static final Parser<String> _linkInlineDestination = (((char("<") >
                  manySimple(choiceSimple([
                    noneOfSet(_linkStopCharsPointed),
                    _escapedChar1,
                    _htmlEntity1,
                    _linkBalancedParenthesis,
                    oneOf2('&', '\\')
                  ]))) <
              char(">")) |
          manySimple(choiceSimple([
            noneOfSet(_linkStopChars),
            _escapedChar1,
            _htmlEntity1,
            _linkBalancedParenthesis,
            oneOf2('&', '\\')
          ]))) ^
      (List<String> i) => i.join();

  static final Parser<String> _linkBlockDestination =
      (((char("<") > many1Simple(noneOf3("<", ">", "\n"))) < char(">")) |
              many1Simple(choiceSimple([
                noneOfSet(_linkStopChars),
                _escapedChar1,
                _htmlEntity1,
                _linkBalancedParenthesis,
                oneOf2('&', '\\')
              ]))) ^
          (List<String> i) => i.join();

  static final Parser<String> _oneNewLine = newline.notFollowedBy(blankline);

  static final Parser<String> _linkTitle = choiceSimple([
        ((char("'") >
                manySimple(choiceSimple([
                  noneOf4("'", "&", "\\", "\n"),
                  _oneNewLine,
                  _escapedChar1,
                  _htmlEntity1,
                  oneOf2('&', '\\')
                ]))) <
            char("'")),
        ((char('"') >
                manySimple(choiceSimple([
                  noneOf4('"', "&", "\\", "\n"),
                  _oneNewLine,
                  _escapedChar1,
                  _htmlEntity1,
                  oneOf2('&', '\\')
                ]))) <
            char('"')),
        ((char('(') >
                manySimple(choiceSimple([
                  noneOf4(')', "&", "\\", "\n"),
                  _oneNewLine,
                  _escapedChar1,
                  _htmlEntity1,
                  oneOf2('&', '\\')
                ]))) <
            char(')'))
      ]) ^
      (List<String> i) => i.join();

  //
  // Inlines
  //

  //
  // whitespace
  //

  /// Parser for whitespace
  static final Parser<List<Inline>> whitespace =
      (char(' ') ^ (_) => [new Space()]) | (char('\t') ^ (_) => [new Tab()]);

  // TODO better escaped chars support
  static final Set<String> _escapedCharSet =
      new Set<String>.from("!\"#\$%&'()*+,-./:;<=>?@[\\]^_`{|}~".split(""));
  static final Parser<String> _escapedChar1 =
      (char('\\') > oneOfSet(_escapedCharSet));

  /// Parser for escaped chars
  static final Parser<List<Inline>> escapedChar =
      _escapedChar1 ^ (String char) => [new Str(char)];

  //
  // html entities
  //

  static final RegExp _decimalEntity = new RegExp(r'^#(\d{1,8})$');
  static final RegExp _hexadecimalEntity =
      new RegExp(r'^#[xX]([0-9a-fA-F]{1,8})$');
  static final Parser<String> _htmlEntity1 = (((char('&') >
              ((char('#').maybe + record1Many(alphanum)) ^
                  (Option<String> a, String b) =>
                      (a.isDefined ? '#' : '') + b)) <
          char(';')) ^
      (String entity) {
        if (htmlEntities.containsKey(entity)) {
          return htmlEntities[entity];
        }

        int code;
        Match m = _decimalEntity.firstMatch(entity);
        if (m != null) {
          code = int.parse(m.group(1));
        }

        m = _hexadecimalEntity.firstMatch(entity);

        if (m != null) {
          code = int.parse(m.group(1), radix: 16);
        }

        if (code != null) {
          if (code > 1114111 || code == 0) {
            code = 0xFFFD;
          }
          return new String.fromCharCode(code);
        }

        return '&$entity;';
      });

  /// Parser for html entities
  static final Parser<List<Inline>> htmlEntity = _htmlEntity1 ^
      (String str) =>
          str == "\u{a0}" ? [new NonBreakableSpace()] : [new Str(str)];

  //
  // inline code
  //

  static final Parser<String> _inlineCode1 = record1Many(char('`'));
  static final Parser<String> _inlineCode2 = recordMany(noneOf2('\n', '`'));

  /// Parser for inline code
  static final Parser<List<Inline>> inlineCode =
      new Parser<List<Inline>>((String s, Position pos) {
    if (pos.offset >= s.length || s[pos.offset] != '`') {
      // Fast check
      return _failure(s, pos);
    }

    ParseResult<List<String>> openRes = _inlineCode1.run(s, pos);
    assert(openRes.isSuccess);
    if (pos.offset > 0 && s[pos.offset - 1] == '`') {
      return _failure(s, pos);
    }

    int fenceSize = openRes.value.length;

    StringBuffer str = new StringBuffer();
    Position position = openRes.position;
    while (true) {
      ParseResult<String> res = _inlineCode2.run(s, position);
      assert(res.isSuccess);
      str.write(res.value);
      position = res.position;

      // Checking for paragraph end
      ParseResult<String> blankRes = char('\n').run(s, position);
      if (blankRes.isSuccess) {
        str.write('\n');
        position = blankRes.position;
        ParseResult<String> blankRes2 = blankline.run(s, position);
        if (blankRes2.isSuccess) {
          // second \n - closing block
          return _failure(s, pos);
        }
        position = blankRes.position;
        continue;
      }

      res = _inlineCode1.run(s, position);
      if (!res.isSuccess) {
        return res;
      }
      if (res.value.length == fenceSize) {
        return _success([
          new Code(_trimAndReplaceSpaces(str.toString()), fenceSize: fenceSize)
        ], s, res.position);
      }
      str.write(res.value);
      position = res.position;
    }
  });

  //
  // emphasis and strong
  //

  static final RegExp _isSpace = new RegExp(r'^\s');

  static final RegExp _isPunctuation = new RegExp(
      "^[\u{2000}-\u{206F}\u{2E00}-\u{2E7F}\\\\'!\"#\\\$%&\\(\\)\\*\\+,\\-\\.\\/:;<=>\\?@\\[\\]\\^_`\\{\\|\\}~]");

  // Can't be static
  Parser<List<dynamic>> _scanDelimsCache;
  Map<String, Parser<List<String>>> _scanDelimsParserCache = {};
  Parser<List<dynamic>> get _scanDelims {
    if (_scanDelimsCache == null) {
      Parser<String> testParser = oneOfSet(_inlineDelimiters).lookAhead;
      _scanDelimsCache = new Parser<List<dynamic>>((String s, Position pos) {
        ParseResult<String> testRes = testParser.run(s, pos);
        if (!testRes.isSuccess) {
          return testRes;
        }
        String c = testRes.value;

        Parser<List<String>> p = _scanDelimsParserCache[c];
        if (p == null) {
          p = many1Simple(char(c));
          _scanDelimsParserCache[c] = p;
        }
        ParseResult<List<String>> res = p.run(s, pos);
        if (!res.isSuccess) {
          return res;
        }

        int numDelims = res.value.length;

        int i = 1;
        while (pos.offset - i >= 0 &&
            _intrawordDelimiters.contains(s[pos.offset - i])) {
          ++i;
        }
        String charBefore = pos.offset - i < 0 ? '\n' : s[pos.offset - i];

        i = 0;
        while (res.position.offset + i < s.length &&
            _intrawordDelimiters.contains(s[res.position.offset + i])) {
          ++i;
        }
        String charAfter = res.position.offset + i < s.length
            ? s[res.position.offset + i]
            : '\n';
        bool leftFlanking = !_isSpace.hasMatch(charAfter) &&
            (!_isPunctuation.hasMatch(charAfter) ||
                _isSpace.hasMatch(charBefore) ||
                _isPunctuation.hasMatch(charBefore));
        bool rightFlanking = !_isSpace.hasMatch(charBefore) &&
            (!_isPunctuation.hasMatch(charBefore) ||
                _isSpace.hasMatch(charAfter) ||
                _isPunctuation.hasMatch(charAfter));
        bool canOpen = numDelims > 0 && leftFlanking;
        bool canClose = numDelims > 0 && rightFlanking;
        if (c == '_') {
          canOpen = canOpen &&
              (!rightFlanking || _isPunctuation.hasMatch(charBefore));
          canClose =
              canClose && (!leftFlanking || _isPunctuation.hasMatch(charAfter));
        }
        if (c == '~' && !_options.subscript && numDelims < 2) {
          canOpen = false;
          canClose = false;
        }
        return _success([numDelims, canOpen, canClose, c], s, res.position);
      });
    }
    return _scanDelimsCache;
  }

  Parser<List<Inline>> _emphasisCache;

  /// Parser for emphasis, strong, subscrip, superscript and smart quotes
  Parser<List<Inline>> get emphasis {
    if (_emphasisCache == null) {
      _emphasisCache = new Parser<List<Inline>>((String s, Position pos) {
        ParseResult<List<dynamic>> res = _scanDelims.run(s, pos);
        if (!res.isSuccess) {
          return res;
        }
        int numDelims = res.value[0];
        bool canOpen = res.value[1];
        bool canClose = res.value[2];
        String char = res.value[3];

        if (!canOpen) {
          return _success([new Str(char * numDelims)], s, res.position);
        }

        List<_EmphasisStackItem> stack = <_EmphasisStackItem>[];
        Inlines result = new Inlines();
        Position position = res.position;

        void mergeWithPrevious() {
          Inlines inlines = new Inlines();
          if (stack.last.char == "'" || stack.last.char == '"') {
            for (int i = 0; i < stack.last.numDelims; ++i) {
              inlines.add(new SmartQuote(new Inlines(),
                  single: stack.last.char == "'", close: false));
            }
          } else {
            inlines.add(new Str(stack.last.char * stack.last.numDelims));
          }
          inlines.addAll(stack.last.inlines);
          stack.removeLast();
          if (stack.length > 0) {
            stack.last.inlines.addAll(inlines);
          } else {
            result.addAll(inlines);
          }
        }
        void addToStack(Inline inline) {
          if (stack.length > 0) {
            stack.last.inlines.add(inline);
          } else {
            result.add(inline);
          }
        }
        void addAllToStack(List<Inline> inlines) {
          stack.last.inlines.addAll(inlines);
        }

        Inlines transformEscapedSpace(Inlines inlines, Inline replacement) {
          return new Inlines.from(inlines.map((Inline el) {
            if (el is _EscapedSpace) {
              return replacement;
            }
            if (el is Subscript) {
              el.contents = transformEscapedSpace(el.contents, replacement);
            } else if (el is Superscript) {
              el.contents = transformEscapedSpace(el.contents, replacement);
            } else if (el is Strikeout) {
              el.contents = transformEscapedSpace(el.contents, replacement);
            } else if (el is Emph) {
              el.contents = transformEscapedSpace(el.contents, replacement);
            } else if (el is Strong) {
              el.contents = transformEscapedSpace(el.contents, replacement);
            }
            return el;
          }));
        }

        /// Add all inlines to stack. If there's Space marks all subscript and superscript delimiters as invalid
        /// and return false, otherwise return true;
        bool processSpacesAndAddAllToStack(List<Inline> inlines) {
          bool res = true;
          inlines.forEach((Inline el) {
            if (el is Space) {
              stack.forEach((_EmphasisStackItem item) {
                bool convert = false;
                if (_options.subscript && item.char == '~' ||
                    _options.superscript && item.char == '^') {
                  item.cantCloseAnyway = true;
                  convert = true;
                }
                if (convert) {
                  item.inlines = transformEscapedSpace(
                      item.inlines, new NonBreakableSpace());
                }
              });
              res = false;
            }
            stack.last.inlines.add(el);
          });

          return res;
        }

        void wrapStackInlines(String str) {
          stack.last.inlines
            ..insert(0, new Str(str))
            ..add(new Str(str));
        }

        mainloop: while (true) {
          // Trying to close
          if (canOpen && canClose && char == "'" && numDelims == 1) {
            // Special case for smart quote, apostrophe
            addToStack(
                new SmartQuote(new Inlines(), single: true, open: false));
          } else {
            if (canClose) {
              bool openFound =
                  stack.any((_EmphasisStackItem item) => item.char == char);
              while (openFound && numDelims > 0 && stack.length > 0) {
                while (stack.length > 0 && stack.last.char != char) {
                  mergeWithPrevious();
                }
                Inlines inlines = stack.last.inlines;
                Inline inline;
                int count = numDelims < stack.last.numDelims
                    ? numDelims
                    : stack.last.numDelims;
                numDelims -= count;
                stack.last.numDelims -= count;
                if (char == "'" || char == '"') {
                  // Smart quotes

                  while (count > 0) {
                    inline = new SmartQuote(inlines, single: char == "'");
                    inlines = new Inlines();
                    inlines.add(inline);
                    count--;
                  }
                } else if (char == "~") {
                  if (_options.strikeout && _options.subscript) {
                    // Strikeouts and subscripts

                    if (count & 1 == 1) {
                      if (stack.last.cantCloseAnyway) {
                        wrapStackInlines("~");
                      } else {
                        inline = new Subscript(
                            transformEscapedSpace(inlines, new Space()));
                        inlines = new Inlines();
                        inlines.add(inline);
                      }
                      count--;
                    }
                    while (count > 0) {
                      inline = new Strikeout(transformEscapedSpace(
                          inlines, new NonBreakableSpace()));
                      inlines = new Inlines();
                      inlines.add(inline);
                      count -= 2;
                    }
                  } else if (_options.subscript) {
                    // Subscript only

                    if (stack.last.cantCloseAnyway) {
                      wrapStackInlines("~" * count);
                    } else {
                      while (count > 0) {
                        inline = new Subscript(
                            transformEscapedSpace(inlines, new Space()));
                        inlines = new Inlines();
                        inlines.add(inline);
                        count--;
                      }
                    }
                  } else {
                    // Strikeout only

                    if (count & 1 == 1) {
                      inlines.add(new Str("~"));
                      count--;
                    }
                    while (count > 0) {
                      inline = new Strikeout(inlines);
                      inlines = new Inlines();
                      inlines.add(inline);
                      count -= 2;
                    }
                  }
                } else if (char == "^") {
                  // Superscript

                  if (stack.last.cantCloseAnyway) {
                    wrapStackInlines("^" * count);
                  } else {
                    while (count > 0) {
                      inline = new Superscript(
                          transformEscapedSpace(inlines, new Space()));
                      inlines = new Inlines();
                      inlines.add(inline);
                      count--;
                    }
                  }
                } else {
                  // Strongs and emphasises

                  if (count & 1 == 1) {
                    inline = new Emph(inlines);
                    inlines = new Inlines();
                    inlines.add(inline);
                    count--;
                  }
                  while (count > 0) {
                    inline = new Strong(inlines);
                    inlines = new Inlines();
                    inlines.add(inline);
                    count -= 2;
                  }
                }

                if (inline != null) {
                  if (stack.last.numDelims == 0) {
                    stack.removeLast();
                  } else {
                    stack.last.inlines = new Inlines();
                  }
                  addToStack(inline);
                } else {
                  mergeWithPrevious();
                }
                if (numDelims > 0) {
                  openFound =
                      stack.any((_EmphasisStackItem item) => item.char == char);
                }
              }
            }
            // Trying to open
            if (canOpen && numDelims > 0) {
              stack.add(new _EmphasisStackItem(char, numDelims, new Inlines()));
              numDelims = 0;
            }

            if (numDelims > 0) {
              // ending delimiters without open ones
              if (char == "'" || char == '"') {
                for (int i = 0; i < stack.last.numDelims; ++i) {
                  addToStack(new SmartQuote(new Inlines(),
                      single: stack.last.char == "'", open: false));
                }
              } else {
                addToStack(new Str(char * numDelims));
              }
            }
          }

          if (stack.length == 0) {
            break;
          }

          bool excludeSpaces = (_options.subscript || _options.superscript) &&
              stack.firstWhere((_EmphasisStackItem el) {
                    return _options.subscript && el.char == '~' ||
                        _options.superscript && el.char == '^';
                  }, orElse: () => null) !=
                  null;
          while (true) {
            ParseResult<List<dynamic>> res = _scanDelims.run(s, position);
            if (res.isSuccess) {
              numDelims = res.value[0];
              canOpen = res.value[1];
              canClose = res.value[2];
              char = res.value[3];
              position = res.position;
              break;
            }

            if (excludeSpaces) {
              res = spaceEscapedInline.run(s, position);
              if (!res.isSuccess) {
                break mainloop;
              }

              excludeSpaces = processSpacesAndAddAllToStack(res.value);
            } else {
              res = inline.run(s, position);
              if (!res.isSuccess) {
                break mainloop;
              }

              addAllToStack(res.value);
            }

            position = res.position;
          }
        }

        while (stack.length > 0) {
          mergeWithPrevious();
        }

        return _success(result, s, position);
      });
    }

    return _emphasisCache;
  }

  //
  // link and image
  //

  static final Parser<String> _linkWhitespace =
      (blankline > (whitespaceChar < skipWhitespace)) |
          (whitespaceChar < skipWhitespace);
  static final Parser<Target> _linkInline = (char('(') >
          (((_linkWhitespace.maybe > _linkInlineDestination) +
                  ((_linkWhitespace > _linkTitle).maybe <
                      _linkWhitespace.maybe)) ^
              (String a, Option<String> b) => new Target(a, b.asNullable))) <
      char(')');

  bool _isContainsLink(Inlines inlines) => inlines.any((Inline inline) {
        if (inline is Link) {
          return true;
        }
        if (inline is Emph) {
          return _isContainsLink(inline.contents);
        }
        if (inline is Strong) {
          return _isContainsLink(inline.contents);
        }
        if (inline is Image) {
          return _isContainsLink(inline.label);
        }
        return false;
      });

  static final Parser<String> _linkOrImageTestParser = char('[');
  Parser<List<Inline>> _linkOrImage(bool isLink) {
    Parser<String> labelParser = isLink ? _linkText : _imageText;
    return new Parser<List<Inline>>((String s, Position pos) {
      ParseResult<String> testRes = _linkOrImageTestParser.run(s, pos);
      if (!testRes.isSuccess) {
        return testRes;
      }

      // Try inline
      ParseResult<String> labelRes = labelParser.run(s, pos);
      if (!labelRes.isSuccess) {
        return labelRes;
      }
      if (isLink && labelRes.value.contains(new RegExp(r"^\s*$"))) {
        return _failure(s, pos);
      }
      Inlines linkInlines = inlines.parse(labelRes.value, tabStop: tabStop);
      if (isLink && _isContainsLink(linkInlines)) {
        List<Inline> resValue = [new Str('[')];
        resValue.addAll(linkInlines);
        resValue.add(new Str(']'));
        return _success(resValue, s, labelRes.position);
      }
      ParseResult<Target> destRes = _linkInline.run(s, labelRes.position);
      if (destRes.isSuccess) {
        // Links inside link content are not allowed
        return _success(
            isLink
                ? [new InlineLink(linkInlines, destRes.value)]
                : [new InlineImage(linkInlines, destRes.value)],
            s,
            destRes.position);
      }

      // Try reference link
      ParseResult<String> refRes = _linkLabel.run(s, labelRes.position);
      if (refRes.isSuccess) {
        String reference = refRes.value == "" ? labelRes.value : refRes.value;
        String normalizedReference = _normalizeReference(reference);
        Target target = _references[normalizedReference];
        if (target == null) {
          target = _options.linkResolver(normalizedReference, reference);
        }
        if (target != null) {
          return _success(
              isLink
                  ? [new ReferenceLink(reference, linkInlines, target)]
                  : [new ReferenceImage(reference, linkInlines, target)],
              s,
              refRes.position);
        }
      } else {
        // Try again from beginning because reference couldn't contain brackets
        labelRes = _linkLabel.run(s, pos);
        if (!labelRes.isSuccess) {
          return labelRes;
        }
        String normalizedReference = _normalizeReference(labelRes.value);
        Target target = _references[normalizedReference];
        if (target == null) {
          target = _options.linkResolver(normalizedReference, labelRes.value);
        }
        if (target != null) {
          return _success(
              isLink
                  ? [new ReferenceLink(labelRes.value, linkInlines, target)]
                  : [new ReferenceImage(labelRes.value, linkInlines, target)],
              s,
              labelRes.position);
        }
      }

      return _failure(s, pos);
    });
  }

  /// Parser for image inlines
  Parser<List<Inline>> get image => char('!') > _linkOrImage(false);

  /// Parser for link inlines
  Parser<List<Inline>> get link => _linkOrImage(true);

  static final RegExp _autolinkEmailRegExp = new RegExp(
      r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}"
      r"[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$");

  static final Parser<List<String>> _autolinkParser = char('<') >
      manyUntilSimple(
          pred((String char) =>
              char.codeUnitAt(0) > 0x20 && char != "<" && char != ">"),
          char('>'));

  /// Parser for autolink inlines
  static final Parser<List<Inline>> autolink =
      new Parser<List<Inline>>((String s, Position pos) {
    if (pos.offset >= s.length || s[pos.offset] != '<') {
      // Fast check
      return _failure(s, pos);
    }
    ParseResult<List<String>> res = _autolinkParser.run(s, pos);
    if (!res.isSuccess) {
      return res;
    }
    String contents = res.value.join();
    int colon = contents.indexOf(":");
    if (colon >= 2) {
      return _success([new Autolink(contents)], s, res.position);
    }

    if (contents.contains(_autolinkEmailRegExp)) {
      return _success([new Autolink.email(contents)], s, res.position);
    }

    return _failure(s, pos);
  });

  //
  // raw html
  //

  /// Parser for raw inline HTML.
  static final Parser<List<Inline>> rawInlineHtml = choiceSimple([
        _htmlOpenTag,
        _htmlCloseTag,
        _htmlCompleteComment,
        _htmlCompletePI,
        _htmlDeclaration,
        _htmlCompleteCDATA
      ]) ^
      (String result) => [new HtmlRawInline(result)];

  //
  // Line break
  //

  /// Parser for line breaks
  static final Parser<List<Inline>> lineBreak =
      (((string('  ') < skipManySimple(whitespaceChar)) < newline) |
              string("\\\n")) ^
          (_) => [new LineBreak()];

  //
  // smartPunctuation extension
  //

  /// Parser for smart punctuation (quotes processed separately)
  static final Parser<List<Inline>> smartPunctuation = (string("...") ^
          (_) => [new Ellipsis()]) |
      (char("-") > many1Simple(char("-"))) ^
          (List<String> res) {
            /*
                  From spec.

                  A sequence of more than three hyphens is
                  parsed as a sequence of em and/or en dashes,
                  with no hyphens. If possible, a homogeneous
                  sequence of dashes is used (so, 10 hyphens
                  = 5 en dashes, and 9 hyphens = 3 em dashes).
                  When a heterogeneous sequence must be used,
                  the em dashes come first, followed by the en
                  dashes, and as few en dashes as possible are
                  used (so, 7 hyphens = 2 em dashes an 1 en
                  dash).
                 */
            int len = res.length + 1;
            if (len % 3 == 0) {
              return new List<Inline>.filled(len ~/ 3, new MDash());
            }
            if (len % 2 == 0) {
              return new List<Inline>.filled(len ~/ 2, new NDash());
            }
            List<Inline> result = [];
            if (len % 3 == 2) {
              result.addAll(new List<Inline>.filled(len ~/ 3, new MDash()));
              result.add(new NDash());
            } else {
              result.addAll(new List<Inline>.filled(len ~/ 3 - 1, new MDash()));
              result.addAll([new NDash(), new NDash()]);
            }

            return result;
          };

  //
  // TeX math between `$`s or `$$`s.
  //

  static final Parser<String> _texMathSingleDollarStart =
      char(r'$').notFollowedBy(oneOf(' 0123456789\n'));
  static final Parser<String> _texMathSingleDollarContent = choice([
    string(r'\$') ^ (_) => r'$',
    (oneOf(' \n\t') < char(r'$')) ^ (String c) => c + r'$',
    anyChar
  ]);
  static final Parser<String> _texMathSingleDollarEnd = char(r'$');
  static final Parser<List<Inline>> _texMathSingleDollar =
      (_texMathSingleDollarStart >
              _texMathSingleDollarContent.manyUntil(_texMathSingleDollarEnd)) ^
          (List<String> content) => [new TexMathInline(content.join())];

  static final Parser<List<Inline>> _texMathDoubleDollar =
      (string(r'$$') > anyChar.manyUntil(string(r'$$'))) ^
          (List<String> content) => [new TexMathDisplay(content.join())];

  /// Parser for TeX math between `$`s or `$$`s.
  static final Parser<List<Inline>> texMathDollars =
      _texMathDoubleDollar | _texMathSingleDollar;

  //
  // TeX math between `\(` and `\)`, or `\[` and `\]`
  //

  static final Parser<List<Inline>> _texMathSingleBackslashParens =
      (string(r'\(') > anyChar.manyUntil(string(r'\)'))) ^
          (List<String> content) => [new TexMathInline(content.join())];
  static final Parser<List<Inline>> _texMathSingleBackslashBracket =
      (string(r'\[') > anyChar.manyUntil(string(r'\]'))) ^
          (List<String> content) => [new TexMathDisplay(content.join())];

  /// Parser for TeX math between `\(` and `\)`, or `\[` and `\]`
  static final Parser<List<Inline>> texMathSingleBackslash =
      _texMathSingleBackslashParens | _texMathSingleBackslashBracket;

  //
  // TeX math between `\\(` and `\\)`, or `\\[` and `\\]`
  //

  static final Parser<List<Inline>> _texMathDoubleBackslashParens =
      (string(r'\\(') > anyChar.manyUntil(string(r'\\)'))) ^
          (List<String> content) => [new TexMathInline(content.join())];
  static final Parser<List<Inline>> _texMathDoubleBackslashBracket =
      (string(r'\\[') > anyChar.manyUntil(string(r'\\]'))) ^
          (List<String> content) => [new TexMathDisplay(content.join())];

  /// Parser for TEX math between `\\(` and `\\)`, or `\\[` and `\\]`
  static final Parser<List<Inline>> texMathDoubleBackslash =
      _texMathDoubleBackslashParens | _texMathDoubleBackslashBracket;

  //
  // str
  //

  static final RegExp _nbspRegExp = new RegExp("\u{a0}");
  static List<Inline> _transformString(String str) {
    Match m = _nbspRegExp.firstMatch(str);
    List<Inline> result = [];
    while (m != null) {
      if (m.start > 0) {
        result.add(new Str(str.substring(0, m.start)));
      }
      result.add(new NonBreakableSpace());
      str = str.substring(m.end);
      m = _nbspRegExp.firstMatch(str);
    }
    if (str.length > 0) {
      result.add(new Str(str));
    }
    return result;
  }

  Parser<List<Inline>> _strCache;

  /// Parser for str inlines
  Parser<List<Inline>> get str {
    if (_strCache == null) {
      _strCache = choiceSimple([
        record1Many(
                noneOfSet(new Set<String>.from(_strSpecialChars)..add("\n"))) ^
            (String chars) => _transformString(chars),
        oneOfSet(_strSpecialChars) ^ (String chars) => _transformString(chars),
        char("\n").notFollowedBy(blankline) ^ (_) => [new Str("\n")]
      ]);
    }
    return _strCache;
  }

  //
  // Inline
  //

  Parser<List<Inline>> _inlineCache;

  /// Parser for any inline
  Parser<List<Inline>> get inline {
    if (_inlineCache == null) {
      List<Parser<List<Inline>>> inlineParsers = [lineBreak, whitespace];
      if (_options.texMathSingleBackslash) {
        inlineParsers.add(texMathSingleBackslash);
      }
      if (_options.texMathDoubleBackslash) {
        inlineParsers.add(texMathDoubleBackslash);
      }
      inlineParsers.addAll([
        escapedChar,
        htmlEntity,
        inlineCode,
        emphasis,
        link,
        image,
        autolink,
        rawInlineHtml
      ]);
      if (_options.smartPunctuation) {
        inlineParsers.add(smartPunctuation);
      }
      if (_options.texMathDollars) {
        inlineParsers.add(texMathDollars);
      }
      inlineParsers.add(str);
      _inlineCache = choiceSimple(inlineParsers);
    }
    return _inlineCache;
  }

  Parser<List<Inline>> _spaceEscapedInlineCache;

  /// Parser for inlines with escaped spaces (subscript, superscript)
  Parser<List<Inline>> get spaceEscapedInline {
    if (_spaceEscapedInlineCache == null) {
      _spaceEscapedInlineCache =
          (string(r'\ ') ^ (_) => [new _EscapedSpace()]) | inline;
    }
    return _spaceEscapedInlineCache;
  }

  Parser<Inlines> _inlinesCache;

  /// Parser for all inlines in block
  Parser<Inlines> get inlines {
    if (_inlinesCache == null) {
      _inlinesCache = manyUntilSimple(inline, eof) ^
          (List<List<Inline>> res) => _processParsedInlines(res);
    }
    return _inlinesCache;
  }

  //
  // Blocks
  //

  Parser<List<Block>> _blockCached;

  /// Parser for any blocks
  Parser<List<Block>> get block {
    if (_blockCached == null) {
      List<Parser<List<Block>>> blocks = [
        blanklines ^ (_) => [],
        hrule,
        list,
        codeBlockIndented,
        codeBlockFenced,
        atxHeading,
        rawHtml
      ];
      if (_options.rawTex) {
        blocks.add(rawTex);
      }
      blocks.addAll([linkReference, blockquote, paraOrSetextHeading]);
      _blockCached = choiceSimple(blocks);
    }
    return _blockCached;
  }

  Parser<List<Block>> _lazyLineBlockCache;

  /// Parser for lazy line blocks
  Parser<List<Block>> get lazyLineBlock {
    if (_lazyLineBlockCache == null) {
      List<Parser<List<Block>>> blocks = [
        blanklines ^ (_) => [],
        hrule,
        list,
        codeBlockFenced,
        atxHeading,
        rawHtml
      ];
      if (_options.rawTex) {
        blocks.add(rawTex);
      }
      blocks.addAll([linkReference, blockquote, para]);
      _lazyLineBlockCache = choiceSimple(blocks);
    }
    return _lazyLineBlockCache;
  }

  Parser<List<Block>> _listTightBlockCache;

  /// Parser for tight list blocks
  Parser<List<Block>> get listTightBlock {
    if (_listTightBlockCache == null) {
      List<Parser<List<Block>>> blocks = [
        hrule,
        codeBlockIndented,
        codeBlockFenced,
        atxHeading,
        rawHtml
      ];
      if (_options.rawTex) {
        blocks.add(rawTex);
      }
      blocks.addAll([linkReference, blockquote, paraOrSetextHeading]);
      _listTightBlockCache = choiceSimple(blocks);
    }
    return _listTightBlockCache;
  }

  //
  // Horizontal rule
  //

  static Map<String, Parser<List<Block>>> _hruleParserCache = {};
  static Parser<List<Block>> _hruleParser(String start) {
    if (_hruleParserCache[start] == null) {
      _hruleParserCache[start] = ((((count(2, skipWhitespace > char(start)) >
                      skipManySimple(whitespaceChar | char(start))) >
                  newline) >
              blanklines.maybe) >
          success([new HorizontalRule()]));
    }
    return _hruleParserCache[start];
  }

  static final Parser<String> _hruleStartParser =
      (_skipNonindentCharsFromAnyPosition > oneOf3('*', '-', '_'));

  /// Parser for HRule blocks
  static final Parser<List<Block>> hrule =
      new Parser<List<Block>>((String s, Position pos) {
    ParseResult<String> startRes = _hruleStartParser.run(s, pos);
    if (!startRes.isSuccess) {
      return startRes;
    }

    return _hruleParser(startRes.value).run(s, startRes.position);
  });

  //
  // ATX Heading
  //

  static final Parser<List<String>> _atxHeadingStartParser =
      _skipNonindentChars > many1Simple(char('#'));
  static final Parser<String> _atxHeadingEmptyParser =
      ((whitespaceChar > skipWhitespace) >
              (skipManySimple(char('#')) > blankline)) |
          (newline ^ (_) => null);
  static final Parser<List<String>> _atxHeadingRegularParser = ((space >
              skipSpaces) >
          manyUntilSimple(escapedChar.record | anyChar,
              (string(' #') > skipManySimple(char('#'))).maybe > blankline)) |
      (newline ^ (_) => []);

  /// Parser for ATX heading blocks
  static final Parser<List<Block>> atxHeading =
      new Parser<List<Block>>((String s, Position pos) {
    ParseResult<List<String>> startRes = _atxHeadingStartParser.run(s, pos);
    if (!startRes.isSuccess) {
      return startRes;
    }
    int level = startRes.value.length;
    if (level > 6) {
      return _failure(s, pos);
    }

    // Try empty
    ParseResult<String> textRes =
        _atxHeadingEmptyParser.run(s, startRes.position);
    if (textRes.isSuccess) {
      return _success([new AtxHeading(level, new _UnparsedInlines(''))], s,
          textRes.position);
    }
    ParseResult<List<String>> textRes2 =
        _atxHeadingRegularParser.run(s, startRes.position);
    if (!textRes2.isSuccess) {
      return textRes2;
    }
    String raw = textRes2.value.join();
    _UnparsedInlines inlines = new _UnparsedInlines(raw.trim());
    return _success([new AtxHeading(level, inlines)], s, textRes2.position);
  });

  //
  // Indented code
  //

  static final Parser<String> _indentedLine =
      (indent > anyLine) ^ (String line) => line + "\n";

  /// Parser for indented code blocks
  static final Parser<List<Block>> codeBlockIndented = (_indentedLine +
          (manySimple(_indentedLine |
              (blanklines + _indentedLine) ^
                  (List<String> b, String l) => b.join('') + l))) ^
      (String f, List<String> c) => [
            new IndentedCodeBlock(_stripTrailingNewlines(f + c.join('')) + '\n')
          ];

  //
  // Fenced code
  //

  static final Parser<List<dynamic>> _openFenceStartParser =
      (_skipNonindentCharsFromAnyPosition + (string('~~~') | string('```')))
          .list;
  static Parser<List<String>> _openFenceInfoStringParser(String fenceChar) =>
      ((skipWhitespace >
              manySimple(choiceSimple([
                noneOfSet(
                    new Set<String>.from(["&", "\n", "\\", " ", fenceChar])),
                _escapedChar1,
                _htmlEntity1,
                oneOf2('&', '\\')
              ]))) <
          skipManySimple(noneOf2("\n", fenceChar))) <
      newline;
  static Parser<List<List<String>>> _openFenceTopFenceParser(
          String fenceChar) =>
      (manySimple(char(fenceChar)) + _openFenceInfoStringParser(fenceChar))
          .list;
  static final Parser<List<List<String>>> _openFenceTildeTopFenceParser =
      _openFenceTopFenceParser('~');
  static final Parser<List<List<String>>> _openFenceBacktickTopFenceParser =
      _openFenceTopFenceParser('`');
  // TODO special record class for openFence results
  static final Parser<List<dynamic>> _openFence =
      new Parser<List<dynamic>>((String s, Position pos) {
    ParseResult<List<dynamic>> fenceStartRes =
        _openFenceStartParser.run(s, pos);
    if (!fenceStartRes.isSuccess) {
      return fenceStartRes;
    }
    int indent = fenceStartRes.value[0];
    String fenceChar = fenceStartRes.value[1][0];
    Parser<List<List<String>>> topFenceParser = fenceChar == '~'
        ? _openFenceTildeTopFenceParser
        : _openFenceBacktickTopFenceParser;
    ParseResult<List<List<String>>> topFenceRes =
        topFenceParser.run(s, fenceStartRes.position);
    if (!topFenceRes.isSuccess) {
      return topFenceRes;
    }

    int fenceSize = topFenceRes.value[0].length + 3;
    String infoString = topFenceRes.value[1].join();
    return _success(
        [indent, fenceChar, fenceSize, infoString], s, topFenceRes.position);
  });

  /// Parser for fenced code blocks
  static final Parser<List<Block>> codeBlockFenced =
      new Parser<List<Block>>((String s, Position pos) {
    ParseResult<List<dynamic>> openFenceRes = _openFence.run(s, pos);
    if (!openFenceRes.isSuccess) {
      return openFenceRes;
    }
    int indent = openFenceRes.value[0] + pos.character - 1;
    String fenceChar = openFenceRes.value[1];
    int fenceSize = openFenceRes.value[2];
    String infoString = openFenceRes.value[3];

    FenceType fenceType = FenceType.backtick;
    if (fenceChar == '~') {
      fenceType = FenceType.tilde;
    }

    Parser<String> lineParser = anyLine;
    if (indent > 0) {
      lineParser = atMostIndent(indent) > lineParser;
    }
    // TODO extract creation
    Parser<String> endFenceParser =
        (((_skipNonindentChars > string(fenceChar * fenceSize)) >
                    skipManySimple(char(fenceChar))) >
                skipWhitespace) >
            newline;
    Parser<List<Block>> restParser =
        manyUntilSimple(lineParser, endFenceParser | eof) ^
            (List<String> lines) => [
                  new FencedCodeBlock(lines.map((String i) => i + '\n').join(),
                      fenceType: fenceType,
                      fenceSize: fenceSize,
                      attributes: new InfoString(infoString))
                ];

    return restParser.run(s, openFenceRes.position);
  });

  //
  // Raw html block
  //

  static final List<Map<String, Pattern>> _rawHtmlTests = [
    {
      // <script>, <pre> or <style>
      "start": new RegExp(r'^(script|pre|style)( |>|$)',
          caseSensitive: false), // TODO \t
      "end": new RegExp(r'</(script|pre|style)>', caseSensitive: false)
    },
    {
      // <!-- ... -->
      "start": new RegExp(r'^!--'),
      "end": "-->"
    },
    {
      // <? ... ?>
      "start": new RegExp(r'^\?'),
      "end": "?>"
    },
    {
      // <!... >
      "start": new RegExp(r'^![A-Z]'),
      "end": ">"
    },
    {
      // <![CDATA[
      "start": new RegExp(r'^!\[CDATA\['),
      "end": "]]>"
    }
  ];
  static final Pattern _rawHtmlTest6 =
      new RegExp(r'^/?([a-zA-Z]+)( |>|$)'); // TODO \t

  static final Parser<int> _rawHtmlParagraphStopTestSimple =
      _skipNonindentChars < char('<');
  static final Parser<bool> _rawHtmlParagraphStopTest =
      new Parser<bool>((String s, Position pos) {
    // Simple test
    ParseResult<int> testRes = _rawHtmlParagraphStopTestSimple.run(s, pos);
    if (!testRes.isSuccess) {
      return testRes;
    }

    ParseResult<String> lineRes = anyLine.run(s, testRes.position);
    assert(lineRes.isSuccess);
    Map<String, Pattern> passedTest =
        _rawHtmlTests.firstWhere((Map<String, Pattern> element) {
      return lineRes.value.contains(element['start']);
    }, orElse: () => null);
    if (passedTest != null) {
      return _success(true, s, pos);
    }

    Match match = _rawHtmlTest6.matchAsPrefix(lineRes.value);
    if (match != null && _allowedTags.contains(match.group(1).toLowerCase())) {
      return _success(true, s, pos);
    }

    return _failure(s, pos);
  });

  static final Parser<String> _rawHtmlTest =
      (_skipNonindentChars < char('<')).record;
  static final Parser<String> _rawHtmlRule7Parser =
      ((_skipNonindentChars < (_htmlOpenTag | _htmlCloseTag)) < blankline)
          .record;

  /// Parser for raw HTML blocks
  static final Parser<List<Block>> rawHtml =
      new Parser<List<Block>>((String s, Position pos) {
    // Simple test
    ParseResult<String> testRes = _rawHtmlTest.run(s, pos);
    if (!testRes.isSuccess) {
      return testRes;
    }

    String content = testRes.value;

    ParseResult<String> lineRes = anyLine.run(s, testRes.position);
    assert(lineRes.isSuccess);
    Map<String, Pattern> passedTest =
        _rawHtmlTests.firstWhere((Map<String, Pattern> element) {
      return lineRes.value.contains(element['start']);
    }, orElse: () => null);
    if (passedTest != null) {
      // Got it
      content += lineRes.value + '\n';
      Position position = lineRes.position;
      while (!lineRes.value.contains(passedTest['end'])) {
        lineRes = anyLine.run(s, position);
        if (!lineRes.isSuccess) {
          // eof
          return _success([new HtmlRawBlock(content)], s, position);
        }
        content += lineRes.value + '\n';
        position = lineRes.position;
      }
      return _success([new HtmlRawBlock(content)], s, position);
    }

    Match match = _rawHtmlTest6.matchAsPrefix(lineRes.value);
    Position position;
    if (match == null || !_allowedTags.contains(match.group(1).toLowerCase())) {
      // Trying rule 7

      ParseResult<String> rule7Res = _rawHtmlRule7Parser.run(s, pos);
      if (!rule7Res.isSuccess ||
          rule7Res.value.indexOf('\n') != rule7Res.value.length - 1) {
        // There could be only one \n, and it's in the end.
        return _failure(s, pos);
      }

      content = rule7Res.value;
      position = rule7Res.position;
    } else {
      content += lineRes.value + '\n';
      position = lineRes.position;
    }

    do {
      ParseResult<String> blanklineRes = blankline.run(s, position);
      if (blanklineRes.isSuccess) {
        return _success([new HtmlRawBlock(content)], s, blanklineRes.position);
      }
      lineRes = anyLine.run(s, position);
      if (!lineRes.isSuccess) {
        // eof
        return _success([new HtmlRawBlock(content)], s, position);
      }
      content += lineRes.value + '\n';
      position = lineRes.position;
    } while (true);
  });

  //
  // Raw TeX blocks
  //

  static final Set<String> _texEnvironmentChars =
      new Set<String>.from(_alphanum)..addAll(['_', '-', '+', '*']);
  static final Parser<String> _rawTexStart =
      (((_skipNonindentChars > string(r'\begin{')) >
                  many1Simple(oneOfSet(_texEnvironmentChars))) <
              char('}')) ^
          (List<String> env) => env.join();
  static Parser<String> _rawTexEnd(String env) =>
      ((_skipNonindentChars > string(r'\end{' + env + '}')) < blankline).record;

  /// Parser for raw TeX blocks
  static final Parser<List<Block>> rawTex =
      new Parser<List<Block>>((String s, Position pos) {
    ParseResult<String> startRes = _rawTexStart.run(s, pos);
    if (!startRes.isSuccess) {
      return startRes;
    }
    String env = startRes.value;

    ParseResult<String> lineRes = anyLine.run(s, pos);
    assert(lineRes.isSuccess);
    String contents = lineRes.value + '\n';
    Position position = lineRes.position;
    Parser<String> endParser = _rawTexEnd(env);
    do {
      ParseResult<String> endRes = endParser.run(s, position);
      if (endRes.isSuccess) {
        contents += endRes.value + '\n';
        return _success([new TexRawBlock(contents)], s, endRes.position);
      }
      lineRes = anyLine.run(s, position);
      if (!lineRes.isSuccess) {
        // eof
        return _failure(s, pos);
      }
      contents += lineRes.value + '\n';
      position = lineRes.position;
    } while (true);
  });

  //
  // Link reference
  //

  static final Parser<String> _linkReferenceLabelParser =
      (_skipNonindentChars > _linkLabel) < char(':');
  static final Parser<String> _linkReferenceDestinationParser =
      (blankline.maybe > skipWhitespace) > _linkBlockDestination;
  static final Parser<String> _linkReferenceTitleParser =
      (skipWhitespace > _linkTitle) < blankline;

  /// Parser for link reference block
  static final Parser<_LinkReference> linkReference =
      new Parser<_LinkReference>((String s, Position pos) {
    ParseResult<String> labelRes = _linkReferenceLabelParser.run(s, pos);
    if (!labelRes.isSuccess) {
      return labelRes;
    }
    ParseResult<String> destinationRes =
        _linkReferenceDestinationParser.run(s, labelRes.position);
    if (!destinationRes.isSuccess) {
      return destinationRes;
    }
    ParseResult<Option<String>> blanklineRes =
        blankline.maybe.run(s, destinationRes.position);
    assert(blanklineRes.isSuccess);
    ParseResult<String> titleRes =
        _linkReferenceTitleParser.run(s, blanklineRes.position);

    _LinkReference value;
    ParseResult<dynamic> res;
    if (!titleRes.isSuccess) {
      if (blanklineRes.value.isDefined) {
        value = new _LinkReference(
            labelRes.value, new Target(destinationRes.value, null));
        res = blanklineRes;
      } else {
        return _failure(s, pos);
      }
    } else {
      value = new _LinkReference(
          labelRes.value, new Target(destinationRes.value, titleRes.value));
      res = titleRes;
    }

    // Reference couldn't be empty
    if (value.reference.contains(new RegExp(r"^\s*$"))) {
      return _failure(s, pos);
    }
    return _success(value, s, res.position);
  });

  //
  // Paragraph and setext heading
  //

  static final Parser<List<String>> _setextHeadingLine = (_skipNonindentChars >
          (many1Simple(char('=')) | many1Simple(char('-')))) <
      blankline;
  static final Parser<dynamic> _paraFirstLineParser = choiceSimple([
    blankline,
    hrule,
    _listMarkerTest(4),
    atxHeading,
    _openFence,
    _rawHtmlParagraphStopTest,
    _skipNonindentChars >
        choiceSimple([
          char('>'),
          (oneOf3('+', '-', '*') > whitespaceChar),
          ((countBetween(1, 9, digit) > oneOf2('.', ')')) > whitespaceChar)
        ])
  ]);
  static final Parser<dynamic> _paraEndParser = choiceSimple([
    blankline,
    hrule,
    _listMarkerTest(4),
    atxHeading,
    _openFence,
    _rawHtmlParagraphStopTest,
    _setextHeadingLine,
    _skipNonindentChars >
        choiceSimple([
          char('>'),
          (oneOf3('+', '-', '*') > whitespaceChar),
          ((countBetween(1, 9, digit) > oneOf2('.', ')')) > whitespaceChar)
        ])
  ]);
  static final Parser<List<String>> _paraOrSetextParser =
      (_paraFirstLineParser.notAhead > anyLine) +
              manySimple(_paraEndParser.notAhead > anyLine) ^
          (String a, List<String> b) {
            b.insert(0, a);
            return b;
          };

  /// Parser for paragraph or Setext
  static final Parser<List<Block>> paraOrSetextHeading =
      new Parser<List<Block>>((String s, Position pos) {
    ParseResult<List<String>> res = _paraOrSetextParser.run(s, pos);
    if (!res.isSuccess) {
      return res;
    }

    _UnparsedInlines inlines =
        new _UnparsedInlines(res.value.join("\n").trim());

    // Test setext
    ParseResult<List<String>> setextRes =
        _setextHeadingLine.run(s, res.position);
    if (setextRes.isSuccess) {
      return _success(
          [new SetextHeading(setextRes.value[0] == '=' ? 1 : 2, inlines)],
          s,
          setextRes.position);
    }

    return _success([new Para(inlines)], s, res.position);
  });

  static final Parser<List<String>> _paraParser =
      manySimple(_paraFirstLineParser.notAhead > anyLine);

  /// Parser for para blocks
  static final Parser<List<Block>> para =
      new Parser<List<Block>>((String s, Position pos) {
    ParseResult<List<String>> res = _paraParser.run(s, pos);
    if (!res.isSuccess) {
      return res;
    }

    _UnparsedInlines inlines =
        new _UnparsedInlines(res.value.join("\n").trim());

    return _success([new Para(inlines)], s, res.position);
  });

  //
  // Lazy line aux function
  //

  /// Trying to add current line as lazy to nested list blocks.
  ///
  /// Returns `true` when line was accepted.
  static bool _acceptLazy(Iterable<Block> blocks, String s) {
    if (blocks.length > 0) {
      if (blocks.last is Para) {
        Para last = blocks.last;
        _UnparsedInlines inlines = last.contents;
        inlines.raw += "\n" + s;
        return true;
      } else if (blocks.last is Blockquote) {
        Blockquote last = blocks.last;
        return _acceptLazy(last.contents, s);
      } else if (blocks.last is ListBlock) {
        ListBlock last = blocks.last;
        return _acceptLazy(last.items.last.contents, s);
      }
    }

    return false;
  }

  //
  // Blockquote
  //

  static final Parser<String> _blockquoteStrictLine =
      ((_skipNonindentChars > char('>')) > whitespaceChar.maybe) >
          anyLine; // TODO check tab
  // TODO special record class for blockquoteLine
  static final Parser<List<dynamic>> _blockquoteLine =
      (_blockquoteStrictLine ^ (String l) => [true, l]) |
          (anyLine ^ (String l) => [false, l]);

  Parser<List<Block>> _blockquoteCache;

  /// Parser for blockquote blocks
  Parser<List<Block>> get blockquote {
    if (_blockquoteCache == null) {
      _blockquoteCache = new Parser<List<Block>>((String s, Position pos) {
        ParseResult<String> firstLineRes = _blockquoteStrictLine.run(s, pos);
        if (!firstLineRes.isSuccess) {
          return firstLineRes;
        }
        List<String> buffer = [firstLineRes.value];
        List<Block> blocks = [];

        bool closeParagraph = false;

        void buildBuffer() {
          String s = buffer.map((String l) => l + "\n").join();
          List<Block> innerRes = (manyUntilSimple(block, eof) ^
                  (List<List<Block>> res) => _processParsedBlocks(res))
              .parse(s, tabStop: tabStop);
          if (!closeParagraph &&
              innerRes.length > 0 &&
              innerRes.first is Para) {
            Para first = innerRes.first;
            _UnparsedInlines inlines = first.contents;
            if (_acceptLazy(blocks, inlines.raw)) {
              innerRes.removeAt(0);
            }
          }
          if (innerRes.length > 0) {
            blocks.addAll(innerRes);
          }
          buffer = [];
        }

        Position position = firstLineRes.position;
        while (true) {
          ParseResult<List<dynamic>> res = _blockquoteLine.run(s, position);
          if (!res.isSuccess) {
            break;
          }
          bool isStrict = res.value[0];
          String line = res.value[1];
          if (isStrict) {
            closeParagraph = line.trim() == "";
            buffer.add(line);
          } else {
            if (buffer.length > 0) {
              buildBuffer();
            }
            List<Block> lineBlock =
                lazyLineBlock.parse(line + "\n", tabStop: tabStop);
            if (!closeParagraph &&
                lineBlock.length == 1 &&
                lineBlock[0] is Para) {
              Para block = lineBlock[0];
              _UnparsedInlines inlines = block.contents;
              if (!_acceptLazy(blocks, inlines.raw)) {
                break;
              }
            } else {
              break;
            }
          }
          position = res.position;
        }

        if (buffer.length > 0) {
          buildBuffer();
        }

        return _success([new Blockquote(blocks)], s, position);
      });
    }

    return _blockquoteCache;
  }

  //
  // Lists
  //

  static const int _listTypeOrdered = 0;
  static const int _listTypeUnordered = 1;

  /// Parser for ordered list marker
  static ParserAccumulator3 _orderedListMarkerTest(int indent) =>
      _skipListIndentChars(indent) +
      countBetween(1, 9, digit) + // 1-9 digits
      oneOf2('.', ')');

  /// Parser for unordered list marker
  static ParserAccumulator2 _unorderedListMarkerTest(int indent) =>
      _skipListIndentChars(indent).notFollowedBy(hrule) + oneOf3('-', '+', '*');

  /// Parser for list marker
  static Parser<List<dynamic>> _listMarkerTest(int indent) =>
      (((_orderedListMarkerTest(indent) ^
                      (int sp, List<dynamic> d, String c) =>
                          [_listTypeOrdered, sp, d, c]) |
                  (_unorderedListMarkerTest(indent) ^
                      (int sp, String c) => [_listTypeUnordered, sp, c])) +
              choiceSimple([
                char("\n"),
                countBetween(1, 4, char(' ')).notFollowedBy(char(' ')),
                oneOf2(' ', '\t')
              ]))
          .list;

  Parser<List<Block>> _listCache;

  /// Parser for list blocks
  Parser<List<Block>> get list {
    if (_listCache == null) {
      _listCache = new Parser<List<Block>>((String s, Position pos) {
        List<_ListStackItem> stack = [];

        int getSubIndent() => stack.length > 0 ? stack.last.subIndent : 0;
        int getIndent() => stack.length > 0 ? stack.last.indent : 0;
        bool getTight() => stack.length > 0 ? stack.last.block.tight : true;
        void setTight(bool tight) {
          if (stack.length > 0) {
            stack.last.block.tight = tight;
          }
        }

        /// Is previous parsed line was empty?
        bool afterEmptyLine = false;
        bool markerOnSaparateLine = false;
        List<Block> blocks = [];
        List<String> buffer = [];
        void buildBuffer() {
          String s = buffer.map((String l) => l + "\n").join();
          List<Block> innerBlocks;
          if (s == "\n" && blocks.length == 0) {
            // Test for empty items
            blocks = [];
            buffer = [];
            return;
          }
          if (getTight()) {
            // TODO extract parser
            ParseResult<List<Block>> innerRes =
                (manyUntilSimple(listTightBlock, eof) ^
                        (Iterable<dynamic> res) => _processParsedBlocks(res))
                    .run(s);
            if (innerRes.isSuccess) {
              innerBlocks = innerRes.value;
            } else {
              setTight(false);
            }
          }

          if (!getTight()) {
            innerBlocks = (manyUntilSimple(block, eof) ^
                    (Iterable<dynamic> res) => _processParsedBlocks(res))
                .parse(s, tabStop: tabStop);
          }
          if (!afterEmptyLine &&
              innerBlocks.length > 0 &&
              innerBlocks.first is Para) {
            Para para = innerBlocks.first;
            _UnparsedInlines inlines = para.contents;
            if (_acceptLazy(blocks, inlines.raw)) {
              innerBlocks.removeAt(0);
            }
          }
          if (innerBlocks.length > 0) {
            blocks.addAll(innerBlocks);
          }
          buffer = [];
        }

        void addToListItem(ListItem item, Iterable<Block> c) {
          if (item.contents is List<Block>) {
            List<Block> contents = item.contents;
            contents.addAll(c);
            return;
          }
          List<Block> contents = new List<Block>.from(item.contents);
          contents.addAll(c);
          item.contents = contents;
        }

        bool addListItem(int type,
            {IndexSeparator indexSeparator, BulletType bulletType}) {
          bool success = false;
          if (stack.length == 0) {
            return false;
          }
          ListBlock block = stack.last.block;
          if (type == _listTypeOrdered &&
              block is OrderedList &&
              block.indexSeparator == indexSeparator) {
            success = true;
          }
          if (type == _listTypeUnordered &&
              block is UnorderedList &&
              block.bulletType == bulletType) {
            success = true;
          }
          if (success) {
            if (afterEmptyLine) {
              setTight(false);
              afterEmptyLine = false;
            }
            buildBuffer();
            addToListItem(block.items.last, blocks);
            blocks = [];
            if (block.items is List<ListItem>) {
              List<ListItem> items = block.items;
              items.add(new ListItem([]));
            } else {
              List<ListItem> list = new List<ListItem>.from(block.items);
              list.add(new ListItem([]));
              block.items = list;
            }
          }
          return success;
        }

        Position getNewPositionAfterListMarker(ParseResult<List<dynamic>> res) {
          if (res.value[1] == "\n" || res.value[1].length <= 4) {
            return res.position;
          } else {
            int diff = res.value[1].length - 1;
            return new Position(res.position.offset - diff, res.position.line,
                res.position.character - diff,
                tabStop: tabStop);
          }
        }

        /// Current parsing position
        Position position = pos; // Current parsing position

        /// Will list item nested inside current?
        bool nextLevel = true;

        // TODO Split loop to smaller parts
        while (true) {
          bool closeListItem = false;
          ParseResult<dynamic> eofRes = eof.run(s, position);
          if (eofRes.isSuccess) {
            // End of input reached
            break;
          }

          // If we at the line start and there's only spaces left then applying new line rules
          if (position.character == 1) {
            ParseResult<String> blanklineRes = blankline.run(s, position);
            if (blanklineRes.isSuccess) {
              if (afterEmptyLine) {
                // It's second new line. Closing all lists.
                break;
              }
              afterEmptyLine = true;
              position = blanklineRes.position;
              continue;
            }
          }

          // Parsing from line start
          if (position.character == 1 && getSubIndent() > 0) {
            // Waiting for indent
            ParseResult<int> indentRes =
                _waitForIndent(getSubIndent()).run(s, position);
            if (indentRes.isSuccess) {
              position = indentRes.position;
              s = indentRes.text; // We've probably updated text
              nextLevel = true;
            } else {
              // Trying lazy line
              if (!afterEmptyLine) {
                // Lazy line couldn't appear after empty line
                if (buffer.length > 0) {
                  buildBuffer();
                }

                ParseResult<String> lineRes = anyLine.run(s, position);
                assert(lineRes.isSuccess);
                List<Block> lineBlock = block
                    .parse(lineRes.value.trimLeft() + "\n", tabStop: tabStop);
                if (lineBlock.length == 1 && lineBlock[0] is Para) {
                  Para para = lineBlock[0];
                  _UnparsedInlines inlines = para.contents;
                  if (_acceptLazy(blocks, inlines.raw)) {
                    position = lineRes.position;
                    continue;
                  }
                }
              }

              if (buffer.length > 0 || blocks.length > 0) {
                buildBuffer();
                addToListItem(stack.last.block.items.last, blocks);
                blocks = [];
              }

              // Closing all nested lists until we found one with enough indent to accept current line
              nextLevel = false;
              while (stack.length > 1) {
                ParseResult<int> indentRes =
                    _waitForIndent(getIndent()).run(s, position);
                if (indentRes.isSuccess) {
                  position = indentRes.position;
                  s = indentRes.text;
                  closeListItem = true;
                  break;
                }
                stack.last.block.tight = getTight();
                stack.removeLast();
              }
            }
          }

          // Trying to find new list item

          ParseResult<List<dynamic>> markerRes =
              _listMarkerTest(getIndent() + tabStop).run(s, position);
          if (markerRes.isSuccess) {
            markerOnSaparateLine = false;
            int type = markerRes.value[0][0];
            IndexSeparator indexSeparator = (type == _listTypeOrdered
                ? IndexSeparator.fromChar(markerRes.value[0][3])
                : null);
            int startIndex = type == _listTypeOrdered
                ? int.parse(markerRes.value[0][2].join(), onError: (_) => 1)
                : 1;
            BulletType bulletType = (type == _listTypeUnordered
                ? BulletType.fromChar(markerRes.value[0][2])
                : null);

            // It's a new list item on same level
            if (!nextLevel) {
              bool addSuccess = addListItem(type,
                  indexSeparator: indexSeparator, bulletType: bulletType);
              if (!addSuccess) {
                if (stack.length == 1) {
                  // It's a new list on top level. Stopping here
                  break;
                }
                // New list on same level, so we a closing previous one.
                stack.removeLast();
              } else {
                int subIndent = markerRes.position.character - 1;
                if (markerRes.value[1] == "\n") {
                  markerOnSaparateLine = true;
                  subIndent = position.character +
                      markerRes.value[0][1] +
                      1; // marker + space after marker - char
                  if (type == _listTypeOrdered) {
                    subIndent += markerRes.value[0][2].length;
                  }
                }
                stack.last.indent =
                    position.character + markerRes.value[0][1] - 1;
                stack.last.subIndent = getIndent() + subIndent;

                position = getNewPositionAfterListMarker(markerRes);
                continue;
              }
            }

            // Flush buffer
            if (stack.length > 0 && (buffer.length > 0 || blocks.length > 0)) {
              if (afterEmptyLine) {
                setTight(false);
                afterEmptyLine = false;
              }
              buildBuffer();
              addToListItem(stack.last.block.items.last, blocks);
              blocks = [];
            }

            // Ok, it's a new list on new level.
            ListBlock newListBlock;
            int subIndent = markerRes.position.character - 1;
            if (markerRes.value[1] == "\n") {
              markerOnSaparateLine = true;
              subIndent = position.character +
                  markerRes.value[0][1] +
                  1; // marker + space after marker - char
              if (type == _listTypeOrdered) {
                subIndent += markerRes.value[0][2].length;
              }
            }
            if (type == _listTypeOrdered) {
              newListBlock = new OrderedList([new ListItem([])],
                  tight: true,
                  indexSeparator: indexSeparator,
                  startIndex: startIndex);
              //subIndent += markerRes.value[0][2].length;
            } else {
              newListBlock = new UnorderedList([new ListItem([])],
                  tight: true, bulletType: bulletType);
            }

            if (stack.length > 0) {
              addToListItem(stack.last.block.items.last, [newListBlock]);
            }

            int indent = getSubIndent();
            stack.add(new _ListStackItem(indent, subIndent, newListBlock));
            position = getNewPositionAfterListMarker(markerRes);
            nextLevel = true;
            continue;
          } else if (stack.length == 0) {
            // That was first marker test and it's failed. Return with fail.
            return markerRes;
          }

          if (closeListItem) {
            stack.last.block.tight = getTight();
            if (stack.length > 1) {
              stack.removeLast();
            } else {
              break;
            }
          }

          if (position.character > 1) {
            // Fenced code block requires special treatment.
            ParseResult<List<dynamic>> openFenceRes =
                _openFence.run(s, position);
            if (openFenceRes.isSuccess) {
              if (buffer.length > 0) {
                buildBuffer();
              }

              int indent = openFenceRes.value[0] + position.character - 1;
              String fenceChar = openFenceRes.value[1];
              int fenceSize = openFenceRes.value[2];
              String infoString = openFenceRes.value[3];

              FenceType fenceType = FenceType.backtick;
              if (fenceChar == '~') {
                fenceType = FenceType.tilde;
              }

              position = openFenceRes.position;

              Parser<int> indentParser = _waitForIndent(indent);
              Parser<String> endFenceParser =
                  (((skipWhitespace > string(fenceChar * fenceSize)) >
                              skipManySimple(char(fenceChar))) >
                          skipWhitespace) >
                      newline;
              Parser<String> lineParser = anyLine;

              List<String> code = [];
              while (true) {
                ParseResult<dynamic> eofRes = eof.run(s, position);
                if (eofRes.isSuccess) {
                  break;
                }

                ParseResult<String> blanklineRes = blankline.run(s, position);
                if (blanklineRes.isSuccess) {
                  position = blanklineRes.position;
                  code.add("");
                  continue;
                }

                ParseResult<int> indentRes = indentParser.run(s, position);
                if (!indentRes.isSuccess) {
                  break;
                }
                position = indentRes.position;
                s = indentRes.text;

                ParseResult<String> endFenceRes =
                    endFenceParser.run(s, position);
                if (endFenceRes.isSuccess) {
                  position = endFenceRes.position;
                  break;
                }

                ParseResult<String> lineRes = lineParser.run(s, position);
                if (!lineRes.isSuccess) {
                  break;
                }
                code.add(lineRes.value);
                position = lineRes.position;
              }

              blocks.add(new FencedCodeBlock(
                  code.map((String i) => i + '\n').join(),
                  fenceType: fenceType,
                  fenceSize: fenceSize,
                  attributes: new InfoString(infoString)));
              afterEmptyLine = false;
              continue;
            }

            if (markerOnSaparateLine && afterEmptyLine) {
              // A list item can begin with at most one blank line.
              break;
            }

            // Strict line
            ParseResult<String> lineRes = anyLine.run(s, position);
            assert(lineRes.isSuccess);
            if (afterEmptyLine) {
              buffer.add("");
              afterEmptyLine = false;
            }
            buffer.add(lineRes.value);
            position = lineRes.position;
          } else {
            break;
          }
        }

        // End
        if (stack.length > 0) {
          if (buffer.length > 0 || blocks.length > 0) {
            buildBuffer();
            addToListItem(stack.last.block.items.last, blocks);
          }

          return _success([stack.first.block], s, position);
        } else {
          return _failure(s, pos);
        }
      });
    }

    return _listCache;
  }

  //
  // Document
  //

  /// Main document parser
  Parser<Document> get document => (manyUntilSimple(block, eof) ^
      (Iterable<dynamic> res) => new Document(_processParsedBlocks(res)));

  /// Predefined markdown parser with CommonMark default settings
  static final CommonMarkParser commonmark =
      new CommonMarkParser(Options.commonmark);

  /// Predefined markdown parser with default settings
  static final CommonMarkParser defaults =
      new CommonMarkParser(Options.defaults);

  /// Predefined markdown parser with strict settings
  static final CommonMarkParser strict = new CommonMarkParser(Options.strict);
}
