library md_proc;

import 'src/html_writer.dart';
import 'src/markdown_parser.dart';

export 'src/definitions.dart';
export 'src/markdown_parser.dart';
export 'src/html_writer.dart';

/**
 * Converts markdown string to html string.
 */
String markdownToHtml(String markdown) {
  return HtmlWriter.DEFAULT.write(CommonMarkParser.DEFAULT.parse(markdown));
}