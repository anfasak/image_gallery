import 'package:hive_flutter/hive_flutter.dart';

import '../models/image_model.dart';

class HiveService {
  HiveService._();

  static const String _favoritesBoxName = 'favorites';
  static const String _downloadsBoxName = 'downloads';

  static Box<Map>? _favoritesBox;
  static Box<String>? _downloadsBox;

  // ─────────────────────────────────────────────
  // Initialisation
  // ─────────────────────────────────────────────

  /// Initialises Hive and opens all required boxes.
  ///
  /// Call this once before `runApp()` in `main()`.
  static Future<void> initializeHive() async {
    try {
      await Hive.initFlutter();
      _favoritesBox = await Hive.openBox<Map>(_favoritesBoxName);
      _downloadsBox = await Hive.openBox<String>(_downloadsBoxName);
    } catch (error) {
      throw Exception('Failed to initialise local storage: $error');
    }
  }

  // ─────────────────────────────────────────────
  // Favorites
  // ─────────────────────────────────────────────

  /// Adds an image to favourites.
  ///
  /// The image id is used as the Hive key to prevent duplicate entries.
  static Future<void> addFavorite(ImageModel image) async {
    try {
      final Box<Map> box = _favBox;
      if (box.containsKey(image.id)) return;
      await box.put(image.id, image.toJson());
    } catch (error) {
      throw Exception('Failed to add image to favourites: $error');
    }
  }

  /// Removes an image from favourites by its id.
  static Future<void> removeFavorite(String imageId) async {
    try {
      await _favBox.delete(imageId);
    } catch (error) {
      throw Exception('Failed to remove image from favourites: $error');
    }
  }

  /// Returns `true` when the image is saved as a favourite.
  static bool isFavorite(String imageId) {
    try {
      return _favBox.containsKey(imageId);
    } catch (error) {
      throw Exception('Failed to check favourite status: $error');
    }
  }

  /// Returns all saved favourite images.
  static List<ImageModel> getFavorites() {
    try {
      return _favBox.values
          .map(
            (Map imageJson) => ImageModel.fromJson(
              Map<String, dynamic>.from(imageJson),
            ),
          )
          .toList(growable: false);
    } catch (error) {
      throw Exception('Failed to load favourite images: $error');
    }
  }

  /// Removes every saved favourite image.
  static Future<void> clearFavorites() async {
    try {
      await _favBox.clear();
    } catch (error) {
      throw Exception('Failed to clear favourites: $error');
    }
  }

  // ─────────────────────────────────────────────
  // Downloads
  // ─────────────────────────────────────────────

  /// Returns the locally stored file path for [imageId], or `null` if the
  /// image has not been downloaded yet.
  static String? getDownloadedPath(String imageId) {
    try {
      return _dlBox.get(imageId);
    } catch (error) {
      return null;
    }
  }

  /// Persists the [filePath] for [imageId] so duplicate downloads are avoided.
  static Future<void> setDownloadedPath(String imageId, String filePath) async {
    try {
      await _dlBox.put(imageId, filePath);
    } catch (error) {
      throw Exception('Failed to save download path: $error');
    }
  }

  /// Returns `true` when the image has a stored local file path.
  static bool isDownloaded(String imageId) {
    try {
      return _dlBox.containsKey(imageId);
    } catch (error) {
      return false;
    }
  }

  // ─────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────

  static Box<Map> get _favBox {
    final Box<Map>? box = _favoritesBox;
    if (box == null || !box.isOpen) {
      throw Exception(
        'HiveService is not initialised. Call initializeHive() before use.',
      );
    }
    return box;
  }

  static Box<String> get _dlBox {
    final Box<String>? box = _downloadsBox;
    if (box == null || !box.isOpen) {
      throw Exception(
        'HiveService is not initialised. Call initializeHive() before use.',
      );
    }
    return box;
  }
}