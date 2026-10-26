import '../../models/user_spec.dart';

enum SpecInput { text, number, date, month, choices, toggle, tags, reminders }

class SpecField {
  const SpecField(this.key, this.label,
      {this.input = SpecInput.text,
      this.hint = '',
      this.options = const [],
      this.maxLength,
      this.rows = 1,
      this.half = false,
      this.visibleWhen,
      this.required = false});
  final String key;
  final String label;
  final SpecInput input;
  final String hint;
  final List<String> options;
  final int? maxLength;
  final int rows;
  final bool half;
  final String? visibleWhen;
  final bool required;
}

class SpecSection {
  const SpecSection(this.title, this.fields);
  final String title;
  final List<SpecField> fields;
}

class SpecFormSchema {
  const SpecFormSchema(this.title, this.description, this.sections);
  final String title;
  final String description;
  final List<SpecSection> sections;
}

const specForms = <SpecType, SpecFormSchema>{
  SpecType.certification:
      SpecFormSchema('자격증 정보 입력', '취득하신 자격증 정보를 정확히 입력해 주세요.', [
    SpecSection('', [
      SpecField('name', '자격증 명칭', hint: '예: 정보처리기사, SQLD, 전산세무 등'),
      SpecField('issuer', '발급기관', hint: '예: 한국산업인력공단 (Q-Net), 한국데이터산업진흥원'),
    ]),
    SpecSection('', [
      SpecField('acquiredOn', '취득일자', input: SpecInput.date),
      SpecField('result', '합격 구분/점수 (선택)', hint: '예: 최종합격 / 88점', half: true),
      SpecField('grade', '등급/급수 (선택)', hint: '예: 1급, Advanced', half: true),
      SpecField('certificateNumber', '자격 번호 / 등록 번호', hint: '예: 24-04-129841'),
    ]),
    SpecSection('유효기간 및 갱신 관리', [
      SpecField('lifetime', '평생 유효 자격증', input: SpecInput.toggle),
      SpecField('expiresOn', '자격증 만료 일자',
          input: SpecInput.date, visibleWhen: '!lifetime'),
      SpecField('reminders', '갱신 알림',
          input: SpecInput.reminders, visibleWhen: '!lifetime'),
    ]),
    SpecSection('자소서·포트폴리오 역량 키워드', [
      SpecField('keywords', '',
          input: SpecInput.tags, hint: '관련 역량 키워드 입력 후 추가', maxLength: 5)
    ]),
  ]),
  SpecType.languageScore:
      SpecFormSchema('어학 성적 등록', '어학 시험 종류와 취득 점수(등급)를 등록하세요.', [
    SpecSection('어학 시험 선택', [
      SpecField('exam', '', input: SpecInput.choices, options: [
        'TOEIC',
        'OPIc',
        '토익스피킹',
        'JLPT',
        'HSK',
        'TEPS',
        'TOEFL',
        '기타'
      ])
    ]),
    SpecSection('취득 점수 / 등급', [
      SpecField('score', '점수 입력 (선택)',
          input: SpecInput.number, hint: '예: 890', half: true),
      SpecField('grade', '등급 입력 (선택)', hint: '예: AL / IH / 1급', half: true),
    ]),
    SpecSection('응시일자 / 시험일', [
      SpecField('testedOn', '', input: SpecInput.date),
      SpecField('reminder', '만료 30일 전 리마인더', input: SpecInput.toggle),
    ]),
    SpecSection('발급기관 / 등록번호 (수험번호)', [
      SpecField('issuer', '', hint: '발급기관 (예: ETS)'),
      SpecField('registrationNumber', '', hint: '수험번호 입력'),
    ]),
  ]),
  SpecType.educationRecord:
      SpecFormSchema('학점·학력 등록', '학교, 전공 및 학적 정보를 등록하세요.', [
    SpecSection('학적 상태 및 학위 구분', [
      SpecField('academicStatus', '학적 상태',
          input: SpecInput.choices, options: ['재학', '휴학', '졸업예정', '졸업']),
      SpecField('degree', '학위 구분',
          input: SpecInput.choices, options: ['학사', '전문학사', '석사', '박사']),
    ]),
    SpecSection('학교 및 전공 정보', [
      SpecField('school', '학교명', hint: '예: 한국대학교'),
      SpecField('major', '전공명 (주전공)', hint: '예: 컴퓨터공학과'),
      SpecField('hasAdditionalMajor', '복수전공 / 부전공 여부', input: SpecInput.toggle),
      SpecField('additionalMajor', '',
          hint: '전공명 (예: 경영학)', half: true, visibleWhen: 'hasAdditionalMajor'),
      SpecField('additionalMajorType', '',
          input: SpecInput.choices,
          options: ['복수전공', '부전공', '연계전공'],
          half: true,
          visibleWhen: 'hasAdditionalMajor'),
    ]),
    SpecSection('취득 학점 및 성적', [
      SpecField('gpaScale', '학점 만점 기준',
          input: SpecInput.choices, options: ['4.5', '4.3', '100']),
      SpecField('gpa', '총 평점 (GPA)', input: SpecInput.number, half: true),
      SpecField('majorGpa', '전공 평점', input: SpecInput.number, half: true),
    ]),
  ]),
  SpecType.award:
      SpecFormSchema('수상·공모전 등록', '교내외 공모전, 해커톤, 경진대회 수상 내역을 입력하세요.', [
    SpecSection('수상 및 공모전 명칭', [
      SpecField('name', '공모전 / 대회명', hint: '예: 2024 공공데이터 활용 창업경진대회'),
      SpecField('organizer', '주최 / 주관 기관', hint: '예: 행정안전부, 한국지능정보사회진흥원(NIA)'),
    ]),
    SpecSection('수상 내역 및 일자', [
      SpecField('prize', '수상 훈격 (상격)',
          input: SpecInput.choices,
          options: ['대상', '최우수상', '우수상', '장려상/입선', '특별상']),
      SpecField('awardedOn', '수상 일자', input: SpecInput.date),
      SpecField('participation', '참가 형태',
          input: SpecInput.choices, options: ['팀', '개인']),
      SpecField('role', '팀 내 역할', hint: '예: 기획 및 데이터 엔지니어링'),
    ]),
    SpecSection('출품작 및 성과 기록', [
      SpecField('projectName', '출품작(프로젝트) 명칭', hint: '예: 실시간 대기 오염 분석 솔루션'),
      SpecField('contribution', '성과 및 핵심 기여 내용',
          hint: '본인이 기여한 주요 역할, 문제 해결 과정, 수치적 성과를 입력하세요.',
          rows: 3,
          maxLength: 500),
      SpecField('relatedUrl', '관련 링크 URL (Github, 노션, 시연 영상 등)',
          hint: 'https://'),
    ]),
    SpecSection('자소서·포트폴리오 역량 키워드', [
      SpecField('keywords', '',
          input: SpecInput.tags, hint: '역량 키워드 입력 후 추가 (예: #문제해결력)')
    ]),
  ]),
  SpecType.project: SpecFormSchema('프로젝트 경험 등록',
      '자소서 및 면접에 직결되는 STAR(상황·과제·행동·결과) 프레임워크로 경험을 입체적으로 구조화하세요.', [
    SpecSection('프로젝트 기본 정보', [
      SpecField('name', '프로젝트명', hint: '예: 소상공인 상권 분석 웹 플랫폼, 캠퍼스 기반 매칭 어플'),
      SpecField('projectType', '소속 / 진행 형태',
          input: SpecInput.choices,
          options: ['캡스톤/졸업작품', '사이드 프로젝트', '해커톤/공모전', '교내 수업/동아리']),
      SpecField('ongoing', '현재 진행 중', input: SpecInput.toggle),
      SpecField('startedMonth', '진행 기간',
          input: SpecInput.month, hint: '시작월 (YYYY.MM)', half: true),
      SpecField('endedMonth', '',
          input: SpecInput.month,
          hint: '종료월 (YYYY.MM)',
          half: true,
          visibleWhen: '!ongoing'),
      SpecField('role', '나의 역할 및 직무', hint: '예: 프론트엔드 개발 / UI 디자이너'),
      SpecField('teamSize', '팀 구성 인원',
          input: SpecInput.choices, options: ['1인 개인', '2~4인 팀', '5인 이상']),
    ]),
    SpecSection('STAR 구조화 서술', [
      SpecField('situation', 'S · 상황 / 배경',
          hint: '당시 상황과 풀어야 했던 문제를 구체적으로 입력하세요...', rows: 3, maxLength: 300),
      SpecField('task', 'T · 과제 / 목표',
          hint: '해결해야 할 핵심 과제나 목표를 알려주세요...', rows: 3, maxLength: 300),
      SpecField('action', 'A · 행동 / 해결책',
          hint: '본인이 주도적으로 실행한 구체적 액션과 문제해결 과정을 작성하세요...',
          rows: 5,
          maxLength: 500),
      SpecField('result', 'R · 결과 / 배운 점',
          hint: '정량적 성과와 회고를 정리해주세요...', rows: 3, maxLength: 300),
    ]),
    SpecSection('기술 스택 및 결과물 링크', [
      SpecField('skills', '기술 스택 및 툴 태그',
          input: SpecInput.tags, hint: '기술 스택 입력 후 추가 (예: Next.js)'),
      SpecField('repositoryUrl', '프로젝트 링크 (선택)', hint: 'GitHub 레포지토리 URL'),
      SpecField('demoUrl', '', hint: '데모 또는 배포 프로젝트 URL'),
    ]),
  ]),
  SpecType.workExperience: SpecFormSchema(
      '인턴십 · 실무 경험 등록', '실제 기업 실무에서 수행한 담당 업무와 직무 성과, 트러블슈팅 경험을 구체적으로 기록하세요.', [
    SpecSection('회사 및 근무 정보', [
      SpecField('company', '회사/기관명', hint: '예: 네이버클라우드, 토스, 무신사 등'),
      SpecField('employmentType', '근무 형태',
          input: SpecInput.choices, options: ['인턴', '정규직', '계약직']),
      SpecField('departmentRole', '근무 부서 및 담당 직무',
          hint: '예: 서비스 기획팀 / 프로덕트 매니저 인턴'),
      SpecField('ongoing', '현재 재직 중', input: SpecInput.toggle),
      SpecField('startedMonth', '근무 기간',
          input: SpecInput.month, hint: '시작 연월', half: true),
      SpecField('endedMonth', '',
          input: SpecInput.month,
          hint: '종료 연월',
          half: true,
          visibleWhen: '!ongoing'),
    ]),
    SpecSection('주요 업무 및 실무 성과', [
      SpecField('summary', '담당 핵심 업무 요약', hint: '실제 실무 프로젝트나 운영 업무 내용을 작성하세요'),
      SpecField('achievements', '주요 성과 및 기여도 (수치 기반)',
          hint: '수치와 팩트 중심으로 작성하세요.', rows: 3, maxLength: 500),
      SpecField('troubleshooting', '업무 트러블슈팅 / 문제 해결 경험',
          hint: '갈등, 부서 간 의견 충돌, 일정 정체 등의 장애 요소를 어떻게 극복했는지 설명하세요.', rows: 3),
    ]),
  ]),
  SpecType.externalActivity: SpecFormSchema(
      '대외활동 · 서포터즈 등록', '기업 서포터즈, 동아리 운영, 봉사활동 등 다양한 조직에서의 활동과 기여도를 기록하세요.', [
    SpecSection('활동 기본 정보', [
      SpecField('name', '활동 / 단체명', hint: '예: 신한은행 대학생 홍보대사, 멋쟁이사자처럼'),
      SpecField('organizer', '주최 / 주관 기관', hint: '예: 신한은행, 멋쟁이사자처럼 대학 본부'),
      SpecField('activityType', '활동 분야',
          input: SpecInput.choices,
          options: ['기업 서포터즈/기자단', '연합 동아리/학회', '봉사/사회공헌', '멘토링/교육봉사']),
      SpecField('ongoing', '현재 활동 중', input: SpecInput.toggle),
      SpecField('startedMonth', '활동 기간',
          input: SpecInput.month, hint: '시작 연월', half: true),
      SpecField('endedMonth', '',
          input: SpecInput.month,
          hint: '종료 연월',
          half: true,
          visibleWhen: '!ongoing'),
    ]),
    SpecSection('활동 내용 및 성과', [
      SpecField('role', '소속 팀 및 나의 역할', hint: '예: 콘텐츠 기획팀 팀장 / 브랜드 크리에이터'),
      SpecField('description', '주요 활동 내용 및 결과물',
          hint: '구체적인 수치와 액션을 포함해 작성해 주세요.', rows: 4, maxLength: 1000),
      SpecField('awards', '우수 활동자 수상 내역',
          hint: '예: 최우수 활동자 선정 (전체 100명 중), 우수 서포터즈상'),
    ]),
  ]),
  SpecType.training: SpecFormSchema('교육 · 부트캠프 등록',
      'K-Digital Training, 국비지원, 개발 및 데이터 분석 집중과정 수료 내역을 체계적으로 등록하세요.', [
    SpecSection('교육 과정 기본 정보', [
      SpecField('name', '교육 과정명',
          hint: '예: K-Digital Training 클라우드 기반 풀스택 개발자 양성과정'),
      SpecField('institution', '교육 기관 / 플랫폼',
          hint: '예: 프로그래머스, 패스트캠퍼스, 엘리스, SSAFY, 우아한테크코스'),
      SpecField('trainingType', '교육 유형', input: SpecInput.choices, options: [
        'K-Digital Training',
        '부트캠프 집중과정',
        '기업 주관 아카데미',
        '온라인 코스/직무교육'
      ]),
      SpecField('hours', '총 교육 이수 시간', input: SpecInput.number, hint: '예: 840'),
      SpecField('startedOn', '교육 기간', input: SpecInput.date, half: true),
      SpecField('completedOn', '', input: SpecInput.date, half: true),
    ]),
    SpecSection('핵심 학습 기술 및 커리큘럼', [
      SpecField('skills', '학습 기술 스택 태그 (최대 10개)',
          input: SpecInput.tags,
          maxLength: 10,
          hint: '기술 스택 입력 후 추가 (예: Redis, Kafka, React)'),
      SpecField('summary', '핵심 학습 내용 요약',
          hint: '과정 중 배운 핵심 CS 이론, 주요 아키텍처 원칙 등을 구체적으로 정리해주세요.',
          rows: 4,
          maxLength: 300),
    ]),
    SpecSection('파이널 프로젝트 경험', [
      SpecField('projectName', '파이널 프로젝트명',
          hint: "예: 실시간 위치 기반 알림 시스템 '지하철 알림'"),
      SpecField('projectRole', '본인 역할 및 기여 내용',
          hint: '팀 내 담당 역할과 기여도를 적어주세요.', rows: 3),
      SpecField('projectUrl', '깃허브 저장소 / 데모 배포 링크',
          hint: 'https://github.com/...'),
    ]),
  ]),
};
