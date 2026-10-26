import 'job_data.dart';

enum JobMatchStatus {
  confirmed('confirmed', '충족'),
  notConfirmed('not_confirmed', '기준 미달'),
  unknown('unknown', '확인 불가'),
  notRequired('not_required', '제한 없음');

  const JobMatchStatus(this.value, this.label);
  final String value, label;

  static JobMatchStatus parse(Object? value) => values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw const FormatException('Invalid comparison status'));
}

class JobMatchCheck {
  const JobMatchCheck({
    required this.kind,
    required this.condition,
    required this.required,
    required this.status,
    required this.reasonCode,
    required this.reason,
    required this.evidenceSpecIds,
  });

  factory JobMatchCheck.fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'kind': String kind,
          'condition': String condition,
          'required': bool required,
          'status': String status,
          'reasonCode': String reasonCode,
          'reason': String reason,
          'evidenceSpecIds': List ids,
        }
        when [kind, condition, reasonCode, reason]
                .every((s) => s.trim().isNotEmpty) &&
            ids.every((id) => id is String && id.trim().isNotEmpty)) {
      return JobMatchCheck(
        kind: kind,
        condition: condition,
        required: required,
        status: JobMatchStatus.parse(status),
        reasonCode: reasonCode,
        reason: reason,
        evidenceSpecIds: List.unmodifiable(ids.cast<String>()),
      );
    }
    throw const FormatException('Invalid comparison check');
  }

  final String kind, condition, reasonCode, reason;
  final bool required;
  final JobMatchStatus status;
  final List<String> evidenceSpecIds;
}

class JobMatchSummary {
  const JobMatchSummary(
      {required this.confirmed,
      required this.notConfirmed,
      required this.unknown,
      required this.notRequired});

  factory JobMatchSummary.fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'confirmed': int confirmed,
          'not_confirmed': int notConfirmed,
          'unknown': int unknown,
          'not_required': int notRequired,
        }
        when [confirmed, notConfirmed, unknown, notRequired]
            .every((n) => n >= 0)) {
      return JobMatchSummary(
          confirmed: confirmed,
          notConfirmed: notConfirmed,
          unknown: unknown,
          notRequired: notRequired);
    }
    throw const FormatException('Invalid comparison counts');
  }

  final int confirmed, notConfirmed, unknown, notRequired;
  int get total => confirmed + notConfirmed + unknown + notRequired;

  bool describes(Iterable<JobMatchCheck> checks) {
    final items = checks.toList();
    return items.where((c) => c.status == JobMatchStatus.confirmed).length ==
            confirmed &&
        items.where((c) => c.status == JobMatchStatus.notConfirmed).length ==
            notConfirmed &&
        items.where((c) => c.status == JobMatchStatus.unknown).length ==
            unknown &&
        items.where((c) => c.status == JobMatchStatus.notRequired).length ==
            notRequired;
  }
}

class JobComparison {
  const JobComparison({
    required this.method,
    required this.comparedAt,
    required this.notice,
    required this.detailedRequirementsAvailable,
    required this.required,
    required this.preferred,
    required this.checks,
  });

  factory JobComparison.fromJson(Map<String, dynamic> json) {
    if (json
        case {
          'method': 'rules-v2',
          'comparedAt': String timestamp,
          'notice': String notice,
          'detailedRequirementsAvailable': bool available,
          'required': Map required,
          'preferred': Map preferred,
          'checks': List rawChecks,
        } when notice.trim().isNotEmpty) {
      final date = DateTime.tryParse(timestamp);
      if (date == null || !date.isUtc) {
        throw const FormatException('Invalid comparison time');
      }
      final checks = rawChecks
          .map((item) => JobMatchCheck.fromJson(_object(item)))
          .toList(growable: false);
      final requiredSummary = JobMatchSummary.fromJson(_object(required));
      final preferredSummary = JobMatchSummary.fromJson(_object(preferred));
      if (!requiredSummary.describes(checks.where((c) => c.required)) ||
          !preferredSummary.describes(checks.where((c) => !c.required))) {
        throw const FormatException('Inconsistent comparison counts');
      }
      return JobComparison(
          method: 'rules-v2',
          comparedAt: date,
          notice: notice,
          detailedRequirementsAvailable: available,
          required: requiredSummary,
          preferred: preferredSummary,
          checks: List.unmodifiable(checks));
    }
    throw const FormatException('Unsupported comparison response');
  }

  final String method, notice;
  final DateTime comparedAt;
  final bool detailedRequirementsAvailable;
  final JobMatchSummary required, preferred;
  final List<JobMatchCheck> checks;
  int get confirmed => required.confirmed + preferred.confirmed;
  int get notConfirmed => required.notConfirmed + preferred.notConfirmed;
  int get unknown => required.unknown + preferred.unknown;
  int get notRequired => required.notRequired + preferred.notRequired;
}

class JobComparisonResult {
  const JobComparisonResult({required this.job, required this.comparison});

  factory JobComparisonResult.fromJson(Map<String, dynamic> json) =>
      JobComparisonResult(
          job: JobDetail.fromJson(_object(json['job'])),
          comparison: JobComparison.fromJson(_object(json['comparison'])));

  final JobDetail job;
  final JobComparison comparison;
}

Map<String, dynamic> _object(Object? value) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw const FormatException('Invalid comparison object');
  }
  return value.cast<String, dynamic>();
}
