import 'dart:async';

import 'package:flutter/material.dart';

import '../auth/auth_session.dart';
import '../models/certification_search_data.dart';
import '../services/certification_search_api_client.dart';
import '../services/success_story_api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_page.dart';

class SuccessStoryWriteScreen extends StatefulWidget {
  const SuccessStoryWriteScreen({
    this.initialCertificationId,
    this.initialCertificationName,
    super.key,
  });

  final String? initialCertificationId;
  final String? initialCertificationName;

  @override
  State<SuccessStoryWriteScreen> createState() =>
      _SuccessStoryWriteScreenState();
}

class _SuccessStoryWriteScreenState extends State<SuccessStoryWriteScreen> {
  final _certClient = const CertificationSearchApiClient();
  final _storyClient = const SuccessStoryApiClient();
  final _certSearchController = TextEditingController();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _studyDaysController = TextEditingController();
  final _studyMethodController = TextEditingController();
  final _scoreController = TextEditingController();
  Timer? _certSearchDebounce;
  CertificationSearchResult? _selectedCertification;
  List<CertificationSearchResult> _certifications = const [];
  bool _loadingCertifications = false;
  bool _submitting = false;

  bool get _canSubmit =>
      _selectedCertification != null &&
      _titleController.text.trim().length >= 4 &&
      _bodyController.text.trim().length >= 10 &&
      !_submitting;

  bool get _canTapSubmit => !_submitting;

  @override
  void initState() {
    super.initState();
    if (widget.initialCertificationId != null &&
        widget.initialCertificationName != null) {
      _selectedCertification = CertificationSearchResult(
        id: widget.initialCertificationId!,
        name: widget.initialCertificationName!,
        category: '',
        examineeCount: 0,
        acquiredCount: 0,
        tags: const [],
      );
      _certSearchController.text = widget.initialCertificationName!;
    }
    for (final controller in [
      _titleController,
      _subtitleController,
      _bodyController,
      _studyDaysController,
      _studyMethodController,
      _scoreController,
    ]) {
      controller.addListener(_onInputChanged);
    }
  }

  @override
  void dispose() {
    _certSearchDebounce?.cancel();
    _certSearchController.dispose();
    _titleController.dispose();
    _subtitleController.dispose();
    _bodyController.dispose();
    _studyDaysController.dispose();
    _studyMethodController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _StoryWriteHeaderDelegate(
                canSubmit: _canSubmit,
                submitting: _submitting,
                onBack: Navigator.of(context).pop,
                onSubmit: _submit,
              ),
            ),
            SliverToBoxAdapter(
              child: ResponsivePage(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.x4),
                    _StoryWritePanel(
                      certSearchController: _certSearchController,
                      titleController: _titleController,
                      subtitleController: _subtitleController,
                      bodyController: _bodyController,
                      studyDaysController: _studyDaysController,
                      studyMethodController: _studyMethodController,
                      scoreController: _scoreController,
                      selectedCertification: _selectedCertification,
                      certifications: _certifications,
                      loadingCertifications: _loadingCertifications,
                      onCertificationSearchChanged:
                          _onCertificationSearchChanged,
                      onCertificationSelected: _selectCertification,
                    ),
                    const SizedBox(height: AppSpacing.x5),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _canTapSubmit ? _submit : null,
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(_submitting ? '등록 중' : '후기 등록'),
                      ),
                    ),
                    const SizedBox(height: 118),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadCertifications() async {
    final query = _certSearchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _certifications = const [];
        _loadingCertifications = false;
      });
      return;
    }

    setState(() => _loadingCertifications = true);
    try {
      final items = await _certClient.search(
        query: query,
        sort: 'popular',
        limit: 20,
      );
      if (mounted) {
        setState(() => _certifications = items);
      }
    } finally {
      if (mounted) {
        setState(() => _loadingCertifications = false);
      }
    }
  }

  void _onCertificationSearchChanged(String value) {
    if (_selectedCertification != null &&
        value.trim() != _selectedCertification!.name) {
      setState(() => _selectedCertification = null);
    }
    _certSearchDebounce?.cancel();
    _certSearchDebounce =
        Timer(const Duration(milliseconds: 260), _loadCertifications);
  }

  void _selectCertification(CertificationSearchResult item) {
    setState(() {
      _selectedCertification = item;
      _certSearchController.text = item.name;
      _certifications = const [];
    });
  }

  void _onInputChanged() {
    setState(() {});
  }

  Future<void> _submit() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_submitting) {
      return;
    }
    final validationMessage = _validationMessage();
    if (validationMessage != null) {
      messenger.showSnackBar(SnackBar(content: Text(validationMessage)));
      return;
    }

    final navigator = Navigator.of(context);
    final userId = AuthScope.of(context).user?.id ?? '';
    final studyDays = int.tryParse(_studyDaysController.text.trim()) ?? 0;

    setState(() => _submitting = true);
    try {
      final item = await _storyClient.createStory(
        userId: userId,
        certificationId: _selectedCertification!.id,
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim(),
        body: _bodyController.text.trim(),
        studyPeriodDays: studyDays,
        studyMethod: _studyMethodController.text.trim(),
        score: _scoreController.text.trim(),
        examAttempt: '합격',
      );
      if (!mounted) {
        return;
      }
      navigator.pop(item);
    } catch (error) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  String? _validationMessage() {
    if (_selectedCertification == null) {
      return '자격증을 검색한 뒤 목록에서 선택해주세요.';
    }
    if (_titleController.text.trim().length < 4) {
      return '후기 제목을 4자 이상 입력해주세요.';
    }
    if (_bodyController.text.trim().length < 10) {
      return '본문을 10자 이상 입력해주세요.';
    }
    return null;
  }
}

