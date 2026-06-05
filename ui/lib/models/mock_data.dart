import 'certification.dart';
import 'study_task.dart';

const certifications = [
  Certification(
    title: '정보처리기사',
    category: '국가기술자격',
    description: '실기 핵심 유형과 빈출 개념을 압축해서 관리합니다.',
    progress: 0.72,
    status: CertificationStatus.inProgress,
    examDate: 'D-18',
    score: 82,
  ),
  Certification(
    title: 'SQLD',
    category: '데이터',
    description: '개념 정리, 오답 복습, 기출 회독을 한 화면에서 추적합니다.',
    progress: 1,
    status: CertificationStatus.certified,
    examDate: '취득 완료',
    score: 91,
  ),
  Certification(
    title: '컴퓨터활용능력 1급',
    category: '사무자동화',
    description: '필기와 실기 준비 상태를 분리해서 확인합니다.',
    progress: 0.38,
    status: CertificationStatus.scheduled,
    examDate: 'D-42',
    score: 64,
  ),
];

const todayTasks = [
  StudyTask(
    title: '실기 알고리즘 오답 12문제',
    caption: '정보처리기사',
    minutes: 35,
    completed: false,
  ),
  StudyTask(
    title: 'SQLD 정규화 개념 복습',
    caption: 'SQLD',
    minutes: 20,
    completed: true,
  ),
  StudyTask(
    title: '스프레드시트 함수 유형 정리',
    caption: '컴활 1급',
    minutes: 30,
    completed: false,
  ),
];
