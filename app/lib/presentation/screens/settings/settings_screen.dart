import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/purchase_providers.dart';
import '../../../core/services/backup_service.dart';
import '../../../data/models/settings_model.dart';
import '../../../data/database/database_helper.dart';
import '../../providers/app_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final purchaseState = ref.watch(purchaseStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (settings) => _buildContent(context, ref, settings, purchaseState),
      ),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, SettingsModel settings, PurchaseState purchaseState) {
    // Use store purchase status as primary source, fall back to local settings
    final isPremium = purchaseState.isPremium || settings.isPremium;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.screenPadding),
      children: [
        // Premium section
        if (!isPremium) ...[
          const SizedBox(height: Spacing.md),
          _buildPremiumCard(context, ref, purchaseState, isDark),
          const SizedBox(height: Spacing.lg),
        ] else ...[
          const SizedBox(height: Spacing.md),
        ],

        // Appearance section
        _buildSectionHeader(context, 'Appearance'),
        const SizedBox(height: Spacing.sm),
        _buildSectionCard(
          context,
          isDark,
          children: [
            _buildSettingsTile(
              context: context,
              icon: Icons.dark_mode,
              title: 'Dark Mode',
              subtitle: _getDarkModeLabel(settings.darkMode),
              onTap: () => _showDarkModeDialog(context, ref, settings),
            ),
          ],
        ),

        const SizedBox(height: Spacing.lg),

        // Learning section
        _buildSectionHeader(context, 'Learning'),
        const SizedBox(height: Spacing.sm),
        _buildSectionCard(
          context,
          isDark,
          children: [
            _buildSettingsTile(
              context: context,
              icon: Icons.format_list_numbered,
              title: 'Cards per Session',
              subtitle: '${settings.sessionCardCount} cards',
              onTap: () => _showSessionSizeDialog(context, ref, settings),
            ),
          ],
        ),

        const SizedBox(height: Spacing.lg),

        // Notifications section
        _buildSectionHeader(context, 'Notifications'),
        const SizedBox(height: Spacing.sm),
        _buildSectionCard(
          context,
          isDark,
          children: [
            _buildSwitchTile(
              context: context,
              icon: Icons.notifications,
              title: 'Daily Reminders',
              subtitle: settings.notificationsEnabled
                  ? '${settings.notificationHour.toString().padLeft(2, '0')}:${settings.notificationMinute.toString().padLeft(2, '0')}'
                  : 'Off',
              value: settings.notificationsEnabled,
              onChanged: (value) async {
                await ref.read(settingsProvider.notifier).setNotifications(value);
              },
            ),
            if (settings.notificationsEnabled) ...[
              Divider(
                height: 1,
                indent: 56,
                color: isDark ? Colors.grey[700] : const Color(0xFF1A1A1A).withOpacity(0.15),
              ),
              _buildSettingsTile(
                context: context,
                icon: Icons.access_time,
                title: 'Reminder Time',
                subtitle: '${settings.notificationHour.toString().padLeft(2, '0')}:${settings.notificationMinute.toString().padLeft(2, '0')}',
                onTap: () => _showTimePickerDialog(context, ref, settings),
              ),
            ],
          ],
        ),

        const SizedBox(height: Spacing.lg),

        // Data section
        _buildSectionHeader(context, 'Data'),
        const SizedBox(height: Spacing.sm),
        _buildSectionCard(
          context,
          isDark,
          children: [
            _buildSettingsTile(
              context: context,
              icon: Icons.upload,
              title: 'Export Data',
              subtitle: 'Save backup to device',
              onTap: () => _showExportDialog(context, ref),
            ),
            Divider(
              height: 1,
              indent: 56,
              color: isDark ? Colors.grey[700] : const Color(0xFF1A1A1A).withOpacity(0.15),
            ),
            _buildSettingsTile(
              context: context,
              icon: Icons.download,
              title: 'Import Data',
              subtitle: 'Restore from backup',
              onTap: () => _showImportDialog(context, ref),
            ),
            Divider(
              height: 1,
              indent: 56,
              color: isDark ? Colors.grey[700] : const Color(0xFF1A1A1A).withOpacity(0.15),
            ),
            _buildSettingsTile(
              context: context,
              icon: Icons.refresh,
              title: 'Reset Progress',
              subtitle: 'Keep people, clear learning data',
              onTap: () => _showResetProgressDialog(context, ref),
            ),
            Divider(
              height: 1,
              indent: 56,
              color: isDark ? Colors.grey[700] : const Color(0xFF1A1A1A).withOpacity(0.15),
            ),
            _buildSettingsTile(
              context: context,
              icon: Icons.delete_forever,
              title: 'Delete All Data',
              subtitle: 'Remove all groups, people, and progress',
              isDestructive: true,
              onTap: () => _showDeleteAllDialog(context, ref),
            ),
          ],
        ),

        const SizedBox(height: Spacing.lg),

        // About section
        _buildSectionHeader(context, 'About'),
        const SizedBox(height: Spacing.sm),
        _buildSectionCard(
          context,
          isDark,
          children: [
            _buildSettingsTile(
              context: context,
              icon: Icons.info,
              title: 'Version',
              subtitle: AppConstants.appVersion,
              showChevron: false,
            ),
            Divider(
              height: 1,
              indent: 56,
              color: isDark ? Colors.grey[700] : const Color(0xFF1A1A1A).withOpacity(0.15),
            ),
            _buildSettingsTile(
              context: context,
              icon: Icons.privacy_tip,
              title: 'Privacy Policy',
              showExternalIcon: true,
              onTap: () => _openUrl('https://namedrill.app/privacy'),
            ),
            Divider(
              height: 1,
              indent: 56,
              color: isDark ? Colors.grey[700] : const Color(0xFF1A1A1A).withOpacity(0.15),
            ),
            _buildSettingsTile(
              context: context,
              icon: Icons.mail,
              title: 'Send Feedback',
              showExternalIcon: true,
              onTap: () => _openUrl('mailto:support@namedrill.app?subject=NameDrill%20Feedback'),
            ),
          ],
        ),

        const SizedBox(height: Spacing.xxl),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, top: Spacing.lg),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, bool isDark, {required List<Widget> children}) {
    return Container(
      decoration: NeoStyles.cardDecoration(isDark: isDark, shadowOffset: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(CardStyles.borderRadius - 2),
        child: Column(
          children: children,
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    bool showChevron = true,
    bool showExternalIcon = false,
    bool isDestructive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDestructive ? AppTheme.errorColor : null;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
      leading: Container(
        width: 40,
        height: 40,
        decoration: NeoStyles.chipDecoration(
          backgroundColor: isDark
              ? (color ?? AppTheme.primaryColor).withOpacity(0.15)
              : (color ?? AppTheme.primaryColor).withOpacity(0.12),
          isDark: isDark,
          borderRadius: 10,
          shadowOffset: 2,
          borderWidth: 1.5,
        ),
        child: Icon(
          icon,
          color: color ?? AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color?.withOpacity(0.7),
                  ),
            )
          : null,
      trailing: showExternalIcon
          ? Icon(Icons.open_in_new, size: 18, color: Theme.of(context).colorScheme.outline)
          : (showChevron && onTap != null)
              ? Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outline)
              : null,
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
      leading: Container(
        width: 40,
        height: 40,
        decoration: NeoStyles.chipDecoration(
          backgroundColor: isDark
              ? AppTheme.primaryColor.withOpacity(0.15)
              : AppTheme.primaryColor.withOpacity(0.12),
          isDark: isDark,
          borderRadius: 10,
          shadowOffset: 2,
          borderWidth: 1.5,
        ),
        child: Icon(
          icon,
          color: AppTheme.primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: subtitle != null ? Text(subtitle, style: Theme.of(context).textTheme.bodySmall) : null,
      trailing: Switch.adaptive(
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildPremiumCard(BuildContext context, WidgetRef ref, PurchaseState purchaseState, bool isDark) {
    final isLoading = purchaseState.status == PurchaseStatus.loading;
    
    return Container(
      decoration: NeoStyles.cardDecoration(
        isDark: isDark,
        backgroundColor: AppTheme.accentColor,
        shadowOffset: 5,
      ),
      child: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFFE0E0E0) : const Color(0xFF1A1A1A),
                      width: 2,
                    ),
                  ),
                  child: const Icon(Icons.star, color: Colors.amber, size: 24),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upgrade to Premium',
                        style: TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'Unlock unlimited potential',
                        style: TextStyle(
                          color: Color(0xFF1A1A1A),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: Spacing.lg),
            _buildFeatureRow('Unlimited groups', true),
            const SizedBox(height: Spacing.xs),
            _buildFeatureRow('Unlimited people', true),
            const SizedBox(height: Spacing.xs),
            _buildFeatureRow('Support indie dev ❤️', true),
            const SizedBox(height: Spacing.lg),
            SizedBox(
              width: double.infinity,
              child: Container(
                decoration: NeoStyles.buttonDecoration(
                  backgroundColor: Colors.white,
                  isDark: isDark,
                  borderRadius: 12,
                  shadowOffset: 3,
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: isLoading ? null : () => _handlePurchase(context, ref),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Center(
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                                ),
                              )
                            : Text(
                                purchaseState.priceString.isNotEmpty 
                                    ? 'Unlock for ${purchaseState.priceString}'
                                    : 'Unlock Premium',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            Center(
              child: TextButton(
                onPressed: isLoading ? null : () => _handleRestore(context, ref),
                child: const Text(
                  'Restore Purchase',
                  style: TextStyle(
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text, bool included) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle,
          size: 18,
          color: Color(0xFF1A1A1A),
        ),
        const SizedBox(width: Spacing.sm),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String _getDarkModeLabel(DarkModeOption mode) {
    switch (mode) {
      case DarkModeOption.system:
        return 'System default';
      case DarkModeOption.light:
        return 'Light';
      case DarkModeOption.dark:
        return 'Dark';
    }
  }

  void _showDarkModeDialog(BuildContext context, WidgetRef ref, SettingsModel settings) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dark Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: DarkModeOption.values.map((option) {
            return RadioListTile<DarkModeOption>(
              title: Text(_getDarkModeLabel(option)),
              value: option,
              groupValue: settings.darkMode,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setDarkMode(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showSessionSizeDialog(BuildContext context, WidgetRef ref, SettingsModel settings) {
    final options = [5, 10, 15, 20, 25, 30];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cards per Session'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((count) {
            return RadioListTile<int>(
              title: Text('$count cards'),
              value: count,
              groupValue: settings.sessionCardCount,
              onChanged: (value) {
                if (value != null) {
                  ref.read(settingsProvider.notifier).setSessionCardCount(value);
                  Navigator.pop(context);
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showTimePickerDialog(BuildContext context, WidgetRef ref, SettingsModel settings) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: settings.notificationHour,
        minute: settings.notificationMinute,
      ),
    );

    if (time != null) {
      await ref.read(settingsProvider.notifier).setNotifications(
            true,
            hour: time.hour,
            minute: time.minute,
          );
    }
  }

  void _showExportDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text(
          'This will create a backup file with all your groups, people, photos, and learning progress.\n\nThe file will be saved to your app documents folder.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performExport(context);
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  Future<void> _performExport(BuildContext context) async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Exporting...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final filePath = await BackupService.exportBackup();
      
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup saved to:\n$filePath'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text(
          'This will REPLACE all your current data with the backup.\n\n'
          'Your current groups, people, and progress will be lost!\n\n'
          'Select a .json backup file to restore.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _performImport(context, ref);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Select File'),
          ),
        ],
      ),
    );
  }

  Future<void> _performImport(BuildContext context, WidgetRef ref) async {
    try {
      // Pick a JSON file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return; // User cancelled
      }

      final filePath = result.files.first.path;
      if (filePath == null) {
        throw Exception('Could not access file');
      }

      // Show loading indicator
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Importing...'),
                  ],
                ),
              ),
            ),
          ),
        );
      }

      await BackupService.importBackup(filePath);

      // Refresh all providers
      ref.invalidate(groupsProvider);
      ref.invalidate(userStatsProvider);
      ref.invalidate(settingsProvider);

      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data restored successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        // Close loading dialog if it's showing
        Navigator.of(context).popUntil((route) => route.isFirst || route.settings.name == '/settings');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showResetProgressDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Progress?'),
        content: const Text(
          'This will clear all learning progress and streaks, but keep your groups and people. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.resetProgress();
              ref.invalidate(userStatsProvider);
              ref.invalidate(groupsProvider);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Progress reset')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAllDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data?'),
        content: const Text(
          'This will permanently delete all groups, people, photos, and progress. This cannot be undone!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await DatabaseHelper.instance.resetDatabase();
              ref.invalidate(groupsProvider);
              ref.invalidate(userStatsProvider);
              ref.invalidate(settingsProvider);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data deleted')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePurchase(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(purchaseStateProvider.notifier).purchasePremium();
    
    if (!context.mounted) return;
    
    final purchaseState = ref.read(purchaseStateProvider);
    
    if (success) {
      // Also update local settings for offline access
      ref.read(settingsProvider.notifier).setPremium(true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(purchaseState.successMessage ?? 'Premium unlocked!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (purchaseState.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(purchaseState.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleRestore(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(purchaseStateProvider.notifier).restorePurchases();
    
    if (!context.mounted) return;
    
    final purchaseState = ref.read(purchaseStateProvider);
    
    if (success) {
      // Also update local settings for offline access
      ref.read(settingsProvider.notifier).setPremium(true);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(purchaseState.successMessage ?? 'Purchases restored!'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (purchaseState.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(purchaseState.errorMessage!),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _openUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
