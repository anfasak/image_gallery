import 'package:hive_flutter/hive_flutter.dart';

import '../models/image_model.dart';

class HiveService {
  HiveService._();

  static const String _favoritesBoxName = 'favorites';

  static Box<Map>? _favoritesBox;

  /// Initializes Hive and opens the favorites box.
  ///
  /// Call this once before `runApp()`, usually in `main()`.
  static Future<void> initializeHive() async {
    try {
      await Hive.initFlutter();
      _favoritesBox = await Hive.openBox<Map>(_favoritesBoxName);
    } catch (error) {
      throw Exception('Failed to initialize local storage: $error');
    }
  }

  /// Adds an image to favorites.
  ///
  /// The image id is used as the Hive key, which prevents duplicate entries.
  static Future<void> addFavorite(ImageModel image) async {
    try {
      final Box<Map> box = _box;

      if (box.containsKey(image.id)) {
        return;
      }

      await box.put(image.id, image.toJson());
    } catch (error) {
      throw Exception('Failed to add image to favorites: $error');
    }
  }

  /// Removes an image from favorites by its id.
  static Future<void> removeFavorite(String imageId) async {
    try {
      await _box.delete(imageId);
    } catch (error) {
      throw Exception('Failed to remove image from favorites: $error');
    }
  }

  /// Returns true when the image is already saved as a favorite.
  static bool isFavorite(String imageId) {
    try {
      return _box.containsKey(imageId);
    } catch (error) {
      throw Exception('Failed to check favorite status: $error');
    }
  }

  /// Returns all saved favorite images.
  static List<ImageModel> getFavorites() {
    try {
      return _box.values
          .map(
            (Map imageJson) => ImageModel.fromJson(
              Map<String, dynamic>.from(imageJson),
            ),
          )
          .toList(growable: false);
    } catch (error) {
      throw Exception('Failed to load favorite images: $error');
    }
  }

  /// Removes every saved favorite image.
  static Future<void> clearFavorites() async {
    try {
      await _box.clear();
    } catch (error) {
      throw Exception('Failed to clear favorites: $error');
    }
  }

  static Box<Map> get _box {
    final Box<Map>? box = _favoritesBox;

    if (box == null || !box.isOpen) {
      throw Exception(
        'HiveService is not initialized. Call initializeHive() before use.',
      );
    }

    return box;
  }
}