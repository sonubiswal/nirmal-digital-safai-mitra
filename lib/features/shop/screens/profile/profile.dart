// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'package:nirmal/home_menu.dart';
import 'package:nirmal/features/shop/screens/settings/settings_controller.dart';
import 'profile_controller.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────
class _AppColors {
  static const primary = Color(0xFF2563EB);
  static const primaryLight = Color(0xFFE6F1FB);
  static const primaryDark = Color(0xFF185FA5);
  static const accent = Color(0xFFF59E0B);
  static const accentLight = Color(0xFFFAEEDA);
  static const accentDark = Color(0xFF633806);
  static const danger = Color(0xFFEF4444);
  static const dangerLight = Color(0xFFFEF2F2);
  static const success = Color(0xFF16A34A);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF1C1C1E);
  static const dividerLight = Color(0xFFE5E7EB);
  static const dividerDark = Color(0xFF3A3A3C);
  static const textPrimaryLight = Color(0xFF111827);
  static const textSecondaryLight = Color(0xFF6B7280);
  static const textPrimaryDark = Color(0xFFFFFFFF);
  static const textSecondaryDark = Color(0xFF9CA3AF);
}

// ─────────────────────────────────────────────────────────────────────────────
//  MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _fieldsSeeded = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProfileController>().loadProfile().then((_) => _seedFields());
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _seedFields() {
    if (_fieldsSeeded) return;
    final p = context.read<ProfileController>().profile;
    if (p == null) return;
    _nameCtrl.text = p.name;
    _emailCtrl.text = p.email;
    _phoneCtrl.text = p.phone;
    _fieldsSeeded = true;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ctrl = context.read<ProfileController>();
    final ok = await ctrl.saveProfile(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
    );
    if (!mounted) return;

    if (ok) {
      context.read<SettingsController>().refreshProfileLocally(
            name: _nameCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            role: ctrl.isAdmin ? 'admin' : 'user',
          );
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Profile saved successfully' : ctrl.error ?? 'Save failed'),
      backgroundColor: ok ? _AppColors.success : _AppColors.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ctrl = context.watch<ProfileController>();
    final profile = ctrl.profile;

    if (profile != null && !ctrl.isLoading && !_fieldsSeeded) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _seedFields());
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? Colors.black : const Color(0xFFF8FAFC),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _AppBar(isDark: isDark, isLoading: ctrl.isLoading, onSave: _save),
              if (ctrl.isLoading)
                const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
              else
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hero Card
                          _HeroCard(profile: profile, isDark: isDark),
                          const SizedBox(height: 24),

                          // Personal Information
                          _SectionLabel('Personal Information', isDark: isDark),
                          const SizedBox(height: 12),
                          _InfoCard(
                            nameCtrl: _nameCtrl,
                            emailCtrl: _emailCtrl,
                            phoneCtrl: _phoneCtrl,
                            isDark: isDark,
                          ),
                          const SizedBox(height: 24),

                          // Role & Permissions
                          _SectionLabel('Role & Permissions', isDark: isDark),
                          const SizedBox(height: 12),
                          _RoleCard(profile: profile, isDark: isDark),
                          const SizedBox(height: 16),

                          // Admin Dashboard Banner
                          if (profile?.role == UserRole.admin) ...[
                            _AdminBanner(isDark: isDark),
                            const SizedBox(height: 24),
                          ],

                          // Danger Zone
                          _SectionLabel('Danger Zone', isDark: isDark),
                          const SizedBox(height: 12),
                          _DangerCard(isDark: isDark),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  APP BAR
// ─────────────────────────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  final bool isDark;
  final bool isLoading;
  final VoidCallback onSave;
  const _AppBar({required this.isDark, required this.isLoading, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      backgroundColor: isDark ? _AppColors.surfaceDark : _AppColors.surfaceLight,
      surfaceTintColor: Colors.transparent,
      elevation: 0.5,
      shadowColor: Colors.black12,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18,
            color: isDark ? Colors.white : Colors.black87),
        onPressed: () {
          try {
            final nav = Get.find<NavigationController>();
            nav.selectedIndex.value = 0;
          } catch (_) {}
          Get.offAll(() => const NavigationMenu());
        },
      ),
      title: const Text('My Profile',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
      centerTitle: true,
      actions: [
        isLoading
            ? const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2)))
            : TextButton(
                onPressed: onSave,
                child: const Text('Save',
                    style: TextStyle(color: _AppColors.primary, fontWeight: FontWeight.w600, fontSize: 15)),
              ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  HERO CARD
// ─────────────────────────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final UserProfile? profile;
  final bool isDark;
  const _HeroCard({required this.profile, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isAdmin = profile?.role == UserRole.admin;
    final heroColor = isAdmin ? _AppColors.accentDark : _AppColors.primaryDark;
    final name = profile?.name ?? '';
    final email = profile?.email ?? '';
    final initials = _initials(name);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? _AppColors.surfaceDark : _AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Gradient top band
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [heroColor, heroColor.withOpacity(0.8)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
            child: Column(
              children: [
                // Avatar with edit icon
                Stack(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.2),
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(initials,
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: heroColor, width: 2),
                        ),
                        child: Icon(Icons.camera_alt_rounded, size: 16,
                            color: isAdmin ? _AppColors.accentDark : _AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(name.isEmpty ? 'User' : name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white,
                        letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(email,
                    style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.85))),
                const SizedBox(height: 16),
                // Role badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isAdmin ? Icons.admin_panel_settings_rounded : Icons.verified_user_rounded,
                          size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(isAdmin ? 'Administrator' : 'Standard User',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Stats row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(child: _StatCell(label: 'Member since', value: '2024', isDark: isDark)),
                Container(height: 40, width: 1, color: isDark ? _AppColors.dividerDark : _AppColors.dividerLight),
                Expanded(child: _StatCell(label: 'Email status', value: 'Verified', valueColor: _AppColors.success, isDark: isDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;
  const _StatCell({required this.label, required this.value, this.valueColor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[500] : Colors.grey[600])),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                  color: valueColor ?? (isDark ? Colors.white : Colors.black87))),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PERSONAL INFO CARD
// ─────────────────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController phoneCtrl;
  final bool isDark;
  const _InfoCard({required this.nameCtrl, required this.emailCtrl,
      required this.phoneCtrl, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _Card(
      isDark: isDark,
      child: Column(children: [
        _Field(
          ctrl: nameCtrl,
          label: 'Full name',
          icon: Icons.person_outline_rounded,
          isDark: isDark,
          action: TextInputAction.next,
          validator: (v) => (v?.trim().isEmpty ?? true) ? 'Name is required' : null,
        ),
        _Divider(isDark: isDark),
        _Field(
          ctrl: emailCtrl,
          label: 'Email address',
          icon: Icons.email_outlined,
          isDark: isDark,
          keyboard: TextInputType.emailAddress,
          action: TextInputAction.next,
          validator: (v) {
            if (v?.trim().isEmpty ?? true) return 'Email is required';
            if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(v!)) return 'Enter a valid email';
            return null;
          },
        ),
        _Divider(isDark: isDark),
        _Field(
          ctrl: phoneCtrl,
          label: 'Phone number',
          icon: Icons.phone_outlined,
          isDark: isDark,
          keyboard: TextInputType.phone,
          action: TextInputAction.done,
          validator: (v) {
            if (v?.trim().isEmpty ?? true) return null;
            if (!RegExp(r'^\+?[\d\s\-()]{7,}$').hasMatch(v!)) return 'Enter a valid phone number';
            return null;
          },
        ),
      ]),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool isDark;
  final TextInputType? keyboard;
  final TextInputAction? action;
  final String? Function(String?)? validator;
  const _Field({required this.ctrl, required this.label, required this.icon,
      required this.isDark, this.keyboard, this.action, this.validator});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: isDark ? Colors.grey[400] : Colors.grey[600]),
          ),
          Expanded(
            child: TextFormField(
              controller: ctrl,
              keyboardType: keyboard,
              textInputAction: action,
              validator: validator,
              style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(fontSize: 13, color: isDark ? Colors.grey[500] : Colors.grey[600]),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                errorStyle: const TextStyle(fontSize: 11.5, color: _AppColors.danger),
              ),
            ),
          ),
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
      padding: const EdgeInsets.only(left: 70),
      child: Divider(height: 0.5, thickness: 0.5,
          color: isDark ? _AppColors.dividerDark : _AppColors.dividerLight),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ROLE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _RoleCard extends StatelessWidget {
  final UserProfile? profile;
  final bool isDark;
  const _RoleCard({required this.profile, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isAdmin = profile?.role == UserRole.admin;
    return _Card(
      isDark: isDark,
      child: InkWell(
        onTap: () => _showRoleSheet(context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isAdmin ? _AppColors.accentLight : _AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  isAdmin ? Icons.admin_panel_settings_rounded : Icons.verified_user_rounded,
                  size: 24,
                  color: isAdmin ? _AppColors.accentDark : _AppColors.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Current role',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.grey[500] : Colors.grey[600])),
                    const SizedBox(height: 4),
                    Text(isAdmin ? 'Administrator' : 'Standard User',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text('Change',
                    style: TextStyle(color: _AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRoleSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => ChangeNotifierProvider.value(
        value: context.read<ProfileController>(),
        child: _RoleSheet(isDark: isDark),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ROLE CHANGE SHEET (identical to original but styled)
// ─────────────────────────────────────────────────────────────────────────────
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
  void initState() {
    super.initState();
    _selected = context.read<ProfileController>().profile?.role ?? UserRole.user;
  }

  @override
  void dispose() { _secretCtrl.dispose(); super.dispose(); }

  Future<void> _confirm() async {
    final ctrl = context.read<ProfileController>();
    if (_selected == ctrl.profile?.role) { Navigator.pop(context); return; }
    setState(() => _loading = true);
    final ok = await ctrl.verifyAndChangeRole(
        _selected, _selected == UserRole.admin ? _secretCtrl.text : null);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Role updated to ${_selected == UserRole.admin ? 'Administrator' : 'Standard User'}'),
        backgroundColor: _AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<ProfileController>();
    final bg = widget.isDark ? _AppColors.surfaceDark : _AppColors.surfaceLight;
    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: EdgeInsets.only(left: 24, right: 24, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: widget.isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Text('Change role', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
            color: widget.isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 6),
        Text('Administrator access requires a secret code provided by the developer.',
            style: TextStyle(fontSize: 13, color: widget.isDark ? Colors.grey[400] : Colors.grey[600])),
        const SizedBox(height: 20),
        _RoleOption(role: UserRole.user, selected: _selected == UserRole.user,
            isDark: widget.isDark, onTap: () => setState(() => _selected = UserRole.user)),
        const SizedBox(height: 8),
        _RoleOption(role: UserRole.admin, selected: _selected == UserRole.admin,
            isDark: widget.isDark, onTap: () => setState(() => _selected = UserRole.admin)),
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          child: _selected == UserRole.admin ? Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Secret code', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  letterSpacing: 0.4, color: widget.isDark ? Colors.grey[400] : Colors.grey[600])),
              const SizedBox(height: 8),
              TextField(
                controller: _secretCtrl,
                obscureText: _obscure,
                style: TextStyle(color: widget.isDark ? Colors.white : Colors.black87, fontSize: 15),
                decoration: InputDecoration(
                  hintText: 'Enter the code provided by your developer',
                  filled: true,
                  fillColor: widget.isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20, color: Colors.grey),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
            ]),
          ) : const SizedBox.shrink(),
        ),
        if (ctrl.roleError != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(color: _AppColors.dangerLight, borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.error_outline_rounded, size: 18, color: _AppColors.danger),
              const SizedBox(width: 10),
              Expanded(child: Text(ctrl.roleError!, style: const TextStyle(color: _AppColors.danger, fontSize: 13))),
            ]),
          ),
        ],
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton(
              onPressed: () { ctrl.clearRoleError(); Navigator.pop(context); },
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(color: widget.isDark ? Colors.grey[700]! : Colors.grey[300]!)),
              child: Text('Cancel', style: TextStyle(
                  color: widget.isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600)))),
          const SizedBox(width: 12),
          Expanded(child: FilledButton(
              onPressed: _loading ? null : _confirm,
              style: FilledButton.styleFrom(backgroundColor: _AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Confirm', style: TextStyle(fontWeight: FontWeight.w600)))),
        ]),
      ]),
    );
  }
}

class _RoleOption extends StatelessWidget {
  final UserRole role;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;
  const _RoleOption({required this.role, required this.selected,
      required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == UserRole.admin;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _AppColors.primaryLight : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? _AppColors.primary : Colors.transparent, width: 1.5),
        ),
        child: Row(children: [
          Icon(isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded,
              size: 22, color: selected ? _AppColors.primary : (isDark ? Colors.grey[400] : Colors.grey[500])),
          const SizedBox(width: 14),
          Expanded(child: Text(isAdmin ? 'Administrator' : 'Standard User',
              style: TextStyle(fontSize: 15,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? _AppColors.primaryDark : (isDark ? Colors.white : Colors.black87)))),
          if (selected) const Icon(Icons.check_circle_rounded, color: _AppColors.primary, size: 20),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ADMIN BANNER
// ─────────────────────────────────────────────────────────────────────────────
class _AdminBanner extends StatelessWidget {
  final bool isDark;
  const _AdminBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Admin Dashboard coming soon'),
        backgroundColor: _AppColors.accentDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      )),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_AppColors.accentDark, _AppColors.accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _AppColors.accent.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.dashboard_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Admin Dashboard',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              SizedBox(height: 2),
              Text('Manage users, content & settings',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
            ]),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  DANGER ZONE CARD
// ─────────────────────────────────────────────────────────────────────────────
class _DangerCard extends StatelessWidget {
  final bool isDark;
  const _DangerCard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _Card(
      isDark: isDark,
      child: Column(children: [
        _DangerTile(
          icon: Icons.logout_rounded,
          label: 'Sign out',
          color: _AppColors.primary,
          iconBg: _AppColors.primaryLight,
          isDark: isDark,
          onTap: () => _showConfirm(context,
            icon: Icons.logout_rounded,
            iconBg: _AppColors.primaryLight,
            iconColor: _AppColors.primary,
            title: 'Sign out',
            message: 'Are you sure you want to sign out of your account?',
            confirmLabel: 'Sign out',
            isDark: isDark,
            onConfirm: () async => context.read<ProfileController>().signOut(),
          ),
        ),
        _Divider(isDark: isDark),
        _DangerTile(
          icon: Icons.delete_forever_rounded,
          label: 'Delete account',
          color: _AppColors.danger,
          iconBg: _AppColors.dangerLight,
          isDark: isDark,
          onTap: () => _showConfirm(context,
            icon: Icons.delete_outline_rounded,
            iconBg: _AppColors.dangerLight,
            iconColor: _AppColors.danger,
            title: 'Delete account',
            message: 'This will permanently delete your account and all data. This cannot be undone.',
            confirmLabel: 'Delete',
            isDark: isDark,
            onConfirm: () async {
              final ok = await context.read<ProfileController>().deleteAccount();
              if (ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Account deleted'),
                  backgroundColor: _AppColors.danger,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ));
              }
            },
          ),
        ),
      ]),
    );
  }

  void _showConfirm(BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String message,
    required String confirmLabel,
    required bool isDark,
    required Future<void> Function() onConfirm,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConfirmSheet(
        icon: icon,
        iconBg: iconBg,
        iconColor: iconColor,
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        isDark: isDark,
        onConfirm: onConfirm,
      ),
    );
  }
}

class _DangerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color iconBg;
  final bool isDark;
  final VoidCallback onTap;
  const _DangerTile({required this.icon, required this.label, required this.color,
      required this.iconBg, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 16),
          Text(label, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: color)),
          const Spacer(),
          Icon(Icons.chevron_right_rounded, size: 20,
              color: isDark ? Colors.grey[600] : Colors.grey[400]),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  CONFIRM BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _ConfirmSheet extends StatefulWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String message;
  final String confirmLabel;
  final bool isDark;
  final Future<void> Function() onConfirm;
  const _ConfirmSheet({required this.icon, required this.iconBg, required this.iconColor,
      required this.title, required this.message, required this.confirmLabel,
      required this.isDark, required this.onConfirm});
  @override
  State<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends State<_ConfirmSheet> {
  bool _loading = false;
  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? _AppColors.surfaceDark : _AppColors.surfaceLight;
    return Container(
      decoration: BoxDecoration(color: bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Center(child: Container(width: 40, height: 4,
            decoration: BoxDecoration(color: widget.isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(color: widget.iconBg, shape: BoxShape.circle),
          child: Icon(widget.icon, color: widget.iconColor, size: 28),
        ),
        const SizedBox(height: 16),
        Text(widget.title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700,
            color: widget.isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 8),
        Text(widget.message, textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, height: 1.4,
                color: widget.isDark ? Colors.grey[400] : Colors.grey[600])),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  side: BorderSide(color: widget.isDark ? Colors.grey[700]! : Colors.grey[300]!)),
              child: Text('Cancel', style: TextStyle(
                  color: widget.isDark ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.w600)))),
          const SizedBox(width: 12),
          Expanded(child: FilledButton(
              onPressed: _loading ? null : () async {
                setState(() => _loading = true);
                await widget.onConfirm();
                if (mounted) Navigator.pop(context);
              },
              style: FilledButton.styleFrom(backgroundColor: widget.iconColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _loading
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(widget.confirmLabel, style: const TextStyle(fontWeight: FontWeight.w600)))),
        ]),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  REUSABLE CARD & SECTION LABEL
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  final bool isDark;
  const _SectionLabel(this.text, {required this.isDark});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(text.toUpperCase(),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8,
            color: isDark ? Colors.grey[500] : Colors.grey[600])),
  );
}

class _Card extends StatelessWidget {
  final bool isDark;
  final Widget child;
  const _Card({required this.isDark, required this.child});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: isDark ? _AppColors.surfaceDark : _AppColors.surfaceLight,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
      border: Border.all(
          color: isDark ? _AppColors.dividerDark : _AppColors.dividerLight,
          width: 0.5),
    ),
    clipBehavior: Clip.hardEdge,
    child: child,
  );
}