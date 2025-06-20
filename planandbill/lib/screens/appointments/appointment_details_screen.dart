import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:planandbill/models/appointment.dart';
import 'package:planandbill/services/appointment_service.dart';
import 'package:planandbill/services/client_service.dart';
import 'package:planandbill/screens/appointments/create_appointment_screen.dart';
import 'package:planandbill/screens/billing/create_invoice_screen.dart';
import 'package:planandbill/screens/clients/client_details_screen.dart';
import 'package:planandbill/theme/app_theme.dart';
import 'package:planandbill/models/invoice.dart';
import 'package:planandbill/models/client.dart';

class AppointmentDetailsScreen extends StatelessWidget {
  final Appointment appointment;

  const AppointmentDetailsScreen({
    super.key,
    required this.appointment,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Appointment Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => CreateAppointmentScreen(
                    appointment: appointment,
                  ),
                ),
              ).then((result) {
                if (result == true) {
                  Navigator.of(context).pop(true); // Refresh previous screen
                }
              });
            },
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.copy),
                    SizedBox(width: 8),
                    Text('Duplicate Appointment'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'invoice',
                child: Row(
                  children: [
                    Icon(Icons.receipt),
                    SizedBox(width: 8),
                    Text('Create Invoice'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Appointment', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              switch (value) {
                case 'duplicate':
                  _duplicateAppointment(context);
                  break;
                case 'invoice':
                  _createInvoiceFromAppointment(context);
                  break;
                case 'delete':
                  _confirmDeleteAppointment(context);
                  break;
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
            _buildAppointmentCard(context),
            const SizedBox(height: 16),
            _buildClientCard(context),
            const SizedBox(height: 16),
            _buildDetailsCard(context),
            const SizedBox(height: 16),
            if (appointment.notes.isNotEmpty) ...[
              _buildNotesCard(),
              const SizedBox(height: 16),
            ],
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  appointment.type,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(appointment.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
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
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.calendar_today, color: AppColors.forestGreen),
                const SizedBox(width: 8),
                Text(
                  _formatDate(appointment.date),
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.access_time, color: AppColors.forestGreen),
                const SizedBox(width: 8),
                Text(
                  '${appointment.time} (${appointment.duration} minutes)',
                  style: const TextStyle(
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientCard(BuildContext context) {
    return Consumer<ClientService>(
      builder: (context, clientService, child) {
        final client = clientService.getClientById(appointment.clientId);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Client',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.lightBeige,
                    child: Text(
                      appointment.clientName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.forestGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    appointment.clientName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: client != null ? Text(client.email) : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () {
                      if (client != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => ClientDetailsScreen(client: client),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Location', appointment.location, Icons.location_on),
            if (appointment.fee != null) ...[
              const SizedBox(height: 8),
              _buildDetailRow('Fee', '€${appointment.fee!.toStringAsFixed(2)}', Icons.euro),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(value),
      ],
    );
  }

  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(appointment.notes),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        if (appointment.status == 'scheduled') ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _markAsCompleted(context),
              icon: const Icon(Icons.check_circle),
              label: const Text('Mark as Completed'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.forestGreen,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _createInvoiceFromAppointment(context),
            icon: const Icon(Icons.receipt),
            label: const Text('Create Invoice'),
          ),
        ),
      ],
    );
  }

  void _duplicateAppointment(BuildContext context) {
    final duplicatedAppointment = appointment.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now().add(const Duration(days: 7)),
      status: 'scheduled',
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateAppointmentScreen(
          appointment: duplicatedAppointment,
        ),
      ),
    );
  }

  void _createInvoiceFromAppointment(BuildContext context) {
    final client = Provider.of<ClientService>(context, listen: false)
        .getClientById(appointment.clientId);

    if (client == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client introuvable')),
      );
      return;
    }

    final invoiceItem = InvoiceItem(
      description: '${appointment.type} - ${_formatDate(appointment.date)} ${appointment.time}',
      quantity: 1,
      unitPrice: appointment.fee ?? 0.0,
    );

    final invoice = Invoice(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: appointment.userId,
      clientId: client.id,
      clientName: client.name,
      number: '',
      date: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 30)),
      items: [invoiceItem],
      subtotal: invoiceItem.total,
      taxRate: 20.0,
      taxAmount: invoiceItem.total * 0.2,
      total: invoiceItem.total * 1.2,
      currency: appointment.currency,
      status: 'draft',
      type: 'invoice',
      notes: 'Generated from appointment on ${_formatDate(appointment.date)} at ${appointment.time}',
      createdAt: DateTime.now(),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateInvoiceScreen(
          invoice: invoice,
          initialClient: client, // NOUVEAU
        ),
      ),
    );
  }

  void _markAsCompleted(BuildContext context) {
    final appointmentService = Provider.of<AppointmentService>(context, listen: false);
    final updatedAppointment = appointment.copyWith(status: 'completed');

    appointmentService.updateAppointment(updatedAppointment).then((success) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment marked as completed')),
        );
        Navigator.of(context).pop(true); // Go back and refresh
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appointmentService.error ?? 'Failed to update appointment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _confirmDeleteAppointment(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Appointment'),
        content: Text('Are you sure you want to delete this appointment with ${appointment.clientName}?'),
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

              if (success && context.mounted) {
                Navigator.of(context).pop(true); // Go back and refresh
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Appointment deleted')),
                );
              } else if (context.mounted) {
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
