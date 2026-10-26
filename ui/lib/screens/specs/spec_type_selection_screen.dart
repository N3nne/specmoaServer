import 'package:flutter/material.dart';
import '../../models/user_spec.dart';
import 'spec_register_screen.dart';

class SpecTypeSelectionScreen extends StatefulWidget {
  const SpecTypeSelectionScreen({this.existingCount, super.key});
  final int? existingCount;
  @override
  State<SpecTypeSelectionScreen> createState() =>
      _SpecTypeSelectionScreenState();
}

class _SpecTypeSelectionScreenState extends State<SpecTypeSelectionScreen> {
  bool? _exam = true;
  SpecType? _selected;
  static const _primary = Color(0xFF0057BD);

  Future<void> _next() async {
    if (_exam == null) return;
    if (_selected == null) {
      setState(
          () => _selected = _exam! ? SpecType.certification : SpecType.project);
      return;
    }
    final saved = await Navigator.push<UserSpec>(
        context,
        MaterialPageRoute(
            builder: (_) => SpecRegisterScreen(type: _selected!)));
    if (saved != null && mounted) Navigator.pop(context, saved);
  }

  @override
  Widget build(BuildContext context) {
    final step2 = _selected != null;
    return Theme(
        data: Theme.of(context).copyWith(
            textTheme:
                Theme.of(context).textTheme.apply(fontFamily: 'SpecInter')),
        child: Scaffold(
          backgroundColor: const Color(0xFFF5F7F9),
          appBar: AppBar(
              backgroundColor: const Color(0xFFF5F7F9),
              surfaceTintColor: Colors.transparent,
              toolbarHeight: 64,
              leading: IconButton(
                  tooltip: '뒤로 가기',
                  color: _primary,
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    if (step2) {
                      setState(() => _selected = null);
                    } else {
                      Navigator.pop(context);
                    }
                  }),
              title: const Text('자격증 등록',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
          body: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: ListView(padding: const EdgeInsets.all(20), children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('STEP ${step2 ? 2 : 1} OF 2',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _primary)),
                          Text(step2 ? '2단계: 세부 유형 선택' : '50% 완료',
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF595C5E)))
                        ]),
                    const SizedBox(height: 8),
                    ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                            value: step2 ? 1 : .5,
                            minHeight: 6,
                            color: _primary,
                            backgroundColor: const Color(0xFFDFE3E6))),
                    const SizedBox(height: 12),
                    if (!step2)
                      const Text('1단계: 스펙 대분류 선택',
                          style: TextStyle(
                              fontSize: 12, color: Color(0xFF595C5E))),
                    if (step2) ...[
                      Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: const Color(0xFFEEF1F3),
                              borderRadius: BorderRadius.circular(16)),
                          child: Row(children: [
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  const Text('선택된 대분류',
                                      style: TextStyle(
                                          fontSize: 11, color: _primary)),
                                  const SizedBox(height: 6),
                                  Text(
                                      _exam!
                                          ? '시험 · 성적 스펙 (정량적 지표)'
                                          : '활동 · 경험 스토리 (정성적 경험)',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600))
                                ])),
                            TextButton(
                                onPressed: () =>
                                    setState(() => _selected = null),
                                child: const Text('변경'))
                          ])),
                      const SizedBox(height: 28),
                    ] else
                      const SizedBox(height: 24),
                    Text.rich(
                        TextSpan(children: [
                          TextSpan(
                              text: step2
                                  ? (_exam! ? '세부 스펙 유형을\n' : '세부 경험 유형을\n')
                                  : '어떤 종류의 스펙을\n'),
                          TextSpan(
                              text: step2 ? '선택' : '추가',
                              style: const TextStyle(color: _primary)),
                          TextSpan(text: step2 ? '해주세요' : '할까요?'),
                        ]),
                        style: const TextStyle(
                            fontSize: 24,
                            height: 1.3,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2C2F31))),
                    const SizedBox(height: 8),
                    Text(
                        step2
                            ? '유형별로 최적화된 입력 양식이 제공됩니다.'
                            : '기록하고 싶은 스펙의 성격을 선택해주세요. 알맞은 맞춤형 관리 폼으로 안내해 드립니다.',
                        style: const TextStyle(
                            fontSize: 13,
                            height: 1.7,
                            color: Color(0xFF595C5E))),
                    const SizedBox(height: 24),
                    if (!step2) ...[
                      Row(children: [
                        Expanded(
                            child: Container(
                                height: 64,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12)),
                                child: Row(children: [
                                  Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                          color: const Color(0xFFEEF1F3),
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: const Icon(
                                          Icons.inventory_2_outlined,
                                          size: 20)),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                        const Text('누적 스펙 보관',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF595C5E))),
                                        Text(
                                            '${widget.existingCount ?? '-'}개 등록',
                                            style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700))
                                      ]))
                                ]))),
                        const SizedBox(width: 12),
                        const Expanded(child: SizedBox())
                      ]),
                      const SizedBox(height: 24),
                      _choice(
                          icon: Icons.workspace_premium,
                          title: '시험 · 성적 스펙',
                          subtitle: '점수, 등급, 취득일 및 만료일 관리',
                          selected: _exam == true,
                          onTap: () => setState(() => _exam = true),
                          group: true),
                      const SizedBox(height: 16),
                      _choice(
                          icon: Icons.auto_stories,
                          title: '활동 · 경험 스토리',
                          subtitle: 'STAR 자소서 키워드 연결',
                          selected: _exam == false,
                          onTap: () => setState(() => _exam = false),
                          group: true),
                    ] else
                      for (final type in SpecType.values
                          .where((type) => type.isExamScore == _exam)) ...[
                        _choice(
                            icon: _icons[type]!,
                            title: type.label,
                            subtitle: _subtitles[type]!,
                            selected: _selected == type,
                            onTap: () => setState(() => _selected = type)),
                        const SizedBox(height: 12),
                      ],
                    const SizedBox(height: 20),
                    Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: const Color(0xFFEEF1F3),
                            borderRadius: BorderRadius.circular(12)),
                        child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.lightbulb_outline,
                                  size: 18, color: Color(0xFF747779)),
                              SizedBox(width: 8),
                              Expanded(
                                  child: Text(
                                      '나중에 언제든지 수정하거나 자소서용 태그를 추가로 붙일 수 있어요.',
                                      style: TextStyle(
                                          fontSize: 12,
                                          height: 1.6,
                                          color: Color(0xFF595C5E))))
                            ])),
                  ]))),
          bottomNavigationBar: SafeArea(
              top: false,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: SizedBox(
                      height: 64,
                      child: FilledButton(
                          onPressed: _exam == null ? null : _next,
                          style: FilledButton.styleFrom(
                              backgroundColor: _primary,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16))),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(step2 ? '등록하기' : '세부 유형 선택하기',
                                    style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(width: 8),
                                Icon(
                                    step2
                                        ? Icons.check_circle_outline
                                        : Icons.arrow_forward,
                                    size: 20)
                              ]))))),
        ));
  }

  Widget _choice(
          {required IconData icon,
          required String title,
          required String subtitle,
          required bool selected,
          required VoidCallback onTap,
          bool group = false}) =>
      Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: EdgeInsets.all(group ? 20 : 16),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: selected ? _primary : Colors.transparent,
                      width: 2)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              width: group ? 48 : 44,
                              height: group ? 56 : 44,
                              decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFFC7CFFF)
                                          .withValues(alpha: .4)
                                      : const Color(0xFFEEF1F3),
                                  borderRadius: BorderRadius.circular(12)),
                              child: Icon(icon,
                                  size: 24,
                                  color: selected
                                      ? _primary
                                      : const Color(0xFF595C5E))),
                          const SizedBox(width: 16),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(title,
                                    style: TextStyle(
                                        fontSize: group ? 18 : 16,
                                        fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text(subtitle,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        height: 1.5,
                                        color: Color(0xFF595C5E)))
                              ])),
                          const SizedBox(width: 8),
                          Icon(
                              selected
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color:
                                  selected ? _primary : const Color(0xFFDFE3E6),
                              size: 22),
                        ]),
                    if (group) ...[
                      const SizedBox(height: 16),
                      Text(
                          title.startsWith('시험')
                              ? '자격증, 공인 어학 성적, 학점 등 공식 평가 기관의 인증 번호와 유효기간이 있는 스펙'
                              : '대외활동, 인턴십, 실무 프로젝트 등 실제 역할과 트러블슈팅을 증명하는 경험 기록',
                          style: const TextStyle(
                              fontSize: 12,
                              height: 1.65,
                              color: Color(0xFF595C5E))),
                      const SizedBox(height: 16),
                      Wrap(spacing: 6, runSpacing: 6, children: [
                        for (final tag in title.startsWith('시험')
                            ? ['자격증', '어학성적', '학점/학력', '수상·공모전']
                            : ['프로젝트(STAR)', '인턴활동', '대외활동', '부트캠프'])
                          Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFEEF1F3),
                                  borderRadius: BorderRadius.circular(999)),
                              child: Text('#$tag',
                                  style: const TextStyle(
                                      fontSize: 11, color: Color(0xFF595C5E))))
                      ]),
                      const SizedBox(height: 28),
                      Row(children: [
                        Text('세부 유형 선택하기',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? _primary
                                    : const Color(0xFF595C5E))),
                        const SizedBox(width: 4),
                        Icon(Icons.arrow_forward,
                            size: 14,
                            color:
                                selected ? _primary : const Color(0xFF595C5E))
                      ]),
                    ]
                  ]),
            )),
      );
}

const _icons = <SpecType, IconData>{
  SpecType.certification: Icons.workspace_premium,
  SpecType.languageScore: Icons.translate,
  SpecType.educationRecord: Icons.school,
  SpecType.award: Icons.emoji_events,
  SpecType.project: Icons.terminal,
  SpecType.workExperience: Icons.work,
  SpecType.externalActivity: Icons.groups,
  SpecType.training: Icons.school
};
const _subtitles = <SpecType, String>{
  SpecType.certification: '국가기술, 국가전문, 공인민간자격',
  SpecType.languageScore: 'TOEIC, OPIc, 토익스피킹, JLPT, HSK 등',
  SpecType.educationRecord: '전공/총 평점, 학위 정보',
  SpecType.award: '해커톤, 경진대회, 학술제, 공모전 수상',
  SpecType.project: '교내외 캡스톤, 사이드 프로젝트, 해커톤 및 실무 과제',
  SpecType.workExperience: '체험형/채용연계형 인턴, 파트타임, 직무 인턴십 경험',
  SpecType.externalActivity: '기업 서포터즈, 학생활동, 동아리 운영진, 홍보 기자단',
  SpecType.training: 'K-Digital Training, 국비지원, 개발/데이터 집중과정'
};
