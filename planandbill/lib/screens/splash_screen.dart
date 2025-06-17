import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:planandbill/services/auth_service.dart';
import 'package:planandbill/screens/auth/login_screen.dart';
import 'package:planandbill/screens/dashboard/dashboard_screen.dart';
import 'package:planandbill/theme/app_theme.dart';
import 'package:planandbill/services/client_service.dart';
import 'package:planandbill/services/appointment_service.dart';
import 'package:planandbill/services/invoice_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final clientService = Provider.of<ClientService>(context, listen: false);
    final appointmentService = Provider.of<AppointmentService>(context, listen: false);
    final invoiceService = Provider.of<InvoiceService>(context, listen: false);

    await authService.checkAuthStatus();
    
    if (!mounted) return;

    if (authService.isAuthenticated && authService.user != null) {
      final userId = authService.user!.id;

      // ✅ chargement des données Firestore
      await clientService.fetchClients(userId);
      await appointmentService.fetchAppointments(userId);
      await invoiceService.fetchInvoicesForUser(userId);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.forestGreen,
              AppColors.darkNavy,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'PlanAndBill',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: AppColors.lightBeige,
                  fontSize: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Art Therapy Management',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.lightBeige,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.lightBeige),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
