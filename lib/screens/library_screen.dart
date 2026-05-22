import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:gal/gal.dart';
import 'package:http/http.dart' as http;
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/premium_header.dart';
import '../providers/user_provider.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';

class LibraryScreen extends StatefulWidget {
  final bool fromBottomNav;
  const LibraryScreen({super.key, this.fromBottomNav = false});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBottomNav = widget.fromBottomNav;
    final credits = context.watch<UserProvider>().credits ?? 0;
    void push(Widget s) => Navigator.push(context, MaterialPageRoute(builder: (_) => s));

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: isBottomNav ? null : AimrAppBar(actions: const []),
      body: Column(
        children: [
          // Bottom nav — full PremiumHeader (same as Explore)
          if (isBottomNav)
            PremiumHeader(
              onProfileTap: () => push(const ProfileScreen()),
              onSettingsTap: () => push(const NotificationsScreen()),
              creditsText: '$credits CREDITS',
            ),

          // Tab bar
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0E0E0A),
              border: Border(
                bottom: BorderSide(
                  color: AppColors.gold.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
            ),
            child: !isBottomNav
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MY LIBRARY',
                            style: AppFonts.poppins(
                              size: 10, weight: FontWeight.w700,
                              color: AppColors.gold, letterSpacing: 3,
                            )),
                        const SizedBox(height: 4),
                        Text('Your Generated Content',
                            style: AppFonts.playfair(
                              size: 28, weight: FontWeight.w900,
                              color: AppColors.white,
                            )),
                        const SizedBox(height: 16),
                        _buildTabBar(),
                      ],
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _buildTabBar(),
                  ),
          ),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ImagesTab(),
                const _VideosTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      indicatorColor: AppColors.gold,
      indicatorWeight: 2,
      labelColor: AppColors.gold,
      unselectedLabelColor: AppColors.muted,
      labelStyle: AppFonts.poppins(
        size: 11, weight: FontWeight.w700, letterSpacing: 1.5,
      ),
      unselectedLabelStyle: AppFonts.poppins(
        size: 11, weight: FontWeight.w500,
      ),
      tabs: const [
        Tab(text: 'IMAGES'),
        Tab(text: 'VIDEOS'),
      ],
    );
  }
}

// ── Images Tab ────────────────────────────────────────────────────────────────
class _ImagesTab extends StatelessWidget {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  _ImagesTab();

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;

    if (uid == null) {
      return _emptyState('Sign in to view your library', Icons.lock_outline);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .doc(uid)
          .collection('generatedImages')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2),
          );
        }

        if (snapshot.hasError) {
          return _emptyState('Error loading images', Icons.error_outline);
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return _emptyState(
            'No images yet.\nGenerate your first image!',
            Icons.image_outlined,
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return _ImageCard(data: data, docId: docs[index].id);
          },
        );
      },
    );
  }

  Widget _emptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.gold.withValues(alpha: 0.3), size: 64),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppFonts.poppins(
              size: 14,
              color: AppColors.muted,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Image Card ────────────────────────────────────────────────────────────────
class _ImageCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const _ImageCard({required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    final imageUrl = data['imageUrl'] as String? ?? '';
    final outfit = data['outfit'] as String? ?? '';
    final location = data['location'] as String? ?? '';
    final gender = data['gender'] as String? ?? '';

    return GestureDetector(
      onTap: () => _showImageDetail(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.15),
            width: 0.8,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Image
              _buildImage(imageUrl),

              // Bottom overlay
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.85),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (outfit.isNotEmpty)
                        Text(
                          outfit,
                          style: AppFonts.poppins(
                            size: 10,
                            weight: FontWeight.w600,
                            color: AppColors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (location.isNotEmpty)
                        Text(
                          location,
                          style: AppFonts.poppins(
                            size: 9,
                            color: AppColors.muted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ),

              // Gender badge
              if (gender.isNotEmpty)
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      gender.toUpperCase(),
                      style: AppFonts.poppins(
                        size: 8,
                        weight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String imageUrl) {
    // Firebase Storage URL
    if (imageUrl.startsWith('https://')) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(
                color: const Color(0xFF1A1A1A),
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2),
                ),
              ),
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFF1A1A1A),
          child: const Icon(Icons.broken_image_outlined, color: AppColors.gold, size: 40),
        ),
      );
    }
    // Legacy base64
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64Str = imageUrl.split(',')[1];
        final bytes = base64Decode(base64Str);
        return Image.memory(bytes, fit: BoxFit.cover);
      } catch (_) {}
    }
    return Container(
      color: const Color(0xFF1A1A1A),
      child: const Icon(Icons.image_outlined, color: AppColors.gold, size: 40),
    );
  }

  void _showImageDetail(BuildContext context) {
    final imageUrl = data['imageUrl'] as String? ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFF1A1A1A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            const SizedBox(height: 12),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Image
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: _buildImage(imageUrl),
                ),
              ),
            ),

            // Details
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _detailRow('Outfit', data['outfit'] ?? ''),
                  const SizedBox(height: 6),
                  _detailRow('Location', data['location'] ?? ''),
                  const SizedBox(height: 6),
                  _detailRow('Mood', data['mood'] ?? ''),
                  const SizedBox(height: 16),

                  // Download button
                  _DownloadButton(imageUrl: imageUrl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppFonts.poppins(size: 11, color: AppColors.muted)),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppFonts.poppins(size: 11, color: AppColors.white, weight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Download Button ───────────────────────────────────────────────────────────
class _DownloadButton extends StatefulWidget {
  final String imageUrl;
  const _DownloadButton({required this.imageUrl});

  @override
  State<_DownloadButton> createState() => _DownloadButtonState();
}

class _DownloadButtonState extends State<_DownloadButton> {
  bool _saving = false;

  Future<void> _download() async {
    setState(() => _saving = true);

    try {
      // Request permission
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        await Gal.requestAccess(toAlbum: true);
      }

      if (widget.imageUrl.startsWith('https://')) {
        // Firebase Storage URL — download bytes then save
        final response = await http.get(Uri.parse(widget.imageUrl));
        if (response.statusCode == 200) {
          await Gal.putImageBytes(response.bodyBytes, album: 'Twinora');
        } else {
          throw Exception('Failed to download image');
        }
      } else if (widget.imageUrl.startsWith('data:image')) {
        // Base64 — decode and save bytes
        final base64Str = widget.imageUrl.split(',')[1];
        final Uint8List bytes = base64Decode(base64Str);
        await Gal.putImageBytes(bytes, album: 'Twinora');
      } else {
        throw Exception('Unknown image format');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to gallery!',
                style: AppFonts.poppins(color: AppColors.white)),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e',
                style: AppFonts.poppins(color: AppColors.white)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _saving ? null : _download,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.gold,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: _saving
              ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(color: AppColors.black, strokeWidth: 2),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.download, color: AppColors.black, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'SAVE TO GALLERY',
                      style: AppFonts.poppins(
                        size: 12,
                        weight: FontWeight.w700,
                        color: AppColors.black,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ── Videos Tab ────────────────────────────────────────────────────────────────
class _VideosTab extends StatelessWidget {
  const _VideosTab();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.play_circle_outline,
            color: AppColors.gold.withValues(alpha: 0.3),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'No videos yet.\nGenerate your first video!',
            textAlign: TextAlign.center,
            style: AppFonts.poppins(
              size: 14,
              color: AppColors.muted,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
