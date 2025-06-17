import 'package:flutter/material.dart';
import 'package:planandbill/theme/app_theme.dart';
import 'package:planandbill/screens/appointments/create_appointment_screen.dart';
import 'package:planandbill/services/auth_service.dart';
import 'package:planandbill/services/appointment_service.dart';
import 'package:planandbill/services/invoice_service.dart';
import 'package:provider/provider.dart';
import 'package:planandbill/models/appointment.dart';
import 'package:planandbill/screens/appointments/appointment_details_screen.dart';
import 'package:planandbill/screens/billing/create_invoice_screen.dart';
import 'package:planandbill/models/invoice.dart';
import 'package:intl/intl.dart';

class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key});

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  late final ScrollController _scrollController = ScrollController();
  DateTime _selectedDate = DateTime.now();
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          final dayIndex = DateTime.now().day - 1;
          _scrollController.jumpTo((dayIndex * 72).toDouble());
        }
      });

      final authService = Provider.of<AuthService>(context, listen: false);
      final appointmentService = Provider.of<AppointmentService>(context, listen: false);
      if (authService.user != null) {
        appointmentService.fetchAppointments(authService.user!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _buildCalendarHeader(),
          Expanded(
            child: _buildAppointmentsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CreateAppointmentScreen(
                selectedDate: _selectedDate,
              ),
            ),
          ).then((result) {
            if (result == true) {
              // Refresh appointments
              final authService = Provider.of<AuthService>(context, listen: false);
              final appointmentService = Provider.of<AppointmentService>(context, listen: false);
              if (authService.user != null) {
                appointmentService.fetchAppointments(authService.user!.id);
              }
            }
          });
        },
        backgroundColor: AppColors.forestGreen,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getMonthYearText(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _selectedDate = DateTime(
                          _selectedDate.year,
                          _selectedDate.month - 1,
                          _selectedDate.day,
                        );
                      });
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        _selectedDate = DateTime(
                          _selectedDate.year,
                          _selectedDate.month + 1,
                          _selectedDate.day,
                        );
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildWeekDaySelector(),
        ],
      ),
    );
  }

  Widget _buildWeekDaySelector() {
    final today = DateTime.now();
    final monthDays = _getMonthDays();

    return SizedBox(
      height: 80,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: monthDays.length,
        itemBuilder: (context, index) {
          final day = monthDays[index];
          final isToday = _isSameDay(day, today);
          final isSelected = _isSameDay(day, _selectedDate);

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = day;
              });
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.forestGreen : null,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _getWeekdayShort(day.weekday),
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isToday && !isSelected ? AppColors.lightBeige : null,
                    ),
                    child: Center(
                      child: Text(
                        day.day.toString(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : isToday
                              ? AppColors.forestGreen
                              : null,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppointmentsList() {
    return Consumer<AppointmentService>(
      builder: (context, appointmentService, child) {
        final appointments = appointmentService.getAppointmentsForDate(_selectedDate);

        if (appointmentService.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (appointments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'No appointments for this day',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), // évite le scroll horizontal
            itemCount: appointments.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final appointment = appointments[index];
              return _buildAppointmentCard(context, appointment);
            },
          ),
        );
      },
    );
  }

  Widget _buildAppointmentCard(BuildContext context, Appointment appointment) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Première ligne : heure + type
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  appointment.time,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getAppointmentColor(appointment.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    appointment.type,
                    style: TextStyle(
                      fontSize: 12,
                      color: _getAppointmentColor(appointment.type),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const CircleAvatar(radius: 16, child: Icon(Icons.person, size: 16)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.clientName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (appointment.location.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              appointment.location,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => CreateAppointmentScreen(appointment: appointment),
                    ));
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, size: 18),
                  onPressed: () => _showAppointmentOptions(context, appointment),
                ),
              ],
            ),
            if (appointment.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.lightBeige.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  appointment.notes,
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showAppointmentOptions(BuildContext context, Appointment appointment) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Appointment'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CreateAppointmentScreen(
                      appointment: appointment,
                    ),
                  ),
                ).then((result) {
                  if (result == true) {
                    final authService = Provider.of<AuthService>(context, listen: false);
                    final appointmentService = Provider.of<AppointmentService>(context, listen: false);
                    if (authService.user != null) {
                      appointmentService.fetchAppointments(authService.user!.id);
                    }
                  }
                });
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Duplicate Appointment'),
              onTap: () {
                Navigator.pop(context);
                // Create a copy with new ID and date
                final duplicatedAppointment = appointment.copyWith(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  date: appointment.date.add(const Duration(days: 7)),
                );
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CreateAppointmentScreen(
                      appointment: duplicatedAppointment,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt),
              title: const Text('Generate Invoice'),
              onTap: () async {
                Navigator.pop(context);

                final invoiceService = Provider.of<InvoiceService>(context, listen: false);
                final authService = Provider.of<AuthService>(context, listen: false);

                final generatedNumber = await invoiceService.generateCustomInvoiceNumber(
                  clientName: appointment.clientName,
                  userId: authService.user!.id,
                );

                // Create an invoice item from the appointment
                final invoiceItem = InvoiceItem(
                  description: '${appointment.type} - ${_formatDate(appointment.date)} ${appointment.time}',
                  quantity: 1,
                  unitPrice: appointment.fee ?? 0.0,
                );

                // Create a draft invoice
                final invoice = Invoice(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  userId: appointment.userId,
                  clientId: appointment.clientId,
                  clientName: appointment.clientName,
                  number: generatedNumber,
                  date: DateTime.now(),
                  dueDate: DateTime.now().add(const Duration(days: 30)),
                  items: [invoiceItem],
                  subtotal: invoiceItem.total,
                  taxRate: 20.0, // Default tax rate
                  taxAmount: invoiceItem.total * 0.2,
                  total: invoiceItem.total * 1.2,
                  status: 'draft',
                  type: 'invoice',
                  notes: 'Generated from appointment on ${_formatDate(appointment.date)} at ${appointment.time}',
                  createdAt: DateTime.now(),
                );

                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => CreateInvoiceScreen(
                      invoice: invoice,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Appointment', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteAppointment(context, appointment);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAppointment(BuildContext context, Appointment appointment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: Text('Are you sure you want to delete the appointment with ${appointment.clientName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final appointmentService = Provider.of<AppointmentService>(context, listen: false);
              final success = await appointmentService.deleteAppointment(appointment.id);

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Appointment deleted')),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(appointmentService.error ?? 'Failed to delete appointment'),
                    backgroundColor: Colors.red,
                  ),
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

  String _getMonthYearText() {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[_selectedDate.month - 1]} ${_selectedDate.year}';
  }

  List<DateTime> _getMonthDays() {
    final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final lastDay = DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
    final totalDays = lastDay.day;

    return List.generate(
      totalDays,
          (index) => DateTime(_selectedDate.year, _selectedDate.month, index + 1),
    );
  }


  String _getWeekdayShort(int weekday) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[weekday - 1];
  }

  Color _getAppointmentColor(String type) {
    switch (type.toLowerCase()) {
      case 'individual therapy':
        return AppColors.forestGreen;
      case 'group session':
        return AppColors.goldenYellow;
      case 'art workshop':
        return AppColors.peach;
      case 'consultation':
        return AppColors.darkNavy;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
