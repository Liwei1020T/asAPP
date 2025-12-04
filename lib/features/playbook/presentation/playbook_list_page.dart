import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/training_material.dart';
import '../../../data/repositories/supabase/playbook_repository.dart';
import '../../auth/application/auth_providers.dart';
import '../../../data/repositories/supabase/storage_repository.dart';

// 训练资料分类（静态配置，用于筛选 UI）
const List<MaterialCategory> _defaultPlaybookCategories = [
  MaterialCategory(
    id: 'cat-1',
    name: '基础技术',
    description: '羽毛球基本功训练',
    icon: 'sports_tennis',
    color: '#4CAF50',
    sortOrder: 1,
  ),
  MaterialCategory(
    id: 'cat-2',
    name: '步伐训练',
    description: '场上移动和步法',
    icon: 'directions_run',
    color: '#2196F3',
    sortOrder: 2,
  ),
  MaterialCategory(
    id: 'cat-3',
    name: '击球技术',
    description: '各种击球方式详解',
    icon: 'sports',
    color: '#FF9800',
    sortOrder: 3,
  ),
  MaterialCategory(
    id: 'cat-4',
    name: '战术策略',
    description: '单打双打战术',
    icon: 'psychology',
    color: '#9C27B0',
    sortOrder: 4,
  ),
  MaterialCategory(
    id: 'cat-5',
    name: '体能训练',
    description: '力量和耐力提升',
    icon: 'fitness_center',
    color: '#F44336',
    sortOrder: 5,
  ),
];

class PlaybookListPage extends ConsumerStatefulWidget {
  const PlaybookListPage({super.key});

  @override
  ConsumerState<PlaybookListPage> createState() => _PlaybookListPageState();
}

class _PlaybookListPageState extends ConsumerState<PlaybookListPage> {
  String? _selectedCategoryId;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _defaultPlaybookCategories;
    final stream = ref.read(supabasePlaybookRepositoryProvider).watchMaterials();
    final selectedCategoryName = _selectedCategoryId == null
        ? null
        : categories.firstWhere((c) => c.id == _selectedCategoryId, orElse: () => categories.first).name;

