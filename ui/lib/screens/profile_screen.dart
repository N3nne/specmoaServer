import 'package:flutter/material.dart';

import '../auth/auth_session.dart';
import '../settings/app_settings.dart';
import '../theme/app_theme.dart';
import '../widgets/app_logo_icon.dart';
import '../widgets/responsive_page.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SettingsHubScreen()),
    );
  }

  void _openNotificationSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const NotificationSettingsScreen(),
      ),
    );
  }

  void _openInquiry(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const InquiryScreen()),
    );
  }

  void _openNotices(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NoticesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final session = AuthScope.of(context);
    final user = session.user;

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _ProfileHeaderDelegate(
              onSettings: () => _openSettings(context),
            ),
          ),
          SliverToBoxAdapter(
            child: ResponsivePage(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.x4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.x8),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: const Icon(
                            Icons.person_rounded,
                            size: 42,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.x4),
                        Text(
                          user?.displayName ?? '사용자',
                          style: textTheme.titleLarge,
                        ),
                        const SizedBox(height: AppSpacing.x1),
                        Text(
                          user?.email ?? '',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x5),
                  _MenuSection(
                    title: '설정',
                    children: [
                      _MenuTile(
                        icon: Icons.tune_rounded,
                        label: '앱 설정',
                        onTap: () => _openSettings(context),
                      ),
                      _MenuTile(
                        icon: Icons.notifications_rounded,
                        label: '알림 설정',
                        onTap: () => _openNotificationSettings(context),
                      ),
                      const _ThemeToggleTile(),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x5),
                  _MenuSection(
                    title: '정보',
                    children: [
                      _MenuTile(
                        icon: Icons.mail_rounded,
                        label: '문의하기',
                        onTap: () => _openInquiry(context),
                      ),
                      _MenuTile(
                        icon: Icons.campaign_rounded,
                        label: '공지사항',
                        onTap: () => _openNotices(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.x5),
                  _LogoutTile(onTap: session.signOut),
                  const SizedBox(height: 118),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsHubScreen extends StatelessWidget {
  const SettingsHubScreen({super.key});

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: '앱 설정',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingsGroup(
            title: '환경',
            children: [
              _SettingsNavTile(
                icon: Icons.tune_rounded,
                title: '앱 설정',
                subtitle: '알림, 데이터, 앱 동작을 관리해요',
                onTap: () => _push(context, const AppSettingsScreen()),
              ),
              _SettingsNavTile(
                icon: Icons.notifications_rounded,
                title: '알림 설정',
                subtitle: '시험, 학습, 커뮤니티 알림을 조정해요',
                onTap: () => _push(
                  context,
                  const NotificationSettingsScreen(),
                ),
              ),
              _SettingsNavTile(
                icon: Icons.palette_rounded,
                title: '테마 설정',
                subtitle: '테마와 화면 모드를 조정해요',
                onTap: () => _push(context, const ThemeSettingsScreen()),
              ),
              _SettingsNavTile(
                icon: Icons.text_fields_rounded,
                title: '글자 크기 설정',
                subtitle: '목록과 본문 글자 크기를 맞춰요',
                onTap: () => _push(context, const TextSizeSettingsScreen()),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x5),
          _SettingsGroup(
            title: '약관 및 개인정보',
            children: [
              _SettingsNavTile(
                icon: Icons.privacy_tip_rounded,
                title: '개인정보 처리방침',
                subtitle: '개인정보 수집과 이용 기준을 확인해요',
                onTap: () => _push(
                  context,
                  const PolicyDocumentScreen(type: PolicyDocumentType.privacy),
                ),
              ),
              _SettingsNavTile(
                icon: Icons.description_rounded,
                title: '서비스 이용약관',
                subtitle: '스펙모아.zip 이용 규칙을 확인해요',
                onTap: () => _push(
                  context,
                  const PolicyDocumentScreen(type: PolicyDocumentType.terms),
                ),
              ),
            ],
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);

    return _SettingsScaffold(
      title: '앱 설정',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingsGroup(
            title: '알림',
            children: [
              _SettingsSwitchTile(
                icon: Icons.notifications_active_rounded,
                title: '푸시 알림',
                subtitle: '시험 일정과 커뮤니티 활동을 알려줘요',
                value: settings.pushEnabled,
                onChanged: settings.setPushEnabled,
              ),
              _SettingsSwitchTile(
                icon: Icons.timer_rounded,
                title: '학습 리마인더',
                subtitle: '준비 중인 자격증 학습 시간을 챙겨요',
                value: settings.studyReminder,
                onChanged: settings.setStudyReminder,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x5),
          _SettingsGroup(
            title: '데이터',
            children: [
              _SettingsSwitchTile(
                icon: Icons.sync_rounded,
                title: '데이터 자동 새로고침',
                subtitle: '자격증 일정과 인기 순위를 자동으로 갱신해요',
                value: settings.autoRefresh,
                onChanged: settings.setAutoRefresh,
              ),
              _SettingsSwitchTile(
                icon: Icons.campaign_rounded,
                title: '서비스 소식 수신',
                subtitle: '업데이트와 이벤트 정보를 받아요',
                value: settings.marketing,
                onChanged: settings.setMarketing,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x5),
          const _SettingsGroup(
            title: '앱 정보',
            children: [
              _SettingsInfoTile(
                leading: AppLogoIcon(size: 32),
                title: '스펙모아.zip',
                value: 'v1.0.0',
              ),
            ],
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);

    return _SettingsScaffold(
      title: '알림 설정',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NotificationStatusCard(enabled: settings.pushEnabled),
          const SizedBox(height: AppSpacing.x5),
          _SettingsGroup(
            title: '기본 알림',
            children: [
              _SettingsSwitchTile(
                icon: Icons.notifications_active_rounded,
                title: '전체 푸시 알림',
                subtitle: '스펙모아.zip에서 보내는 모든 알림의 기준이에요',
                value: settings.pushEnabled,
                onChanged: settings.setPushEnabled,
              ),
              _SettingsSwitchTile(
                icon: Icons.do_not_disturb_on_rounded,
                title: '방해금지 시간대',
                subtitle: '늦은 시간에는 긴급하지 않은 알림을 줄여요',
                value: settings.quietHours,
                onChanged: settings.setQuietHours,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x5),
          _SettingsGroup(
            title: '자격증',
            children: [
              _SettingsSwitchTile(
                icon: Icons.event_available_rounded,
                title: '시험 일정 알림',
                subtitle: '접수 시작, 시험일, 발표일을 놓치지 않게 알려줘요',
                value: settings.examScheduleNotification,
                onChanged: settings.setExamScheduleNotification,
              ),
              _SettingsSwitchTile(
                icon: Icons.timer_rounded,
                title: '학습 리마인더',
                subtitle: '준비 중인 자격증의 학습 루틴을 챙겨요',
                value: settings.studyReminder,
                onChanged: settings.setStudyReminder,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x5),
          _SettingsGroup(
            title: '커뮤니티',
            children: [
              _SettingsSwitchTile(
                icon: Icons.forum_rounded,
                title: '질문/댓글 알림',
                subtitle: '내 질문의 댓글과 채택 답변 활동을 알려줘요',
                value: settings.communityNotification,
                onChanged: settings.setCommunityNotification,
              ),
              _SettingsSwitchTile(
                icon: Icons.workspace_premium_rounded,
                title: '합격 후기 알림',
                subtitle: '관심 자격증의 새 합격 후기를 받아요',
                value: settings.successStoryNotification,
                onChanged: settings.setSuccessStoryNotification,
              ),
            ],
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

class NoticesScreen extends StatelessWidget {
  const NoticesScreen({super.key});

  static const _notices = [
    (
      title: '스펙모아.zip 베타 서비스 안내',
      date: '2026.06.04',
      badge: '공지',
      body: '자격증 탐색, 학습 타이머, 커뮤니티 기능을 순차적으로 안정화하고 있어요.',
    ),
    (
      title: '자격증 일정 데이터 업데이트',
      date: '2026.06.01',
      badge: '업데이트',
      body: '공공데이터 기반 시험 일정과 자격증 상세 정보 동기화 범위를 넓혔어요.',
    ),
    (
      title: '커뮤니티 이용 가이드',
      date: '2026.05.28',
      badge: '안내',
      body: '질문과 합격 후기는 자격증명 태그를 기준으로 더 쉽게 모아볼 수 있어요.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: '공지사항',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final notice in _notices) ...[
            _NoticeCard(
              title: notice.title,
              date: notice.date,
              badge: notice.badge,
              body: notice.body,
            ),
            const SizedBox(height: AppSpacing.x3),
          ],
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

class InquiryScreen extends StatefulWidget {
  const InquiryScreen({super.key});

  @override
  State<InquiryScreen> createState() => _InquiryScreenState();
}

class _InquiryScreenState extends State<InquiryScreen> {
  final _emailController = TextEditingController();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (email.isEmpty || title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이메일, 제목, 문의 내용을 모두 입력해주세요.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('문의가 접수되었습니다. 확인 후 답변드릴게요.')),
    );
    _titleController.clear();
    _contentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _SettingsScaffold(
      title: '문의하기',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.x5),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '문의 내용을 남겨주세요',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.x1),
                Text(
                  '답변 받을 이메일과 문의 내용을 입력하면 검토 후 안내드릴게요.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.x5),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '이메일',
                    hintText: 'reply@example.com',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.x3),
                TextField(
                  controller: _titleController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '제목',
                    hintText: '문의 제목을 입력하세요',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.x3),
                TextField(
                  controller: _contentController,
                  minLines: 5,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: '문의 내용',
                    hintText: '불편한 점이나 궁금한 내용을 입력하세요',
                    prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.x5),
                FilledButton.icon(
                  onPressed: _submit,
                  icon: const Icon(Icons.send_rounded),
                  label: const Text('문의 보내기'),
                ),
              ],
            ),
          ),
          // const SizedBox(height: AppSpacing.x4),
          // const _InquiryInfoRow(
          //   icon: Icons.schedule_rounded,
          //   title: '답변 시간',
          //   value: '영업일 기준 1-3일 이내',
          // ),
          // const SizedBox(height: AppSpacing.x3),
          // const _InquiryInfoRow(
          //   icon: Icons.shield_rounded,
          //   title: '개인정보',
          //   value: '문의 처리를 위한 정보만 사용해요',
          // ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);

    return _SettingsScaffold(
      title: '테마 설정',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SettingsGroup(
            title: '화면 모드',
            children: [
              _SettingsChoiceTile(
                title: '시스템 설정',
                subtitle: '기기 설정에 맞춰 자동 적용',
                selected: settings.themePreference == AppThemePreference.system,
                onTap: () => settings.setThemePreference(
                  AppThemePreference.system,
                ),
              ),
              _SettingsChoiceTile(
                title: '라이트 모드',
                subtitle: '밝은 배경과 파란 포인트',
                selected: settings.themePreference == AppThemePreference.light,
                onTap: () => settings.setThemePreference(
                  AppThemePreference.light,
                ),
              ),
              _SettingsChoiceTile(
                title: '다크 모드',
                subtitle: '어두운 배경 중심의 화면',
                selected: settings.themePreference == AppThemePreference.dark,
                onTap: () => settings.setThemePreference(
                  AppThemePreference.dark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x5),
          _SettingsGroup(
            title: '접근성',
            children: [
              _SettingsSwitchTile(
                icon: Icons.contrast_rounded,
                title: '대비 강화',
                subtitle: '텍스트와 경계선을 더 또렷하게 표시해요',
                value: settings.highContrast,
                onChanged: settings.setHighContrast,
              ),
            ],
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

class TextSizeSettingsScreen extends StatefulWidget {
  const TextSizeSettingsScreen({super.key});

  @override
  State<TextSizeSettingsScreen> createState() => _TextSizeSettingsScreenState();
}

class _TextSizeSettingsScreenState extends State<TextSizeSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final settings = AppSettingsScope.of(context);
    final scale = settings.textScale;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return _SettingsScaffold(
      title: '글자 크기 설정',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.x5),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '미리보기',
                  style: textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.x3),
                Text(
                  '정보처리기사 시험 일정이 업데이트되었어요.',
                  style: textTheme.titleMedium?.copyWith(
                    fontSize: 18 * scale,
                  ),
                ),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  '목록, 카드, 본문 영역에서 읽기 편한 크기를 선택할 수 있어요.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 14 * scale,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x5),
          Container(
            padding: const EdgeInsets.all(AppSpacing.x5),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.text_decrease_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    Expanded(
                      child: Slider(
                        value: scale,
                        min: 0.9,
                        max: 1.2,
                        divisions: 3,
                        label: '${(scale * 100).round()}%',
                        onChanged: settings.setTextScale,
                      ),
                    ),
                    Icon(
                      Icons.text_increase_rounded,
                      color: colorScheme.primary,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('작게', style: textTheme.labelMedium),
                    Text(
                      '${(scale * 100).round()}%',
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                    Text('크게', style: textTheme.labelMedium),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

enum PolicyDocumentType { privacy, terms }

class PolicyDocumentScreen extends StatelessWidget {
  const PolicyDocumentScreen({required this.type, super.key});

  final PolicyDocumentType type;

  @override
  Widget build(BuildContext context) {
    final isPrivacy = type == PolicyDocumentType.privacy;
    final title = isPrivacy ? '개인정보 처리방침' : '서비스 이용약관';
    final paragraphs = isPrivacy ? _privacyParagraphs : _termsParagraphs;
    final colorScheme = Theme.of(context).colorScheme;

    return _SettingsScaffold(
      title: title,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.x5),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.x2),
            Text(
              '시행일 2026.06.04',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.x5),
            for (final paragraph in paragraphs) ...[
              Text(
                paragraph,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      height: 1.65,
                    ),
              ),
              const SizedBox(height: AppSpacing.x4),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsScaffold extends StatelessWidget {
  const _SettingsScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _SettingsHeaderDelegate(title: title),
            ),
            SliverToBoxAdapter(
              child: ResponsivePage(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.x4),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationStatusCard extends StatelessWidget {
  const _NotificationStatusCard({required this.enabled});

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent = enabled ? colorScheme.primary : colorScheme.onSurfaceVariant;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.x5),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft,
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              enabled
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_rounded,
              color: accent,
            ),
          ),
          const SizedBox(width: AppSpacing.x4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  enabled ? '알림이 켜져 있어요' : '알림이 꺼져 있어요',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.x1),
                Text(
                  enabled
                      ? '시험 일정, 학습, 커뮤니티 소식을 받을 수 있어요.'
                      : '전체 푸시 알림을 켜면 세부 알림을 받을 수 있어요.',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.title,
    required this.date,
    required this.badge,
    required this.body,
  });

  final String title;
  final String date;
  final String badge;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.x5),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x2,
                  vertical: AppSpacing.x1,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  badge,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                date,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x3),
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: AppSpacing.x2),
          Text(
            body,
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeaderDelegate extends SliverPersistentHeaderDelegate {
  _ProfileHeaderDelegate({required this.onSettings});

  final VoidCallback onSettings;

  @override
  double get minExtent => 64;

  @override
  double get maxExtent => 64;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.surface.withValues(alpha: 0.92),
      child: ResponsivePage(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x5),
        child: Row(
          children: [
            const AppLogoIcon(size: 32),
            const SizedBox(width: AppSpacing.x2),
            Text(
              '스펙모아.zip',
              style: textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: '알림',
              onPressed: () {},
              icon: const Icon(Icons.notifications_none_rounded),
              color: colorScheme.onSurfaceVariant,
            ),
            IconButton(
              tooltip: '앱 설정',
              onPressed: onSettings,
              icon: const Icon(Icons.settings_rounded),
              color: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _ProfileHeaderDelegate oldDelegate) =>
      oldDelegate.onSettings != onSettings;
}

class _SettingsHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _SettingsHeaderDelegate({required this.title});

  final String title;

  @override
  double get minExtent => 64;

  @override
  double get maxExtent => 64;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colorScheme.surface.withValues(alpha: 0.94),
      child: ResponsivePage(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3),
        child: Row(
          children: [
            IconButton(
              tooltip: '뒤로가기',
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              color: colorScheme.onSurface,
            ),
            const SizedBox(width: AppSpacing.x1),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SettingsHeaderDelegate oldDelegate) =>
      oldDelegate.title != title;
}

class _MenuSection extends StatelessWidget {
  const _MenuSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.x4,
            bottom: AppSpacing.x2,
          ),
          child: Text(
            title,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.72),
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: AppShadows.soft,
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return _MenuSection(title: title, children: children);
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.icon, required this.label, this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x4,
            vertical: AppSpacing.x4,
          ),
          child: Row(
            children: [
              Icon(icon, color: colorScheme.onSurfaceVariant, size: 22),
              const SizedBox(width: AppSpacing.x3),
              Expanded(child: Text(label, style: textTheme.titleSmall)),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsNavTile extends StatelessWidget {
  const _SettingsNavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x4,
            vertical: AppSpacing.x4,
          ),
          child: Row(
            children: [
              _SettingsIcon(icon: icon),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.outlineVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x4,
        vertical: AppSpacing.x3,
      ),
      child: Row(
        children: [
          _SettingsIcon(icon: icon),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleSmall),
                const SizedBox(height: AppSpacing.x1),
                Text(
                  subtitle,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SettingsChoiceTile extends StatelessWidget {
  const _SettingsChoiceTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x4,
            vertical: AppSpacing.x4,
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? colorScheme.primary : colorScheme.outline,
              ),
              const SizedBox(width: AppSpacing.x3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.x1),
                    Text(
                      subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsInfoTile extends StatelessWidget {
  const _SettingsInfoTile({
    required this.title,
    required this.value,
    required this.leading,
  });

  final Widget leading;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x4,
        vertical: AppSpacing.x4,
      ),
      child: Row(
        children: [
          SizedBox(width: 42, height: 42, child: Center(child: leading)),
          const SizedBox(width: AppSpacing.x3),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleSmall),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Icon(icon, color: colorScheme.primary, size: 22),
    );
  }
}

class _ThemeToggleTile extends StatelessWidget {
  const _ThemeToggleTile();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final settings = AppSettingsScope.of(context);
    final isDarkMode = settings.themePreference == AppThemePreference.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x4,
        vertical: AppSpacing.x3,
      ),
      child: Row(
        children: [
          Icon(
            Icons.dark_mode_rounded,
            color: colorScheme.onSurfaceVariant,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.x3),
          Expanded(child: Text('다크 모드', style: textTheme.titleSmall)),
          Switch(
            value: isDarkMode,
            onChanged: (value) => settings.setThemePreference(
              value ? AppThemePreference.dark : AppThemePreference.light,
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutTile extends StatelessWidget {
  const _LogoutTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.soft,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x4,
              vertical: AppSpacing.x4,
            ),
            child: Row(
              children: [
                const Icon(Icons.logout_rounded, color: AppColors.error),
                const SizedBox(width: AppSpacing.x3),
                Text(
                  '로그아웃',
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

const _privacyParagraphs = [
  '스펙모아.zip은 회원 식별, 자격증 등록, 학습 기록, 커뮤니티 이용을 위해 필요한 최소한의 개인정보를 처리합니다.',
  '회원이 등록한 자격증, 학습 시간, 게시글과 댓글 정보는 앱 기능 제공을 위해 저장되며, 법령상 보관 의무가 있는 경우를 제외하고 목적 달성 후 지체 없이 파기합니다.',
  '이용자는 언제든지 자신의 개인정보 열람, 수정, 삭제를 요청할 수 있으며 서비스 내 설정 또는 문의 채널을 통해 접수할 수 있습니다.',
];

const _termsParagraphs = [
  '스펙모아.zip은 자격증 정보 탐색, 학습 관리, 커뮤니티 기능을 제공하는 서비스입니다. 이용자는 관련 법령과 본 약관을 준수해야 합니다.',
  '공공데이터 기반 정보는 제공 기관의 갱신 시점에 따라 실제 일정과 차이가 있을 수 있으므로, 시험 접수 전 공식 기관 안내를 함께 확인해야 합니다.',
  '커뮤니티 게시글과 댓글은 타인의 권리를 침해하거나 허위 정보를 유포하는 목적으로 사용할 수 없으며, 운영 기준에 따라 제한될 수 있습니다.',
];
