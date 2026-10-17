import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'package:nirmal/features/shop/screens/profile/profile_controller.dart';
import 'package:nirmal/features/shop/screens/profile/profile.dart';
import 'package:nirmal/features/shop/screens/settings/settings_controller.dart';
import 'package:nirmal/home_menu.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsController>();
    final profile = context.watch<ProfileController>();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(context, isDark),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileHero(settings: settings, profile: profile, isDark: isDark),
                  const SizedBox(height: 24),
                  _SectionLabel('Appearance', isDark: isDark),
                  const SizedBox(height: 8),
                  _SettingsCard(isDark: isDark, children: [
                    _SettingsRow(
                      icon: Icons.wb_sunny_outlined,
                      iconBg: const Color(0xFFFAEEDA),
                      iconColor: const Color(0xFF854F0B),
                      label: 'Appearance',
                      value: settings.appearanceMode.label,
                      isDark: isDark,
                      onTap: () => _showAppearanceSheet(context, settings, isDark),
                    ),
                    _Divider(isDark: isDark),
                    _SettingsRow(
                      icon: Icons.language_outlined,
                      iconBg: const Color(0xFFE1F5EE),
                      iconColor: const Color(0xFF0F6E56),
                      label: 'App language',
                      value: settings.appLanguage.label.split('(').first.trim(),
                      isDark: isDark,
                      onTap: () => _showLanguageSheet(context, settings, isDark),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _SectionLabel('Notifications', isDark: isDark),
                  const SizedBox(height: 8),
                  _SettingsCard(isDark: isDark, children: [
                    _ToggleRow(
                      icon: Icons.notifications_outlined,
                      iconBg: const Color(0xFFFAEEDA),
                      iconColor: const Color(0xFF854F0B),
                      label: 'Push notifications',
                      subtitle: 'Alerts for truck updates',
                      value: settings.notificationsEnabled,
                      isDark: isDark,
                      onChanged: settings.setNotificationsEnabled,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _SectionLabel('Account', isDark: isDark),
                  const SizedBox(height: 8),
                  _SettingsCard(isDark: isDark, children: [
                    _SettingsRow(
                      icon: Icons.shield_outlined,
                      iconBg: const Color(0xFFE6F1FB),
                      iconColor: const Color(0xFF185FA5),
                      label: 'Change role',
                      subtitle: 'Currently: ${profile.isAdmin ? 'Administrator' : 'Standard User'}',
                      isDark: isDark,
                      onTap: () => _showRoleSheet(context, profile, isDark),
                    ),
                    _Divider(isDark: isDark),
                    _SettingsRow(
                      icon: Icons.chat_bubble_outline_rounded,
                      iconBg: const Color(0xFFE1F5EE),
                      iconColor: const Color(0xFF0F6E56),
                      label: 'Send feedback',
                      isDark: isDark,
                      onTap: () => _showFeedbackSheet(context, context.read<SettingsController>(), isDark),
                    ),
                    _Divider(isDark: isDark),
                    _SettingsRow(
                      icon: Icons.logout_rounded,
                      iconBg: const Color(0xFFE6F1FB),
                      iconColor: const Color(0xFF185FA5),
                      label: 'Sign out',
                      labelColor: const Color(0xFF185FA5),
                      isDark: isDark,
                      onTap: () => _showSignOutSheet(context, profile, isDark),
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _SectionLabel('About', isDark: isDark),
                  const SizedBox(height: 8),
                  _SettingsCard(isDark: isDark, children: [
                    _SettingsRow(
                      icon: Icons.info_outline_rounded,
                      iconBg: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF1EFE8),
                      iconColor: isDark ? Colors.grey[400]! : const Color(0xFF5F5E5A),
                      label: 'App version',
                      value: '1.0.0',
                      isDark: isDark,
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF1C1C1E) : Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: Colors.black12,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18,
            color: isDark ? Colors.white : Colors.black87),
        onPressed: () {
          // ✅ Reset bottom navigation to index 0 (Home) then go to NavigationMenu
          try {
            final nav = Get.find<NavigationController>();
            nav.selectedIndex.value = 0;
          } catch (_) {}
          Get.offAll(() => const NavigationMenu());
        },
      ),
      title: Text('Settings',
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87)),
      centerTitle: true,
    );
  }

  void _showAppearanceSheet(BuildContext ctx, SettingsController s, bool isDark) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AppearanceSheet(controller: s, isDark: isDark),
    );
  }

  void _showLanguageSheet(BuildContext ctx, SettingsController s, bool isDark) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _LanguageSheet(controller: s, isDark: isDark),
    );
  }

  void _showRoleSheet(BuildContext ctx, ProfileController p, bool isDark) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: p,
        child: _RoleSheet(isDark: isDark),
      ),
    );
  }

  void _showFeedbackSheet(BuildContext ctx, SettingsController s, bool isDark) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _FeedbackSheet(controller: s, isDark: isDark),
    );
  }

  void _showSignOutSheet(BuildContext ctx, ProfileController p, bool isDark) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ConfirmSheet(
        icon: Icons.logout_rounded,
        iconBg: const Color(0xFFE6F1FB),
        iconColor: const Color(0xFF185FA5),
        title: 'Sign out',
        message: 'Are you sure you want to sign out of your account?',
        confirmLabel: 'Sign out',
        isDark: isDark,
        onConfirm: () async => await p.signOut(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE HERO
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileHero extends StatelessWidget {
  final SettingsController settings;
  final ProfileController profile;
  final bool isDark;
  const _ProfileHero({required this.settings, required this.profile, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isAdmin = profile.isAdmin;
    final name = settings.userName.isEmpty ? (profile.profile?.name ?? '') : settings.userName;
    final email = settings.userEmail.isEmpty ? (profile.profile?.email ?? '') : settings.userEmail;
    final initials = settings.userInitials.isEmpty ? profile.initials : settings.userInitials;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E7EB), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isAdmin ? const Color(0xFFFAEEDA) : const Color(0xFFE6F1FB),
              border: Border.all(color: isAdmin ? const Color(0xFFF59E0B) : const Color(0xFF2563EB), width: 2),
            ),
            child: Center(child: Text(initials, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isAdmin ? const Color(0xFF633806) : const Color(0xFF0C447C)))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isEmpty ? 'User' : name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(email.isEmpty ? '' : email, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[500] : Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                _RolePill(isAdmin: isAdmin),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: () => Get.to(() => const ProfileScreen()),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFE6F1FB),
              foregroundColor: const Color(0xFF185FA5),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('View profile', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  final bool isAdmin;
  const _RolePill({required this.isAdmin});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: isAdmin ? const Color(0xFFFAEEDA) : const Color(0xFFE6F1FB), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isAdmin ? Icons.admin_panel_settings_rounded : Icons.verified_user_outlined, size: 11, color: isAdmin ? const Color(0xFF854F0B) : const Color(0xFF185FA5)),
          const SizedBox(width: 4),
          Text(isAdmin ? 'Administrator' : 'Standard User', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isAdmin ? const Color(0xFF633806) : const Color(0xFF0C447C))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE PRIMITIVES (with inkwell for tap feedback)
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionLabel(this.text, {required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(text.toUpperCase(), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, letterSpacing: 0.7, color: isDark ? Colors.grey[500] : Colors.grey[600])),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final bool isDark;
  final List<Widget> children;
  const _SettingsCard({required this.isDark, required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E7EB), width: 0.5),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(children: children),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final String? value;
  final Color? labelColor;
  final bool isDark;
  final VoidCallback? onTap;
  const _SettingsRow({required this.icon, required this.iconBg, required this.iconColor, required this.label, required this.isDark, this.subtitle, this.value, this.labelColor, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        highlightColor: isDark ? Colors.white10 : Colors.black12,
        splashColor: isDark ? Colors.white24 : Colors.black26,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              Container(width: 34, height: 34, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 17, color: iconColor)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: labelColor ?? (isDark ? Colors.white : Colors.black87))),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(subtitle!, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[500] : Colors.grey[600])),
                    ],
                  ],
                ),
              ),
              if (value != null) ...[const SizedBox(width: 8), Text(value!, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[500] : Colors.grey[600]))],
              if (onTap != null) ...[const SizedBox(width: 4), Icon(Icons.chevron_right_rounded, size: 18, color: isDark ? Colors.grey[600] : Colors.grey[400])],
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String? subtitle;
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.icon, required this.iconBg, required this.iconColor, required this.label, required this.value, required this.isDark, required this.onChanged, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Container(width: 34, height: 34, decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 17, color: iconColor)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87)),
                if (subtitle != null) ...[const SizedBox(height: 1), Text(subtitle!, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[500] : Colors.grey[600]))],
              ],
            ),
          ),
          Switch.adaptive(value: value, onChanged: onChanged, activeColor: const Color(0xFF2563EB)),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final bool isDark;
  const _Divider({required this.isDark});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 62),
      child: Divider(height: 0.5, thickness: 0.5, color: isDark ? const Color(0xFF3A3A3C) : const Color(0xFFE5E7EB)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM SHEETS – Lifted higher (bottom margin 40)
// ─────────────────────────────────────────────────────────────────────────────
class _SheetBase extends StatelessWidget {
  final bool isDark;
  final Widget child;
  const _SheetBase({required this.isDark, required this.child});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 40),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          left: 24, right: 24, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(color: isDark ? Colors.grey[700] : Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          child,
        ]),
      ),
    );
  }
}

