import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/utils/constants.dart';
import '../../../models/life_event.dart';
import '../../../widgets/common/app_image.dart';
import '../../auth/providers/auth_providers.dart';
import '../../timeline/providers/life_event_providers.dart';

class LifeEventFormScreen extends ConsumerStatefulWidget {
  final String? eventId;

  const LifeEventFormScreen({super.key, this.eventId});

  bool get isEditing => eventId != null;

  @override
  ConsumerState<LifeEventFormScreen> createState() => _LifeEventFormScreenState();
}

class _LifeEventFormScreenState extends ConsumerState<LifeEventFormScreen> {
  static const _titleMaxLength = 50;

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();

  // 新規作成時は今月を初期値にして、入力の手間を減らす。
  int _year = DateTime.now().year;
  int _month = DateTime.now().month;
  String _category = LifeEventCategories.all.first;
  String _emotionLabel = '普通';
  bool _isTurningPoint = false;
  String _visibility = VisibilityOption.public;
  final List<File> _newImages = [];
  List<String> _existingImageUrls = [];
  bool _loadedInitialValues = false;
  bool _isSaving = false;

  /// 入力内容が変わったか。戻るときに破棄の確認を出すために使う。
  bool _isDirty = false;

  void _loadFromEvent(LifeEvent? event) {
    if (_loadedInitialValues || event == null) return;
    _titleController.text = event.title;
    _bodyController.text = event.body;
    final parts = event.occurredYearMonth.split('-');
    if (parts.length == 2) {
      _year = int.tryParse(parts[0]) ?? _year;
      _month = int.tryParse(parts[1]) ?? _month;
    }
    _category = event.category;
    _emotionLabel = event.emotionTag;
    _isTurningPoint = event.isTurningPoint;
    _visibility = event.visibility.name;
    _existingImageUrls = List<String>.from(event.imageUrls);
    _loadedInitialValues = true;
  }

