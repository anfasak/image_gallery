import 'package:flutter/material.dart';
import 'package:image_gallery/database/hive_service.dart';
import 'package:image_gallery/models/image_model.dart';
import 'package:image_gallery/models/screens/favourties_screen.dart';
import 'package:image_gallery/models/widgets/image_card.dart';
import 'package:image_gallery/services/api_service.dart';

class ImageGalleryScreen extends StatefulWidget {
  const ImageGalleryScreen({super.key});

  @override
  State<ImageGalleryScreen> createState() => _ImageGalleryScreenState();
}

class _ImageGalleryScreenState extends State<ImageGalleryScreen> {
  final ApiService _apiService = ApiService();

  late Future<List<ImageModel>> _imagesFuture;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _imagesFuture = _loadImages();
  }

  // ─────────────────────────────────────────────
  // Data loading
  // ─────────────────────────────────────────────

  Future<List<ImageModel>> _loadImages() async {
    final bool online = await ApiService.hasConnection();

    if (!online) {
      // Offline: serve favourite images from Hive so the app still works.
      if (mounted) {
        setState(() => _isOffline = true);
      }
      return HiveService.getFavorites();
    }

    // Online: clear the offline flag and fetch from the API.
    if (mounted) {
      setState(() => _isOffline = false);
    }
    return _apiService.fetchImages();
  }

  Future<void> _refreshImages() async {
    setState(() {
      _imagesFuture = _loadImages();
    });
    await _imagesFuture;
  }

  // ─────────────────────────────────────────────
  // Navigation
  // ─────────────────────────────────────────────

  Future<void> _openFavorites() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const FavoritesScreen(),
      ),
    );
    // Refresh heart icons after returning from the Favorites screen.
    if (mounted) {
      setState(() {});
    }
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Gallery'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.favorite),
            tooltip: 'Favorites',
            onPressed: _openFavorites,
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          // ── Offline banner ────────────────────────────────────────────────
          if (_isOffline)
            Material(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.wifi_off,
                      size: 18,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Offline Mode – showing saved favourites',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onErrorContainer,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          // ── Image grid ───────────────────────────────────────────────────
          Expanded(
            child: FutureBuilder<List<ImageModel>>(
              future: _imagesFuture,
              builder: (
                BuildContext context,
                AsyncSnapshot<List<ImageModel>> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _ErrorView(
                    message: snapshot.error.toString(),
                    onRetry: _refreshImages,
                  );
                }

                final List<ImageModel> images =
                    snapshot.data ?? <ImageModel>[];

                if (images.isEmpty) {
                  return const Center(child: Text('No images found.'));
                }

                return RefreshIndicator(
                  onRefresh: _refreshImages,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: images.length,
                    itemBuilder: (BuildContext context, int index) {
                      return ImageCard(image: images[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error view
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}