class _AppearanceSheet extends StatefulWidget {
  final SettingsController controller;
  final bool isDark;
  const _AppearanceSheet({required this.controller, required this.isDark});
  @override
  State<_AppearanceSheet> createState() => _AppearanceSheetState();
}
class _AppearanceSheetState extends State<_AppearanceSheet> {
  late AppearanceMode _selected;
  @override
  void initState() { super.initState(); _selected = widget.controller.appearanceMode; }
  @override
  Widget build(BuildContext context) {
    return _SheetBase(isDark: widget.isDark, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Appearance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: widget.isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 16),
        Row(children: AppearanceMode.values.map((m) {
          final sel = _selected == m;
          return Expanded(child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selected = m),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFFE6F1FB) : (widget.isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sel ? const Color(0xFF2563EB) : Colors.transparent, width: 1.5),
                ),
                child: Text(m.label, textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                        color: sel ? const Color(0xFF185FA5) : (widget.isDark ? Colors.grey[400] : Colors.grey[600]))),
              ),
            ),
          ));
        }).toList()),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text('Cancel', style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)))),
          const SizedBox(width: 12),
          Expanded(child: FilledButton(
              onPressed: () { widget.controller.setAppearanceMode(_selected); Navigator.pop(context); },
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w600)))),
        ]),
      ],
    ));
  }
}

