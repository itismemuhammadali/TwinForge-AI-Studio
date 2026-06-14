import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/stock_image_service.dart';

class StockImageGallery extends StatefulWidget {
  final Function(StockImage) onImageSelected;
  final String initialQuery;

  const StockImageGallery({
    super.key,
    required this.onImageSelected,
    this.initialQuery = 'fashion',
  });

  @override
  State<StockImageGallery> createState() => _StockImageGalleryState();
}

class _StockImageGalleryState extends State<StockImageGallery> {
  late TextEditingController _searchController;
  List<StockImage> _images = [];
  bool _isLoading = false;
  String _currentQuery = '';
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _currentQuery = widget.initialQuery;
    _loadImages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadImages() async {
    if (_currentQuery.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final images = await StockImageService.searchBoth(
        query: _currentQuery,
        perPage: 20,
        page: _currentPage,
      );

      setState(() {
        if (_currentPage == 1) {
          _images = images;
        } else {
          _images.addAll(images);
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading images: $e')),
        );
      }
    }
  }

  void _search() {
    _currentQuery = _searchController.text.trim();
    _currentPage = 1;
    if (_currentQuery.isNotEmpty) {
      _loadImages();
    }
  }

  void _loadMore() {
    _currentPage++;
    _loadImages();
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
              hintText: 'Search stock images...',
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

        // Images Grid
        Expanded(
          child: _isLoading && _images.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.gold),
                      const SizedBox(height: 16),
                      Text(
                        'Loading images...',
                        style: AppFonts.poppins(color: AppColors.muted),
                      ),
                    ],
                  ),
                )
              : _images.isEmpty
                  ? Center(
                      child: Text(
                        'No images found. Try a different search.',
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
                      itemCount: _images.length + (_isLoading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _images.length) {
                          return Center(
                            child: CircularProgressIndicator(color: AppColors.gold),
                          );
                        }

                        final image = _images[index];
                        return GestureDetector(
                          onTap: () => widget.onImageSelected(image),
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
                                // Image
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    image.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: AppColors.surface,
                                        child: Icon(
                                          Icons.image_not_supported,
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
                                          image.photographer,
                                          style: AppFonts.poppins(
                                            size: 10,
                                            color: AppColors.gold,
                                            weight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          image.source.toUpperCase(),
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
        if (_images.isNotEmpty && !_isLoading)
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
