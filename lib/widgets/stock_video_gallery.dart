import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/stock_image_service.dart';

class StockVideoGallery extends StatefulWidget {
  final Function(StockImage) onVideoSelected;
  final String initialQuery;

  const StockVideoGallery({
    super.key,
    required this.onVideoSelected,
    this.initialQuery = 'lifestyle',
  });

  @override
  State<StockVideoGallery> createState() => _StockVideoGalleryState();
}

class _StockVideoGalleryState extends State<StockVideoGallery> {
  late TextEditingController _searchController;
  List<StockImage> _videos = [];
  bool _isLoading = false;
  String _currentQuery = '';
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _currentQuery = widget.initialQuery;
    _loadVideos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVideos() async {
    if (_currentQuery.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Search for videos (Pexels has video support)
      final videos = await StockImageService.searchBoth(
        query: _currentQuery,
        perPage: 20,
        page: _currentPage,
      );

      setState(() {
        if (_currentPage == 1) {
          _videos = videos;
        } else {
          _videos.addAll(videos);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading videos: $e')),
        );
      }
    }
  }

  void _search() {
    _currentQuery = _searchController.text.trim();
    _currentPage = 1;
    if (_currentQuery.isNotEmpty) {
      _loadVideos();
    }
  }

  void _loadMore() {
    _currentPage++;
    _loadVideos();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            style: AppFonts.poppins(size: 14, color: AppColors.white),
            decoration: InputDecoration(
              hintText: 'Search stock videos...',
              hintStyle: AppFonts.poppins(size: 14, color: AppColors.muted),
              prefixIcon: Icon(Icons.search, color: AppColors.gold),
              suffixIcon: _searchController.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      child: Icon(Icons.clear, color: AppColors.gold),
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.gold),
              ),
            ),
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _search(),
          ),
        ),

        // Search Button
        if (_searchController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _search,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  disabledBackgroundColor: AppColors.gold.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _isLoading ? 'SEARCHING...' : 'SEARCH',
                  style: AppFonts.poppins(
                    size: 12,
                    weight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                ),
              ),
            ),
          ),

        // Videos Grid
        Expanded(
          child: _isLoading && _videos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.gold),
                      const SizedBox(height: 16),
                      Text(
                        'Loading videos...',
                        style: AppFonts.poppins(color: AppColors.muted),
                      ),
                    ],
                  ),
                )
              : _videos.isEmpty
                  ? Center(
                      child: Text(
                        'No videos found. Try a different search.',
                        style: AppFonts.poppins(color: AppColors.muted),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: _videos.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _videos.length) {
                          return Center(
                            child: CircularProgressIndicator(color: AppColors.gold),
                          );
                        }

                        final video = _videos[index];
                        return GestureDetector(
                          onTap: () => widget.onVideoSelected(video),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                // Video Thumbnail
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    video.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: AppColors.surface,
                                        child: Icon(
                                          Icons.video_library,
                                          color: AppColors.muted,
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                // Overlay with info
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
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

                                // Play button overlay
                                Center(
                                  child: Container(
                                    width: 48,
                                    height: 48,
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
                                      Icons.play_arrow,
                                      color: AppColors.black,
                                      size: 24,
                                    ),
                                  ),
                                ),

                                // Info at bottom
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          video.photographer,
                                          style: AppFonts.poppins(
                                            size: 10,
                                            color: AppColors.gold,
                                            weight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          video.source.toUpperCase(),
                                          style: AppFonts.poppins(
                                            size: 8,
                                            color: AppColors.muted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Select button
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.gold,
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.gold.withValues(alpha: 0.5),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.check,
                                      color: AppColors.black,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),

        // Load More Button
        if (_videos.isNotEmpty && !_isLoading)
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loadMore,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.surface,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: AppColors.gold.withValues(alpha: 0.5)),
                  ),
                ),
                child: Text(
                  'LOAD MORE',
                  style: AppFonts.poppins(
                    size: 12,
                    weight: FontWeight.w700,
                    color: AppColors.gold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
