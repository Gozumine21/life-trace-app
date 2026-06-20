import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/utils/constants.dart';
import '../../../models/life_event.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _yearController = TextEditingController();
  final _monthController = TextEditingController();

  String _category = LifeEventCategories.all.first;
  String _emotionLabel = EmotionTag.all.first.label;
  bool _isTurningPoint = false;
  String _visibility = VisibilityOption.public;
  final List<File> _newImages = [];
  List<String> _existingImageUrls = [];
  bool _loadedInitialValues = false;
  bool _isSaving = false;

  void _loadFromEvent(dynamic event) {
    if (_loadedInitialValues || event == null) return;
    _titleController.text = event.title;
    _bodyController.text = event.body;
    final parts = (event.occurredYearMonth as String).split('-');
    if (parts.length == 2) {
      _yearController.text = parts[0];
      _monthController.text = parts[1];
    }
    _category = event.category;
    _emotionLabel = event.emotionTag;
    _isTurningPoint = event.isTurningPoint;
    _visibility = (event.visibility as EventVisibility).name;
    _existingImageUrls = List<String>.from(event.imageUrls as List);
    _loadedInitialValues = true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _yearController.dispose();
    _monthController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() {
        _newImages.addAll(picked.map((p) => File(p.path)));
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      final occurredYearMonth =
          '${_yearController.text.padLeft(4, '0')}-${_monthController.text.padLeft(2, '0')}';
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
        if (mounted) context.pop();
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
        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('保存に失敗しました: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEditing) {
      final eventAsync = ref.watch(lifeEventProvider(widget.eventId!));
      eventAsync.whenData((event) => _loadFromEvent(event));
    }

    return Scaffold(
      appBar: AppBar(title: Text(widget.isEditing ? 'ライフイベント編集' : 'ライフイベント作成')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'タイトル'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'タイトルを入力してください' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bodyController,
              decoration: const InputDecoration(labelText: '本文'),
              maxLines: 5,
              validator: (v) => (v == null || v.trim().isEmpty) ? '本文を入力してください' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _yearController,
                    decoration: const InputDecoration(labelText: '発生年 (例: 2015)'),
                    keyboardType: TextInputType.number,
                    validator: (v) =>
                        (v == null || v.trim().length != 4) ? '4桁で入力' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _monthController,
                    decoration: const InputDecoration(labelText: '発生月 (1-12)'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v ?? '');
                      if (n == null || n < 1 || n > 12) return '1〜12で入力';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'カテゴリ'),
              items: LifeEventCategories.all
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 16),
            const Text('感情タグ', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: EmotionTag.all.map((tag) {
                final selected = tag.label == _emotionLabel;
                return ChoiceChip(
                  label: Text(tag.label),
                  selected: selected,
                  onSelected: (_) => setState(() => _emotionLabel = tag.label),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('人生の転機（ターニングポイント）として表示'),
              value: _isTurningPoint,
              onChanged: (v) => setState(() => _isTurningPoint = v),
            ),
            const SizedBox(height: 8),
            const Text('公開範囲', style: TextStyle(fontWeight: FontWeight.bold)),
            RadioGroup<String>(
              groupValue: _visibility,
              onChanged: (value) => setState(() => _visibility = value!),
              child: Column(
                children: VisibilityOption.all
                    .map(
                      (v) => RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        value: v,
                        title: Text(VisibilityOption.labelFor(v)),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            const Text('画像', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._existingImageUrls.map(
                  (url) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(url, width: 80, height: 80, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: -4,
                        top: -4,
                        child: IconButton(
                          icon: const Icon(Icons.cancel, size: 18),
                          onPressed: () => setState(() => _existingImageUrls.remove(url)),
                        ),
                      ),
                    ],
                  ),
                ),
                ..._newImages.map(
                  (file) => Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
                      ),
                      Positioned(
                        right: -4,
                        top: -4,
                        child: IconButton(
                          icon: const Icon(Icons.cancel, size: 18),
                          onPressed: () => setState(() => _newImages.remove(file)),
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: _pickImages,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_photo_alternate_outlined),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isSaving ? null : _submit,
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(widget.isEditing ? '更新する' : '保存する'),
            ),
          ],
        ),
      ),
    );
  }
}