class _StoryWriteHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _StoryWriteHeaderDelegate({
    required this.canSubmit,
    required this.submitting,
    required this.onBack,
    required this.onSubmit,
  });

  final bool canSubmit;
  final bool submitting;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

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

    return ColoredBox(
      color: AppColors.surface.withValues(alpha: 0.94),
      child: ResponsivePage(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x2),
        child: Row(
          children: [
            IconButton(
              tooltip: '뒤로가기',
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: AppSpacing.x1),
            Expanded(
              child: Text(
                '후기 작성',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton(
              onPressed: submitting ? null : onSubmit,
              child: Text(submitting ? '등록 중' : '등록'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _StoryWriteHeaderDelegate oldDelegate) {
    return oldDelegate.canSubmit != canSubmit ||
        oldDelegate.submitting != submitting ||
        oldDelegate.onBack != onBack ||
        oldDelegate.onSubmit != onSubmit;
  }
}

class _StoryWritePanel extends StatelessWidget {
  const _StoryWritePanel({
    required this.certSearchController,
    required this.titleController,
    required this.subtitleController,
    required this.bodyController,
    required this.studyDaysController,
    required this.studyMethodController,
    required this.scoreController,
    required this.selectedCertification,
    required this.certifications,
    required this.loadingCertifications,
    required this.onCertificationSearchChanged,
    required this.onCertificationSelected,
  });

  final TextEditingController certSearchController;
  final TextEditingController titleController;
  final TextEditingController subtitleController;
  final TextEditingController bodyController;
  final TextEditingController studyDaysController;
  final TextEditingController studyMethodController;
  final TextEditingController scoreController;
  final CertificationSearchResult? selectedCertification;
  final List<CertificationSearchResult> certifications;
  final bool loadingCertifications;
  final ValueChanged<String> onCertificationSearchChanged;
  final ValueChanged<CertificationSearchResult> onCertificationSelected;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x5),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('자격증 선택', style: textTheme.labelLarge),
          const SizedBox(height: AppSpacing.x2),
          TextField(
            controller: certSearchController,
            onChanged: onCertificationSearchChanged,
            decoration: const InputDecoration(
              hintText: '합격한 자격증을 선택하세요',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.x2),
          if (selectedCertification != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                avatar: const Icon(Icons.workspace_premium_outlined, size: 16),
                label: Text(selectedCertification!.name),
              ),
            ),
          if (loadingCertifications)
            const LinearProgressIndicator()
          else
            _CertificationAutocompleteList(
              certifications: certifications,
              selectedCertification: selectedCertification,
              onSelected: onCertificationSelected,
            ),
          const SizedBox(height: AppSpacing.x5),
          TextField(
            controller: titleController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: '후기 제목',
              prefixIcon: Icon(Icons.title_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          TextField(
            controller: subtitleController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: '한 줄 요약',
              prefixIcon: Icon(Icons.short_text_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          TextField(
            controller: studyDaysController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: '공부일수',
              helperText: '일 단위로 입력하세요. 예: 21',
              suffixText: '일',
              prefixIcon: Icon(Icons.schedule_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          TextField(
            controller: studyMethodController,
            decoration: const InputDecoration(
              hintText: '공부 방법',
              prefixIcon: Icon(Icons.menu_book_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          TextField(
            controller: scoreController,
            decoration: const InputDecoration(
              hintText: '합격 성적',
              prefixIcon: Icon(Icons.verified_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          TextField(
            controller: bodyController,
            minLines: 8,
            maxLines: 14,
            decoration: const InputDecoration(
              hintText: '본문을 입력하세요',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 164),
                child: Icon(Icons.notes_rounded),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CertificationAutocompleteList extends StatelessWidget {
  const _CertificationAutocompleteList({
    required this.certifications,
    required this.selectedCertification,
    required this.onSelected,
  });

  final List<CertificationSearchResult> certifications;
  final CertificationSearchResult? selectedCertification;
  final ValueChanged<CertificationSearchResult> onSelected;

  @override
  Widget build(BuildContext context) {
    if (certifications.isEmpty || selectedCertification != null) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surfaceHigh),
      ),
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        itemCount: certifications.length.clamp(0, 6),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = certifications[index];

          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: const Icon(
              Icons.workspace_premium_outlined,
              color: AppColors.onSurfaceVariant,
            ),
            title: Text(
              item.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            subtitle: Text(
              item.category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => onSelected(item),
          );
        },
      ),
    );
  }
}
