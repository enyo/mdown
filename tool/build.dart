library mdown.tool.build;

import 'dart:async';
import 'package:source_gen/source_gen.dart';
import 'package:build_runner/build_runner.dart';
import 'package:mdown/generators/embed_tests_generator.dart';
import 'package:mdown/generators/embed_blns_tests_generator.dart';

final PhaseGroup _phases = new PhaseGroup.singleAction(
    new GeneratorBuilder(const <Generator>[
      const EmbedTestsGenerator(),
      const EmbedBlnsTestsGenerator(),
    ]),
    new InputSet('mdown', const <String>['test/data/test_data.dart']));

/// Main method for generated code builder.
Future<dynamic> main(List<String> args) async {
  await build(_phases, deleteFilesByDefault: true);
}
