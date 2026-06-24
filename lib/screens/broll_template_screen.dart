import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BrollTemplateScreen extends StatelessWidget {
  const BrollTemplateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'SELECT TEMPLATE',
          style: AppFonts.poppins(
            size: 14,
            weight: FontWeight.w700,
            color: AppColors.gold,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Templates coming soon...',
          style: TextStyle(color: Colors.white54),
        ),
      ),
    );
  }
}
