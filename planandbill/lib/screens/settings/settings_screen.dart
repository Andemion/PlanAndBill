import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:planandbill/services/auth_service.dart';
import 'package:planandbill/services/notification_service.dart';
import 'package:planandbill/services/appointment_service.dart';
import 'package:planandbill/screens/auth/login_screen.dart';
import 'package:planandbill/screens/settings/business_info_screen.dart';
import 'package:planandbill/theme/app_theme.dart';


class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;
  bool _emailReportsEnabled = false;
  bool _dailyReminderEnabled = false;
  TimeOfDay _dailyReminderTime = const TimeOfDay(hour: 8, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;
    final appointmentService = Provider.of<AppointmentService>(context, listen: false);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            _buildProfileSection(user),
            const SizedBox(height: 24),

            // App Settings
            _buildSectionTitle('App Settings'),
            _buildSettingsCard([
              _buildSwitchTile(
                'Push Notifications',
                'Receive appointment reminders 1 hour before',
                Icons.notifications_outlined,
                _notificationsEnabled,
                    (value) async {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                  // Enregistre le choix de l'utilisateur
                  await NotificationService.setPushNotifications(value);
                  if (value) {
                    await appointmentService.fetchAppointments(user!.id);
                    final appointments = appointmentService.appointments;
                    for (final appointment in appointments) {
                      // Planifie seulement ceux dans le futur
                      if (appointment.date.isAfter(DateTime.now())) {
                        await NotificationService.scheduleAppointmentNotification(appointment);
                      }
                    }
                  }
                },
              ),
              _buildSwitchTile(
                'Daily Notification',
                'Receive the list of tomorrow\'s appointments',
                Icons.today_outlined,
                _dailyReminderEnabled,
                    (value) async {
                  setState(() {
                    _dailyReminderEnabled = value;
                  });
                  // Enregistre le choix de l'utilisateur
                  await NotificationService.setDailyReminder(value);
                },
              ),
              if (_dailyReminderEnabled)
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('Heure de notification'),
                  subtitle: Text(
                    _dailyReminderTime.format(context),
                  ),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _dailyReminderTime,
                    );
                    if (picked != null) {
                      setState(() {
                        _dailyReminderTime = picked;
                      });
                      // Enregistre le choix de l'utilisateur
                      await NotificationService.setDailyReminderTime(_dailyReminderTime);
                    }
                  },
                ),
              _buildSwitchTile(
                'Email Reports',
                'Monthly summaries',
                Icons.email_outlined,
                _emailReportsEnabled,
                    (value) {
                  setState(() {
                    _emailReportsEnabled = value;
                  });
                },
              ),
            ]),

            const SizedBox(height: 24),

            // Business Settings
            _buildSectionTitle('Business Settings'),
            _buildSettingsCard([
              _buildTile(
                'Business Information',
                'Update your professional details',
                Icons.business_outlined,
                    () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const BusinessInfoScreen(),
                    ),
                  );
                },
              ),
              // _buildTile(
              //   'Invoice Templates',
              //   'Customize your invoice design',
              //   Icons.receipt_long_outlined,
              //       () {
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       const SnackBar(content: Text('Invoice templates feature coming soon!')),
              //     );
              //   },
              // ),
              // _buildTile(
              //   'Payment Methods',
              //   'Manage accepted payment options',
              //   Icons.payment_outlined,
              //       () {
              //     ScaffoldMessenger.of(context).showSnackBar(
              //       const SnackBar(content: Text('Payment methods feature coming soon!')),
              //     );
              //   },
              // ),
            ]),

            const SizedBox(height: 24),

            // Data & Privacy
            _buildSectionTitle('Data & Privacy'),
            _buildSettingsCard([
              _buildTile(
                'Export Data',
                'Download all your data (GDPR)',
                Icons.download_outlined,
                    () {
                  _showExportDataDialog();
                },
              ),
              _buildTile(
                'Privacy Policy',
                'View our privacy policy',
                Icons.privacy_tip_outlined,
                    () {
                  _showPrivacyPolicy();
                },
              ),
              _buildTile(
                'Delete Account',
                'Permanently delete your account',
                Icons.delete_forever_outlined,
                    () {
                  _showDeleteAccountDialog();
                },
                isDestructive: true,
              ),
            ]),

            const SizedBox(height: 24),

            // Support
            _buildSectionTitle('Support'),
            _buildSettingsCard([
              // _buildTile(
              //   'Help Center',
              //   'Get help and support',
              //   Icons.help_outline,
              //       () {
              //     _showHelpCenter();
              //   },
              // ),
              _buildTile(
                'Contact Us',
                'Send feedback or report issues',
                Icons.contact_support_outlined,
                    () {
                  _showContactForm();
                },
              ),
              _buildTile(
                'About',
                'App version and information',
                Icons.info_outline,
                    () {
                  _showAboutDialog();
                },
              ),
            ]),

            const SizedBox(height: 32),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _showSignOutDialog();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: user?.photoUrl != null
                  ? NetworkImage(user!.photoUrl!)
                  : null,
              child: user?.photoUrl == null
                  ? Text(
                user?.displayName?.substring(0, 1) ?? 'U',
                style: const TextStyle(fontSize: 24),
              )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.displayName ?? 'User',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile editing feature coming soon!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Card(
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildTile(
      String title,
      String subtitle,
      IconData icon,
      VoidCallback onTap, {
        bool isDestructive = false,
      }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : null,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile(
      String title,
      String subtitle,
      IconData icon,
      bool value,
      ValueChanged<bool> onChanged,
      ) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.forestGreen,
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Provider.of<AuthService>(context, listen: false).signOut();
              if (!mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showExportDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text(
          'This will export all your data including appointments, clients, and invoices. The export will be sent to your email address.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final authService = Provider.of<AuthService>(context, listen: false);
              final userData = await authService.exportUserData();

              if (userData.isNotEmpty && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data export started. You will receive an email shortly.'),
                  ),
                );
              }
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // fermer le dialog d'abord

              // ✅ utiliser le contexte du widget parent (this.context)
              final confirmed = await _showFinalDeleteConfirmation();
              if (!confirmed || !mounted) return;

              final authService = Provider.of<AuthService>(this.context, listen: false);
              final success = await authService.deleteAccount();

              if (success && mounted) {
                Navigator.of(this.context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showFinalDeleteConfirmation() async {
    final TextEditingController _confirmController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Final Confirmation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Type "DELETE" to confirm account deletion:'),
              const SizedBox(height: 12),
              TextField(
                controller: _confirmController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Type DELETE',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final text = _confirmController.text.trim();
                if (text == 'DELETE') {
                  Navigator.pop(context, true);
                } else {
                  Navigator.pop(context, false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Confirm Delete'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'PlanAndBill',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.calendar_today,
        size: 48,
        color: AppColors.forestGreen,
      ),
      children: [
        const Text('Art Therapy Management App'),
        const SizedBox(height: 16),
        const Text('Designed for art therapists to manage appointments and billing.'),
      ],
    );
  }

  void _showHelpCenter() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help Center'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Getting Started:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('• Create your first client'),
            Text('• Schedule appointments'),
            Text('• Generate invoices'),
            SizedBox(height: 16),
            Text('Need more help?', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Contact us through the Contact Us option in settings.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showContactForm() {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Us'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Send us your feedback or report an issue:'),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                hintText: 'Your message...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message sent! We\'ll get back to you soon.')),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Data Collection:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('We collect only the data necessary to provide our services.'),
              SizedBox(height: 16),
              Text('Data Usage:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Your data is used solely for appointment management and billing.'),
              SizedBox(height: 16),
              Text('Data Security:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('All data is encrypted and stored securely.'),
              SizedBox(height: 16),
              Text('Your Rights:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('You can export or delete your data at any time.'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _loadSettings() async {
    final push = await NotificationService.getPushNotifications();
    final daily = await NotificationService.getDailyReminder();
    final hour = await NotificationService.getDailyReminderTime();

    setState(() {
      _notificationsEnabled = push;
      _dailyReminderEnabled = daily;
      _dailyReminderTime = hour;
    });
  }
}