    return Scaffold(
      appBar: AppBar(
        title: const Text('训练手册'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateMaterialDialog,
            tooltip: '添加资料',
          ),
        ],
      ),
      body: Row(
        children: [
          // 左侧分类栏
          Container(
            width: 200,
            decoration: BoxDecoration(
              color: ASColors.backgroundLight,
              border: Border(
                right: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(ASSpacing.lg),
                  child: Text(
                    '分类',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.folder),
                  title: const Text('全部'),
                  selected: _selectedCategoryId == null,
                  selectedTileColor: ASColors.primary.withValues(alpha: 0.1),
                  onTap: () {
                    setState(() {
                      _selectedCategoryId = null;
                    });
                  },
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      return ListTile(
                        leading: Icon(
                          _getCategoryIcon(category.icon),
                          color: Color(int.parse(category.color.replaceFirst('#', '0xFF'))),
                        ),
                        title: Text(category.name),
                        selected: _selectedCategoryId == category.id,
                        selectedTileColor: ASColors.primary.withValues(alpha: 0.1),
                        onTap: () {
                          setState(() {
                            _selectedCategoryId = category.id;
                          });
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          // 右侧内容区
          Expanded(
            child: Column(
              children: [
                // 搜索栏
                Padding(
                  padding: const EdgeInsets.all(ASSpacing.pagePadding),
                  child: ASSearchField(
                    controller: _searchController,
                    hint: '搜索资料...',
                    onChanged: (value) => setState(() => _searchQuery = value),
                    onClear: () => setState(() => _searchQuery = ''),
                  ),
                ),
                // 资料列表
                Expanded(
                  child: StreamBuilder<List<TrainingMaterial>>(
                    stream: stream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                        return const Padding(
                          padding: EdgeInsets.all(ASSpacing.pagePadding),
                          child: ASSkeletonGrid(
                            itemCount: 6,
                            crossAxisCount: 3,
                            childAspectRatio: 0.85,
                          ),
                        );
                      }

                      var materials = snapshot.data ?? [];

                      // 分类过滤
                      if (selectedCategoryName != null) {
                        materials = materials.where((m) => m.category == selectedCategoryName).toList();
                      }

                      // 搜索过滤
                      if (_searchQuery.isNotEmpty) {
                        final q = _searchQuery.toLowerCase();
                        materials = materials
                            .where((m) =>
                                m.title.toLowerCase().contains(q) ||
                                (m.description?.toLowerCase().contains(q) ?? false))
                            .toList();
                      }

                      if (materials.isEmpty) {
                        return const ASEmptyState(
                          type: ASEmptyStateType.noData,
                          title: '暂无资料',
                          description: '上传训练视频或文档后会显示在这里',
                          icon: Icons.folder_open,
                        );
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(ASSpacing.pagePadding),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: ASResponsive.getGridColumns(
                            context,
                            mobile: 1,
                            tablet: 2,
                            desktop: 3,
                            largeDesktop: 4,
                          ),
                          childAspectRatio: 0.9,
                          crossAxisSpacing: ASSpacing.md,
                          mainAxisSpacing: ASSpacing.md,
                        ),
                        itemCount: materials.length,
                        itemBuilder: (context, index) {
                          final material = materials[index];
                          return _MaterialCard(
                            material: material,
                            onTap: () => _openMaterialContent(material),
                            onEdit: () => _editMaterial(material),
                            onDelete: () => _deleteMaterial(material),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'sports_tennis':
        return Icons.sports_tennis;
      case 'fitness_center':
        return Icons.fitness_center;
      case 'psychology':
        return Icons.psychology;
      case 'school':
        return Icons.school;
      default:
        return Icons.folder;
    }
  }

  void _showMaterialDetail(TrainingMaterial material) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _getTypeIcon(material.type),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      material.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (material.thumbnailUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    material.thumbnailUrl!,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: Colors.grey.shade200,
                      child: const Center(child: Icon(Icons.image, size: 48)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                material.description ?? '',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: (material.tags ?? [])
                    .map((tag) => Chip(
                          label: Text(tag),
                          backgroundColor: ASColors.primary.withValues(alpha: 0.1),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.category, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    material.category ?? '未分类',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.visibility, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    '${material.viewCount}次查看',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('关闭'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('正在打开资料...')),
                      );
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('打开'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getTypeIcon(TrainingMaterialType type) {
    IconData icon;
    Color color;

    switch (type) {
      case TrainingMaterialType.video:
        icon = Icons.play_circle;
        color = Colors.red;
        break;
      case TrainingMaterialType.document:
        icon = Icons.description;
        color = Colors.blue;
        break;
      case TrainingMaterialType.image:
        icon = Icons.image;
        color = Colors.green;
        break;
      case TrainingMaterialType.link:
        icon = Icons.link;
        color = Colors.orange;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color),
    );
  }

  void _showCreateMaterialDialog() {
    _createMaterial();
  }

  Future<void> _createMaterial() async {
    final created = await _CreateMaterialDialog.show(context, ref);
    if (created != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('资料添加成功')),
      );
    }
  }

  String _getTypeName(TrainingMaterialType type) {
    switch (type) {
      case TrainingMaterialType.video:
        return '视频';
      case TrainingMaterialType.document:
        return '文档';
      case TrainingMaterialType.image:
        return '图片';
      case TrainingMaterialType.link:
        return '链接';
    }
  }

  Future<void> _editMaterial(TrainingMaterial material) async {
    final updated = await _CreateMaterialDialog.show(context, ref, initial: material);
    if (updated != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('资料已更新')),
      );
    }
  }

  Future<void> _deleteMaterial(TrainingMaterial material) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除资料'),
        content: Text('确定删除《${material.title}》吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('删除', style: TextStyle(color: ASColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(supabasePlaybookRepositoryProvider).deleteMaterial(material.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败：$e')),
        );
      }
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已删除')),
      );
    }
  }

  void _openMaterialContent(TrainingMaterial material) {
    if (material.type == TrainingMaterialType.image && material.contentUrl != null) {
      _showImagePreview(context, material.contentUrl!);
    } else if (material.contentUrl != null) {
      _launchUrl(material.contentUrl!);
    } else if (material.thumbnailUrl != null && material.type == TrainingMaterialType.image) {
      // Fallback to thumbnail if contentUrl is missing but it's an image
      _showImagePreview(context, material.thumbnailUrl!);
    } else {
      // Fallback to detail dialog if no content to open
      _showMaterialDetail(material);
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('无法打开链接：$urlString')),
        );
      }
    }
  }

  void _showImagePreview(BuildContext context, String url) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black87,
      builder: (_) {
        return GestureDetector(
          onTap: () => Navigator.of(context, rootNavigator: true).pop(),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4,
                    child: Image.network(
                      url,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white, size: 64),
                    ),
                  ),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MaterialCard extends StatelessWidget {
  final TrainingMaterial material;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MaterialCard({
    required this.material,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overlayColor = theme.colorScheme.surfaceContainerHighest;

    return ASCard.gradient(
      padding: EdgeInsets.zero,
      onTap: onTap,
      gradient: ASColors.cardGradient,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 缩略图
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (material.thumbnailUrl != null)
                  Image.network(
                    material.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: overlayColor,
                      child: const Center(child: Icon(Icons.image, size: 32)),
                    ),
                  )
                else
                  Container(
                    color: overlayColor,
                    child: Center(
                      child: Icon(
                        _getTypeIconData(material.type),
                        size: 32,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: ASTag(
                    label: _getTypeName(material.type),
                    type: ASTagType.info,
                  ),
                ),
              ],
            ),
          ),
          // 内容
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(ASSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    material.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      material.description ?? '',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.visibility, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        '${material.viewCount}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        material.category ?? '',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18),
                        onSelected: (value) {
                          if (value == 'edit') {
                            onEdit();
                          } else if (value == 'delete') {
                            onDelete();
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('编辑'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              '删除',
                              style: TextStyle(color: ASColors.error),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIconData(TrainingMaterialType type) {
    switch (type) {
      case TrainingMaterialType.video:
        return Icons.play_circle;
      case TrainingMaterialType.document:
        return Icons.description;
      case TrainingMaterialType.image:
        return Icons.image;
      case TrainingMaterialType.link:
        return Icons.link;
    }
  }

  String _getTypeName(TrainingMaterialType type) {
    switch (type) {
      case TrainingMaterialType.video:
        return '视频';
      case TrainingMaterialType.document:
        return '文档';
      case TrainingMaterialType.image:
        return '图片';
      case TrainingMaterialType.link:
        return '链接';
    }
  }
}

class _CreateMaterialDialog extends ConsumerStatefulWidget {
  const _CreateMaterialDialog({this.initial});

  final TrainingMaterial? initial;

  static Future<TrainingMaterial?> show(BuildContext context, WidgetRef ref, {TrainingMaterial? initial}) {
    return showDialog<TrainingMaterial>(
      context: context,
      builder: (_) => Dialog(
        child: SizedBox(
          width: 520,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _CreateMaterialDialog(initial: initial),
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<_CreateMaterialDialog> createState() => _CreateMaterialDialogState();
}

class _CreateMaterialDialogState extends ConsumerState<_CreateMaterialDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _linkController;
  late TextEditingController _thumbController;
  TrainingMaterialType _type = TrainingMaterialType.video;
  String? _category;
  bool _isSubmitting = false;
  Uint8List? _contentBytes;
  Uint8List? _thumbBytes;
  String? _contentFileName;
  String? _thumbFileName;
  bool _isUploading = false;
  String? _uploadError;

  bool get isEditing => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initial?.title ?? '');
    _descController = TextEditingController(text: widget.initial?.description ?? '');
    _linkController = TextEditingController(text: widget.initial?.contentUrl ?? '');
    _thumbController = TextEditingController(text: widget.initial?.thumbnailUrl ?? '');
    _type = widget.initial?.type ?? TrainingMaterialType.video;
    _category = widget.initial?.category;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _linkController.dispose();
    _thumbController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _defaultPlaybookCategories;
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isEditing ? '编辑训练资料' : '添加训练资料',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '标题',
              border: OutlineInputBorder(),
            ),
            validator: (v) => v == null || v.trim().isEmpty ? '请输入标题' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<TrainingMaterialType>(
            value: _type,
            decoration: const InputDecoration(
              labelText: '类型',
              border: OutlineInputBorder(),
            ),
            items: TrainingMaterialType.values
                .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(_typeName(type)),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _type = v ?? TrainingMaterialType.video),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _category,
            decoration: const InputDecoration(
              labelText: '分类',
              border: OutlineInputBorder(),
            ),
            items: categories
                .map((c) => DropdownMenuItem(
                      value: c.name,
                      child: Text(c.name),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _category = v),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descController,
            decoration: const InputDecoration(
              labelText: '描述',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _linkController,
            decoration: const InputDecoration(
              labelText: '资料链接（可选，或上传文件）',
              border: OutlineInputBorder(),
              hintText: 'https://...',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _pickContentFile,
                  icon: const Icon(Icons.upload_file),
                  label: Text(_contentFileName ?? '上传资料文件'),
                ),
              ),
            ],
          ),
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: LinearProgressIndicator(minHeight: 6),
            ),
          if (_uploadError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _uploadError!,
                style: const TextStyle(color: ASColors.error),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isSubmitting ? null : _pickThumbFile,
                  icon: const Icon(Icons.image),
                  label: Text(_thumbFileName ?? '上传封面（可选）'),
                ),
              ),
            ],
          ),
          if (_type == TrainingMaterialType.video)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '视频上传后可能需处理，稍后可播放',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                child: const Text('取消'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save),
                label: Text(isEditing ? '保存' : '添加'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickContentFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result != null && result.files.isNotEmpty && result.files.first.bytes != null) {
      setState(() {
        _contentBytes = result.files.first.bytes;
        _contentFileName = result.files.first.name;
      });
    }
  }

  Future<void> _pickThumbFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty && result.files.first.bytes != null) {
      setState(() {
        _thumbBytes = result.files.first.bytes;
        _thumbFileName = result.files.first.name;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    final now = DateTime.now();
    final currentUser = ref.read(currentUserProvider);
    String? contentUrl = _linkController.text.trim().isEmpty ? null : _linkController.text.trim();
    String? thumbUrl = _thumbController.text.trim().isEmpty ? null : _thumbController.text.trim();

    try {
      final storage = ref.read(supabaseStorageRepositoryProvider);

      if (_contentBytes != null) {
        final path =
            'playbook/${currentUser?.id ?? 'unknown'}/${now.millisecondsSinceEpoch}-${_contentFileName ?? 'file'}';
        contentUrl = await storage.uploadBytes(
          bytes: _contentBytes!,
          bucket: 'playbook',
          path: path,
          fileOptions: FileOptions(upsert: false),
        );
      }

      if (_thumbBytes != null) {
        final path =
            'playbook/thumbs/${currentUser?.id ?? 'unknown'}/${now.millisecondsSinceEpoch}-${_thumbFileName ?? 'thumb'}.jpg';
        thumbUrl = await storage.uploadBytes(
          bytes: _thumbBytes!,
          bucket: 'playbook',
          path: path,
          fileOptions: FileOptions(
            upsert: false,
            contentType: 'image/jpeg',
          ),
        );
      }
      if (mounted) setState(() => _isUploading = false);
    } catch (e) {
      _uploadError = '上传失败：$e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('上传失败：$e'), backgroundColor: ASColors.error),
      );
    }

    final draft = TrainingMaterial(
      id: widget.initial?.id ?? 'material-${now.millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      category: _category,
      type: _type,
      contentUrl: contentUrl,
      thumbnailUrl: thumbUrl,
      keyPoints: widget.initial?.keyPoints,
      tags: widget.initial?.tags,
      visibility: widget.initial?.visibility ?? MaterialVisibility.public,
      authorId: currentUser?.id ?? widget.initial?.authorId,
      createdAt: widget.initial?.createdAt ?? now,
      updatedAt: now,
      viewCount: widget.initial?.viewCount ?? 0,
    );

    try {
      final saved = isEditing
          ? await ref.read(supabasePlaybookRepositoryProvider).updateMaterial(draft)
          : await ref.read(supabasePlaybookRepositoryProvider).createMaterial(draft);
      if (mounted) Navigator.pop(context, saved);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存资料失败：$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isUploading = false;
        });
      }
    }
  }

  String _typeName(TrainingMaterialType type) {
    switch (type) {
      case TrainingMaterialType.video:
        return '视频';
      case TrainingMaterialType.document:
        return '文档';
      case TrainingMaterialType.image:
        return '图片';
      case TrainingMaterialType.link:
        return '链接';
    }
  }
}
