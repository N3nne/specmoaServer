import 'user_spec.dart';

enum DesiredOccupation {
  backend,
  frontend,
  mobile,
  data,
  design,
  marketing,
  accounting,
  electrical,
  safety,
  mechanical;

  static DesiredOccupation parse(Object? value) => values.firstWhere(
      (item) => item.name == value,
      orElse: () => throw const FormatException('Unknown career occupation'));
}

class CareerOccupationOption {
  CareerOccupationOption._(this.code, this.label);
  final DesiredOccupation code;
  final String label;
}

class CareerOccupationCatalog {
  CareerOccupationCatalog._(this.items);

  factory CareerOccupationCatalog.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 'job-occupations-v1') {
      throw const FormatException('Unsupported occupation catalog');
    }
    final items = _list(json['items']).map((raw) {
      final item = _object(raw);
      return CareerOccupationOption._(
          DesiredOccupation.parse(item['code']), _text(item['label']));
    }).toList();
    if (items.length != DesiredOccupation.values.length ||
        items.map((item) => item.code).toSet().length != items.length) {
      throw const FormatException('Incomplete occupation catalog');
    }
    return CareerOccupationCatalog._(List.unmodifiable(items));
  }

  final List<CareerOccupationOption> items;
}

enum CareerPreferenceStatus { unset, set, needsReview }

class CareerPreferences {
  CareerPreferences._(this.status, this.desiredOccupations, this.updatedAt);

  factory CareerPreferences.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 'career-preferences-v1') {
      throw const FormatException('Unsupported career preferences');
    }
    final status = switch (json['status']) {
      'unset' => CareerPreferenceStatus.unset,
      'set' => CareerPreferenceStatus.set,
      'needs_review' => CareerPreferenceStatus.needsReview,
      _ => throw const FormatException('Unknown preference status'),
    };
    final codes =
        _list(json['desiredOccupations']).map(DesiredOccupation.parse).toList();
    final updatedAt =
        json['updatedAt'] == null ? null : _timestamp(json['updatedAt']);
    if (codes.toSet().length != codes.length ||
        (status == CareerPreferenceStatus.set &&
            (codes.isEmpty || updatedAt == null)) ||
        (status != CareerPreferenceStatus.set && codes.isNotEmpty) ||
        (status == CareerPreferenceStatus.needsReview && updatedAt != null)) {
      throw const FormatException('Inconsistent career preferences');
    }
    return CareerPreferences._(status, List.unmodifiable(codes), updatedAt);
  }

  final CareerPreferenceStatus status;
  final List<DesiredOccupation> desiredOccupations;
  final DateTime? updatedAt;
}

enum CareerSpecStatus { empty, partial, available, unsupported }

class CareerAnalysisFact {
  CareerAnalysisFact._(this.field, this.path, this.value);
  final String field, path;
  final Object value;
}

class CareerAnalysisIssue {
  CareerAnalysisIssue._(this.field, this.code);
  final String? field;
  final String code;
}

class CareerSpecAnalysis {
  CareerSpecAnalysis._(
      this.specId,
      this.rawType,
      this.type,
      this.updatedAt,
      this.status,
      this.facts,
      this.missingFields,
      this.missingContext,
      this.issues);

