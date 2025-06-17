import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:planandbill/services/auth_service.dart';
import 'package:planandbill/screens/appointments/appointments_screen.dart';
import 'package:planandbill/screens/clients/clients_screen.dart';
import 'package:planandbill/screens/billing/billing_screen.dart';
import 'package:planandbill/screens/settings/settings_screen.dart';
import 'package:planandbill/theme/app_theme.dart';
import 'package:planandbill/widgets/upcoming_appointments_widget.dart';
import 'package:planandbill/widgets/recent_invoices_widget.dart';
import 'package:planandbill/screens/appointments/create_appointment_screen.dart';
import 'package:planandbill/screens/clients/create_client_screen.dart';
import 'package:planandbill/screens/billing/create_invoice_screen.dart';
import 'package:planandbill/services/appointment_service.dart';
import 'package:planandbill/screens/appointments/appointment_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardHomeScreen(),
    const AppointmentsScreen(),
    const ClientsScreen(),
    const BillingScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;

    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Dashboard' : _getTitle()),
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                _showNotifications(context);
              },
            ),
          CircleAvatar(
            backgroundImage: user?.photoUrl != null
                ? NetworkImage(user!.photoUrl!)
                : null,
            child: user?.photoUrl == null
                ? Text(user?.displayName?.substring(0, 1) ?? 'U')
                : null,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.forestGreen,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Appointments',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Clients',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_outlined),
            activeIcon: Icon(Icons.receipt),
            label: 'Billing',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (_selectedIndex) {
      case 1:
        return 'Appointments';
      case 2:
        return 'Clients';
      case 3:
        return 'Billing';
      case 4:
        return 'Settings';
      default:
        return 'Dashboard';
    }
  }

  void _showNotifications(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Consumer<AppointmentService>(
          builder: (context, appointmentService, child) {
            final upcomingAppointments = appointmentService.getUpcomingAppointments(limit: 3);

            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (upcomingAppointments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: Text('No upcoming appointments'),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          ...upcomingAppointments.map((appointment) => ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.lightBeige,
                              child: Icon(
                                Icons.event,
                                color: AppColors.forestGreen,
                              ),
                            ),
                            title: Text(
                              DateFormat('dd/MM/yyyy').format(appointment.date),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${appointment.time} - ${appointment.type}'),
                                Text('With ${appointment.clientName}'),
                              ],
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      AppointmentDetailsScreen(appointment: appointment),
                                ),
                              );
                            },
                          )),
                          const Divider(),
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.amber[100],
                              child: Icon(
                                Icons.receipt,
                                color: Colors.amber[800],
                              ),
                            ),
                            title: const Text('Invoice Reminder'),
                            subtitle: const Text('You have 2 unpaid invoices'),
                            onTap: () {
                              Navigator.pop(context);
                              _navigateToTab(3);
                            },
                          ),
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue[100],
                              child: Icon(
                                Icons.info,
                                color: Colors.blue[800],
                              ),
                            ),
                            title: const Text('System Update'),
                            subtitle: const Text('New features available! Check out the PDF export.'),
                            onTap: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    );
  }

  void _navigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class DashboardHomeScreen extends StatelessWidget {
  const DashboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome, ${user?.displayName ?? 'User'}',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Today is ${_formatDate2(DateTime.now())}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Quick actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  'New Appointment',
                  Icons.add_circle_outline,
                  AppColors.forestGreen,
                      () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CreateAppointmentScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  'New Client',
                  Icons.person_add_outlined,
                  AppColors.goldenYellow,
                      () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CreateClientScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  'New Invoice',
                  Icons.receipt_long_outlined,
                  AppColors.peach,
                      () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CreateInvoiceScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Upcoming appointments
          Text(
            'Upcoming Appointments',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          const UpcomingAppointmentsWidget(),

          const SizedBox(height: 24),

          // Recent invoices
          Text(
            'Recent Invoices',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          const RecentInvoicesWidget(),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: color,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate2(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
