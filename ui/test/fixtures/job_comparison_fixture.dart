Map<String, dynamic> comparisonCheckFixture({
  String kind = 'certification',
  String condition = '정보처리기사',
  String status = 'unknown',
  bool required = true,
  String reason = '같은 명칭으로 등록한 자격증이 없습니다.',
  String reasonCode = 'evidence_missing',
  List<String> evidence = const [],
}) =>
    {
      'kind': kind,
      'condition': condition,
      'status': status,
      'required': required,
      'reason': reason,
      'reasonCode': reasonCode,
      'evidenceSpecIds': evidence,
    };

Map<String, dynamic> comparisonFixture({
  List<Map<String, dynamic>>? checks,
  bool detailedRequirementsAvailable = true,
}) {
  final items = checks ??
      [
        comparisonCheckFixture(
            kind: 'education',
            condition: 'bachelor',
            reason: '등록된 학력 정보가 없습니다.'),
        comparisonCheckFixture(
            kind: 'experience',
            condition: 'entry',
            reason: '신입 인정 기준을 확인할 수 없습니다.'),
      ];
  Map<String, int> summary(bool required) => {
        for (final status in [
          'confirmed',
          'not_confirmed',
          'unknown',
          'not_required'
        ])
          status: items
              .where((c) => c['required'] == required && c['status'] == status)
              .length,
      };
  return {
    'method': 'rules-v2',
    'comparedAt': '2026-10-25T00:00:00.000Z',
    'notice':
        '등록한 정보와 공고 조건을 비교한 참고 결과입니다. 공식 인증·합격 확률·지원 가능 여부를 보장하지 않습니다. 미입력은 미충족으로 처리하지 않습니다.',
    'detailedRequirementsAvailable': detailedRequirementsAvailable,
    'required': summary(true),
    'preferred': summary(false),
    'checks': items,
  };
}
