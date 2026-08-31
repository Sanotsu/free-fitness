import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/storage/db_ai_helper.dart';
import '../../../core/utils/tools.dart';
import '../../../models/ai/ai_custom_role.dart';
import '../../../models/ai/ai_role.dart';
import '../../../models/cus_app_localizations.dart';
import 'modify_role_page.dart';

/// 2026-08-27 自定义角色管理页
///
/// 内置 5 个角色只读展示(不可编辑删除)；
/// 自定义角色支持新增/编辑/删除(存 ff_ai_role 表)；
/// 删除自定义角色不级联修改历史会话(旧会话按兜底角色显示)。
class ManageRolesPage extends StatefulWidget {
  const ManageRolesPage({super.key});

  @override
  State<ManageRolesPage> createState() => _ManageRolesPageState();
}

class _ManageRolesPageState extends State<ManageRolesPage> {
  final DBAiHelper _dbHelper = DBAiHelper();

  List<AiCustomRole> customRoles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    var temp = await _dbHelper.queryCustomRoles();
    if (!mounted) return;
    setState(() {
      customRoles = temp;
      isLoading = false;
    });
  }

  // 新增/编辑自定义角色(独立页面，系统提示词较长时弹窗会溢出)
  Future<void> _openRoleEditPage({AiCustomRole? oldRole}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModifyRolePage(
          mode: oldRole == null ? RolePageMode.add : RolePageMode.edit,
          initialName: oldRole?.name,
          initialPrompt: oldRole?.systemPrompt,
          onSave: (name, systemPrompt) async {
            if (oldRole == null) {
              await _dbHelper.insertCustomRole(
                AiCustomRole(
                  name: name,
                  systemPrompt: systemPrompt,
                  gmtCreate: getCurrentDateTime(),
                  gmtModified: getCurrentDateTime(),
                ),
              );
            } else {
              oldRole.name = name;
              oldRole.systemPrompt = systemPrompt;
              oldRole.gmtModified = getCurrentDateTime();
              await _dbHelper.updateCustomRole(oldRole);
            }
          },
          // 详情页删除确认后回调，返回列表时统一刷新
          onDelete: oldRole == null
              ? null
              : () async {
                  await _dbHelper.deleteCustomRoleById(oldRole.roleId!);
                },
        ),
      ),
    );

    await _loadRoles();
  }

  // 内置角色点击进入只读详情页(提示词较长，列表两行看不全)
  void _openRoleViewPage(AiRole role, bool useEnData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModifyRolePage(
          mode: RolePageMode.view,
          initialName: role.name(useEnData),
          initialPrompt: role.systemPrompt(useEnData),
        ),
      ),
    );
  }

  // 左滑/详情页删除共用：确认弹窗后删除并刷新列表
  Future<bool> _confirmAndDelete(AiCustomRole role) async {
    var confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(CusAL.of(context).tipsTitle),
          content: Text(CusAL.of(context).rolesDeleteNote(role.name)),
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

    if (confirmed != true) return false;

    await _dbHelper.deleteCustomRoleById(role.roleId!);
    await _loadRoles();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    // UI 文案走 ARB；内置角色双语"数据"按实际 locale 选变体(非 zh 回退英文)
    var l10n = CusAL.of(context);
    var useEnData = Localizations.localeOf(context).languageCode != 'zh';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.rolesTitle)),
      body: isLoading
          ? Center(child: CircularProgressIndicator(strokeWidth: 2.sp))
          : ListView(
              children: [
                // 内置角色(只读展示)
                Padding(
                  padding: EdgeInsets.all(10.sp),
                  child: Text(
                    l10n.rolesBuiltIn,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ),
                ...builtinAiRoles.map((r) {
                  return Card(
                    elevation: 1.sp,
                    margin: EdgeInsets.symmetric(
                      horizontal: 10.sp,
                      vertical: 4.sp,
                    ),
                    // 点击进入只读详情页查看完整设定
                    child: ListTile(
                      leading: Icon(r.icon),
                      title: Text(r.name(useEnData)),
                      subtitle: Text(
                        useEnData ? r.systemPromptEn : r.systemPromptZh,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      onTap: () => _openRoleViewPage(r, useEnData),
                    ),
                  );
                }),

                // 自定义角色
                Padding(
                  padding: EdgeInsets.all(10.sp),
                  child: Text(
                    l10n.rolesCustom,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                ),
                if (customRoles.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(10.sp),
                    child: Center(
                      child: Text(
                        l10n.rolesEmptyCustom,
                        style: TextStyle(color: Colors.grey, fontSize: 13.sp),
                      ),
                    ),
                  ),
                // 2026-08-28 对齐 llm_config 列表交互：点行进详情编辑，左滑删除
                ...customRoles.map((r) {
                  return Dismissible(
                    key: ValueKey(r.roleId),
                    direction: DismissDirection.endToStart,
                    // 向左滑出红色删除背景；确认后删除
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 20.sp),
                      color: Colors.red,
                      child: Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                    ),
                    confirmDismiss: (direction) => _confirmAndDelete(r),
                    child: Card(
                      elevation: 1.sp,
                      margin: EdgeInsets.symmetric(
                        horizontal: 10.sp,
                        vertical: 4.sp,
                      ),
                      // 裁剪圆角，避免滑动删除的红色背景从卡片圆角处露出
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        leading: const Icon(Icons.person_pin),
                        title: Text(r.name),
                        subtitle: Text(
                          r.systemPrompt,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12.sp),
                        ),
                        onTap: () => _openRoleEditPage(oldRole: r),
                      ),
                    ),
                  );
                }),
                SizedBox(height: 80.sp),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openRoleEditPage(),
        tooltip: CusAL.of(context).rolesAddTooltip,
        child: const Icon(Icons.add),
      ),
    );
  }
}
