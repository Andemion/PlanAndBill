import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:planandbill/models/appointment.dart';
import 'package:planandbill/models/client.dart';
import 'package:planandbill/services/appointment_service.dart';
import 'package:planandbill/services/client_service.dart';
import 'package:planandbill/services/auth_service.dart';
import 'package:planandbill/theme/app_theme.dart';

class CreateAppointmentScreen extends StatefulWidget {
  final DateTime? selectedDate;
  final Appointment? appointment; // For editing

  const CreateAppointmentScreen({
    super.key,
    this.selectedDate,
    this.appointment,
  });

  @override
  State<CreateAppointmentScreen> createState() => _CreateAppointmentScreenState();
}

class _CreateAppointmentScreenState extends State<CreateAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final _locationController = TextEditingController();
  final _feeController = TextEditingController();

  Client? _selectedClient;
  String _selectedType = 'Individual Therapy';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _duration = 60;
  bool _isLoading = false;
  String _selectedCurrency = '€';

  final List<String> _appointmentTypes = [
    'Individual Therapy',
    'Group Session',
    'Art Workshop',
    'Consultation',
    'Assessment',
  ];

  final List<int> _durations = [30, 45, 60, 90, 120];
  String _recurrence = 'None';
  int _recurrenceCount = 4;
  List<Appointment> appointmentsToCreate = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final clientService = Provider.of<ClientService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      if (authService.user != null) {
        await clientService.fetchClients(authService.user!.id);
      }


      if (widget.selectedDate != null) {
        _selectedDate = widget.selectedDate!;
      }

      if (widget.appointment != null) {
        _loadAppointmentData(clientService);
      }

      setState(() {});
    });
  }

  void _loadAppointmentData(ClientService clientService) {
    final appointment = widget.appointment!;
    _selectedClient = clientService.getClientById(appointment.clientId);
    _selectedType = appointment.type;
    _selectedDate = appointment.date;
    _selectedTime = TimeOfDay(
      hour: int.parse(appointment.time.split(':')[0]),
      minute: int.parse(appointment.time.split(':')[1].split(' ')[0]),
    );
    _duration = appointment.duration;
    _notesController.text = appointment.notes;
    _locationController.text = appointment.location;
    _feeController.text = appointment.fee?.toString() ?? '';
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appointment == null ? 'New Appointment' : 'Edit Appointment'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveAppointment,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildClientSelection(),
              const SizedBox(height: 24),
              _buildAppointmentTypeSelection(),
              const SizedBox(height: 24),
              _buildRecurrenceSelection(),
              const SizedBox(height: 24),
              _buildRecurrenceCountField(),
              const SizedBox(height: 24),
              _buildDateTimeSelection(),
              const SizedBox(height: 24),
              _buildDurationSelection(),
              const SizedBox(height: 24),
              _buildLocationField(),
              const SizedBox(height: 24),
              _buildFeeField(),
              const SizedBox(height: 24),
              _buildNotesField(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientSelection() {
    return Consumer<ClientService>(
      builder: (context, clientService, child) {
        if (clientService.isLoading) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Client',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<Client>(
                  value: clientService.clients.contains(_selectedClient) ? _selectedClient : null,
                  decoration: const InputDecoration(
                    hintText: 'Select a client',
                    border: OutlineInputBorder(),
                  ),
                  items: clientService.clients.map((client) {
                    return DropdownMenuItem(
                      value: client,
                      child: Text(client.name),
                    );
                  }).toList(),
                  onChanged: (client) {
                    setState(() {
                      _selectedClient = client;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a client';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentTypeSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Appointment Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: _appointmentTypes.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (type) {
                setState(() {
                  _selectedType = type!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date & Time',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today),
                          const SizedBox(width: 8),
                          Text(_formatDate(_selectedDate)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _selectTime,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time),
                          const SizedBox(width: 8),
                          Text(_selectedTime.format(context)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurrenceSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recurrence',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _recurrence,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: ['None', 'Weekly'].map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _recurrence = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecurrenceCountField() {
    if (_recurrence == 'None') return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Number of occurrences',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _recurrenceCount,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: List.generate(10, (i) => i + 1).map((count) {
                return DropdownMenuItem(
                  value: count,
                  child: Text('$count times'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _recurrenceCount = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Duration',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: _duration,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                suffixText: 'minutes',
              ),
              items: _durations.map((duration) {
                return DropdownMenuItem(
                  value: duration,
                  child: Text('$duration minutes'),
                );
              }).toList(),
              onChanged: (duration) {
                setState(() {
                  _duration = duration!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                hintText: 'e.g., Office Room 1, Studio, Online',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a location';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Fee (Optional)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                DropdownButton<String>(
                  value: _selectedCurrency,
                  items: ['€', 'CHF'].map((currency) {
                    return DropdownMenuItem(
                      value: currency,
                      child: Text(currency),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCurrency = value;
                      });
                    }
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _feeController,
                    decoration: InputDecoration(
                      hintText: '0.00',
                      border: const OutlineInputBorder(),
                      prefixText: '$_selectedCurrency ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                hintText: 'Additional notes about this appointment...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() {
        _selectedDate = date;
      });
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() {
        _selectedTime = time;
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _saveAppointment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final appointmentService = Provider.of<AppointmentService>(context, listen: false);

      final appointmentDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final appointment = Appointment(
        id: widget.appointment?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        userId: authService.user!.id,
        clientId: _selectedClient!.id,
        clientName: _selectedClient!.name,
        type: _selectedType,
        date: appointmentDate,
        time: _selectedTime.format(context),
        duration: _duration,
        location: _locationController.text,
        notes: _notesController.text,
        fee: _feeController.text.isNotEmpty ? double.tryParse(_feeController.text) : null,
        currency: _selectedCurrency,
        status: 'scheduled',
        createdAt: widget.appointment?.createdAt ?? DateTime.now(),
      );

      if (_recurrence == 'None') {
        appointmentsToCreate.add(appointment);
      } else {
        for (int i = 0; i < _recurrenceCount; i++) {
          final newDate = _recurrence == 'Weekly'
              ? appointmentDate.add(Duration(days: 7 * i))
              : appointmentDate.add(Duration(days: 30 * i));

          appointmentsToCreate.add(appointment.copyWith(
            id: DateTime.now().millisecondsSinceEpoch.toString() + '_$i',
            date: newDate,
          ));
        }
      }

      bool success = true;
      for (var appt in appointmentsToCreate) {
        bool result;
        if (widget.appointment == null) {
          result = await appointmentService.createAppointment(appt);
        } else {
          result = await appointmentService.updateAppointment(appt);
        }

        if (!result) {
          success = false; // un échec suffit pour signaler l’échec global
        }
      }


      if (success && mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.appointment == null
                ? 'Appointment created successfully'
                : 'Appointment updated successfully'),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(appointmentService.error ?? 'Failed to save appointment'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _locationController.dispose();
    _feeController.dispose();
    super.dispose();
  }
}
