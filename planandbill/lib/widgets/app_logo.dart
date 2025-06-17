import 'package:flutter/material.dart';
import 'package:planandbill/theme/app_theme.dart';

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({
    super.key,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.forestGreen,
            AppColors.darkNavy,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkNavy.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.calendar_today,
          color: AppColors.lightBeige,
          size: size * 0.5,
        ),
      ),
    );
  }
}
