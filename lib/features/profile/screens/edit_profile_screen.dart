import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/providers/firebase_providers.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/life_age.dart';
import '../../../widgets/common/app_image.dart';
import '../../../widgets/common/loading_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/profile_providers.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _birthController = TextEditingController();
  String _defaultVisibility = VisibilityOption.private;
  File? _newIcon;
  bool _loaded = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _birthController.dispose();
    super.dispose();
  }

  void _loadFromProfile(dynamic profile) {
    if (_loaded || profile == null) return;
    _nameController.text = profile.displayName;
    _bioController.text = profile.bio;
    _birthController.text = profile.birthYearMonth ?? '';
    _defaultVisibility = profile.defaultVisibility;
    _loaded = true;
  }

  Future<void> _pickIcon() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _newIcon = File(picked.path));
    }
  }

  Future<void> _save() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    final birth = _birthController.text.trim();
    if (birth.isNotEmpty && LifeAge.parseYearMonth(birth) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('生年月は「1990-04」のように、年-月の形で入力してください')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final data = <String, dynamic>{
        'displayName': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'birthYearMonth': _birthController.text.trim().isEmpty ? null : _birthController.text.trim(),
        'defaultVisibility': _defaultVisibility,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };
      if (_newIcon != null) {
        try {
          data['iconUrl'] = await ref.read(storageServiceProvider).uploadUserIcon(user.uid, _newIcon!);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('画像のアップロードに失敗しました: $e')),
            );
          }
        }
      }
      await ref.read(firestoreServiceProvider).updateUserProfile(user.uid, data);
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('保存に失敗しました: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const LoadingView();
    final profileAsync = ref.watch(currentUserProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('プロフィール編集')),
      body: profileAsync.when(
        data: (profile) {
          _loadFromProfile(profile);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundImage: _newIcon != null
                          ? FileImage(_newIcon!) as ImageProvider
                          : (profile?.iconUrl != null ? AppImage(url: profile!.iconUrl!).toImageProvider() : null),
                      child: (_newIcon == null && profile?.iconUrl == null)
                          ? const Icon(Icons.person, size: 48)
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: IconButton.filled(
                        icon: const Icon(Icons.camera_alt, size: 18),
                        onPressed: _pickIcon,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '表示名',
                  helperText: '実名ではなくニックネームがおすすめです',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _bioController,
                decoration: const InputDecoration(
                  labelText: '自己紹介',
                  hintText: '例: IT企業で働く会社員。製造業の品質管理から転職しました。遠回りのキャリアと学び直しについて記録しています。',
                  helperText: '今の立場・これまでの歩み・記録しているテーマを2〜3行で',
                  helperMaxLines: 2,
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _birthController,
                decoration: InputDecoration(
                  labelText: '生年月 (例: 1990-04)',
                  helperText: '読む人が「何歳ごろの出来事か」を想像しやすくなります。年代での検索にも使われます',
                  helperMaxLines: 2,
                  suffixIcon: _birthController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => setState(() => _birthController.clear()),
                        )
                      : null,
                ),
                keyboardType: TextInputType.datetime,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              const Text('デフォルトの公開範囲', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '新しく記録するときの初期値です。最初は「非公開」にして、書いてから公開を判断するのがおすすめです',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              RadioGroup<String>(
                groupValue: _defaultVisibility,
                onChanged: (value) => setState(() => _defaultVisibility = value!),
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
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('保存する'),
              ),
            ],
          );
        },
        loading: () => const LoadingView(),
        error: (e, st) => Text('読み込みエラー: $e'),
      ),
    );
  }
}
