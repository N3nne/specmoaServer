import 'dart:async';

import 'package:flutter/material.dart';

import '../auth/auth_session.dart';
import '../models/certification_search_data.dart';
import '../services/certification_search_api_client.dart';
import '../services/community_qna_api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_page.dart';

class CommunityQuestionWriteScreen extends StatefulWidget {
  const CommunityQuestionWriteScreen({
    this.initialCertification,
    super.key,
  });

  final CertificationSearchResult? initialCertification;

  @override
  State<CommunityQuestionWriteScreen> createState() =>
      _CommunityQuestionWriteScreenState();
}

class _CommunityQuestionWriteScreenState
    extends State<CommunityQuestionWriteScreen> {
  final _certClient = const CertificationSearchApiClient();
  final _qnaClient = const CommunityQnaApiClient();
  final _certSearchController = TextEditingController();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  Timer? _certSearchDebounce;
  CertificationSearchResult? _selectedCertification;
  List<CertificationSearchResult> _certifications = const [];
  bool _loadingCertifications = false;
  bool _submitting = false;
  bool _anonymous = false;

  bool get _canSubmit =>
      _selectedCertification != null &&
      _titleController.text.trim().length >= 4 &&
      _bodyController.text.trim().length >= 10 &&
      !_submitting;

  @override
  void initState() {
    super.initState();
    _selectedCertification = widget.initialCertification;
    if (_selectedCertification != null) {
      _certSearchController.text = _selectedCertification!.name;
    }
    _titleController.addListener(_onInputChanged);
    _bodyController.addListener(_onInputChanged);
  }

  @override
  void dispose() {
    _certSearchDebounce?.cancel();
    _certSearchController.dispose();
    _titleController.dispose();
    _bodyController.dispose();
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
              delegate: _WriteHeaderDelegate(
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
                    _WritePanel(
                      certSearchController: _certSearchController,
                      titleController: _titleController,
                      bodyController: _bodyController,
                      selectedCertification: _selectedCertification,
                      certifications: _certifications,
                      loadingCertifications: _loadingCertifications,
                      anonymous: _anonymous,
                      onCertificationSearchChanged:
                          _onCertificationSearchChanged,
                      onCertificationSelected: _selectCertification,
                      onAnonymousChanged: (value) {
                        setState(() => _anonymous = value);
                      },
                    ),
                    const SizedBox(height: AppSpacing.x5),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _canSubmit ? _submit : null,
                        icon: _submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(_submitting ? '등록 중' : '등록하기'),
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
    });
  }

  void _onInputChanged() {
    setState(() {});
  }

  Future<void> _submit() async {
    if (!_canSubmit) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final userId = AuthScope.of(context).user?.id ?? '';

    setState(() => _submitting = true);
    try {
      final item = await _qnaClient.createQuestion(
        userId: userId,
        certificationId: _selectedCertification!.id,
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        tags: const [],
        isAnonymous: _anonymous,
      );
      if (!mounted) {
        return;
      }
      navigator.pop(item);
    } catch (error) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
              content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

class _WriteHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _WriteHeaderDelegate({
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
                '질문 작성',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            TextButton(
              onPressed: canSubmit ? onSubmit : null,
              child: Text(submitting ? '등록 중' : '등록'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _WriteHeaderDelegate oldDelegate) {
    return oldDelegate.canSubmit != canSubmit ||
        oldDelegate.submitting != submitting ||
        oldDelegate.onBack != onBack ||
        oldDelegate.onSubmit != onSubmit;
  }
}

class _WritePanel extends StatelessWidget {
  const _WritePanel({
    required this.certSearchController,
    required this.titleController,
    required this.bodyController,
    required this.selectedCertification,
    required this.certifications,
    required this.loadingCertifications,
    required this.anonymous,
    required this.onCertificationSearchChanged,
    required this.onCertificationSelected,
    required this.onAnonymousChanged,
  });

  final TextEditingController certSearchController;
  final TextEditingController titleController;
  final TextEditingController bodyController;
  final CertificationSearchResult? selectedCertification;
  final List<CertificationSearchResult> certifications;
  final bool loadingCertifications;
  final bool anonymous;
  final ValueChanged<String> onCertificationSearchChanged;
  final ValueChanged<CertificationSearchResult> onCertificationSelected;
  final ValueChanged<bool> onAnonymousChanged;

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
              hintText: '질문할 자격증을 선택하세요',
              prefixIcon: Icon(Icons.search_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.x2),
          if (selectedCertification != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                avatar: const Icon(Icons.verified_outlined, size: 16),
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
              hintText: '질문 제목을 입력하세요',
              prefixIcon: Icon(Icons.title_rounded),
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          TextField(
            controller: bodyController,
            minLines: 8,
            maxLines: 12,
            decoration: const InputDecoration(
              hintText: '본문을 입력하세요',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 142),
                child: Icon(Icons.notes_rounded),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          SwitchListTile.adaptive(
            value: anonymous,
            onChanged: onAnonymousChanged,
            contentPadding: EdgeInsets.zero,
            title: Text(
              '익명으로 질문하기',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w800,
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
    if (certifications.isEmpty) {
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
          final selected = selectedCertification?.id == item.id;

          return ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.workspace_premium_outlined,
              color: selected ? AppColors.primary : AppColors.onSurfaceVariant,
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
