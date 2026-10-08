import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_header.dart';
import '../services/stock_image_service.dart';
import '../services/trending_service.dart';
import '../providers/user_provider.dart';
import '../providers/admin_provider.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'generate_screen.dart';

class PhotoshootScreen extends StatefulWidget {
  const PhotoshootScreen({super.key});

  @override
  State<PhotoshootScreen> createState() => _PhotoshootScreenState();
}

class _PhotoshootScreenState extends State<PhotoshootScreen> {
  List<TrendingTemplate> _trendingTemplates = [];
  List<StockImage> _trendingImages = [];
  List<AdminContent> _adminContent = [];
  bool _isTrendingLoading = false;
  bool _isLoadingMore = false;
  int _trendingPage = 1;

  @override
  void initState() {
    super.initState();
    _loadAdminContent();
  }

  Future<void> _loadMoreTrendingTemplates() async {
    setState(() => _isLoadingMore = true);
    try {
      _trendingPage++;
      
      List<StockImage> moreImages = [];
      if (_trendingTemplates.isNotEmpty) {
        for (var i = 0; i < _trendingTemplates.length && moreImages.length < 6; i++) {
          final trend = _trendingTemplates[i];
          if (trend.searchTerms.isNotEmpty) {
            try {
              final images = await StockImageService.searchBoth(
                query: trend.searchTerms[0],
                perPage: 2,
                page: _trendingPage,
              );
              moreImages.addAll(images);
            } catch (e) {
              continue;
            }
          }
        }
      }

      setState(() {
        _trendingImages.addAll(moreImages);
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  void _loadAdminContent() {
    FirebaseFirestore.instance
        .collection('admin_content')
        .snapshots()
        .listen(
      (snapshot) {
        if (mounted) {
          final items = snapshot.docs
              .map((doc) => AdminContent.fromMap({'id': doc.id, ...doc.data()}))
              .toList();
          for (final item in items) {
            precacheImage(NetworkImage(item.imageUrl), context);
          }
          items.shuffle();
          setState(() {
            _adminContent = items;
          });
        }
      },
      onError: (e) {
        debugPrint('Error loading admin content: $e');
      },
    );
  }

  void _push(BuildContext context, Widget w) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => w));

  @override
  Widget build(BuildContext context) {
    final credits = context.watch<UserProvider>().credits ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E0A),
      body: Column(
        children: [
          PremiumHeader(
            onProfileTap: () => _push(context, const ProfileScreen()),
            onSettingsTap: () => _push(context, const NotificationsScreen()),
            creditsText: '$credits CREDITS',
          ),
          Expanded(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PHOTOSHOOT',
                        style: AppFonts.poppins(
                          size: 10,
                          weight: FontWeight.w700,
                          color: AppColors.gold,
                          letterSpacing: 3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose Template Style',
                        style: AppFonts.playfair(
                          size: 32,
                          weight: FontWeight.w900,
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Select a template image to extract style features',
                        style: AppFonts.poppins(
                          size: 13,
                          color: AppColors.muted,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Images Grid
                Expanded(
                  child: _buildTrendingContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingContent() {
    if (_isTrendingLoading && _adminContent.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.gold),
            const SizedBox(height: 16),
            Text(
              'Loading trending templates...',
              style: AppFonts.poppins(color: AppColors.muted),
            ),
          ],
        ),
      );
    }

    if (_adminContent.isEmpty && _trendingImages.isEmpty) {
      return Center(
        child: Text(
          'No trending templates available.',
          style: AppFonts.poppins(color: AppColors.muted),
          textAlign: TextAlign.center,
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Admin-uploaded content
          if (_adminContent.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                'TEMPLATES',
                style: AppFonts.poppins(
                  size: 10,
                  weight: FontWeight.w700,
                  color: AppColors.gold,
                  letterSpacing: 2,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.65,
              ),
              itemCount: _adminContent.length,
              itemBuilder: (context, index) {
                final item = _adminContent[index];
                return _buildAdminContentCard(context, item);
              },
            ),
            const SizedBox(height: 16),
          ],

          // Stock trending images
          if (_trendingImages.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text(
                'TRENDING',
                style: AppFonts.poppins(
                  size: 10,
                  weight: FontWeight.w700,
                  color: AppColors.gold,
                  letterSpacing: 2,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.65,
              ),
              itemCount: _trendingImages.length,
              itemBuilder: (context, index) {
                final image = _trendingImages[index];
                return _buildTemplateCard(context, image);
              },
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: _isLoadingMore ? null : _loadMoreTrendingTemplates,
                child: _buildLoadMoreButton(),
              ),
            ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.4),
          width: 1.5,
        ),
        color: _isLoadingMore
            ? AppColors.gold.withValues(alpha: 0.1)
            : AppColors.surface,
      ),
      child: Center(
        child: _isLoadingMore
            ? SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                  color: AppColors.gold,
                  strokeWidth: 2,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add,
                    color: AppColors.gold,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'LOAD MORE',
                    style: AppFonts.poppins(
                      size: 11,
                      weight: FontWeight.w700,
                      color: AppColors.gold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTemplateCard(BuildContext context, StockImage image) {
    return GestureDetector(
      onTap: () {
        _push(
          context,
          GenerateScreen(
            templateImage: image,
            presetStyle: image.source,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                image.imageUrl,
                fit: BoxFit.cover,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded || frame != null) return child;
                  return Container(
                    color: AppColors.surface,
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.surface,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.image_not_supported,
                          color: AppColors.muted,
                          size: 40,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load',
                          style: AppFonts.poppins(
                            size: 10,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Overlay gradient
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),

            // Info at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      image.photographer,
                      style: AppFonts.poppins(
                        size: 11,
                        color: AppColors.gold,
                        weight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.gold.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        image.source.toUpperCase(),
                        style: AppFonts.poppins(
                          size: 8,
                          color: AppColors.gold,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Click indicator
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.6),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_forward,
                  color: AppColors.black,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Podcast': return const Color(0xFFE74C3C);
      case 'Trending': return const Color(0xFFF39C12);
      case 'B-Roll': return const Color(0xFFE8A0B4);
      case 'Carousel': return const Color(0xFF9B59B6);
      case 'Luxury Lifestyle': return const Color(0xFFD4AF37);
      case 'Luxury Office': return const Color(0xFF8B6914);
      case 'Luxury Car': return const Color(0xFFC0392B);
      case 'Seaside Work': return const Color(0xFF1ABC9C);
      default: return AppColors.gold;
    }
  }

  Widget _buildAdminContentCard(BuildContext context, AdminContent item) {
    final categoryColor = _getCategoryColor(item.category);
    return GestureDetector(
      onTap: () {
        _push(
          context,
          GenerateScreen(
            templateImage: StockImage(
              id: item.id,
              imageUrl: item.imageUrl,
              title: '${item.category} Template',
              photographer: 'Twinora',
              source: 'Admin',
            ),
            prefilledPrompt: item.prompt,
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: categoryColor.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: categoryColor.withValues(alpha: 0.1),
              blurRadius: 8,
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded || frame != null) return child;
                  return Container(
                    color: AppColors.surface,
                    child: const Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.surface,
                  child: const Icon(Icons.image_not_supported, color: AppColors.muted, size: 40),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: categoryColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.category.toUpperCase(),
                        style: AppFonts.poppins(
                          size: 8,
                          color: AppColors.white,
                          weight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (item.prompt != null && item.prompt!.isNotEmpty)
                      Text(
                        item.prompt!,
                        style: AppFonts.poppins(
                          size: 9,
                          color: AppColors.white.withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.6),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_forward, color: AppColors.black, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