  /// 入力値を変更し、未保存の変更ありとして記録する。
  void _update(VoidCallback change) {
    setState(() {
      change();
      _isDirty = true;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      _update(() => _newImages.addAll(picked.map((p) => File(p.path))));
    }
  }

  Future<void> _pickYearMonth() async {
    final result = await showDialog<(int, int)>(
      context: context,
      builder: (context) => _YearMonthPickerDialog(initialYear: _year, initialMonth: _month),
    );
    if (result != null) {
      _update(() {
        _year = result.$1;
        _month = result.$2;
      });
    }
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('入力内容を破棄しますか？'),
        content: const Text('保存していない内容は失われます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('編集を続ける'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('破棄する'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未入力の項目があります。赤く表示された欄を確認してください。')),
      );
      return;
    }
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSaving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final occurredYearMonth =
          '${_year.toString().padLeft(4, '0')}-${_month.toString().padLeft(2, '0')}';
      final emotionScore = EmotionTag.scoreFor(_emotionLabel);

      if (widget.isEditing) {
        var imageUrls = _existingImageUrls;
        if (_newImages.isNotEmpty) {
          final uploaded = await ref
              .read(storageServiceProvider)
              .uploadLifeEventImages(user.uid, widget.eventId!, _newImages);
          imageUrls = [..._existingImageUrls, ...uploaded];
        }
        await ref.read(lifeEventControllerProvider.notifier).updateLifeEvent(
              widget.eventId!,
              {
                'title': _titleController.text.trim(),
                'body': _bodyController.text.trim(),
                'occurredYearMonth': occurredYearMonth,
                'category': _category,
                'emotionTag': _emotionLabel,
                'emotionScore': emotionScore,
                'isTurningPoint': _isTurningPoint,
                'visibility': _visibility,
                'imageUrls': imageUrls,
              },
            );
      } else {
        final eventId = await ref
            .read(lifeEventControllerProvider.notifier)
            .createLifeEvent(
              title: _titleController.text.trim(),
              body: _bodyController.text.trim(),
              occurredYearMonth: occurredYearMonth,
              category: _category,
              emotionTag: _emotionLabel,
              emotionScore: emotionScore,
              isTurningPoint: _isTurningPoint,
              visibility: _visibility,
              imageUrls: const [],
            );
        if (_newImages.isNotEmpty) {
          final uploaded = await ref
              .read(storageServiceProvider)
              .uploadLifeEventImages(user.uid, eventId, _newImages);
          await ref
              .read(lifeEventControllerProvider.notifier)
              .updateLifeEvent(eventId, {'imageUrls': uploaded});
        }
      }
      if (!mounted) return;
      _isDirty = false;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(widget.isEditing ? '変更を保存しました' : 'ライフイベントを記録しました')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('保存できませんでした。通信環境を確認して、もう一度お試しください。\n($e)')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing) {
      final eventAsync = ref.watch(lifeEventProvider(widget.eventId!));
      eventAsync.whenData(_loadFromEvent);
    }
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !_isDirty || _isSaving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmDiscard()) navigator.pop();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isEditing ? 'ライフイベントを編集' : 'ライフイベントを記録'),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : _submit,
              child: const Text('保存'),
            ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              const _SectionHeader(
                step: '1',
                title: 'いつの出来事？',
                help: 'おおよその年月で大丈夫です',
              ),
              InkWell(
                onTap: _pickYearMonth,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: '年月',
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  child: Text('$_year年 $_month月'),
                ),
              ),
              const _SectionHeader(
                step: '2',
                title: '何があった？',
                help: 'タイトルは一言で。本文には当時の様子を自由に書きましょう',
              ),
              TextFormField(
                controller: _titleController,
                maxLength: _titleMaxLength,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'タイトル',
                  hintText: '例: 第一志望の大学に合格した',
                ),
                onChanged: (_) => _update(() {}),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'タイトルを入力してください' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bodyController,
                minLines: 4,
                maxLines: 12,
                decoration: const InputDecoration(
                  labelText: '本文',
                  hintText: '例: 何度も模試で落ち込んだけれど、最後まで諦めずに勉強を続けた。合格発表の日は家族みんなで喜んだ。',
                  alignLabelWithHint: true,
                ),
                onChanged: (_) => _update(() {}),
                validator: (v) => (v == null || v.trim().isEmpty) ? '本文を入力してください' : null,
              ),
              const _SectionHeader(
                step: '3',
                title: 'どんな気持ちだった？',
                help: '選んだ気持ちが「感情グラフ」の高さになります',
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: EmotionTag.all.map((tag) {
                  return ChoiceChip(
                    label: Text('${tag.emoji} ${tag.label}'),
                    selected: tag.label == _emotionLabel,
                    onSelected: (_) => _update(() => _emotionLabel = tag.label),
                  );
                }).toList(),
              ),
              const _SectionHeader(
                step: '4',
                title: 'どんなジャンル？',
                help: '検索やグラフの分類に使われます',
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: LifeEventCategories.all.map((c) {
                  return ChoiceChip(
                    label: Text('${LifeEventCategories.emojiFor(c)} $c'),
                    selected: c == _category,
                    onSelected: (_) => _update(() => _category = c),
                  );
                }).toList(),
              ),
              const _SectionHeader(step: '5', title: '誰に見せる？'),
              RadioGroup<String>(
                groupValue: _visibility,
                onChanged: (value) => _update(() => _visibility = value!),
                child: Column(
                  children: VisibilityOption.all
                      .map(
                        (v) => RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          value: v,
                          title: Text(VisibilityOption.labelFor(v)),
                          subtitle: Text(VisibilityOption.descriptionFor(v)),
                        ),
                      )
                      .toList(),
                ),
              ),
              const _SectionHeader(title: 'そのほか（任意）'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                secondary: const Icon(Icons.bolt, color: Colors.amber),
                title: const Text('人生の転機としてマークする'),
                subtitle: const Text('感情グラフや一覧で目立つように表示されます'),
                value: _isTurningPoint,
                onChanged: (v) => _update(() => _isTurningPoint = v),
              ),
              const SizedBox(height: 8),
              Text('写真', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._existingImageUrls.map(
                    (url) => _ImageThumbnail(
                      image: AppImage(url: url, width: 80, height: 80, fit: BoxFit.cover),
                      onRemove: () => _update(() => _existingImageUrls.remove(url)),
                    ),
                  ),
                  ..._newImages.map(
                    (file) => _ImageThumbnail(
                      image: Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
                      onRemove: () => _update(() => _newImages.remove(file)),
                    ),
                  ),
                  Tooltip(
                    message: '写真を追加',
                    child: InkWell(
                      onTap: _pickImages,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          border: Border.all(color: colorScheme.outline),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, color: colorScheme.primary),
                            const SizedBox(height: 4),
                            Text('追加', style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                onPressed: _isSaving ? null : _submit,
                icon: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(
                  _isSaving ? '保存しています…' : (widget.isEditing ? '変更を保存する' : 'この内容で記録する'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String? step;
  final String title;
  final String? help;

  const _SectionHeader({this.step, required this.title, this.help});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (step != null) ...[
            CircleAvatar(
              radius: 12,
              backgroundColor: colorScheme.primary,
              child: Text(
                step!,
                style: TextStyle(fontSize: 12, color: colorScheme.onPrimary, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                if (help != null)
                  Text(help!, style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageThumbnail extends StatelessWidget {
  final Widget image;
  final VoidCallback onRemove;

  const _ImageThumbnail({required this.image, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: image),
        Positioned(
          right: -4,
          top: -4,
          child: IconButton(
            icon: const Icon(Icons.cancel, size: 20),
            tooltip: '写真を外す',
            onPressed: onRemove,
          ),
        ),
      ],
    );
  }
}

/// 年と月をタップだけで選べるダイアログ。結果は (年, 月) で返す。
class _YearMonthPickerDialog extends StatefulWidget {
  final int initialYear;
  final int initialMonth;

  const _YearMonthPickerDialog({required this.initialYear, required this.initialMonth});

  @override
  State<_YearMonthPickerDialog> createState() => _YearMonthPickerDialogState();
}

class _YearMonthPickerDialogState extends State<_YearMonthPickerDialog> {
  static const _minYear = 1900;
  final _maxYear = DateTime.now().year;
  late int _year = widget.initialYear.clamp(_minYear, _maxYear);
  late int _month = widget.initialMonth;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('年月を選ぶ'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: '前の年',
                  onPressed: _year > _minYear ? () => setState(() => _year--) : null,
                ),
                DropdownButton<int>(
                  value: _year,
                  menuMaxHeight: 320,
                  items: [
                    for (var y = _maxYear; y >= _minYear; y--)
                      DropdownMenuItem(value: y, child: Text('$y年')),
                  ],
                  onChanged: (v) => setState(() => _year = v!),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: '次の年',
                  onPressed: _year < _maxYear ? () => setState(() => _year++) : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (var m = 1; m <= 12; m++)
                  SizedBox(
                    width: 64,
                    child: ChoiceChip(
                      label: SizedBox(width: double.infinity, child: Text('$m月', textAlign: TextAlign.center)),
                      showCheckmark: false,
                      selected: m == _month,
                      onSelected: (_) => setState(() => _month = m),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
        FilledButton(
          onPressed: () => Navigator.pop(context, (_year, _month)),
          child: const Text('決定'),
        ),
      ],
    );
  }
}
