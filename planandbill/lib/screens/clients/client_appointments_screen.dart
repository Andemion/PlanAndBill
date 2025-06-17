import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:planandbill/models/client.dart';
import 'package:planandbill/models/appointment.dart';
import 'package:planandbill/services/appointment_service.dart';
import 'package:planandbill/screens/appointments/appointment_details_screen.dart';
import 'package:planandbill/screens/appointments/create_appointment_screen.dart';
import 'package:planandbill/theme/app_theme.dart';

class ClientAppointmentsScreen extends StatelessWidget {
  final Client client;

  const ClientAppointmentsScreen({
    super.key,
    required this.client,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${client.name}\'s Appointments'),
      ),
      body: Consumer<AppointmentService>(
        builder: (context, appointmentService, child) {
          final clientAppointments = appointmentService.appointments
              .where((appointment) => appointment.clientId == client.id)
              .toList();

          if (clientAppointments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No appointments for this client',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: clientAppointments.length,
            itemBuilder: (context, index) {
              final appointment = clientAppointments[index];
              return _buildAppointmentCard(context, appointment);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CreateAppointmentScreen(
                selectedDate: DateTime.now(),
              ),
            ),
          );
        },
        backgroundColor: AppColors.forestGreen,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context, Appointment appointment) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => AppointmentDetailsScreen(appointment: appointment),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(appointment.date),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(appointment.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      appointment.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getStatusColor(appointment.status),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _getAppointmentColor(appointment.type),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.type,
                          style: TextStyle(
                            color: _getAppointmentColor(appointment.type),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${appointment.time} (${appointment.duration} minutes)',
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              appointment.location,
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getAppointmentColor(String type) {
    switch (type.toLowerCase()) {
      case 'individual therapy':
        return AppColors.forestGreen;
      case 'group session':
        return AppColors.goldenYellow;
      case 'art workshop':
        return AppColors.peach;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'scheduled':
        return AppColors.forestGreen;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
