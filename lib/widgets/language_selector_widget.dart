import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';
import '../theme/app_theme.dart';

class LanguageSelectorWidget extends StatelessWidget {
  final bool isCompact;

  const LanguageSelectorWidget({super.key, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    final locService = context.watch<LocalizationService>();
    final currentCode = locService.locale.languageCode;

    if (isCompact) {
      return PopupMenuButton<Locale>(
        icon: const Icon(Icons.translate, size: 20),
        tooltip: 'Change Language / भाषा बदलें / భాష మార్చండి',
        initialValue: locService.locale,
        onSelected: (locale) => context.read<LocalizationService>().setLanguage(locale),
        itemBuilder: (context) => supportedLanguages.map((lang) {
          final isSelected = lang.locale.languageCode == currentCode;
          return PopupMenuItem<Locale>(
            value: lang.locale,
            child: Row(
              children: [
                if (isSelected)
                  const Icon(Icons.check, size: 18, color: AppTheme.primary)
                else
                  const SizedBox(width: 18),
                const SizedBox(width: 8),
                Text(
                  lang.nativeName,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppTheme.primaryDark : null,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${lang.name})',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }).toList(),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.translate, size: 18, color: AppTheme.primary),
          const SizedBox(width: 8),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: supportedLanguages.any((l) => l.locale.languageCode == currentCode)
                  ? currentCode
                  : 'en',
              isDense: true,
              borderRadius: BorderRadius.circular(12),
              icon: const Icon(Icons.arrow_drop_down, color: AppTheme.primaryDark),
              onChanged: (code) {
                if (code != null) {
                  final lang = supportedLanguages.firstWhere(
                    (l) => l.locale.languageCode == code,
                    orElse: () => supportedLanguages.first,
                  );
                  context.read<LocalizationService>().setLanguage(lang.locale);
                }
              },
              items: supportedLanguages.map((lang) {
                return DropdownMenuItem<String>(
                  value: lang.locale.languageCode,
                  child: Text(
                    '${lang.nativeName} (${lang.name})',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
