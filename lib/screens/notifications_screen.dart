import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Future<void> _markAllRead(String uid) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();

    final batch = FirebaseFirestore.instance.batch();
    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'read': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: AimrAppBar(actions: []),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('NOTIFICATIONS',
                            style: AppFonts.poppins(
                              size: 10, weight: FontWeight.w700,
                              color: AppColors.gold, letterSpacing: 3,
                            )),
                        const SizedBox(height: 8),
                        Text('Your Updates',
                            style: AppFonts.playfair(
                              size: 32, weight: FontWeight.w900, color: AppColors.white,
                            )),
                      ],
                    ),
                  ),
                  // Mark all read button
                  if (uid != null)
                    GestureDetector(
                      onTap: () => _markAllRead(uid),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.done_all, color: AppColors.gold, size: 14),
                            const SizedBox(width: 6),
                            Text('Mark all read',
                                style: AppFonts.poppins(
                                  size: 10, weight: FontWeight.w700,
                                  color: AppColors.gold,
                                )),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: uid == null
                  ? _emptyState('Sign in to view notifications')
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('notifications')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.gold, strokeWidth: 2,
                            ),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];

                        if (docs.isEmpty) {
                          return _emptyState('No notifications yet.\nWe\'ll let you know when something happens!');
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: docs.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final data = docs[index].data() as Map<String, dynamic>;
                            final isRead = data['read'] as bool? ?? false;
                            return _NotificationCard(
                              docId: docs[index].id,
                              uid: uid,
                              title: data['title'] as String? ?? 'Notification',
                              message: data['message'] as String? ?? '',
                              type: data['type'] as String? ?? 'info',
                              isRead: isRead,
                              createdAt: data['createdAt'],
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            color: AppColors.gold.withValues(alpha: 0.3),
            size: 72,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppFonts.poppins(size: 14, color: AppColors.muted, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final String docId;
  final String uid;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final dynamic createdAt;

  const _NotificationCard({
    required this.docId,
    required this.uid,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  Color get _typeColor {
    switch (type) {
      case 'success': return const Color(0xFF27AE60);
      case 'warning': return const Color(0xFFF39C12);
      case 'error': return const Color(0xFFE74C3C);
      default: return AppColors.gold;
    }
  }

  IconData get _typeIcon {
    switch (type) {
      case 'success': return Icons.check_circle_outline;
      case 'warning': return Icons.warning_amber_outlined;
      case 'error': return Icons.error_outline;
      case 'image': return Icons.image_outlined;
      case 'video': return Icons.play_circle_outline;
      default: return Icons.notifications_outlined;
    }
  }

  void _markAsRead() {
    if (!isRead) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('notifications')
          .doc(docId)
          .update({'read': true, 'readAt': FieldValue.serverTimestamp()});
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _markAsRead,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isRead
              ? AppColors.surface.withValues(alpha: 0.3)
              : _typeColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRead
                ? AppColors.white.withValues(alpha: 0.06)
                : _typeColor.withValues(alpha: 0.25),
            width: 0.8,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _typeColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_typeIcon, color: _typeColor, size: 20),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppFonts.poppins(
                            size: 13,
                            weight: isRead ? FontWeight.w500 : FontWeight.w700,
                            color: isRead ? AppColors.text : AppColors.white,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _typeColor,
                          ),
                        ),
                    ],
                  ),
                  if (message.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: AppFonts.poppins(
                        size: 11, color: AppColors.muted, height: 1.5,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
