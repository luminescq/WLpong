import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_colors.dart';
import '../models/check_profile.dart';
import '../providers/database_provider.dart';
import '../providers/check_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/common/screen_header.dart';

// ─── Модель профиля (UI обертка) ───────────────────────────────────────────────

class ProfileUI {
  final int? dbId; // null = профиль по умолчанию
  String name;
  final IconData icon;
  final bool isDefault;
  List<String> domains;
  bool isExpanded;

  ProfileUI({
    this.dbId,
    required this.name,
    required this.icon,
    this.isDefault = false,
    required this.domains,
    this.isExpanded = false,
  });
}

// ─── Экран расширенного режима ────────────────────────────────────────────────

class AdvancedScreen extends ConsumerStatefulWidget {
  const AdvancedScreen({super.key});

  @override
  ConsumerState<AdvancedScreen> createState() => _AdvancedScreenState();
}

class _AdvancedScreenState extends ConsumerState<AdvancedScreen> {
  int _activeProfileIndex = 0;
  int _renamingIndex = -1;
  final _renameController = TextEditingController();
  final _renameFocusNode = FocusNode();
  
  final Map<int, TextEditingController> _domainControllers = {};
  final Map<int, FocusNode> _domainFocusNodes = {};
  
  List<ProfileUI> _localProfiles = [];

  @override
  void initState() {
    super.initState();
    _renameFocusNode.addListener(() {
      if (!_renameFocusNode.hasFocus && _renamingIndex != -1) {
        _commitRename();
      }
    });
  }

  @override
  void dispose() {
    for (final c in _domainControllers.values) c.dispose();
    for (final f in _domainFocusNodes.values) f.dispose();
    _renameController.dispose();
    _renameFocusNode.dispose();
    super.dispose();
  }

  void _syncProfiles(List<CheckProfile> dbProfiles) {
    final expandedStates = {
      for (var p in _localProfiles) p.dbId: p.isExpanded
    };

    _localProfiles = [
      ProfileUI(
        dbId: null,
        name: 'По умолчанию',
        icon: Icons.bolt_rounded,
        isDefault: true,
        domains: [], // В UI не редактируются
        isExpanded: false,
      ),
      ...dbProfiles.map((p) => ProfileUI(
            dbId: p.id,
            name: p.name,
            // ignore: non_const_argument_for_const_parameter
            icon: IconData(p.iconCodePoint, fontFamily: 'MaterialIcons'),
            domains: List.from(p.domains),
            isExpanded: expandedStates[p.id] ?? false,
          ))
    ];

    for (int i = 0; i < _localProfiles.length; i++) {
      _domainControllers.putIfAbsent(i, () => TextEditingController());
      _domainFocusNodes.putIfAbsent(i, () => FocusNode());
    }
  }

  Future<void> _saveProfileToDb(ProfileUI profile) async {
    if (profile.dbId == null) return;
    final db = ref.read(databaseProvider);
    final p = CheckProfile()
      ..id = profile.dbId!
      ..name = profile.name
      ..iconCodePoint = profile.icon.codePoint
      ..domains = profile.domains;
    await db.saveProfile(p);
  }

  // ── Выбор профиля ─────────────────────────────────────────────