class _LanguageSheet extends StatefulWidget {
  final SettingsController controller;
  final bool isDark;
  const _LanguageSheet({required this.controller, required this.isDark});
  @override
  State<_LanguageSheet> createState() => _LanguageSheetState();
}
class _LanguageSheetState extends State<_LanguageSheet> {
  late AppLanguage _selected;
  @override
  void initState() { super.initState(); _selected = widget.controller.appLanguage; }
  @override
  Widget build(BuildContext context) {
    return _SheetBase(isDark: widget.isDark, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('App language', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: widget.isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 16),
        ...AppLanguage.values.map((lang) {
          final sel = _selected == lang;
          return GestureDetector(
            onTap: () => setState(() => _selected = lang),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFFE6F1FB) : (widget.isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7)),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: sel ? const Color(0xFF2563EB) : Colors.transparent, width: 1.5),
              ),
              child: Row(
                children: [
                  Expanded(child: Text(lang.label, style: TextStyle(fontSize: 14, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? const Color(0xFF185FA5) : (widget.isDark ? Colors.white : Colors.black87)))),
                  if (sel) const Icon(Icons.check_rounded, color: Color(0xFF2563EB), size: 18),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text('Cancel', style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)))),
          const SizedBox(width: 12),
          Expanded(child: FilledButton(
              onPressed: () { widget.controller.setAppLanguage(_selected); Navigator.pop(context); },
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w600)))),
        ]),
      ],
    ));
  }
}

class _RoleSheet extends StatefulWidget {
  final bool isDark;
  const _RoleSheet({required this.isDark});
  @override
  State<_RoleSheet> createState() => _RoleSheetState();
}
class _RoleSheetState extends State<_RoleSheet> {
  final _secretCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  late UserRole _selected;
  @override
  void initState() { super.initState(); _selected = context.read<ProfileController>().profile?.role ?? UserRole.user; }
  @override
  void dispose() { _secretCtrl.dispose(); super.dispose(); }
  Future<void> _confirm() async {
    final ctrl = context.read<ProfileController>();
    if (_selected == ctrl.profile?.role) { Navigator.pop(context); return; }
    setState(() => _loading = true);
    final ok = await ctrl.verifyAndChangeRole(_selected, _selected == UserRole.admin ? _secretCtrl.text : null);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      context.read<SettingsController>().refreshProfileLocally(
        name: ctrl.profile?.name ?? '', email: ctrl.profile?.email ?? '', phone: ctrl.profile?.phone ?? '', role: ctrl.profile?.role == UserRole.admin ? 'admin' : 'user',
      );
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Role updated to ${_selected == UserRole.admin ? 'Administrator' : 'Standard User'}'),
        backgroundColor: const Color(0xFF2563EB), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }
  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ProfileController>();
    return _SheetBase(isDark: widget.isDark, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Change role', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: widget.isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 4),
        Text('Administrator access requires a secret code from your developer.', style: TextStyle(fontSize: 13, color: widget.isDark ? Colors.grey[400] : Colors.grey[600])),
        const SizedBox(height: 16),
        _RoleOption(role: UserRole.user, selected: _selected == UserRole.user, isDark: widget.isDark, onTap: () => setState(() => _selected = UserRole.user)),
        const SizedBox(height: 6),
        _RoleOption(role: UserRole.admin, selected: _selected == UserRole.admin, isDark: widget.isDark, onTap: () => setState(() => _selected = UserRole.admin)),
        AnimatedSize(
          duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic,
          child: _selected == UserRole.admin ? Padding(
            padding: const EdgeInsets.only(top: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Secret code', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.4, color: widget.isDark ? Colors.grey[400] : Colors.grey[600])),
              const SizedBox(height: 8),
              TextField(
                controller: _secretCtrl, obscureText: _obscure,
                style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Enter the code provided by your developer', filled: true,
                  fillColor: widget.isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: Colors.grey), onPressed: () => setState(() => _obscure = !_obscure)),
                ),
              ),
            ]),
          ) : const SizedBox.shrink(),
        ),
        if (ctrl.roleError != null) ...[
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFEF4444)), const SizedBox(width: 8), Expanded(child: Text(ctrl.roleError!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)))]),
          ),
        ],
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () { ctrl.clearRoleError(); Navigator.pop(context); },
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text('Cancel', style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)))),
          const SizedBox(width: 12),
          Expanded(child: FilledButton(
              onPressed: _loading ? null : _confirm,
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w600)))),
        ]),
      ],
    ));
  }
}