  factory CareerSpecAnalysis.fromJson(Map<String, dynamic> json) {
    final id = _text(json['specId']);
    final rawType = _text(json['type']);
    final type =
        SpecType.values.where((item) => item.apiValue == rawType).firstOrNull;
    final updatedAt = _timestamp(json['updatedAt']);
    final status = CareerSpecStatus.values.firstWhere(
        (item) => item.name == json['status'],
        orElse: () => throw const FormatException('Unknown analysis status'));
    if (json['verification'] != 'unverified' ||
        (status == CareerSpecStatus.unsupported) != (type == null)) {
      throw const FormatException('Invalid analysis type or verification');
    }
    final fields = type == null ? <String, _FactKind>{} : _fieldsFor(type);
    final facts = _list(json['facts']).map((raw) {
      final item = _object(raw);
      final field = _text(item['field']);
      final path = _text(item['path']);
      final kind = fields[field];
      if (kind == null || path != 'data.$field') {
        throw const FormatException('Invalid analysis field or source path');
      }
      final rawValue = item['value'];
      final Object value;
      switch (kind) {
        case _FactKind.text:
          value = _text(rawValue);
        case _FactKind.number:
          if (rawValue is! num || !rawValue.isFinite || rawValue < 0) {
            throw const FormatException('Invalid numeric fact');
          }
          value = rawValue;
        case _FactKind.boolean:
          if (rawValue is! bool) {
            throw const FormatException('Invalid boolean fact');
          }
          value = rawValue;
        case _FactKind.strings:
          final items = _strings(rawValue);
          if (items.isEmpty) throw const FormatException('Empty fact list');
          value = items;
      }
      return CareerAnalysisFact._(field, path, value);
    }).toList();
    final factFields = facts.map((fact) => fact.field).toSet();
    final missingFields = _strings(json['missingFields']);
    final missingContext = _list(json['missingContext']).map((raw) {
      final group = _strings(raw);
      if (group.isEmpty ||
          group.any((field) => !missingFields.contains(field))) {
        throw const FormatException('Invalid missing context');
      }
      return group;
    }).toList();
    final issues = _list(json['issues']).map((raw) {
      final item = _object(raw);
      final field = item['field'] == null ? null : _text(item['field']);
      final code = _text(item['code']);
      if (!const {
            'invalid_value',
            'inconsistent_range',
            'missing_context',
            'invalid_record',
            'unsupported_type'
          }.contains(code) ||
          (field != null && !fields.containsKey(field)) ||
          (field == null &&
              code != 'invalid_record' &&
              code != 'unsupported_type')) {
        throw const FormatException('Invalid analysis issue');
      }
      return CareerAnalysisIssue._(field, code);
    }).toList();
    if (factFields.length != facts.length ||
        missingFields.any((field) =>
            !fields.containsKey(field) || factFields.contains(field))) {
      throw const FormatException('Inconsistent analysis fields');
    }
    if (status == CareerSpecStatus.unsupported) {
      if (facts.isNotEmpty ||
          missingFields.isNotEmpty ||
          missingContext.isNotEmpty ||
          issues.length != 1 ||
          issues.single.code != 'unsupported_type') {
        throw const FormatException('Unsupported record contains analysis');
      }
    } else {
      final expected = issues.isNotEmpty
          ? CareerSpecStatus.partial
          : facts.isEmpty
              ? CareerSpecStatus.empty
              : missingContext.isNotEmpty
                  ? CareerSpecStatus.partial
                  : CareerSpecStatus.available;
      if (status != expected) {
        throw const FormatException('Inconsistent analysis status');
      }
    }
    return CareerSpecAnalysis._(
        id,
        rawType,
        type,
        updatedAt,
        status,
        List.unmodifiable(facts),
        missingFields,
        List.unmodifiable(missingContext),
        List.unmodifiable(issues));
  }

  final String specId, rawType;
  final SpecType? type;
  final DateTime updatedAt;
  final CareerSpecStatus status;
  final List<CareerAnalysisFact> facts;
  final List<String> missingFields;
  final List<List<String>> missingContext;
  final List<CareerAnalysisIssue> issues;
  String get verification => 'unverified';
}

class CareerTypeSummary {
  CareerTypeSummary._(
      this.type, this.total, this.available, this.partial, this.empty);
  final SpecType type;
  final int total, available, partial, empty;
}

class CareerAnalysisContext {
  CareerAnalysisContext._(this.generatedAt, this.preferences, this.specs,
      this.totalSpecs, this.unsupportedSpecs, this.byType, this.excludedFields);

  factory CareerAnalysisContext.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 'career-context-v1') {
      throw const FormatException('Unsupported career context');
    }
    final generatedAt = _timestamp(json['generatedAt']);
    final preferences =
        CareerPreferences.fromJson(_object(json['preferences']));
    final privacy = _object(json['privacy']);
    final excluded = _strings(privacy['excludedFields']);
    if (privacy['mode'] != 'server_only' ||
        privacy['externalAiTransmissionAllowed'] != false ||
        privacy['userProvidedTextMayContainPersonalData'] != true ||
        !excluded.toSet().containsAll(const {
          'certificateNumber',
          'registrationNumber',
          'certificationId',
          'reminders',
          'reminder',
          'relatedUrl',
          'repositoryUrl',
          'demoUrl',
          'projectUrl'
        })) {
      throw const FormatException('Unexpected career data policy');
    }
    final specs = _list(json['specs'])
        .map((raw) => CareerSpecAnalysis.fromJson(_object(raw)))
        .toList();
    final summary = _object(json['summary']);
    final total = _count(summary['totalSpecs']);
    final unsupported = _count(summary['unsupportedSpecs']);
    if (total != specs.length ||
        specs.map((spec) => spec.specId).toSet().length != specs.length ||
        specs
                .where((spec) => spec.status == CareerSpecStatus.unsupported)
                .length !=
            unsupported) {
      throw const FormatException('Inconsistent analysis totals');
    }
    final groups = _list(summary['byType']).map((raw) {
      final item = _object(raw);
      final type = SpecType.values
          .where((type) => type.apiValue == item['type'])
          .firstOrNull;
      if (type == null) throw const FormatException('Unknown summary type');
      final group = CareerTypeSummary._(
          type,
          _count(item['total']),
          _count(item['available']),
          _count(item['partial']),
          _count(item['empty']));
      final actual = specs.where((spec) => spec.type == type).toList();
      if (group.total != actual.length ||
          group.available !=
              actual
                  .where((spec) => spec.status == CareerSpecStatus.available)
                  .length ||
          group.partial !=
              actual
                  .where((spec) => spec.status == CareerSpecStatus.partial)
                  .length ||
          group.empty !=
              actual
                  .where((spec) => spec.status == CareerSpecStatus.empty)
                  .length) {
        throw const FormatException('Inconsistent analysis group');
      }
      return group;
    }).toList();
    if (groups.length != SpecType.values.length ||
        groups.map((group) => group.type).toSet().length != groups.length) {
      throw const FormatException('Incomplete analysis groups');
    }
    return CareerAnalysisContext._(
        generatedAt,
        preferences,
        List.unmodifiable(specs),
        total,
        unsupported,
        List.unmodifiable(groups),
        excluded);
  }

  final DateTime generatedAt;
  final CareerPreferences preferences;
  final List<CareerSpecAnalysis> specs;
  final int totalSpecs, unsupportedSpecs;
  final List<CareerTypeSummary> byType;
  final List<String> excludedFields;
  bool get externalAiTransmissionAllowed => false;
  bool get userProvidedTextMayContainPersonalData => true;
}