  void _selectProfile(int index) {
    if (_activeProfileIndex == index) return;
    setState(() => _activeProfileIndex = index);
    ref.read(activeProfileIdProvider.notifier).state = _localProfiles[index].dbId;
    if (ref.read(settingsProvider).hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  // ── Разворот профиля ─────────────────────────────────────────

  void _toggleExpand(int index) {
    setState(() {
      _localProfiles[index].isExpanded = !_localProfiles[index].isExpanded;
      if (!_localProfiles[index].isExpanded) {
        _domainControllers[index]?.clear();
        _domainFocusNodes[index]?.unfocus();
      }
    });
  }

  // ── Переименование ────────────────────────────────────────────────────────

  void _startRename(int index) {
    if (_localProfiles[index].isDefault) return;
    setState(() {
      _renamingIndex = index;
      _renameController.text = _localProfiles[index].name;
      _renameController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _renameController.text.length,
      );
    });
    Future.microtask(() => _renameFocusNode.requestFocus());
  }

  Future<void> _commitRename() async {
    final text = _renameController.text.trim();
    if (text.isNotEmpty && _renamingIndex != -1) {
      final p = _localProfiles[_renamingIndex];
      p.name = text;
      await _saveProfileToDb(p);
    }
    setState(() {
      _renamingIndex = -1;
    });
  }

  // ── Домены ────────────────────────────────────────────────────────────────

  String _normalizeDomain(String input) {
    var domain = input.trim().toLowerCase();
    
    // Удаляем http:// и https://
    if (domain.startsWith('http://')) {
      domain = domain.substring(7);
    } else if (domain.startsWith('https://')) {
      domain = domain.substring(8);
    }
    
    // Удаляем пути и параметры (всё что после '/')
    final slashIndex = domain.indexOf('/');
    if (slashIndex != -1) {
      domain = domain.substring(0, slashIndex);
    }
    
    // Удаляем порты (всё что после ':')
    final colonIndex = domain.indexOf(':');
    if (colonIndex != -1) {
      domain = domain.substring(0, colonIndex);
    }
    
    return domain;
  }

  Future<void> _addDomain(int index) async {
    final rawText = _domainControllers[index]?.text ?? '';
    final domain = _normalizeDomain(rawText);
    
    if (domain.isEmpty) return;
    
    final p = _localProfiles[index];
    
    // Проверка на дубликаты
    if (p.domains.contains(domain)) {
      _domainControllers[index]?.clear();
      return;
    }
    
    p.domains.add(domain);
    _domainControllers[index]?.clear();
    
    await _saveProfileToDb(p);
    if (ref.read(settingsProvider).hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _removeDomain(int profileIndex, int domainIndex) async {
    final p = _localProfiles[profileIndex];
    p.domains.removeAt(domainIndex);
    await _saveProfileToDb(p);
    if (ref.read(settingsProvider).hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  // ── Добавить профиль ─────────────────────────────────────────────────────

  Future<void> _addProfile() async {
    final db = ref.read(databaseProvider);
    final newProfile = CheckProfile()
      ..name = 'Новый профиль'
      ..iconCodePoint = Icons.person_outline_rounded.codePoint
      ..domains = [];
    
    await db.saveProfile(newProfile);
    
    if (ref.read(settingsProvider).hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(profilesStreamProvider);
    final isPerfMode = ref.watch(settingsProvider).performanceMode;

    Widget content = Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isPerfMode ? Colors.black.withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(32),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                    // Шапка
                    Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20, top: 24),
                      child: ScreenHeader(
                        title: 'Профили',
                        subtitle: 'Настройка списков доменов',
                        trailing: Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            color: AppColors.bgElevated,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.add_rounded, color: AppColors.textSecondary, size: 20),
                            tooltip: 'Добавить профиль',
                            padding: const EdgeInsets.all(8),
                            constraints: const BoxConstraints(),
                            onPressed: _addProfile,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    Expanded(
                      child: profilesAsync.when(
                        data: (dbProfiles) {
                          _syncProfiles(dbProfiles);
                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                            physics: const BouncingScrollPhysics(),
                            itemCount: _localProfiles.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (_, index) => _buildProfileCard(index),
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accentGreen)),
                        error: (e, _) => Center(child: Text('Ошибка: $e', style: const TextStyle(color: Colors.white))),
                      ),
                    ),
                  ],
                ),
    );

    Widget glassContainer = isPerfMode
        ? ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: content,
          )
        : ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: content,
            ),
          );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GestureDetector(
        onTap: () {
          if (_renamingIndex != -1) _commitRename();
        },
        behavior: HitTestBehavior.translucent,
        child: Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: 96,
          ),
          child: glassContainer,
        ),
      ),
    );
  }



  // ── Карточка профиля ─────────────────────────────────────────────────────────

  Widget _buildProfileCard(int index) {
    final profile = _localProfiles[index];
    final isActive = _activeProfileIndex == index;
    final isRenaming = _renamingIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C20).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? Colors.white.withValues(alpha: 0.20)
              : Colors.white.withValues(alpha: 0.07),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _selectProfile(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.textPrimary : AppColors.bgElevated,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive ? Colors.transparent : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Icon(
                      profile.icon,
                      size: 18,
                      color: isActive ? AppColors.bgBase : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: profile.isDefault ? null : () => _startRename(index),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isRenaming)
                          SizedBox(
                            height: 22,
                            child: TextField(
                              controller: _renameController,
                              focusNode: _renameFocusNode,
                              onSubmitted: (_) => _commitRename(),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                height: 1,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              textInputAction: TextInputAction.done,
                            ),
                          )
                        else
                          Row(
                            children: [
                              Text(
                                profile.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (!profile.isDefault) ...[
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.edit_outlined,
                                  size: 13,
                                  color: AppColors.textTertiary,
                                ),
                              ],
                            ],
                          ),
                        const SizedBox(height: 2),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: isActive
                              ? const Text(
                                  'Активен',
                                  key: ValueKey('active'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.accentGreen,
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                              : Text(
                                  'Нажмите на значок для выбора',
                                  key: const ValueKey('inactive'),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (!profile.isDefault) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _toggleExpand(index),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: AnimatedRotation(
                        turns: profile.isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeInOut,
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textSecondary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  // Кнопка удаления профиля
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () async {
                      if (profile.dbId != null) {
                        final db = ref.read(databaseProvider);
                        await db.deleteProfile(profile.dbId!);
                        if (_activeProfileIndex == index) {
                          setState(() => _activeProfileIndex = 0);
                          ref.read(activeProfileIdProvider.notifier).state = null;
                        }
                      }
                    },
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!profile.isDefault)
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: profile.isExpanded ? _buildExpandedBody(index) : const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }

  // ── Тело с доменами ──────────────────────────────────────────────────────────

  Widget _buildExpandedBody(int index) {
    final profile = _localProfiles[index];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(
          height: 1,
          thickness: 1,
          color: Colors.white.withValues(alpha: 0.07),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Добавить домен',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _domainControllers[index],
                        focusNode: _domainFocusNodes[index],
                        onSubmitted: (_) => _addDomain(index),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Введите домен...',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: AppColors.textTertiary,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.done,
                        autocorrect: false,
                        enableSuggestions: false,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _addDomain(index),
                      child: const SizedBox(
                        width: 44,
                        height: 44,
                        child: Icon(
                          Icons.add_rounded,
                          color: AppColors.textSecondary,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (profile.domains.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Добавленные домены',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                ...List.generate(profile.domains.length, (di) {
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: di < profile.domains.length - 1 ? 6 : 0,
                    ),
                    child: _buildDomainRow(index, di),
                  );
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Строка домена ────────────────────────────────────────────────────────────

  Widget _buildDomainRow(int profileIndex, int domainIndex) {
    final domain = _localProfiles[profileIndex].domains[domainIndex];

    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.textPrimary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              domain,
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () => _removeDomain(profileIndex, domainIndex),
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Icon(
                Icons.close_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
