import 'dart:async';
import 'dart:typed_data';

// Native-only File import
import 'native_file_stub.dart' if (dart.library.io) 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/colors.dart';
import '../../../core/constants/spacing.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../core/widgets/widgets.dart';
import '../../../core/widgets/video_player_widget.dart';
import '../../../data/models/training_material.dart';
import '../../../data/repositories/supabase/playbook_repository.dart';
import '../../auth/application/auth_providers.dart';
import '../../../data/repositories/storage_repository.dart';

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

    final theme = Theme.of(context);

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
            width: 220,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                right: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(ASSpacing.lg),
                  child: Text(
                    '分类',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildCategoryItem(
                  icon: Icons.folder_outlined,
                  title: '全部',
                  isSelected: _selectedCategoryId == null,
                  onTap: () => setState(() => _selectedCategoryId = null),
                  color: theme.colorScheme.primary,
                ),
                const Divider(height: ASSpacing.md),
                Expanded(
                  child: ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final color = Color(int.parse(category.color.replaceFirst('#', '0xFF')));
                      return _buildCategoryItem(
                        icon: _getCategoryIcon(category.icon),
                        title: category.name,
                        isSelected: _selectedCategoryId == category.id,
                        onTap: () => setState(() => _selectedCategoryId = category.id),
                        color: color,
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

                      return ASAnimatedGrid(
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
                        items: materials,
                        itemBuilder: (context, material, index) {
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

  Widget _buildCategoryItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: ASSpacing.sm, vertical: 2),
      child: Material(
        color: isSelected ? theme.colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(ASSpacing.buttonRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: ASSpacing.md, vertical: ASSpacing.sm),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected ? theme.colorScheme.onPrimaryContainer : color,
                ),
                const SizedBox(width: ASSpacing.md),
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
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
    if (material.contentUrl == null) {
      // 没有内容链接，显示详情对话框
      _showMaterialDetail(material);
      return;
    }

    switch (material.type) {
      case TrainingMaterialType.video:
        // Windows 桌面平台：在外部播放器中打开（video_player在Windows上有问题）
        final isDesktop = !kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.windows ||
                defaultTargetPlatform == TargetPlatform.linux);
        if (isDesktop) {
          _launchUrl(material.contentUrl!);
        } else {
          // 其他平台：使用内嵌视频播放器
          VideoPreviewDialog.show(
            context,
            videoUrl: material.contentUrl!,
            title: material.title,
          );
        }
        break;
      case TrainingMaterialType.image:
        // 图片类型：显示图片预览
        _showImagePreview(context, material.contentUrl!);
        break;
      case TrainingMaterialType.document:
      case TrainingMaterialType.link:
        // 文档和链接：在浏览器中打开
        _launchUrl(material.contentUrl!);
        break;
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

    return ASCard(
      padding: EdgeInsets.zero,
      onTap: onTap,
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
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                // 视频播放按钮覆盖层
                if (material.type == TrainingMaterialType.video && material.contentUrl != null)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          size: 56,
                          color: Colors.white,
                        ),
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
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      material.description ?? '',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.visibility, size: 14, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text(
                        '${material.viewCount}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const Spacer(),
                      PopupMenuButton<String>(
                        icon: Icon(Icons.more_vert, size: 18, color: theme.colorScheme.onSurfaceVariant),
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
      builder: (dialogContext) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 520,
            maxHeight: MediaQuery.of(dialogContext).size.height * 0.85,
          ),
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
  // 改用存储 PlatformFile 引用，避免同步读取大文件导致 UI 卡死
  PlatformFile? _contentFile;
  Uint8List? _thumbBytes;
  String? _thumbFileName;
  bool _isPickingFile = false; // 正在选择文件中
  bool _isUploadingContent = false;
  bool _isUploadingThumb = false;
  double? _contentProgress;
  String? _contentTargetUrl;
  bool _contentHalfwayReady = false;
  double? _thumbProgress;
  String? _uploadError;

  bool get _isUploadingAny => _isUploadingContent || _isUploadingThumb;
  bool get _canSubmitWhileUploadingContent =>
      _isUploadingContent &&
      _contentHalfwayReady &&
      (_linkController.text.isNotEmpty || _contentTargetUrl != null);
  bool get _isSubmitBlockedByContentUpload =>
      _isUploadingContent && !_canSubmitWhileUploadingContent;
  bool get _isSubmitDisabled => _isSubmitting || _isSubmitBlockedByContentUpload;

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
      child: SingleChildScrollView(
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
                hintText: '请输入资料标题',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.isEmpty ? '请输入标题' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: '描述',
                hintText: '请输入资料描述',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              decoration: const InputDecoration(
                labelText: '分类',
                border: OutlineInputBorder(),
              ),
              items: categories.map((c) {
                return DropdownMenuItem(
                  value: c.name,
                  child: Text(c.name),
                );
              }).toList(),
              onChanged: (value) => setState(() => _category = value),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<TrainingMaterialType>(
              value: _type,
              decoration: const InputDecoration(
                labelText: '类型',
                border: OutlineInputBorder(),
              ),
              items: TrainingMaterialType.values.map((t) {
                return DropdownMenuItem(
                  value: t,
                  child: Text(_getTypeName(t)),
                );
              }).toList(),
              onChanged: (value) => setState(() => _type = value!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _linkController,
              decoration: const InputDecoration(
                labelText: '内容链接/URL',
                hintText: '请输入视频或文档链接',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: (_isUploadingContent || _isPickingFile) ? null : _pickAndUploadContentFile,
                  icon: (_isUploadingContent || _isPickingFile)
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(_isPickingFile 
                      ? '正在读取文件...' 
                      : (_isUploadingContent ? '上传中...' : '上传内容文件')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _contentFile != null
                        ? '已选择: ${_contentFile!.name} (${_formatFileSize(_contentFile!.size)})'
                        : '支持上传图片/视频/文档，上传后自动填充链接',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (_isUploadingContent)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(
                  value: _contentProgress,
                  minHeight: 6,
                ),
              ),
            if (_isUploadingContent)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  _contentProgress != null && _contentProgress! >= 1.0
                      ? '等待服务器响应...'
                      : _canSubmitWhileUploadingContent
                          ? '已超过50%，可直接保存（后台继续上传） ${_formatPercent(_contentProgress)}'
                          : '内容上传中 ${_formatPercent(_contentProgress)}，达到50%后可保存',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _thumbController,
              decoration: const InputDecoration(
                labelText: '封面链接（可选）',
                hintText: '图片地址，留空则不设置',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _isUploadingThumb ? null : _pickAndUploadThumb,
                  icon: _isUploadingThumb
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.image),
                  label: Text(_isUploadingThumb ? '上传中...' : '上传封面'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _thumbFileName != null ? '已选择: $_thumbFileName' : '可选：上传封面图将自动填入链接',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (_isUploadingThumb)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(
                  value: _thumbProgress,
                  minHeight: 6,
                ),
              ),
            if (_isUploadingThumb)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '封面上传中 ${_formatPercent(_thumbProgress)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            if (_uploadError != null) ...[
              const SizedBox(height: 8),
              Text(
                _uploadError!,
                style: const TextStyle(color: ASColors.error, fontSize: 12),
              ),
            ],
            if (_isUploadingAny) ...[
              const SizedBox(height: 8),
              Text(
                _isUploadingContent
                    ? '💡 提示：上传超过50%即可保存，后台会继续完成上传，您也可以先关闭对话框'
                    : '💡 提示：上传会在后台继续，您可以关闭此对话框',
                style: const TextStyle(color: ASColors.secondary, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(_isUploadingAny ? '后台上传' : '取消'),
                ),
                const SizedBox(width: 16),
                FilledButton(
                  onPressed: _isSubmitDisabled ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(isEditing ? '保存' : '添加'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

  FileType _fileTypeForContent() {
    switch (_type) {
      case TrainingMaterialType.image:
        return FileType.image;
      case TrainingMaterialType.video:
        return FileType.video;
      case TrainingMaterialType.document:
        return FileType.any;
      case TrainingMaterialType.link:
        return FileType.any;
    }
  }

  Future<void> _pickAndUploadContentFile() async {
    setState(() {
      _uploadError = null;
      _isPickingFile = true;
    });
    
    try {
      // 关键：先让 UI 更新显示加载状态
      await Future.delayed(Duration.zero);
      
      final result = await FilePicker.platform.pickFiles(
        type: _fileTypeForContent(),
        allowMultiple: false,
        withData: kIsWeb, // Web 必须用 withData
        withReadStream: !kIsWeb, // Native 用流式读取
        allowedExtensions: _type == TrainingMaterialType.document
            ? ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'txt']
            : null,
      );
      
      if (!mounted) return;
      
      if (result == null || result.files.isEmpty) {
        setState(() => _isPickingFile = false);
        return;
      }

      final file = result.files.first;
      
      // Web 检查 bytes，Native 检查 path 或 readStream
      if (kIsWeb && file.bytes == null) {
        setState(() {
          _isPickingFile = false;
          _uploadError = '无法读取文件内容，请重试或更换文件。';
        });
        return;
      }
      if (!kIsWeb && file.path == null) {
        setState(() {
          _isPickingFile = false;
          _uploadError = '无法获取文件路径，请重试或更换文件。';
        });
        return;
      }

      // 立即更新 UI 显示已选择的文件
      setState(() {
        _contentFile = file;
        _isPickingFile = false;
      });

      // 后台启动上传
      _startContentUpload();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPickingFile = false;
          _uploadError = '选择文件失败：$e';
        });
      }
    }
  }

  void _startContentUpload() {
    // 启动后台上传，不阻塞表单填写
    unawaited(_uploadContentFile());
  }

  void _updateContentProgress(double rawProgress) {
    final hasReachedHalf = rawProgress >= 0.5 || _contentHalfwayReady;
    final normalized = hasReachedHalf && rawProgress < 0.5 ? 0.5 : rawProgress;
    final clamped = normalized.clamp(0.0, 1.0).toDouble();
    if (!mounted) return;
    setState(() {
      _contentHalfwayReady = hasReachedHalf;
      _contentProgress = clamped;
    });
  }

  Future<void> _uploadContentFile() async {
    final file = _contentFile;
    if (file == null) return;
    
    final repo = ref.read(storageRepositoryProvider);
    final userId = ref.read(currentUserProvider)?.id ?? 'unknown';
    final folder = 'playbook/$userId/${DateTime.now().millisecondsSinceEpoch}';
    String? targetUrl;
    try {
      targetUrl = repo.buildPublicUrl(
        filename: file.name,
        folder: folder,
      );
    } catch (e) {
      // 预填 URL 失败不阻塞上传
    }

    setState(() {
      _isUploadingContent = true;
      _contentProgress = 0;
      _uploadError = null;
      _contentTargetUrl = targetUrl;
      if (targetUrl != null) {
        _linkController.text = targetUrl;
      }
    });

    // Web/内存上传文件在选择后已准备好，可提前允许保存
    final readyInMemory = kIsWeb || (file.bytes != null && file.bytes!.isNotEmpty);
    if (readyInMemory) {
      _updateContentProgress(0.5);
    }
    
    try {
      // Native 平台：从文件路径读取流
      Stream<List<int>>? fileStream;
      if (!kIsWeb && file.path != null) {
        fileStream = File(file.path!).openRead();
      }
      
      final url = await repo.uploadFile(
        bytes: kIsWeb ? file.bytes : null,
        stream: fileStream,
        contentLength: file.size,
        filename: file.name,
        folder: folder,
        onProgress: (p) {
          _updateContentProgress(p);
        },
      );
      if (!mounted) return;
      setState(() {
        _linkController.text = url;
        _uploadError = null;
        _contentTargetUrl = url;
        _contentHalfwayReady = false;
      });
      // 显示成功通知
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ 文件「${file.name}」上传成功！'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadError = '内容上传失败：$e';
        _contentHalfwayReady = false;
        _contentTargetUrl = null;
      });
      // 显示失败通知
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ 文件「${file.name}」上传失败'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingContent = false;
          _contentProgress = null;
          _contentHalfwayReady = false;
          // 上传完成后不清除 _contentFile，保留显示
        });
      }
    }
  }

  Future<void> _pickAndUploadThumb() async {
    setState(() => _uploadError = null);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true, // 封面图较小，直接读取 bytes 不会卡顿
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.bytes == null) {
      setState(() => _uploadError = '无法读取封面文件，请重试或更换文件。');
      return;
    }

    setState(() {
      _thumbBytes = file.bytes;
      _thumbFileName = file.name;
    });

    await _uploadThumbFile();
  }

  Future<void> _uploadThumbFile() async {
    if (_thumbBytes == null) return;
    setState(() {
      _isUploadingThumb = true;
      _thumbProgress = 0;
    });
    final repo = ref.read(storageRepositoryProvider);
    final userId = ref.read(currentUserProvider)?.id ?? 'unknown';
    final folder = 'playbook/$userId/${DateTime.now().millisecondsSinceEpoch}/thumbs';

    try {
      final url = await repo.uploadFile(
        bytes: _thumbBytes!,
        filename: _thumbFileName ?? 'thumb.jpg',
        folder: folder,
        onProgress: (p) {
          if (mounted) {
            setState(() => _thumbProgress = p);
          }
        },
      );
      if (!mounted) return;
      setState(() {
        _thumbController.text = url;
        _uploadError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadError = '封面上传失败：$e');
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingThumb = false;
          _thumbProgress = null;
          _thumbBytes = null;
        });
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitBlockedByContentUpload) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('内容文件上传未超过50%，请稍后再保存')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final material = TrainingMaterial(
        id: widget.initial?.id ?? '', // ID will be ignored on create
        title: _titleController.text,
        description: _descController.text,
        type: _type,
        category: _category,
        contentUrl: _linkController.text.isNotEmpty ? _linkController.text : null,
        thumbnailUrl: _thumbController.text.isNotEmpty ? _thumbController.text : null,
        createdAt: widget.initial?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (isEditing) {
        await ref.read(supabasePlaybookRepositoryProvider).updateMaterial(material);
        if (mounted) Navigator.pop(context, material);
      } else {
        await ref.read(supabasePlaybookRepositoryProvider).createMaterial(material);
        if (mounted) Navigator.pop(context, material);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('提交失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String _formatPercent(double? value) {
    if (value == null) return '--%';
    final pct = (value * 100).clamp(0, 100).toStringAsFixed(0);
    return '$pct%';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}
