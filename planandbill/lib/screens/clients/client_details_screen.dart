import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:planandbill/models/client.dart';
import 'package:planandbill/models/appointment.dart';
import 'package:planandbill/services/appointment_service.dart';
import 'package:planandbill/services/client_service.dart';
import 'package:planandbill/screens/clients/create_client_screen.dart';
import 'package:planandbill/screens/appointments/create_appointment_screen.dart';
import 'package:planandbill/theme/app_theme.dart';
import 'package:planandbill/screens/clients/client_appointments_screen.dart';

class ClientDetailsScreen extends StatefulWidget {
  final Client client;

  const ClientDetailsScreen({
    super.key,
    required this.client,
  });

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.client.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CreateClientScreen(client: widget.client),
                ),
              );
              if (result == true) {
                // Refresh client data
                setState(() {});
              }
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Client', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteConfirmation();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildClientInfoCard(),
            const SizedBox(height: 16),
            _buildContactInfoCard(),
            const SizedBox(height: 16),
            if (widget.client.emergencyContact != null) ...[
              _buildEmergencyContactCard(),
              const SizedBox(height: 16),
            ],
            _buildAppointmentsSection(),
          ],
        ),
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

  Widget _buildClientInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.lightBeige,
                  child: Text(
                    widget.client.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.forestGreen,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.client.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(widget.client.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.client.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStatusColor(widget.client.status),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (widget.client.dateOfBirth != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.cake, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Born: ${_formatDate(widget.client.dateOfBirth!)}',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ],
            if (widget.client.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Notes:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(widget.client.notes),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildContactRow(Icons.email, widget.client.email),
            const SizedBox(height: 8),
            _buildContactRow(Icons.phone, widget.client.phone),
            if (widget.client.address != null) ...[
              const SizedBox(height: 8),
              _buildContactRow(Icons.location_on, widget.client.address!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Emergency Contact',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildContactRow(Icons.person, widget.client.emergencyContact!),
            if (widget.client.emergencyPhone != null) ...[
              const SizedBox(height: 8),
              _buildContactRow(Icons.phone, widget.client.emergencyPhone!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }

  Widget _buildAppointmentsSection() {
    return Consumer<AppointmentService>(
      builder: (context, appointmentService, child) {
        final clientAppointments = appointmentService.appointments
            .where((appointment) => appointment.clientId == widget.client.id)
            .toList();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Appointments',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${clientAppointments.length} total',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (clientAppointments.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No appointments yet',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...clientAppointments.take(5).map((appointment) =>
                      _buildAppointmentTile(appointment)
                  ),
                if (clientAppointments.length > 5)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ClientAppointmentsScreen(client: widget.client),
                        ),
                      );
                    },
                    child: Text('View all ${clientAppointments.length} appointments'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentTile(Appointment appointment) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 4,
        height: 40,
        decoration: BoxDecoration(
          color: _getAppointmentColor(appointment.type),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      title: Text(appointment.type),
      subtitle: Text('${_formatDate(appointment.date)} at ${appointment.time}'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: _getStatusColor(appointment.status).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          appointment.status.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            color: _getStatusColor(appointment.status),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'scheduled':
      case 'paid':
        return AppColors.forestGreen;
      case 'inactive':
      case 'cancelled':
        return Colors.grey;
      case 'new':
      case 'pending':
        return AppColors.goldenYellow;
      case 'completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
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
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Client'),
        content: Text('Are you sure you want to delete ${widget.client.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final clientService = Provider.of<ClientService>(context, listen: false);
              final success = await clientService.deleteClient(widget.client.id);

              if (success && mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Client deleted successfully')),
                );
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(clientService.error ?? 'Failed to delete client'),
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
}