enum _FactKind { text, number, boolean, strings }

Map<String, _FactKind> _fieldsFor(SpecType type) {
  final text = switch (type) {
    SpecType.certification => [
        'name',
        'issuer',
        'acquiredOn',
        'result',
        'grade',
        'expiresOn'
      ],
    SpecType.languageScore => ['exam', 'grade', 'testedOn', 'issuer'],
    SpecType.educationRecord => [
        'academicStatus',
        'degree',
        'school',
        'major',
        'additionalMajor',
        'additionalMajorType'
      ],
    SpecType.award => [
        'name',
        'organizer',
        'prize',
        'awardedOn',
        'participation',
        'role',
        'projectName',
        'contribution'
      ],
    SpecType.project => [
        'name',
        'projectType',
        'startedMonth',
        'endedMonth',
        'role',
        'teamSize',
        'situation',
        'task',
        'action',
        'result'
      ],
    SpecType.workExperience => [
        'company',
        'employmentType',
        'departmentRole',
        'startedMonth',
        'endedMonth',
        'summary',
        'achievements',
        'troubleshooting'
      ],
    SpecType.externalActivity => [
        'name',
        'organizer',
        'activityType',
        'startedMonth',
        'endedMonth',
        'role',
        'description',
        'awards'
      ],
    SpecType.training => [
        'name',
        'institution',
        'trainingType',
        'startedOn',
        'completedOn',
        'summary',
        'projectName',
        'projectRole'
      ],
  };
  final numbers = switch (type) {
    SpecType.languageScore => ['score'],
    SpecType.educationRecord => ['gpaScale', 'gpa', 'majorGpa'],
    SpecType.training => ['hours'],
    _ => <String>[],
  };
  final booleans = switch (type) {
    SpecType.certification => ['lifetime'],
    SpecType.educationRecord => ['hasAdditionalMajor'],
    SpecType.project ||
    SpecType.workExperience ||
    SpecType.externalActivity =>
      ['ongoing'],
    _ => <String>[],
  };
  final lists = switch (type) {
    SpecType.certification || SpecType.award => ['keywords'],
    SpecType.project || SpecType.training => ['skills'],
    _ => <String>[],
  };
  return {
    for (final field in text) field: _FactKind.text,
    for (final field in numbers) field: _FactKind.number,
    for (final field in booleans) field: _FactKind.boolean,
    for (final field in lists) field: _FactKind.strings,
  };
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw const FormatException('Invalid career object');
  }
  return value.cast<String, dynamic>();
}

List<dynamic> _list(Object? value) {
  if (value is! List) throw const FormatException('Invalid career list');
  return value;
}

String _text(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException('Invalid career text');
  }
  return value;
}

List<String> _strings(Object? value) {
  final items = _list(value).map(_text).toList();
  if (items.toSet().length != items.length) {
    throw const FormatException('Duplicate career values');
  }
  return List.unmodifiable(items);
}

int _count(Object? value) {
  if (value is! int || value < 0) {
    throw const FormatException('Invalid career count');
  }
  return value;
}

DateTime _timestamp(Object? value) {
  final raw = _text(value);
  final date = DateTime.tryParse(raw);
  if (date == null || !date.isUtc || date.toIso8601String() != raw) {
    throw const FormatException('Invalid career timestamp');
  }
  return date;
}
