import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:planandbill/services/auth_service.dart';
import 'package:planandbill/screens/dashboard/dashboard_screen.dart';
import 'package:planandbill/theme/app_theme.dart';

class GdprConsentScreen extends StatefulWidget {
  const GdprConsentScreen({super.key});

  @override
  State<GdprConsentScreen> createState() => _GdprConsentScreenState();
}

class _GdprConsentScreenState extends State<GdprConsentScreen> {
  bool _consentGiven = false;
  bool _isLoading = false;

  Future<void> _submitConsent() async {
    if (!_consentGiven) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must consent to the data processing to use the app'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.updateGdprConsent(true);
      
      if (!mounted) return;
      
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Privacy Consent'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GDPR Compliance',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 24),
              const Text(
                'Before you can use PlanAndBill, we need your consent to process your personal data in accordance with GDPR regulations.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Data We Collect:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletPoint('Your name and email from Google account'),
                      _buildBulletPoint('Client information you enter'),
                      _buildBulletPoint('Appointment details'),
                      _buildBulletPoint('Billing information for invoices'),
                      
                      const SizedBox(height: 16),
                      const Text(
                        'How We Use Your Data:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletPoint('To provide appointment management services'),
                      _buildBulletPoint('To generate billing documents'),
                      _buildBulletPoint('To send appointment reminders'),
                      _buildBulletPoint('To create summary reports'),
                      
                      const SizedBox(height: 16),
                      const Text(
                        'Your Rights:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBulletPoint('Access your data at any time'),
                      _buildBulletPoint('Export all your data'),
                      _buildBulletPoint('Request complete deletion of your data'),
                      _buildBulletPoint('Withdraw consent at any time'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              CheckboxListTile(
                value: _consentGiven,
                onChanged: (value) {
                  setState(() {
                    _consentGiven = value ?? false;
                  });
                },
                title: const Text(
                  'I consent to the processing of my personal data as described above',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.forestGreen,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitConsent,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Continue'),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Provider.of<AuthService>(context, listen: false).signOut();
                  },
                  child: const Text('Decline and Sign Out'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
