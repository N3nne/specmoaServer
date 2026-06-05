import 'dart:async';

import 'package:flutter/material.dart';

import '../auth/auth_session.dart';
import '../models/certification_search_data.dart';
import '../services/certification_search_api_client.dart';
import '../services/user_certification_api_client.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_page.dart';

enum _RegisterMode { owned, preparing }

class CertificationRegisterScreen extends StatefulWidget {
  const CertificationRegisterScreen({super.key});

  @override
  State<CertificationRegisterScreen> createState() =>
      _CertificationRegisterScreenState();
}

class _CertificationRegisterScreenState
    extends State<CertificationRegisterScreen> {
  final _searchClient = const CertificationSearchApiClient();
  final _userCertificationClient = const UserCertificationApiClient();
  final _certSearchController = TextEditingController();
  final _certificateNumberController = TextEditingController();
  final _notesController = TextEditingController();

  Timer? _searchDebounce;
  _RegisterMode _mode = _RegisterMode.owned;
  CertificationSearchResult? _selectedCertification;
  List<CertificationSearchResult> _certifications = const [];
  DateTime? _certifiedOn;
  DateTime? _targetExamDate;
  bool _loadingCertifications = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _certSearchController.addListener(() => setState(() {}));
    _certificateNumberController.addListener(() => setState(() {}));
    _notesController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _certSearchController.dispose();
    _certificateNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_submitting || _selectedCertification == null) {
      return false;
    }
    if (_mode == _RegisterMode.owned) {
      return _certifiedOn != null &&
          _certificateNumberController.text.trim().isNotEmpty;
    }
    return _targetExamDate != null;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate:
                  _RegisterHeaderDelegate(onBack: Navigator.of(context).pop),
            ),
            SliverToBoxAdapter(
              child: ResponsivePage(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppSpacing.x6),
                    Text(
                      '자격증을 등록해볼까요?',
                      style: textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    Text(
                      '보유 중인 자격증과 준비 중인 자격증을 나눠 관리할 수 있어요.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x8),
                    _RegisterFormCard(
                      mode: _mode,
                      certSearchController: _certSearchController,
                      certificateNumberController: _certificateNumberController,
                      notesController: _notesController,
                      selectedCertification: _selectedCertification,
                      certifications: _certifications,
                      loadingCertifications: _loadingCertifications,
                      certifiedOn: _certifiedOn,
                      targetExamDate: _targetExamDate,
                      onModeChanged: _changeMode,
                      onCertificationSearchChanged:
                          _onCertificationSearchChanged,
                      onCertificationSelected: _selectCertification,
                      onCertifiedOnPick: () => _pickDate(isCertifiedOn: true),
                      onTargetExamDatePick: () =>
                          _pickDate(isCertifiedOn: false),
                    ),
                    const SizedBox(height: 116),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x5,
            AppSpacing.x4,
            AppSpacing.x5,
            AppSpacing.x6,
          ),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.96),
            boxShadow: AppShadows.soft,
          ),
          child: FilledButton.icon(
            onPressed: _canSubmit ? _submit : null,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check_circle_rounded),
            label: Text(_submitting ? '등록 중' : '등록하기'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _changeMode(_RegisterMode value) {
    setState(() {
      _mode = value;
      _certifiedOn = null;
      _targetExamDate = null;
      _certificateNumberController.clear();
      _notesController.clear();
    });
  }

  void _onCertificationSearchChanged(String value) {
    if (_selectedCertification != null &&
        value.trim() != _selectedCertification!.name) {
      setState(() => _selectedCertification = null);
    }
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 260),
      _loadCertifications,
    );
  }

  Future<void> _loadCertifications() async {
    final query = _certSearchController.text.trim();
    if (query.isEmpty || _selectedCertification != null) {
      setState(() => _certifications = const []);
      return;
    }

    setState(() => _loadingCertifications = true);
    try {
      final items = await _searchClient.search(query: query, limit: 8);
      if (mounted) {
        setState(() => _certifications = items);
      }
    } finally {
      if (mounted) {
        setState(() => _loadingCertifications = false);
      }
    }
  }

  void _selectCertification(CertificationSearchResult item) {
    setState(() {
      _selectedCertification = item;
      _certSearchController.text = item.name;
      _certifications = const [];
    });
  }

  Future<void> _pickDate({required bool isCertifiedOn}) async {
    final now = DateTime.now();
    final initial = isCertifiedOn
        ? _certifiedOn ?? now
        : _targetExamDate ?? now.add(const Duration(days: 30));
    final picked = await showDatePicker(
      context: context,
      locale: const Locale('ko', 'KR'),
      initialDate: initial,
      firstDate: DateTime(now.year - 20),
      lastDate: DateTime(now.year + 10),
    );
    if (picked == null || !mounted) {
      return;
    }

    setState(() {
      if (isCertifiedOn) {
        _certifiedOn = picked;
      } else {
        _targetExamDate = picked;
      }
    });
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
      await _userCertificationClient.register(
        userId: userId,
        certificationId: _selectedCertification!.id,
        status: _mode == _RegisterMode.owned ? 'certified' : 'planned',
        certifiedOn:
            _mode == _RegisterMode.owned ? _dateString(_certifiedOn!) : null,
        certificateNumber: _mode == _RegisterMode.owned
            ? _certificateNumberController.text.trim()
            : null,
        targetExamDate: _mode == _RegisterMode.preparing
            ? _dateString(_targetExamDate!)
            : null,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      navigator.pop(true);
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

  String _dateString(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

class _RegisterFormCard extends StatelessWidget {
  const _RegisterFormCard({
    required this.mode,
    required this.certSearchController,
    required this.certificateNumberController,
    required this.notesController,
    required this.selectedCertification,
    required this.certifications,
    required this.loadingCertifications,
    required this.certifiedOn,
    required this.targetExamDate,
    required this.onModeChanged,
    required this.onCertificationSearchChanged,
    required this.onCertificationSelected,
    required this.onCertifiedOnPick,
    required this.onTargetExamDatePick,
  });

  final _RegisterMode mode;
  final TextEditingController certSearchController;
  final TextEditingController certificateNumberController;
  final TextEditingController notesController;
  final CertificationSearchResult? selectedCertification;
  final List<CertificationSearchResult> certifications;
  final bool loadingCertifications;
  final DateTime? certifiedOn;
  final DateTime? targetExamDate;
  final ValueChanged<_RegisterMode> onModeChanged;
  final ValueChanged<String> onCertificationSearchChanged;
  final ValueChanged<CertificationSearchResult> onCertificationSelected;
  final VoidCallback onCertifiedOnPick;
  final VoidCallback onTargetExamDatePick;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x6),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ModeSwitch(mode: mode, onChanged: onModeChanged),
          const SizedBox(height: AppSpacing.x6),
          const _FieldLabel('자격증 이름'),
          const SizedBox(height: AppSpacing.x2),
          TextField(
            controller: certSearchController,
            onChanged: onCertificationSearchChanged,
            decoration: const InputDecoration(
              hintText: '자격증명을 검색하세요',
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
          const SizedBox(height: AppSpacing.x6),
          if (mode == _RegisterMode.owned) ...[
            const _FieldLabel('취득일'),
            const SizedBox(height: AppSpacing.x2),
            _DateField(
              value: _formatDate(certifiedOn),
              hintText: '취득일을 선택하세요',
              onTap: onCertifiedOnPick,
            ),
            const SizedBox(height: AppSpacing.x6),
            const _FieldLabel('자격증 번호'),
            const SizedBox(height: AppSpacing.x2),
            TextField(
              controller: certificateNumberController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: '자격증 번호를 입력하세요',
                prefixIcon: Icon(Icons.confirmation_number_outlined),
              ),
            ),
          ] else ...[
            const _FieldLabel('목표 시험일'),
            const SizedBox(height: AppSpacing.x2),
            _DateField(
              value: _formatDate(targetExamDate),
              hintText: '목표 시험일을 선택하세요',
              onTap: onTargetExamDatePick,
            ),
          ],
          const SizedBox(height: AppSpacing.x6),
          const _FieldLabel('메모', optional: true),
          const SizedBox(height: AppSpacing.x2),
          TextField(
            controller: notesController,
            minLines: 4,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: '간단한 메모를 입력하세요',
              alignLabelWithHint: true,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return '';
    }
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}.$month.$day';
  }
}

class _ModeSwitch extends StatelessWidget {
  const _ModeSwitch({required this.mode, required this.onChanged});

  final _RegisterMode mode;
  final ValueChanged<_RegisterMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeButton(
              label: '보유 자격증',
              selected: mode == _RegisterMode.owned,
              onTap: () => onChanged(_RegisterMode.owned),
            ),
          ),
          Expanded(
            child: _ModeButton(
              label: '준비 자격증',
              selected: mode == _RegisterMode.preparing,
              onTap: () => onChanged(_RegisterMode.preparing),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.x3),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected ? AppColors.onPrimary : AppColors.onSurface,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.value,
    required this.hintText,
    required this.onTap,
  });

  final String value;
  final String hintText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextField(
      readOnly: true,
      controller: TextEditingController(text: value),
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.calendar_today_rounded),
        suffixIcon: IconButton(
          onPressed: onTap,
          icon: const Icon(Icons.edit_calendar_rounded),
        ),
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
      margin: const EdgeInsets.only(top: AppSpacing.x2),
      decoration: BoxDecoration(
        color: AppColors.surfaceLowest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surfaceHigh),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: certifications.length.clamp(0, 6),
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = certifications[index];
          return ListTile(
            dense: true,
            title: Text(item.name),
            subtitle: item.category.isEmpty ? null : Text(item.category),
            onTap: () => onSelected(item),
          );
        },
      ),
    );
  }
}

class _RegisterHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _RegisterHeaderDelegate({required this.onBack});

  final VoidCallback onBack;

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
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x3),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded),
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.x1),
            Text('자격증 등록', style: textTheme.titleLarge),
          ],
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _RegisterHeaderDelegate oldDelegate) =>
      oldDelegate.onBack != onBack;
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label, {this.optional = false});

  final String label;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: label,
        children: [
          TextSpan(
            text: optional ? ' (선택)' : ' *',
            style: TextStyle(
              color: optional ? AppColors.onSurfaceVariant : AppColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w800,
          ),
    );
  }
}
