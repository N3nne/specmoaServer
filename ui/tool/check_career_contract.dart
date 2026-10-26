import 'dart:convert';
import 'dart:io';

import 'package:specmoa_zip_ui/models/career_data.dart';
import 'package:specmoa_zip_ui/models/user_spec.dart';

// Consumes only the synthetic HTTP export from the isolated PostgreSQL test.
Future<void> main(List<String> args) async {
  if (args.length != 1) {
    throw ArgumentError('Pass the isolated career-contract.json fixture path.');
  }
  final raw = jsonDecode(await File(args.single).readAsString())
      as Map<String, dynamic>;
  _require(raw['source'] == 'isolated-postgres-http-fixture');
  final catalog = CareerOccupationCatalog.fromJson(_object(raw['catalog']));
  final preferences = CareerPreferences.fromJson(_object(raw['preferences']));
  final context = CareerAnalysisContext.fromJson(_object(raw['context']));
  final empty = CareerAnalysisContext.fromJson(_object(raw['emptyContext']));
  final afterDelete =
      CareerAnalysisContext.fromJson(_object(raw['afterDelete']));
  _require(catalog.items.length == 10 && context.totalSpecs == 8);
  _require(context.byType.every((group) => group.total == 1));
  _require(
      context.specs.every((spec) => spec.status == CareerSpecStatus.available));
  _require(context.specs
      .map((spec) => spec.type)
      .toSet()
      .containsAll(SpecType.values));
  _require(preferences.desiredOccupations.join(',') ==
      context.preferences.desiredOccupations.join(','));
  _require(empty.totalSpecs == 0 &&
      empty.preferences.status == CareerPreferenceStatus.unset);
  _require(
      afterDelete.specs.every((spec) => spec.specId != raw['deletedSpecId']));
  final edited = afterDelete.specs
      .singleWhere((spec) => spec.specId == raw['updatedSpecId']);
  _require(edited.facts
      .any((fact) => fact.path == 'data.action' && fact.value == '수정한 실제 내용'));
  _require(!context.externalAiTransmissionAllowed);
  stdout.writeln(
      'Career contract passed: 10 occupations, 8 spec types, source paths, edit/delete and privacy boundary.');
}

Map<String, dynamic> _object(Object? value) =>
    (value as Map).cast<String, dynamic>();
void _require(bool condition) {
  if (!condition) throw StateError('Career server/client contract mismatch.');
}