class _RoleOption extends StatelessWidget {
  final UserRole role; final bool selected; final bool isDark; final VoidCallback onTap;
  const _RoleOption({required this.role, required this.selected, required this.isDark, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final isAdmin = role == UserRole.admin;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE6F1FB) : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? const Color(0xFF2563EB) : Colors.transparent, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded, size: 18, color: selected ? const Color(0xFF2563EB) : (isDark ? Colors.grey[400] : Colors.grey[500])),
            const SizedBox(width: 10),
            Expanded(child: Text(isAdmin ? 'Administrator' : 'Standard User', style: TextStyle(fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? const Color(0xFF185FA5) : (isDark ? Colors.white : Colors.black87)))),
            if (selected) const Icon(Icons.check_rounded, color: Color(0xFF2563EB), size: 18),
          ],
        ),
      ),
    );
  }
}

class _FeedbackSheet extends StatefulWidget {
  final SettingsController controller;
  final bool isDark;
  const _FeedbackSheet({required this.controller, required this.isDark});
  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}
class _FeedbackSheetState extends State<_FeedbackSheet> {
  final _ctrl = TextEditingController();
  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>();
    return _SheetBase(isDark: widget.isDark, child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Send feedback', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: widget.isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 4),
        Text('Share your thoughts or report an issue.', style: TextStyle(fontSize: 13, color: widget.isDark ? Colors.grey[400] : Colors.grey[600])),
        const SizedBox(height: 14),
        TextField(
          controller: _ctrl, maxLines: 4,
          style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Describe your feedback...', filled: true,
            fillColor: widget.isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        if (s.feedbackError != null) ...[const SizedBox(height: 10), Text(s.feedbackError!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13))],
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () { s.clearFeedbackError(); Navigator.pop(context); },
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text('Cancel', style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)))),
          const SizedBox(width: 12),
          Expanded(child: FilledButton(
              onPressed: s.isFeedbackLoading ? null : () async { final ok = await s.submitFeedback(_ctrl.text); if (ok && context.mounted) Navigator.pop(context); },
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2563EB), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: s.isFeedbackLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Send', style: TextStyle(fontWeight: FontWeight.w600)))),
        ]),
      ],
    ));
  }
}

class _ConfirmSheet extends StatefulWidget {
  final IconData icon; final Color iconBg; final Color iconColor; final String title; final String message; final String confirmLabel; final bool isDark; final Future<void> Function() onConfirm;
  const _ConfirmSheet({required this.icon, required this.iconBg, required this.iconColor, required this.title, required this.message, required this.confirmLabel, required this.isDark, required this.onConfirm});
  @override
  State<_ConfirmSheet> createState() => _ConfirmSheetState();
}
class _ConfirmSheetState extends State<_ConfirmSheet> {
  bool _loading = false;
  @override
  Widget build(BuildContext context) {
    return _SheetBase(isDark: widget.isDark, child: Column(
      children: [
        Container(width: 52, height: 52, decoration: BoxDecoration(color: widget.iconBg, shape: BoxShape.circle), child: Icon(widget.icon, color: widget.iconColor, size: 24)),
        const SizedBox(height: 14),
        Text(widget.title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: widget.isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 6),
        Text(widget.message, textAlign: TextAlign.center, style: TextStyle(fontSize: 13.5, color: widget.isDark ? Colors.grey[400] : Colors.grey[600], height: 1.4)),
        const SizedBox(height: 22),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text('Cancel', style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)))),
          const SizedBox(width: 12),
          Expanded(child: FilledButton(
              onPressed: _loading ? null : () async { setState(() => _loading = true); await widget.onConfirm(); if (mounted) Navigator.pop(context); },
              style: FilledButton.styleFrom(backgroundColor: widget.iconColor, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Text(widget.confirmLabel, style: const TextStyle(fontWeight: FontWeight.w600)))),
        ]),
      ],
    ));
  }
}