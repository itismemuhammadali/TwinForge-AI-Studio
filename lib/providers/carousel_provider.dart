import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:developer' as developer;
import '../models/carousel_models.dart';

class CarouselProvider extends ChangeNotifier {
  /// Current carousel creation state
  CarouselCreationState? _state;

  /// Undo/Redo history
  final List<Carousel> _history = [];
  int _historyIndex = -1;

  CarouselCreationState? get state => _state;

  /// Getters for convenience
  List<File> get uploadedImages => _state?.uploadedImages ?? [];
  Set<String> get selectedSubcategories => _state?.selectedSubcategories ?? {};
  List<String> get backgroundImageUrls => _state?.backgroundImageUrls ?? [];
  int get currentSlideIndex => _state?.currentSlideIndex ?? 0;
  Carousel get carousel => _state?.carousel ?? Carousel.empty();
  CarouselSlide get currentSlide => carousel.slides[currentSlideIndex];
  
  /// Undo/Redo getters
  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex < _history.length - 1;

  /// Initialize carousel creation flow
  void initializeCarouselCreation() {
    debugLog('🎬 Initializing carousel creation...');
    _state = CarouselCreationState(
      uploadedImages: [],
      selectedSubcategories: {},
      backgroundImageUrls: [],
      currentSlideIndex: 0,
      carousel: Carousel.empty(),
    );
    _history.clear();
    _historyIndex = -1;
    notifyListeners();
  }

