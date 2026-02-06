import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/purchase_providers.dart';
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
    // Use RevenueCat premium status as primary source, fall back to local settings
    final isPremium = purchaseState.isPremium || settings.isPremium;
    
    return ListView(
      children: [
        // Premium section
        if (!isPremium) ...[
          _buildPremiumCard(context, ref, purchaseState),
          const Divider(),
        ],

        // Appearance section
        _buildSectionHeader(context, 'Appearance'),
        ListTile(
          leading: const Icon(Icons.dark_mode),
          title: const Text('Dark Mode'),
          subtitle: Text(_getDarkModeLabel(settings.darkMode)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showDarkModeDialog(context, ref, settings),
        ),

        const Divider(),

        // Learning section
        _buildSectionHeader(context, 'Learning'),
        ListTile(
          leading: const Icon(Icons.format_list_numbered),
          title: const Text('Cards per Session'),
          subtitle: Text('${settings.sessionCardCount} cards'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showSessionSizeDialog(context, ref, settings),
        ),

        const Divider(),

        // Notifications section
        _buildSectionHeader(context, 'Notifications'),
        SwitchListTile(
          secondary: const Icon(Icons.notifications_outlined),
          title: const Text('Daily Reminders'),
          subtitle: settings.notificationsEnabled
              ? Text('${settings.notificationHour.toString().padLeft(2, '0')}:${settings.notificationMinute.toString().padLeft(2, '0')}')
              : const Text('Off'),
          value: settings.notificationsEnabled,
          onChanged: (value) async {
            await ref.read(settingsProvider.notifier).setNotifications(value);
          },
        ),
        if (settings.notificationsEnabled)
          ListTile(
            leading: const SizedBox(width: 24),
            title: const Text('Reminder Time'),
            subtitle: Text(
              '${settings.notificationHour.toString().padLeft(2, '0')}:${settings.notificationMinute.toString().padLeft(2, '0')}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showTimePickerDialog(context, ref, settings),
          ),

        const Divider(),

        // Data section
        _buildSectionHeader(context, 'Data'),
        ListTile(
          leading: const Icon(Icons.upload_outlined),
          title: const Text('Export Data'),
          subtitle: const Text('Save backup to device'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showExportDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.download_outlined),
          title: const Text('Import Data'),
          subtitle: const Text('Restore from backup'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showImportDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.refresh),
          title: const Text('Reset Progress'),
          subtitle: const Text('Keep people, clear learning data'),
          onTap: () => _showResetProgressDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: const Text('Delete All Data', style: TextStyle(color: Colors.red)),
          subtitle: const Text('Remove all groups, people, and progress'),
          onTap: () => _showDeleteAllDialog(context, ref),
        ),

        const Divider(),

        // About section
        _buildSectionHeader(context, 'About'),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('Version'),
          subtitle: const Text(AppConstants.appVersion),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: const Text('Privacy Policy'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => _openUrl('https://namedrill.app/privacy'),
        ),
        ListTile(
          leading: const Icon(Icons.mail_outline),
          title: const Text('Send Feedback'),
          trailing: const Icon(Icons.open_in_new),
          onTap: () => _openUrl('mailto:support@namedrill.app?subject=NameDrill%20Feedback'),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildPremiumCard(BuildContext context, WidgetRef ref, PurchaseState purchaseState) {
    final isLoading = purchaseState.status == PurchaseStatus.loading;
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.star, color: Colors.amber, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upgrade to Premium',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Unlimited groups and people',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFeatureRow(context, 'Unlimited groups', true),
                      _buildFeatureRow(context, 'Unlimited people', true),
                      _buildFeatureRow(context, 'Support indie dev ❤️', true),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : () => _handlePurchase(context, ref),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : Text('Unlock for ${purchaseState.priceString}'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: isLoading ? null : () => _handleRestore(context, ref),
              child: const Text('Restore Purchase'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, String text, bool included) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            included ? Icons.check_circle : Icons.remove_circle_outline,
            size: 16,
            color: included ? Colors.green : Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Text(text, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
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
        content: const Text('Export functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showImportDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Data'),
        content: const Text('Import functionality coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
