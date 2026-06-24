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
  List<StockImage> _images = [];
  List<TrendingTemplate> _trendingTemplates = [];
  List<StockImage> _trendingImages = [];
  List<AdminContent> _adminPodcastImages = [];
  bool _isLoading = true;
  bool _isTrendingLoading = false;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  int _trendingPage = 1;
  late TextEditingController _searchController;
  int _selectedTabIndex = 0; // 0 = Browse, 1 = Trending

  // Business template categories to show
  final List<String> _templateCategories = [
    'business',
    'corporate',
    'professional',
    'office',
    'meeting',
    'entrepreneur',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _loadTemplateImages();
    _loadTrendingTemplates();
    _loadAdminPodcastContent();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTemplateImages() async {
    setState(() => _isLoading = true);
    try {
      // Load images from multiple categories to show variety
      List<StockImage> allImages = [];
      
      for (String category in _templateCategories) {
        try {
          final images = await StockImageService.searchBoth(
            query: category,
            perPage: 3, // Get 3 images per category
            page: _currentPage,
          );
          allImages.addAll(images);
        } catch (e) {
          // Continue with other categories if one fails
          continue;
        }
      }

      setState(() {
        _images = allImages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading templates: $e')),
        );
      }
    }
  }

  Future<void> _loadMoreTemplates() async {
    setState(() => _isLoadingMore = true);
    try {
      _currentPage++;
      List<StockImage> newImages = [];
      
      for (String category in _templateCategories) {
        try {
          final images = await StockImageService.searchBoth(
            query: category,
            perPage: 3,
            page: _currentPage,
          );
          newImages.addAll(images);
        } catch (e) {
          continue;
        }
      }

      setState(() {
        _images.addAll(newImages);
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading more templates: $e')),
        );
      }
    }
  }

  Future<void> _loadTrendingTemplates() async {
    // If already have trending data cached, use it immediately
    if (_trendingImages.isNotEmpty) {
      debugPrint('✅ Using cached trending data');
      return;
    }

    setState(() => _isTrendingLoading = true);
    try {
      final trends = await TrendingService.getTrendingTemplates();
      final sortedTrends = TrendingService.sortByPriority(trends);
      
      if (sortedTrends.isEmpty) {
        setState(() => _isTrendingLoading = false);
        return;
      }

      List<StockImage> trendingImages = [];
      
      // Try to fetch images for each trend
      for (var trend in sortedTrends) {
        if (trend.searchTerms.isNotEmpty) {
          // Try each search term in the list until one succeeds
          for (var searchTerm in trend.searchTerms) {
            try {
              // Try Pexels first (seems more reliable)
              final images = await StockImageService.searchPexels(
                query: searchTerm,
                perPage: 2,
              );
              if (images.isNotEmpty) {
                trendingImages.addAll(images);
                debugPrint('✅ Found ${images.length} Pexels images for "$searchTerm"');
                break; // Success, move to next trend
              }
            } catch (e) {
              debugPrint('⚠️ Pexels failed for "$searchTerm", trying Pixabay...');
              // Try Pixabay as fallback
              try {
                final images = await StockImageService.searchPixabay(
                  query: searchTerm,
                  perPage: 2,
                );
                if (images.isNotEmpty) {
                  trendingImages.addAll(images);
                  debugPrint('✅ Found ${images.length} Pixabay images for "$searchTerm"');
                  break; // Success, move to next trend
                }
              } catch (pixabayError) {
                debugPrint('⚠️ Both sources failed for "$searchTerm": $pixabayError');
                continue; // Try next search term
              }
            }
          }
        }
      }

      setState(() {
        _trendingTemplates = sortedTrends;
        _trendingImages = trendingImages;
        _isTrendingLoading = false;
      });
      
      debugPrint('✅ Loaded ${trendingImages.length} trending images total');
    } catch (e) {
      debugPrint('❌ Error loading trending templates: $e');
      setState(() => _isTrendingLoading = false);
    }
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

  void _loadAdminPodcastContent() {
    FirebaseFirestore.instance
        .collection('admin_content')
        .where('category', isEqualTo: 'Podcast')
        .snapshots()
        .listen(
      (snapshot) {
        if (mounted) {
          setState(() {
            _adminPodcastImages = snapshot.docs
                .map((doc) => AdminContent.fromMap({'id': doc.id, ...doc.data()}))
                .toList();
          });
        }
      },
      onError: (e) {
        debugPrint('Error loading admin podcast content: $e');
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

                // Tab Buttons for Business / Trending
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTabIndex = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTabIndex == 0
                                  ? AppColors.gold.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              border: Border(
                                bottom: BorderSide(
                                  color: _selectedTabIndex == 0
                                      ? AppColors.gold
                                      : AppColors.muted.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Business',
                                style: AppFonts.poppins(
                                  size: 12,
                                  weight: FontWeight.w700,
                                  color: _selectedTabIndex == 0
                                      ? AppColors.gold
                                      : AppColors.muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTabIndex = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTabIndex == 1
                                  ? AppColors.gold.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              border: Border(
                                bottom: BorderSide(
                                  color: _selectedTabIndex == 1
                                      ? AppColors.gold
                                      : AppColors.muted.withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Trending',
                                style: AppFonts.poppins(
                                  size: 12,
                                  weight: FontWeight.w700,
                                  color: _selectedTabIndex == 1
                                      ? AppColors.gold
                                      : AppColors.muted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Images Grid - Business or Trending
                Expanded(
                  child: _selectedTabIndex == 0
                      ? _buildBusinessContent()
                      : _buildTrendingContent(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.gold),
            const SizedBox(height: 16),
            Text(
              'Loading business templates...',
              style: AppFonts.poppins(color: AppColors.muted),
            ),
          ],
        ),
      );
    }

    if (_images.isEmpty) {
      return Center(
        child: Text(
          'No business templates found.',
          style: AppFonts.poppins(color: AppColors.muted),
          textAlign: TextAlign.center,
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
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
            itemCount: _images.length,
            itemBuilder: (context, index) {
              final image = _images[index];
              return _buildTemplateCard(context, image);
            },
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: _isLoadingMore ? null : _loadMoreTemplates,
              child: _buildLoadMoreButton(),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildTrendingContent() {
    if (_isTrendingLoading && _adminPodcastImages.isEmpty) {
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

    if (_adminPodcastImages.isEmpty && _trendingImages.isEmpty) {
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
          // Admin-uploaded Podcast images
          if (_adminPodcastImages.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                'PODCAST',
                style: AppFonts.poppins(
                  size: 10,
                  weight: FontWeight.w700,
                  color: const Color(0xFFE74C3C),
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
              itemCount: _adminPodcastImages.length,
              itemBuilder: (context, index) {
                final item = _adminPodcastImages[index];
                return _buildAdminPodcastCard(context, item);
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
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: AppColors.surface,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.gold,
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
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

  Widget _buildAdminPodcastCard(BuildContext context, AdminContent item) {
    return GestureDetector(
      onTap: () {
        _push(
          context,
          GenerateScreen(
            templateImage: StockImage(
              id: item.id,
              imageUrl: item.imageUrl,
              title: 'Podcast Template',
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
            color: const Color(0xFFE74C3C).withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE74C3C).withValues(alpha: 0.1),
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
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
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
                        color: const Color(0xFFE74C3C),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'PODCAST',
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
