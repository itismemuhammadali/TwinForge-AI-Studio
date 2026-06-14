import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
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
  final bool isSelectionMode;
  const LibraryScreen({super.key, this.fromBottomNav = false, this.isSelectionMode = false});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _tabLabels = ['All', 'Images', 'Carousels', 'Videos'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBottomNav = widget.fromBottomNav;
    final isSelectionMode = widget.isSelectionMode;
    final credits = context.watch<UserProvider>().credits ?? 0;
    void push(Widget s) => Navigator.push(context, MaterialPageRoute(builder: (_) => s));

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      appBar: isBottomNav ? null : AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: isSelectionMode ? Text('SELECT IMAGE', style: AppFonts.poppins(size: 14, weight: FontWeight.w700, color: AppColors.gold, letterSpacing: 2)) : null,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Bottom nav — full PremiumHeader (same as Explore)
          if (isBottomNav)
            PremiumHeader(
              onProfileTap: () => push(const ProfileScreen()),
              onSettingsTap: () => push(const NotificationsScreen()),
              creditsText: '$credits CREDITS',
            ),

          SizedBox(height: isBottomNav ? 24 : 12),
          
          if (!isSelectionMode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('MY LIBRARY',
                      style: AppFonts.poppins(
                        size: 10, weight: FontWeight.w700,
                        color: AppColors.gold, letterSpacing: 3,
                      )),
                  const SizedBox(height: 4),
                  Text('Your Studio',
                      style: AppFonts.playfair(
                        size: 28, weight: FontWeight.w900,
                        color: AppColors.white,
                      )),
                ],
              ),
            ),
          
          const SizedBox(height: 20),

          // Tab bar (Stylized like GalleryScreen)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.white.withValues(alpha: 0.06), width: 0.5),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.gold.withValues(alpha: 0.4), width: 0.5),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelStyle: AppFonts.poppins(size: 10, weight: FontWeight.w700, letterSpacing: 1),
              unselectedLabelStyle: AppFonts.poppins(size: 10),
              labelColor: AppColors.gold,
              unselectedLabelColor: AppColors.muted,
              tabs: _tabLabels.map((l) => Tab(text: l)).toList(),
            ),
          ),
          
          const SizedBox(height: 20),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _AllTab(isSelectionMode: isSelectionMode),
                _ImagesTab(isSelectionMode: isSelectionMode),
                const _CarouselsTab(),
                const _VideosTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── All Tab ───────────────────────────────────────────────────────────────────
class _AllTab extends StatelessWidget {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final bool isSelectionMode;

  _AllTab({this.isSelectionMode = false});

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Sign in to view library'));

    // Combined stream from content and generatedImages
    final contentStream = _firestore.collection('users').doc(uid).collection('content').snapshots();
    final imagesStream = _firestore.collection('users').doc(uid).collection('generatedImages').snapshots();

    return StreamBuilder<List<QuerySnapshot>>(
      stream: Rx.combineLatest2(contentStream, imagesStream, (a, b) => [a, b]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.gold));
        }

        final List<DocumentSnapshot> allDocs = [];
        if (snapshot.hasData) {
          for (var snap in snapshot.data!) {
            allDocs.addAll(snap.docs);
          }
        }

        // Sort by createdAt
        allDocs.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>?)?['createdAt'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>?)?['createdAt'] as Timestamp?;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        if (allDocs.isEmpty) {
          return _emptyState('No content found', Icons.auto_awesome_outlined);
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: allDocs.length,
          itemBuilder: (context, index) {
            final data = allDocs[index].data() as Map<String, dynamic>;
            
            // Map originalImageUrl to imageUrl if needed
            if (data['originalImageUrl'] != null && data['imageUrl'] == null) {
              data['imageUrl'] = data['originalImageUrl'];
            }
            
            final type = data['type'] as String? ?? 'image';
            
            if (type == 'carousel') {
              return _CarouselCard(data: data, docId: allDocs[index].id);
            } else if (type == 'video') {
              return _VideoCard(data: data, docId: allDocs[index].id);
            }
            return _ImageCard(data: data, docId: allDocs[index].id, isSelectionMode: isSelectionMode);
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
          Text(message, textAlign: TextAlign.center, style: AppFonts.poppins(size: 14, color: AppColors.muted)),
        ],
      ),
    );
  }
}

// ── Images Tab ────────────────────────────────────────────────────────────────
class _ImagesTab extends StatelessWidget {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final bool isSelectionMode;

  _ImagesTab({this.isSelectionMode = false});

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const SizedBox();

    final contentStream = _firestore.collection('users').doc(uid).collection('content').where('type', isEqualTo: 'image').snapshots();
    final imagesStream = _firestore.collection('users').doc(uid).collection('generatedImages').snapshots();

