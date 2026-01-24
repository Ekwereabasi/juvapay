import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:juvapay/providers/notification_provider.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  late Map<String, dynamic> _preferences;

  @override
  void initState() {
    super.initState();
    // Get state for initial preferences
    final state = ref.read(notificationProvider);
    _preferences = Map.from(state.preferences);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Notification Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customize how you receive notifications',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 24),

            // Channel Settings
            _buildChannelSection(theme),

            const SizedBox(height: 32),

            // Quiet Hours
            _buildQuietHoursSection(theme),

            const SizedBox(height: 32),

            // Save button
            Center(
              child: ElevatedButton.icon(
                onPressed: () => _savePreferences(ref),
                icon: const Icon(Icons.save),
                label: const Text('Save Preferences'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelSection(ThemeData theme) {
    return Card(
      elevation: 2,
      shadowColor: theme.shadowColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Notification Channels',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildChannelSwitch(
              theme: theme,
              title: 'In-App Notifications',
              subtitle: 'Show notifications in the app',
              value: _preferences['in_app_enabled'] ?? true,
              onChanged: (value) {
                setState(() {
                  _preferences['in_app_enabled'] = value;
                });
              },
              icon: Icons.notifications,
            ),
            Divider(color: theme.dividerColor),
            _buildChannelSwitch(
              theme: theme,
              title: 'Push Notifications',
              subtitle: 'Receive push notifications on your device',
              value: _preferences['push_enabled'] ?? true,
              onChanged: (value) {
                setState(() {
                  _preferences['push_enabled'] = value;
                });
              },
              icon: Icons.notifications_active,
            ),
            Divider(color: theme.dividerColor),
            _buildChannelSwitch(
              theme: theme,
              title: 'Email Notifications',
              subtitle: 'Receive notifications via email',
              value: _preferences['email_enabled'] ?? true,
              onChanged: (value) {
                setState(() {
                  _preferences['email_enabled'] = value;
                });
              },
              icon: Icons.email,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelSwitch({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    return Row(
      children: [
        Icon(icon, size: 24, color: theme.colorScheme.primary),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: theme.colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildQuietHoursSection(ThemeData theme) {
    return Card(
      elevation: 2,
      shadowColor: theme.shadowColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quiet Hours',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set times when you don\'t want to receive non-urgent notifications',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable Quiet Hours'),
              subtitle: Text(
                'Only urgent notifications will be sent during quiet hours',
                style: TextStyle(color: theme.hintColor, fontSize: 12),
              ),
              value: _preferences['quiet_hours_enabled'] ?? true,
              activeColor: theme.colorScheme.primary,
              onChanged: (value) {
                setState(() {
                  _preferences['quiet_hours_enabled'] = value;
                });
              },
            ),
            if (_preferences['quiet_hours_enabled'] ?? true) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Start Time', style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 8),
                        _buildTimeDropdown(
                          theme: theme,
                          value: _preferences['quiet_hours_start'] ?? '22:00',
                          onChanged: (value) {
                            setState(() {
                              _preferences['quiet_hours_start'] = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('End Time', style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 8),
                        _buildTimeDropdown(
                          theme: theme,
                          value: _preferences['quiet_hours_end'] ?? '08:00',
                          onChanged: (value) {
                            setState(() {
                              _preferences['quiet_hours_end'] = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  // Dynamic background: light tint of primary color
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Note: During quiet hours, only HIGH and URGENT priority notifications will be sent.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeDropdown({
    required ThemeData theme,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    final timeOptions = _generateTimeOptions();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: Icon(Icons.arrow_drop_down, color: theme.iconTheme.color),
          dropdownColor: theme.cardColor,
          style: theme.textTheme.bodyLarge,
          items:
              timeOptions
                  .map(
                    (time) => DropdownMenuItem(value: time, child: Text(time)),
                  )
                  .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  List<String> _generateTimeOptions() {
    List<String> options = [];
    for (int hour = 0; hour < 24; hour++) {
      options.add('${hour.toString().padLeft(2, '0')}:00');
      options.add('${hour.toString().padLeft(2, '0')}:30');
    }
    return options;
  }

  Future<void> _savePreferences(WidgetRef ref) async {
    try {
      final notifier = ref.read(notificationProvider.notifier);
      await notifier.savePreferences(_preferences);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Preferences saved successfully'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save preferences: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
