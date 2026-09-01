import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/settings_provider.dart';

class TimeoutScreen extends StatelessWidget {
  const TimeoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final currentTimeout = settings.authTimeoutSeconds;

    final options = [
      {'label': '1 minute', 'value': 60},
      {'label': '2 minutes', 'value': 120},
      {'label': '5 minutes', 'value': 300},
      {'label': '10 minutes', 'value': 600},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Authentication Timeout',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options.map((opt) {
                final label = opt['label'] as String;
                final seconds = opt['value'] as int;
                // Check if the current timeout matches, default to closest if custom
                final isSelected = currentTimeout == seconds || 
                    (opt == options.first && ![120, 300, 600].contains(currentTimeout));
                final isLast = options.last == opt;

                return Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      title: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1D2939),
                        ),
                      ),
                      trailing: isSelected
                          ? Icon(
                              Icons.check_circle,
                              color: settings.accentColor,
                              size: 24,
                            )
                          : null,
                      onTap: () {
                        settings.setAuthTimeout(seconds);
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Session timeout updated to $label'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: settings.accentColor,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    if (!isLast)
                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Color(0xFFF2F4F7),
                        indent: 24,
                        endIndent: 24,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