  /// Add to history for undo/redo
  void _addToHistory(Carousel carousel) {
    // Remove any history after current index (when user makes new change after undo)
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }
    _history.add(carousel);
    _historyIndex = _history.length - 1;
    debugLog('📝 History saved (index: $_historyIndex)');
  }

  /// Undo last action
  void undo() {
    if (canUndo) {
      _historyIndex--;
      if (_state != null) {
        _state = _state!.copyWith(carousel: _history[_historyIndex]);
      }
      debugLog('↶ Undo executed (index: $_historyIndex)');
      notifyListeners();
    }
  }

  /// Redo last undone action
  void redo() {
    if (canRedo) {
      _historyIndex++;
      if (_state != null) {
        _state = _state!.copyWith(carousel: _history[_historyIndex]);
      }
      debugLog('↷ Redo executed (index: $_historyIndex)');
      notifyListeners();
    }
  }

  /// Add uploaded images
  void addUploadedImages(List<File> images) {
    if (_state == null) return;

    // Keep max 5 images
    final allImages = [..._state!.uploadedImages, ...images];
    final limited = allImages.take(5).toList();

    _state = _state!.copyWith(uploadedImages: limited);
    debugLog('📸 Added ${images.length} images. Total: ${limited.length}');
    notifyListeners();
  }

  /// Remove uploaded image by index
  void removeUploadedImage(int index) {
    if (_state == null) return;

    final images = [..._state!.uploadedImages];
    if (index >= 0 && index < images.length) {
      images.removeAt(index);
      _state = _state!.copyWith(uploadedImages: images);
      debugLog('🗑️ Removed image at index $index');
      notifyListeners();
    }
  }

  /// Clear all uploaded images
  void clearUploadedImages() {
    if (_state == null) return;

    _state = _state!.copyWith(uploadedImages: []);
    debugLog('🗑️ Cleared all uploaded images');
    notifyListeners();
  }

  /// Select/deselect subcategories
  void toggleSubcategory(String subcategory) {
    if (_state == null) return;

    final selected = {..._state!.selectedSubcategories};
    if (selected.contains(subcategory)) {
      selected.remove(subcategory);
      debugLog('❌ Deselected: $subcategory');
    } else {
      selected.add(subcategory);
      debugLog('✅ Selected: $subcategory');
    }

    _state = _state!.copyWith(selectedSubcategories: selected);
    notifyListeners();
  }

  /// Clear all subcategory selections
  void clearSubcategorySelection() {
    if (_state == null) return;

    _state = _state!.copyWith(selectedSubcategories: {});
    debugLog('🗑️ Cleared subcategory selection');
    notifyListeners();
  }

  /// Set background images for all 5 slides
  void setBackgroundImages(List<String> imageUrls) {
    if (_state == null) return;

    // Take exactly 5
    final urls = imageUrls.take(5).toList();

    debugLog('🔍 Setting background images: $urls');

    // Update carousel slides with background images
    final updatedSlides = carousel.slides.asMap().entries.map((entry) {
      final index = entry.key;
      final slide = entry.value;
      final newUrl = index < urls.length ? urls[index] : null;
      debugLog('  Slide ${index + 1}: $newUrl (was: ${slide.backgroundImageUrl})');
      return index < urls.length
          ? CarouselSlide(
              id: slide.id,
              backgroundImageUrl: urls[index],
              overlays: slide.overlays,
            )
          : slide;
    }).toList();

    final updatedCarousel = Carousel(slides: updatedSlides);
    _state = _state!.copyWith(
      backgroundImageUrls: urls,
      carousel: updatedCarousel,
    );
    _addToHistory(updatedCarousel);
    debugLog('🖼️ Set background images for all 5 slides');
    notifyListeners();
  }

  /// Switch to slide by index
  void switchToSlide(int index) {
    if (_state == null || index < 0 || index >= 5) return;

    _state = _state!.copyWith(currentSlideIndex: index);
    debugLog('📍 Switched to slide ${index + 1}');
    notifyListeners();
  }

  /// Next slide
  void nextSlide() {
    if (_state == null) return;

    final nextIndex = (currentSlideIndex + 1) % 5;
    switchToSlide(nextIndex);
  }

  /// Previous slide
  void previousSlide() {
    if (_state == null) return;

    final prevIndex = (currentSlideIndex - 1 + 5) % 5;
    switchToSlide(prevIndex);
  }

  /// Add image overlay to current slide
  void addImageOverlay(ImageOverlay overlay) {
    if (_state == null) return;

    final updatedSlide = currentSlide.copyWith(
      overlays: [...currentSlide.overlays, overlay],
    );

    final updatedSlides = [...carousel.slides];
    updatedSlides[currentSlideIndex] = updatedSlide;

    final updatedCarousel = Carousel(slides: updatedSlides);
    _state = _state!.copyWith(carousel: updatedCarousel);
    _addToHistory(updatedCarousel);

    debugLog('🖼️ Added image overlay to slide ${currentSlideIndex + 1}');
    notifyListeners();
  }

  /// Add text overlay to current slide
  void addTextOverlay(TextOverlay overlay) {
    if (_state == null) return;

    final updatedSlide = currentSlide.copyWith(
      overlays: [...currentSlide.overlays, overlay],
    );

    final updatedSlides = [...carousel.slides];
    updatedSlides[currentSlideIndex] = updatedSlide;

    final updatedCarousel = Carousel(slides: updatedSlides);
    _state = _state!.copyWith(carousel: updatedCarousel);
    _addToHistory(updatedCarousel);

    debugLog('📝 Added text overlay to slide ${currentSlideIndex + 1}');
    notifyListeners();
  }

  /// Update overlay on current slide
  void updateOverlay(int overlayIndex, OverlayElement newOverlay) {
    if (_state == null) return;

    final overlays = [...currentSlide.overlays];
    if (overlayIndex >= 0 && overlayIndex < overlays.length) {
      overlays[overlayIndex] = newOverlay;

      final updatedSlide = currentSlide.copyWith(overlays: overlays);

      final updatedSlides = [...carousel.slides];
      updatedSlides[currentSlideIndex] = updatedSlide;

      final updatedCarousel = Carousel(slides: updatedSlides);
      _state = _state!.copyWith(carousel: updatedCarousel);
      _addToHistory(updatedCarousel);

      notifyListeners();
    }
  }

  /// Remove overlay from current slide
  void removeOverlay(int overlayIndex) {
    if (_state == null) return;

    final overlays = [...currentSlide.overlays];
    if (overlayIndex >= 0 && overlayIndex < overlays.length) {
      overlays.removeAt(overlayIndex);

      final updatedSlide = currentSlide.copyWith(overlays: overlays);

      final updatedSlides = [...carousel.slides];
      updatedSlides[currentSlideIndex] = updatedSlide;

      final updatedCarousel = Carousel(slides: updatedSlides);
      _state = _state!.copyWith(carousel: updatedCarousel);
      _addToHistory(updatedCarousel);

      debugLog('🗑️ Removed overlay from slide ${currentSlideIndex + 1}');
      notifyListeners();
    }
  }

  /// Clear all overlays on current slide
  void clearCurrentSlideOverlays() {
    if (_state == null) return;

    final updatedSlide = currentSlide.copyWith(overlays: []);

    final updatedSlides = [...carousel.slides];
    updatedSlides[currentSlideIndex] = updatedSlide;

    final updatedCarousel = Carousel(slides: updatedSlides);
    _state = _state!.copyWith(carousel: updatedCarousel);
    _addToHistory(updatedCarousel);

    debugLog('🗑️ Cleared all overlays on slide ${currentSlideIndex + 1}');
    notifyListeners();
  }

  static void debugLog(String message) {
    developer.log('[CarouselProvider] $message');
  }
}
