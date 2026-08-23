import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_state.dart';
import '../models.dart';
import 'topic_detail_screen.dart';

/// 发帖 / 回复编辑器
class ComposerScreen extends StatefulWidget {
  final bool isNewTopic;
  final int? topicId;
  final int? replyToPostNumber;
  final String? hint;

  const ComposerScreen({
    super.key,
    required this.isNewTopic,
    this.topicId,
    this.replyToPostNumber,
    this.hint,
  });

  @override
  State<ComposerScreen> createState() => _ComposerScreenState();
}

class _ComposerScreenState extends State<ComposerScreen> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _contentFocus = FocusNode();

  List<Category>? _categories;
  Map<int, String>? _parentNames;
  int? _selectedCategory;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.isNewTopic) {
      _loadCategories();
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await context.read<AppState>().api.categories();
      // 只列出子分类（Discourse 顶级分类通常是容器，不允许直接发帖）
      final parents = <int, String>{};
      for (final c in cats) {
        if (c.parentId == null) parents[c.id] = c.name;
      }
      final usable = cats
          .where((c) => c.parentId != null && !c.readRestricted)
          .toList()
        ..sort((a, b) => (a.position ?? 99).compareTo(b.position ?? 99));
      if (!mounted) return;
      setState(() {
        _categories = usable;
        _parentNames = parents;
      });
    } catch (_) {}
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    final raw = _contentCtrl.text.trim();
    if (widget.isNewTopic && title.isEmpty) {
      setState(() => _error = '请输入标题');
      return;
    }
    if (raw.isEmpty) {
      setState(() => _error = '请输入内容（支持 Markdown）');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final app = context.read<AppState>();
    try {
      Map<String, dynamic> result;
      if (widget.isNewTopic) {
        result = await app.api.createTopic(
          title: title,
          raw: raw,
          categoryId: _selectedCategory,
        );
      } else {
        result = await app.api.createReply(
          topicId: widget.topicId!,
          raw: raw,
          replyToPostNumber: widget.replyToPostNumber,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
      final topicId = int.tryParse('${result['topic_id'] ?? widget.topicId}');
      if (widget.isNewTopic && topicId != null && topicId > 0) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TopicDetailScreen(topicId: topicId),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNewTopic ? '发起新话题' : '回复话题'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('发布'),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(14),
          child: ConstrainedBox(
            constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.hint != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: scheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(widget.hint!,
                        style: TextStyle(
                            fontSize: 12.5, color: scheme.primary)),
                  ),
                  const SizedBox(height: 12),
                ],
                if (widget.isNewTopic) ...[
                  TextField(
                    controller: _titleCtrl,
                    textInputAction: TextInputAction.next,
                    maxLength: 120,
                    decoration: const InputDecoration(hintText: '标题'),
                  ),
                  const SizedBox(height: 12),
                  if (_categories != null)
                    DropdownButtonFormField<int>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(hintText: '选择分类（可选）'),
                      items: [
                        for (final c in _categories!)
                          DropdownMenuItem(
                            value: c.id,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: c.color,
                                    borderRadius: BorderRadius.circular(2.5),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    '${_parentNames?[c.parentId] ?? ''} / ${c.name}',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13.5),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                      onChanged: (v) => setState(() => _selectedCategory = v),
                    ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _contentCtrl,
                  focusNode: _contentFocus,
                  maxLines: null,
                  minLines: 10,
                  keyboardType: TextInputType.multiline,
                  decoration: const InputDecoration(
                    hintText: '正文内容，支持 Markdown 语法…',
                  ),
                  style: const TextStyle(fontSize: 14.5, height: 1.5),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: scheme.errorContainer.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_error!,
                        style: TextStyle(
                            fontSize: 13, color: scheme.onErrorContainer)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
