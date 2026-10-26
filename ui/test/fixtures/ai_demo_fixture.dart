import 'job_comparison_fixture.dart';

Map<String, dynamic> aiStatusFixture({bool enabled = true}) => {
      'enabled': enabled,
      'synthetic': true,
      'profileId': 'backend',
      'profileLabel': '가상 백엔드 프로필',
      'profileSummary': '학사 졸업 · 서버 프로젝트 · TOEIC 750점',
    };

// Authored test fixtures, never presented as a verified live Gemini result.
Map<String, dynamic> aiResultFixture({int count = 3, bool cached = false}) => {
      'method': 'gemini-demo-v1',
      'synthetic': true,
      'profileId': 'backend',
      'profileLabel': '가상 백엔드 프로필',
      'profileSummary': '학사 졸업 · 서버 프로젝트 · TOEIC 750점',
      'model': 'gemini-3.5-flash-lite',
      'generatedAt': '2026-10-26T03:30:00Z',
      'cached': cached,
      'candidateCount': 9,
      'notice': '가상 스펙과 가상 공고만 사용한 AI 시연입니다. AI 설명은 틀릴 수 있습니다.',
      'items': List.generate(
          count,
          (index) => {
                'rank': index + 1,
                'jobExternalId':
                    'specmoa-demo-v1-${['001', '009', '013'][index]}',
                'companyName': '스펙모아 가상기업 ${['01', '03', '04'][index]}',
                'title':
                    '[가상 공고] ${['백엔드 개발', '모바일 앱 개발', '데이터 분석'][index]} 신입 모집',
                'region': '서울',
                'experienceLevel': 'entry',
                'employmentType': 'full_time',
                'reasons': [
                  {
                    'specId': 'demo-backend-project',
                    'specField': 'skills',
                    'specQuote': 'TypeScript',
                    'jobField': 'requirements',
                    'jobQuote': 'TypeScript',
                    'explanation': '서버 프로젝트에서 사용한 기술이 가상 공고의 업무와 관련되어 있습니다.',
                  }
                ],
                'cautions': ['기업의 실제 인정 기준은 별도로 확인해야 합니다.'],
                'comparison': comparisonFixture(),
              }),
    };

Map<String, dynamic> aiResolvedJobFixture() => {
      'id': 'fbe88ad0-8185-4c16-b74b-5efc24785651',
      'externalId': 'specmoa-demo-v1-001',
      'source': 'demo',
      'synthetic': true,
      'notice': '시연용 가상 공고입니다.',
      'canApply': false,
      'companyName': '스펙모아 가상기업 01',
      'title': '[가상 공고] 백엔드 개발 신입 모집',
      'occupation': 'backend',
      'region': '서울',
      'employmentType': 'full_time',
      'experienceLevel': 'entry',
      'keywords': ['TypeScript', 'NestJS'],
      'closesAt': null,
      'status': 'open',
      'description': '사용자 서비스 API와 데이터베이스를 개발합니다.',
    };
