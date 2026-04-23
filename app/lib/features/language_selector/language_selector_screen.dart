import 'package:flutter/material.dart';

import '../../core/i18n/languages.dart';

/// Universal Language Selector.
///
/// Design rules (see docs/visual_assets_strategy.md §UI):
///   • Icon-first, text-light — a brand-new user from any country must
///     understand the screen instantly. We rely on flag emoji + the
///     language's *own* native name (never English) so users recognise
///     their language without being able to read the UI chrome.
///   • Auto-RTL: the chosen language's directionality is applied to the
///     whole app the moment the user picks it.
///   • Fast search by typing in any script (Arabic, Latin, CJK …) —
///     matches `nativeName`, `englishName`, or `code`.
///   • Returns the picked [LearningLanguage] via Navigator.pop.
class LanguageSelectorScreen extends StatefulWidget {
  const LanguageSelectorScreen({
    super.key,
    this.initialCode,
    this.languages = kSupportedLanguages,
  });

  final String? initialCode;
  final List<LearningLanguage> languages;

  @override
  State<LanguageSelectorScreen> createState() => _LanguageSelectorScreenState();
}

class _LanguageSelectorScreenState extends State<LanguageSelectorScreen> {
  late final TextEditingController _searchCtrl;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<LearningLanguage> get _filtered {
    if (_query.isEmpty) return widget.languages;
    final q = _query.toLowerCase().trim();
    return widget.languages.where((l) {
      return l.code.toLowerCase().contains(q) ||
          l.englishName.toLowerCase().contains(q) ||
          l.nativeName.toLowerCase().contains(q);
    }).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filtered = _filtered;

    return Scaffold(
      // Globe icon + flag row instead of a translated title — works for
      // any user regardless of the device locale.
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(12),
          child: Icon(Icons.public, size: 28),
        ),
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🌐', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 18),
            SizedBox(width: 8),
            Text('🗣️', style: TextStyle(fontSize: 22)),
          ],
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      ),
                hintText: '🔎',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
                filled: true,
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const _EmptyState()
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 180,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.05,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final lang = filtered[i];
                      final selected = lang.code == widget.initialCode;
                      return _LanguageCard(
                        lang: lang,
                        selected: selected,
                        onTap: () => Navigator.of(context).pop(lang),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.lang,
    required this.selected,
    required this.onTap,
  });

  final LearningLanguage lang;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        // Force the card's text direction to match the language itself,
        // so e.g. Arabic shows right-to-left even if the rest of the
        // app is currently LTR.
        child: Directionality(
          textDirection: lang.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(lang.flag, style: const TextStyle(fontSize: 40)),
                const SizedBox(height: 8),
                Text(
                  lang.nativeName,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  lang.code,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (selected)
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Icon(Icons.check_circle, size: 18),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 48),
          SizedBox(height: 8),
          Text('🤷'),
        ],
      ),
    );
  }
}
