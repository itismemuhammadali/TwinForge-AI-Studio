import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/subscription_screen.dart';

class InsufficientCreditsSheet extends StatelessWidget {
  final int requiredCredits;
  final int currentCredits;
  final String featureName;

  const InsufficientCreditsSheet({
    super.key,
    required this.requiredCredits,
    required this.currentCredits,
    required this.featureName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF141410),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.gold, width: 1.5),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold.withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.bolt_rounded, color: AppColors.gold, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'INSUFFICIENT CREDITS',
              style: AppFonts.playfair(
                size: 22,
                weight: FontWeight.w900,
                color: AppColors.white,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$featureName requires $requiredCredits credits. You currently have $currentCredits credits.',
              textAlign: TextAlign.center,
              style: AppFonts.poppins(
                size: 13,
                color: AppColors.muted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            // Actions
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.3),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'GET MORE CREDITS',
                    style: AppFonts.poppins(
                      size: 13,
                      weight: FontWeight.w700,
                      color: AppColors.black,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'CANCEL',
                style: AppFonts.poppins(
                  size: 12,
                  weight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