    return StreamBuilder<List<QuerySnapshot>>(
      stream: Rx.combineLatest2(contentStream, imagesStream, (a, b) => [a, b]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.gold));
        }

        final List<DocumentSnapshot> allDocs = [];
        if (snapshot.hasData) {
          for (var snap in snapshot.data!) {
            allDocs.addAll(snap.docs);
          }
        }

        // Sort by createdAt
        allDocs.sort((a, b) {
          final aTime = (a.data() as Map<String, dynamic>?)?['createdAt'] as Timestamp?;
          final bTime = (b.data() as Map<String, dynamic>?)?['createdAt'] as Timestamp?;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        if (allDocs.isEmpty) {
          return _emptyState('No images yet', Icons.image_outlined);
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.75,
          ),
          itemCount: allDocs.length,
          itemBuilder: (context, index) {
            final data = allDocs[index].data() as Map<String, dynamic>;
            
            // Map originalImageUrl to imageUrl if needed
            if (data['originalImageUrl'] != null && data['imageUrl'] == null) {
              data['imageUrl'] = data['originalImageUrl'];
            }
            
            return _ImageCard(data: data, docId: allDocs[index].id, isSelectionMode: isSelectionMode);
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
          Text(message, textAlign: TextAlign.center, style: AppFonts.poppins(size: 14, color: AppColors.muted)),
        ],
      ),
    );
  }
}

// ── Carousels Tab ─────────────────────────────────────────────────────────────
class _CarouselsTab extends StatelessWidget {
  const _CarouselsTab();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('content')
          .where('type', isEqualTo: 'carousel')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.gold));
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return _emptyState('No carousels yet', Icons.view_carousel_outlined);
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
            return _CarouselCard(data: docs[index].data() as Map<String, dynamic>, docId: docs[index].id);
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
          Text(message, textAlign: TextAlign.center, style: AppFonts.poppins(size: 14, color: AppColors.muted)),
        ],
      ),
    );
  }
}

// ── Carousel Card ─────────────────────────────────────────────────────────────
class _CarouselCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const _CarouselCard({required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    final slides = data['slides'] as List? ?? [];
    final firstSlideUrl = slides.isNotEmpty ? slides[0]['backgroundImageUrl'] : '';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.15), width: 0.8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (firstSlideUrl != null && firstSlideUrl.isNotEmpty)
              Image.network(firstSlideUrl, fit: BoxFit.cover)
            else
              const Center(child: Icon(Icons.view_carousel, color: AppColors.gold, size: 40)),
            
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Carousel', style: AppFonts.poppins(size: 10, weight: FontWeight.w700, color: AppColors.gold)),
                    Text('${slides.length} Slides', style: AppFonts.poppins(size: 10, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Video Card ────────────────────────────────────────────────────────────────
class _VideoCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final String docId;

  const _VideoCard({required this.data, required this.docId});

  @override
  Widget build(BuildContext context) {
    final videoUrl = data['videoUrl'] as String? ?? '';
    final thumbnailUrl = data['thumbnailUrl'] as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.15), width: 0.8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (thumbnailUrl.isNotEmpty)
              Image.network(thumbnailUrl, fit: BoxFit.cover)
            else
              const Center(child: Icon(Icons.play_circle_fill, color: AppColors.gold, size: 40)),
            
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent],
                  ),
                ),
                child: Text('Video', style: AppFonts.poppins(size: 10, weight: FontWeight.w700, color: AppColors.gold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Image Card ────────────────────────────────────────────────────────────────
class _ImageCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String docId;
  final bool isSelectionMode;

  const _ImageCard({required this.data, required this.docId, this.isSelectionMode = false});

  @override
  State<_ImageCard> createState() => _ImageCardState();
}

class _ImageCardState extends State<_ImageCard> {
  bool _isDownloading = false;

  Future<void> _handleTap() async {
    if (widget.isSelectionMode) {
      setState(() => _isDownloading = true);
      try {
        final imageUrl = widget.data['imageUrl'] as String? ?? '';
        File? imageFile;

        if (imageUrl.startsWith('https://')) {
          final response = await http.get(Uri.parse(imageUrl));
          if (response.statusCode == 200) {
            final tempDir = await getTemporaryDirectory();
            final file = File('${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg');
            await file.writeAsBytes(response.bodyBytes);
            imageFile = file;
          }
        } else if (imageUrl.startsWith('data:image')) {
          final base64Str = imageUrl.split(',')[1];
          final bytes = base64Decode(base64Str);
          final tempDir = await getTemporaryDirectory();
          final file = File('${tempDir.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg');
          await file.writeAsBytes(bytes);
          imageFile = file;
        }

        if (mounted && imageFile != null) {
          Navigator.pop(context, imageFile);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error selecting image: $e')));
        }
      } finally {
        if (mounted) setState(() => _isDownloading = false);
      }
    } else {
      _showImageDetail(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.data['imageUrl'] as String? ?? '';
    final outfit = widget.data['outfit'] as String? ?? '';
    final location = widget.data['location'] as String? ?? '';
    final gender = widget.data['gender'] as String? ?? '';

    return GestureDetector(
      onTap: _isDownloading ? null : _handleTap,
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

              if (_isDownloading)
                Container(
                  color: Colors.black45,
                  child: const Center(child: CircularProgressIndicator(color: AppColors.gold, strokeWidth: 2)),
                ),

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
    final imageUrl = widget.data['imageUrl'] as String? ?? '';

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
                  _detailRow('Outfit', widget.data['outfit'] ?? ''),
                  const SizedBox(height: 6),
                  _detailRow('Location', widget.data['location'] ?? ''),
                  const SizedBox(height: 6),
                  _detailRow('Mood', widget.data['mood'] ?? ''),
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
