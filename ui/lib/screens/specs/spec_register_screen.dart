import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/certification_search_data.dart';
import '../../models/user_spec.dart';
import '../../services/certification_search_api_client.dart';
import '../../services/user_spec_api_client.dart';
import 'spec_form_schema.dart';

class SpecRegisterScreen extends StatefulWidget {
  const SpecRegisterScreen(
      {required this.type,
      this.initial,
      this.client = const UserSpecApiClient(),
      this.searchClient = const CertificationSearchApiClient(),
      super.key});
  final SpecType type;
  final UserSpec? initial;
  final UserSpecApiClient client;
  final CertificationSearchApiClient searchClient;
  @override
  State<SpecRegisterScreen> createState() => _SpecRegisterScreenState();
}

class _SpecRegisterScreenState extends State<SpecRegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _controllers = <String, TextEditingController>{};
  final _values = <String, dynamic>{};
  CertificationSearchApiClient get _search => widget.searchClient;
  Timer? _debounce;
  int _searchRevision = 0;
  List<CertificationSearchResult> _matches = [];
  bool _saving = false;
  SpecFormSchema get _schema => specForms[widget.type]!;
  bool get _compact =>
      widget.type == SpecType.certification ||
      widget.type == SpecType.languageScore;
  Color get _primary => const Color(0xFF0057BD);

  @override
  void initState() {
    super.initState();
    _values.addAll(widget.initial?.data ?? {});
    for (final section in _schema.sections) {
      for (final field in section.fields) {
        _controllers[field.key] = TextEditingController(
            text: [
          SpecInput.text,
          SpecInput.number,
          SpecInput.date,
          SpecInput.month
        ].contains(field.input)
                ? _values[field.key]?.toString() ?? ''
                : '');
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  bool _visible(SpecField field) {
    if (field.visibleWhen == null) return true;
    if (field.visibleWhen == '!ongoing') return true;
    final negative = field.visibleWhen!.startsWith('!');
    final key = negative ? field.visibleWhen!.substring(1) : field.visibleWhen!;
    return negative ? _values[key] != true : _values[key] == true;
  }

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    final data = Map<String, dynamic>.from(_values);
    for (final section in _schema.sections) {
      for (final field in section.fields) {
        if ([SpecInput.text, SpecInput.date, SpecInput.month, SpecInput.number]
            .contains(field.input)) {
          final value = _controllers[field.key]!.text.trim();
          data[field.key] = value.isEmpty
              ? null
              : field.input == SpecInput.number
                  ? double.parse(value)
                  : field.input == SpecInput.month
                      ? value.replaceAll('.', '-')
                      : value;
        }
        if (field.input == SpecInput.tags) {
          final pending = _controllers[field.key]!
              .text
              .trim()
              .replaceFirst(RegExp(r'^#+'), '')
              .trim();
          final tags = <String>{
            ...List<String>.from(data[field.key] as List? ?? []),
            if (pending.isNotEmpty) pending
          }.toList();
          if (field.maxLength != null && tags.length > field.maxLength!) {
            _notice('태그는 최대 ${field.maxLength}개까지 입력할 수 있습니다.');
            return;
          }
          data[field.key] = tags;
        }
      }
    }
    for (final field in _schema.sections
        .expand((section) => section.fields)
        .where((field) => field.required)) {
      final value = data[field.key];
      if (value == null ||
          value is String && value.trim().isEmpty ||
          value is List && value.isEmpty) {
        _notice('${field.label.isEmpty ? field.key : field.label} 항목을 입력하세요.');
        return;
      }
    }
    _debounce?.cancel();
    _searchRevision++;
    setState(() {
      _matches = [];
      _saving = true;
    });
    try {
      final saved = await widget.client
          .save(type: widget.type, data: data, id: widget.initial?.id);
      if (mounted) Navigator.pop(context, saved);
    } catch (error) {
      if (mounted) {
        setState(() => _saving = false);
        _notice(error.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  void _notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  void _searchName(String query, {bool edited = true}) {
    if (_saving) return;
    if (edited) _values['certificationId'] = null;
    _debounce?.cancel();
    final revision = ++_searchRevision;
    setState(() => _matches = []);
    if (query.trim().isEmpty) return;
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      try {
        final matches = await _search.search(query: query.trim());
        if (mounted && revision == _searchRevision) {
          setState(() => _matches = matches);
        }
      } catch (_) {
        if (mounted && revision == _searchRevision) {
          setState(() => _matches = []);
        }
      }
    });
  }

  void _selectCertification(CertificationSearchResult item) {
    if (_saving) return;
    _debounce?.cancel();
    _searchRevision++;
    setState(() {
      _values['certificationId'] = item.id;
      _controllers['name']!.text = item.name;
      _controllers['issuer']!.text = item.organization ?? '';
      _matches = [];
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF5F7F9);
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(
            fontFamily: 'SpecInter',
            bodyColor: const Color(0xFF2C2F31),
            displayColor: const Color(0xFF2C2F31)),
        colorScheme: ColorScheme.fromSeed(
            seedColor: _primary, brightness: Brightness.light),
      ),
      child: Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          toolbarHeight: 64,
          backgroundColor: background,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          titleSpacing: 16,
          title: Row(children: [
            SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                    tooltip: '뒤로 가기',
                    icon: const Icon(Icons.arrow_back, size: 24),
                    onPressed: _saving ? null : () => Navigator.pop(context))),
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                        widget.type == SpecType.certification
                            ? 'Certificate Detail Entry'
                            : widget.type == SpecType.languageScore
                                ? 'Spec Information Input'
                                : widget.type.isExamScore
                                    ? '스펙 정보 입력'
                                    : 'Activity Experience Form',
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'SpecJakarta',
                            fontWeight: FontWeight.w700)))),
            SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                    tooltip: '닫기',
                    icon: const Icon(Icons.close, size: 24),
                    onPressed: _saving ? null : () => Navigator.pop(context))),
            const SizedBox(width: 4),
            CircleAvatar(
                radius: 16,
                backgroundColor: _primary,
                child: const Icon(Icons.person_outline,
                    size: 18, color: Colors.white)),
          ]),
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                children: [
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                            color:
                                const Color(0xFFC7CFFF).withValues(alpha: .6),
                            borderRadius: BorderRadius.circular(999)),
                        child: Text(
                            '${widget.type.isExamScore ? '시험·성적 스펙' : '활동·경험 스토리'} > ${widget.type.label}',
                            style: TextStyle(
                                fontSize: 12,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                                color: _primary)),
                      )),
                  const SizedBox(height: 12),
                  Text(_schema.title,
                      style: TextStyle(
                          fontSize:
                              widget.type == SpecType.certification ? 20 : 24,
                          height: 1.33,
                          fontFamily: 'SpecJakarta',
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(_schema.description,
                      style: const TextStyle(
                          fontSize: 12,
                          height: 1.625,
                          color: Color(0xFF595C5E))),
                  const SizedBox(height: 20),
                  for (final section in _schema.sections) ...[
                    _section(section),
                    SizedBox(
                        height: _compact
                            ? (widget.type == SpecType.certification ? 16 : 20)
                            : 24),
                  ],
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Align(
            heightFactor: 1,
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _saving ? null : _submit,
                      style: FilledButton.styleFrom(
                          backgroundColor: _primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: _saving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Text(widget.initial == null ? '등록하기' : '저장하기',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                    )),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _section(SpecSection section) {
    final fields = section.fields.where(_visible).toList();
    final children = <Widget>[];
    if (section.title.isNotEmpty) {
      children.add(Row(children: [
        if (widget.type == SpecType.languageScore)
          Icon(
            section.title.startsWith('어학')
                ? Icons.language
                : section.title.startsWith('취득')
                    ? Icons.military_tech_outlined
                    : section.title.startsWith('응시')
                        ? Icons.event_available
                        : Icons.apartment,
            size: 18,
            color: _primary,
          )
        else
          Container(
              width: _compact ? 3 : 7,
              height: _compact ? 14 : 18,
              decoration: BoxDecoration(
                  color: _primary, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 8),
        Expanded(
            child: Text(section.title,
                style: TextStyle(
                    fontSize: _compact
                        ? 12
                        : widget.type == SpecType.award
                            ? 14
                            : 16,
                    height: 1.4,
                    fontWeight: FontWeight.w700))),
      ]));
      children.add(const SizedBox(height: 16));
    }
    if (widget.type == SpecType.certification &&
        section.fields.any((field) => field.key == 'acquiredOn')) {
      children.add(const Text('취득 상태',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)));
      children.add(const SizedBox(height: 8));
      children.add(Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: const Color(0xFFEEF1F3),
              borderRadius: BorderRadius.circular(12)),
          child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check_circle_outline, size: 16, color: _primary),
                    const SizedBox(width: 6),
                    Text('취득 완료',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _primary))
                  ])))));
      children.add(const SizedBox(height: 16));
    }
    for (var i = 0; i < fields.length; i++) {
      final field = fields[i];
      if (i > 0) children.add(const SizedBox(height: 16));
      if (field.key == 'ongoing' && i + 1 < fields.length) {
        final next = fields[i + 1];
        children.add(Row(children: [
          Expanded(
              child: Text(next.label,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600))),
          _toggle(field)
        ]));
        children.add(const SizedBox(height: 6));
        final end = i + 2 < fields.length && fields[i + 2].key == 'endedMonth'
            ? fields[i + 2]
            : null;
        children
            .add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _input(next)),
          if (end != null) ...[
            const SizedBox(width: 8),
            Expanded(child: _input(end))
          ]
        ]));
        i += end == null ? 1 : 2;
      } else if (field.half && i + 1 < fields.length && fields[i + 1].half) {
        final next = fields[++i];
        if (next.label.isEmpty) {
          if (field.label.isNotEmpty) {
            children.add(Text(field.label,
                style: const TextStyle(
                    fontSize: 12, height: 1.5, fontWeight: FontWeight.w600)));
            children.add(const SizedBox(height: 6));
          }
          children
              .add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: _input(field)),
            const SizedBox(width: 8),
            Expanded(child: _input(next))
          ]));
          continue;
        }
        children
            .add(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _field(field)),
          const SizedBox(width: 8),
          Expanded(child: _field(next))
        ]));
      } else {
        children.add(_field(field));
      }
    }
    return Container(
      padding: EdgeInsets.all(_compact ? 16 : 20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(_compact ? 12 : 16),
          boxShadow: const [
            BoxShadow(
                color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 2))
          ]),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _field(SpecField field) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (field.label.isNotEmpty && field.input != SpecInput.toggle) ...[
          Row(children: [
            Expanded(
                child: Text('${field.label}${field.required ? ' *' : ''}',
                    style: const TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        fontWeight: FontWeight.w600))),
            if (widget.type == SpecType.certification && field.key == 'name')
              TextButton(
                  style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 18),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  onPressed: _saving
                      ? null
                      : () => _searchName(_controllers['name']!.text,
                          edited: false),
                  child:
                      const Text('공식 명칭 검색', style: TextStyle(fontSize: 11))),
          ]),
          const SizedBox(height: 6),
        ],
        _input(field),
        if (field.key == 'name' && widget.type == SpecType.certification) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                const Text('추천:',
                    style: TextStyle(fontSize: 11, color: Color(0xFF595C5E))),
                const SizedBox(width: 6),
                for (final name in ['정보처리기사', 'SQLD', '컴퓨터활용능력 1급', 'ADsP'])
                  Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                          shape: const StadiumBorder(),
                          label: Text(
                              '#${name == '컴퓨터활용능력 1급' ? '컴활1급' : name}',
                              style: const TextStyle(fontSize: 11)),
                          backgroundColor: const Color(0xFFE5E9EB),
                          side: BorderSide.none,
                          visualDensity: VisualDensity.compact,
                          onPressed: () {
                            _controllers['name']!.text = name;
                            _searchName(name);
                          }))
              ])),
        ],
        if (field.key == 'name' && widget.type == SpecType.certification)
          for (final match in _matches)
            ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(match.name, style: const TextStyle(fontSize: 13)),
                subtitle: Text(match.organization ?? '',
                    style: const TextStyle(fontSize: 11)),
                onTap: () => _selectCertification(match)),
      ]);

  Widget _input(SpecField field) {
    if (field.input == SpecInput.toggle) return _toggle(field);
    if (field.input == SpecInput.choices) return _choices(field);
    if (field.input == SpecInput.tags) return _tags(field);
    if (field.input == SpecInput.reminders) {
      final selected = List<num>.from(_values[field.key] as List? ?? []);
      return Wrap(spacing: 8, runSpacing: 4, children: [
        for (final days in [60, 30, 7])
          FilterChip(
              label: Text('만료 $days일 전', style: const TextStyle(fontSize: 11)),
              selected: selected.contains(days),
              onSelected: (value) => setState(() => _values[field.key] = value
                  ? [...selected, days]
                  : selected.where((item) => item != days).toList()))
      ]);
    }
    final isDate = field.input == SpecInput.date;
    final isMonth = field.input == SpecInput.month;
    final numeric = field.input == SpecInput.number;
    return TextFormField(
      key: ValueKey('spec-field-${field.key}'),
      controller: _controllers[field.key],
      enabled: field.key != 'endedMonth' || _values['ongoing'] != true,
      readOnly: isDate,
      minLines: field.rows,
      maxLines: field.rows,
      maxLength: field.maxLength,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : field.rows > 1
              ? TextInputType.multiline
              : TextInputType.text,
      style: TextStyle(
          fontSize: field.rows > 1 && widget.type != SpecType.externalActivity
              ? 12
              : 14,
          height: field.rows > 1 ? 1.625 : 1.4),
      decoration: InputDecoration(
        constraints: field.rows == 1
            ? BoxConstraints(
                minHeight: _compact ||
                        widget.type == SpecType.award ||
                        widget.type == SpecType.project ||
                        isDate ||
                        isMonth
                    ? 44
                    : 48)
            : null,
        hintText: isDate
            ? (field.key == 'startedOn'
                ? '시작일'
                : field.key == 'completedOn'
                    ? '수료일'
                    : '날짜 선택')
            : field.hint,
        hintStyle: const TextStyle(color: Color(0xFF747779)),
        counterStyle: const TextStyle(fontSize: 10, color: Color(0xFF747779)),
        filled: true,
        fillColor: const Color(0xFFEEF1F3),
        isDense: true,
        contentPadding:
            EdgeInsets.symmetric(horizontal: 14, vertical: _compact ? 12 : 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_compact ? 8 : 12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_compact ? 8 : 12),
            borderSide: BorderSide(color: _primary.withValues(alpha: .3))),
        prefixIcon: widget.type == SpecType.certification && field.key == 'name'
            ? const Icon(Icons.search, size: 20)
            : null,
        suffixText: field.key == 'hours'
            ? '시간'
            : field.key == 'score'
                ? '점'
                : null,
        suffixIcon: isDate
            ? IconButton(
                tooltip:
                    _controllers[field.key]!.text.isEmpty ? '날짜 선택' : '날짜 지우기',
                icon: Icon(
                    _controllers[field.key]!.text.isEmpty
                        ? Icons.calendar_today_outlined
                        : Icons.close,
                    size: 18),
                onPressed: () => _controllers[field.key]!.text.isEmpty
                    ? _pickDate(field)
                    : setState(() => _controllers[field.key]!.clear()))
            : null,
      ),
      onTap: isDate ? () => _pickDate(field) : null,
      onChanged: field.key == 'name' && widget.type == SpecType.certification
          ? _searchName
          : null,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return field.required ? '입력해주세요' : null;
        }
        if (numeric &&
            (double.tryParse(value.trim()) == null ||
                !double.parse(value.trim()).isFinite ||
                double.parse(value.trim()) < 0 ||
                field.key == 'hours' && double.parse(value.trim()) <= 0)) {
          return '올바른 숫자를 입력하세요';
        }
        if (isMonth &&
            !RegExp(r'^\d{4}[.-](0[1-9]|1[0-2])$').hasMatch(value.trim())) {
          return 'YYYY.MM 형식으로 입력하세요';
        }
        return null;
      },
    );
  }

  Future<void> _pickDate(SpecField field) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
        context: context,
        locale: const Locale('ko'),
        initialDate: DateTime.tryParse(_controllers[field.key]!.text) ?? now,
        firstDate: DateTime(1900),
        lastDate: DateTime(now.year + 30));
    if (selected != null && mounted) {
      setState(() => _controllers[field.key]!.text =
          '${selected.year.toString().padLeft(4, '0')}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}');
    }
  }

  Widget _toggle(SpecField field) => field.key == 'lifetime' ||
          field.key == 'reminder'
      ? Row(children: [
          Expanded(
              child: Text(field.label,
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF595C5E)))),
          const SizedBox(width: 12),
          SizedBox(
              width: 40,
              height: 24,
              child: FittedBox(
                  child: Switch(
                      value: _values[field.key] == true,
                      activeTrackColor: _primary,
                      onChanged: (value) =>
                          setState(() => _values[field.key] = value)))),
        ])
      : Row(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                  value: _values[field.key] == true,
                  activeColor: _primary,
                  onChanged: (value) =>
                      setState(() => _values[field.key] = value))),
          const SizedBox(width: 4),
          Flexible(
              child: Text(field.label,
                  style:
                      const TextStyle(fontSize: 11, color: Color(0xFF595C5E)))),
        ]);

  Widget _choices(SpecField field) {
    bool selected(String option) => field.key == 'gpaScale'
        ? _values[field.key] == double.parse(option)
        : _values[field.key] == option;
    final horizontal = field.key == 'exam';
    final grid = ['projectType', 'degree', 'activityType', 'trainingType']
        .contains(field.key);
    final widgets = [
      for (final option in field.options)
        Material(
          color: selected(option) ? _primary : const Color(0xFFEEF1F3),
          borderRadius: BorderRadius.circular(
              horizontal || field.key == 'prize' ? 999 : 12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _values[field.key] = selected(option)
                ? null
                : field.key == 'gpaScale'
                    ? double.parse(option)
                    : option),
            child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal:
                        horizontal || grid || field.key == 'prize' ? 12 : 8,
                    vertical: 10),
                child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (horizontal || field.key == 'projectType') ...[
                        Icon(
                            horizontal
                                ? option == 'TOEIC'
                                    ? Icons.menu_book_outlined
                                    : option == 'OPIc'
                                        ? Icons.record_voice_over_outlined
                                        : Icons.language
                                : Icons.school_outlined,
                            size: 16,
                            color: selected(option)
                                ? Colors.white
                                : const Color(0xFF595C5E)),
                        const SizedBox(width: 4)
                      ],
                      Flexible(
                          child: Text(
                              field.key == 'degree'
                                  ? option == '학사'
                                      ? '학사 (4년제)'
                                      : option == '전문학사'
                                          ? '전문학사 (2/3년제)'
                                          : option
                                  : option,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  fontWeight: FontWeight.w600,
                                  color: selected(option)
                                      ? Colors.white
                                      : const Color(0xFF595C5E)))),
                      if (field.key == 'activityType') ...[
                        const SizedBox(width: 4),
                        Icon(Icons.check_circle_outline,
                            size: 16,
                            color: selected(option)
                                ? Colors.white
                                : Colors.transparent)
                      ],
                    ])),
          ),
        )
    ];
    if (horizontal) {
      return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final widget in widgets)
              Padding(padding: const EdgeInsets.only(right: 8), child: widget)
          ]));
    }
    if (grid) {
      return LayoutBuilder(
          builder: (context, constraints) =>
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final widget in widgets)
                  SizedBox(width: (constraints.maxWidth - 8) / 2, child: widget)
              ]));
    }
    if (field.key == 'prize' || field.key == 'additionalMajorType') {
      return Wrap(spacing: 6, runSpacing: 6, children: widgets);
    }
    return Row(children: [
      for (var i = 0; i < widgets.length; i++) ...[
        if (i > 0) const SizedBox(width: 8),
        Expanded(child: widgets[i])
      ]
    ]);
  }

  Widget _tags(SpecField field) {
    final tags = List<String>.from(_values[field.key] as List? ?? []);
    void add() {
      final text = _controllers[field.key]!
          .text
          .trim()
          .replaceFirst(RegExp(r'^#+'), '')
          .trim();
      if (text.isEmpty) return;
      if (!tags.contains(text) &&
          field.maxLength != null &&
          tags.length >= field.maxLength!) {
        _notice('태그는 최대 ${field.maxLength}개까지 입력할 수 있습니다.');
        return;
      }
      setState(() {
        _values[field.key] = {...tags, text}.toList();
        _controllers[field.key]!.clear();
      });
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: 6, runSpacing: 6, children: [
        for (final tag in tags)
          InputChip(
              label: Text('#$tag', style: const TextStyle(fontSize: 11)),
              onDeleted: () => setState(() => _values[field.key] =
                  tags.where((item) => item != tag).toList()))
      ]),
      if (tags.isNotEmpty) const SizedBox(height: 8),
      TextField(
          controller: _controllers[field.key],
          style: const TextStyle(fontSize: 12),
          onSubmitted: (_) => add(),
          decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFEEF1F3),
              hintText: field.hint,
              hintStyle: const TextStyle(fontSize: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              suffixIcon: IconButton(
                  tooltip: '태그 추가',
                  icon: Icon(Icons.add, size: 20, color: _primary),
                  onPressed: add))),
    ]);
  }
}
