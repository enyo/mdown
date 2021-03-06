library mdown.generators.entities_generator;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'entities.dart';

/// Generator for entities file
class EntitiesGenerator extends GeneratorForAnnotation<Entities> {
  /// Constructor
  const EntitiesGenerator();

  @override
  Future<String> generateForAnnotatedElement(
      Element element, Entities annotation, BuildStep buildStep) async {
    final RegExp r = new RegExp(r"^&(.*);$");
    final HttpClient client = new HttpClient();
    final HttpClientRequest request =
        await client.getUrl(Uri.parse(annotation.url));
    final HttpClientResponse response = await request.close();
    final dynamic json =
        await response.transform(UTF8.decoder).transform(JSON.decoder).first;
    String result =
        'final Map<String, String> _\$${element.displayName} = new HashMap<String, String>.from(<String, String>{\n';
    json.forEach((String k, dynamic v) {
      final Match match = r.firstMatch(k);
      if (match != null) {
        final String entity = match.group(1);
        if (entity == "dollar") {
          result += '  "$entity": "\\\$",';
        } else {
          result += '  "$entity": ${JSON.encode(v['characters'])},';
        }
      }
    });
    result += '});';

    return result;
  }
}
