import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../models/cus_app_localizations.dart';

/// 2026-08-28 角色页的三种模式
/// - add: 新增自定义角色
/// - edit: 编辑自定义角色(改动后才显示保存按钮，默认带删除按钮)
/// - view: 内置角色只读查看(提示词较长，列表页看不全，进详情页阅读)
enum RolePageMode { add, edit, view }

/// 2026-08-27 自定义角色的新增/编辑页面
///
/// 不用弹窗：系统提示词往往较长，弹窗内容多时会溢出，
/// 独立页面提供完整的多行编辑体验。
/// 2026-08-28 对齐 llm_config 交互：编辑时 dirty 才显示保存、AppBar 带删除；
/// 内置角色以 view 模式进入(只读，不可保存删除)。
class ModifyRolePage extends StatefulWidget {
  final RolePageMode mode;

  // 保存回调(add/edit 模式)；view 模式不传
  final Future<void> Function(String name, String systemPrompt)? onSave;
  // 删除确认后的回调(edit 模式)，页面负责确认弹窗与返回
  final Future<void> Function()? onDelete;

  // 初始值(编辑/查看时回填)
  final String? initialName;
  final String? initialPrompt;

  const ModifyRolePage({
    super.key,
    required this.mode,
    this.onSave,
    this.onDelete,
    this.initialName,
    this.initialPrompt,
  });

  @override
  State<ModifyRolePage> createState() => _ModifyRolePageState();
}

class _ModifyRolePageState extends State<ModifyRolePage> {
  late final TextEditingController _nameCtl;
  late final TextEditingController _promptCtl;

  // 是否有未保存的修改(决定 AppBar 是否显示保存按钮)
  bool _dirty = false;

  bool get _isView => widget.mode == RolePageMode.view;

  @override
  void initState() {
    super.initState();
    _nameCtl = TextEditingController(text: widget.initialName ?? '');
    _promptCtl = TextEditingController(text: widget.initialPrompt ?? '');

    if (!_isView) {
      _nameCtl.addListener(_checkDirty);
      _promptCtl.addListener(_checkDirty);
    }
  }

  @override
  void dispose() {
    _nameCtl.dispose();
    _promptCtl.dispose();
    super.dispose();
  }

  // 新增：任一项非空即 dirty；编辑：与初始值不同即 dirty
  void _checkDirty() {
    var dirty = widget.mode == RolePageMode.add
        ? (_nameCtl.text.trim().isNotEmpty || _promptCtl.text.trim().isNotEmpty)
        : (_nameCtl.text != (widget.initialName ?? '') ||
              _promptCtl.text != (widget.initialPrompt ?? ''));
    if (dirty != _dirty) {
      setState(() {
        _dirty = dirty;
      });
    }
  }

  Future<void> _save() async {
    var name = _nameCtl.text.trim();
    var prompt = _promptCtl.text.trim();

    if (name.isEmpty || prompt.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(CusAL.of(context).roleInvalid)));
      return;
    }

    await widget.onSave?.call(name, prompt);
    if (!mounted) return;
    Navigator.pop(context);
  }

  // 编辑模式 AppBar 删除：确认后回调外层执行删除并返回列表
  Future<void> _delete() async {
    var confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(CusAL.of(context).tipsTitle),
          content: Text(
            CusAL.of(context).rolesDeleteNote(_nameCtl.text.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(CusAL.of(context).cancelLabel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(CusAL.of(context).confirmLabel),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await widget.onDelete?.call();
    if (!mounted) return;
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(switch (widget.mode) {
          RolePageMode.add => CusAL.of(context).rolePageAdd,
          RolePageMode.edit => CusAL.of(context).rolePageEdit,
          RolePageMode.view => CusAL.of(context).rolePageDetail,
        }),
        actions: [
          // 编辑模式默认带删除按钮(与 llm_config 详情页一致)
          if (widget.mode == RolePageMode.edit)
            IconButton(
              icon: Icon(Icons.delete_outline, color: Colors.red, size: 22.sp),
              onPressed: _delete,
            ),
          // 有修改才显示保存按钮
          if (widget.mode != RolePageMode.view && _dirty)
            TextButton(
              onPressed: _save,
              child: Text(
                CusAL.of(context).saveLabel,
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(12.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 内置角色只读说明
            if (_isView)
              Padding(
                padding: EdgeInsets.only(bottom: 10.sp),
                child: Text(
                  CusAL.of(context).roleReadOnlyNote,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ),
            TextField(
              controller: _nameCtl,
              readOnly: _isView,
              decoration: InputDecoration(
                labelText: CusAL.of(context).roleNameLabel,
                hintText: _isView ? null : CusAL.of(context).roleNameHint,
                border: const OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15.sp),
            Text(
              CusAL.of(context).rolePromptLabel,
              style: TextStyle(fontSize: 14.sp),
            ),
            SizedBox(height: 6.sp),
            TextField(
              controller: _promptCtl,
              maxLines: null,
              minLines: 12,
              expands: false,
              readOnly: _isView,
              keyboardType: TextInputType.multiline,
              decoration: InputDecoration(
                hintText: _isView ? null : CusAL.of(context).rolePromptHint,
                border: const OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            SizedBox(height: 8.sp),
            if (!_isView)
              Text(
                CusAL.of(context).rolePromptNote,
                style: TextStyle(fontSize: 11.sp, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
