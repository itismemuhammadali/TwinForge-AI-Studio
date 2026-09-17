import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/insufficient_credits_sheet.dart';

class CreditService {
  /// Check if current user has enough credits.
  /// If not, pops up the InsufficientCreditsSheet automatically.
  static Future<bool> ensureSufficientCredits(
    BuildContext context, {
    required int requiredCredits,
    required String featureName,
  }) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentCredits = userProvider.credits ?? 0;

    if (currentCredits < requiredCredits) {
      if (context.mounted) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => InsufficientCreditsSheet(
            requiredCredits: requiredCredits,
            currentCredits: currentCredits,
            featureName: featureName,
          ),
        );
      }
      return false;
    }
    return true;
  }

  /// Deduct credits atomically from Firestore `users/$uid` and log USD backend cost to `usage_logs`
  static Future<bool> deductCredits({
    required BuildContext context,
    required int creditsToDeduct,
    required String feature,
    required double estimatedUsdCost,
    required String provider,
    Map<String, dynamic>? metadata,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;

    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    try {
      // Atomic transaction to ensure balance is non-negative
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) {
          throw Exception('User profile not found');
        }

        final currentCredits = snapshot.data()?['credits'] as int? ?? 0;
        if (currentCredits < creditsToDeduct) {
          throw Exception('Insufficient credits');
        }

        transaction.update(userRef, {
          'credits': currentCredits - creditsToDeduct,
        });
      });

      // Log usage behind the scenes for backend margin & profit tracking (Admin only)
      try {
        await FirebaseFirestore.instance.collection('usage_logs').add({
          'uid': uid,
          'feature': feature,
          'creditsDeducted': creditsToDeduct,
          'backendCostUsd': estimatedUsdCost,
          'provider': provider,
          'timestamp': FieldValue.serverTimestamp(),
          ...?metadata?.map((k, v) => MapEntry(k, v)),
        });
      } catch (logError) {
        debugPrint('⚠️ Non-fatal: failed to write usage log: $logError');
      }

      // Refresh in-memory user provider
      if (context.mounted) {
        await context.read<UserProvider>().refreshCredits();
      }

      return true;
    } catch (e) {
      debugPrint('❌ Credit deduction error: $e');
      return false;
    }
  }
}
