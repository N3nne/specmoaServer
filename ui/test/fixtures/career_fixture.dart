import 'package:specmoa_zip_ui/models/career_data.dart';
import 'package:specmoa_zip_ui/models/user_spec.dart';

const careerTime = '2026-10-26T00:00:00.000Z';

Map<String, dynamic> careerCatalogFixture() => {
      'version': 'job-occupations-v1',
      'items': DesiredOccupation.values
          .map((code) => {
                'code': code.name,
                'label': '직무 ${code.name}',
              })
          .toList(),
    };

Map<String, dynamic> careerPreferencesFixture(
        {List<String> codes = const [], String? status, String? updatedAt}) =>
    {
      'version': 'career-preferences-v1',
      'status': status ?? (codes.isEmpty ? 'unset' : 'set'),
      'desiredOccupations': [...codes],
      'updatedAt': updatedAt ?? (codes.isEmpty ? null : careerTime),
    };

Map<String, dynamic> careerFactFixture(String field, Object value) => {
      'field': field,
      'path': 'data.$field',
      'value': value,
    };

Map<String, dynamic> careerSpecFixture({
  String id = 'spec-project',
  String type = 'project',
  List<Map<String, dynamic>>? facts,
  String status = 'available',
  List<String> missingFields = const [],
  List<List<String>> missingContext = const [],
  List<Map<String, dynamic>> issues = const [],
}) =>
    {
      'specId': id,
      'type': type,
      'updatedAt': careerTime,
      'verification': 'unverified',
      'status': status,
      'facts': facts ??
          [
            careerFactFixture('name', '한글 프로젝트'),
            careerFactFixture('action', 'API와 테스트 구현'),
            careerFactFixture('skills', ['NestJS', 'PostgreSQL']),
            careerFactFixture('ongoing', false)
          ],
      'missingFields': [...missingFields],
      'missingContext': missingContext.map((group) => [...group]).toList(),
      'issues': issues,
    };

Map<String, dynamic> careerContextFixture(
    {List<Map<String, dynamic>>? records, Map<String, dynamic>? preferences}) {
  final specs = records ?? [careerSpecFixture()];
  return {
    'version': 'career-context-v1',
    'generatedAt': careerTime,
    'preferences': preferences ?? careerPreferencesFixture(),
    'summary': {
      'totalSpecs': specs.length,
      'unsupportedSpecs':
          specs.where((spec) => spec['status'] == 'unsupported').length,
      'byType': SpecType.values.map((type) {
        final items =
            specs.where((spec) => spec['type'] == type.apiValue).toList();
        return {
          'type': type.apiValue,
          'total': items.length,
          for (final status in ['available', 'partial', 'empty'])
            status: items.where((spec) => spec['status'] == status).length
        };
      }).toList(),
    },
    'specs': specs,
    'privacy': {
      'mode': 'server_only',
      'externalAiTransmissionAllowed': false,
      'userProvidedTextMayContainPersonalData': true,
      'excludedFields': [
        'certificateNumber',
        'registrationNumber',
        'certificationId',
        'reminders',
        'reminder',
        'relatedUrl',
        'repositoryUrl',
        'demoUrl',
        'projectUrl'
      ],
    },
  };
}
