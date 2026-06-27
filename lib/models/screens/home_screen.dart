import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _imagesFuture = _apiService.fetchImages();
  }

  Future<void> _refreshImages() async {
    setState(() {
      _imagesFuture = _apiService.fetchImages();
    });

    await _imagesFuture;
  }

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
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => const FavoritesScreen(),
                ),
              );
              if (mounted) {
                setState(() {});
              }
            },
          ),
        ],
      ),
      body: FutureBuilder<List<ImageModel>>(
        future: _imagesFuture,
        builder: (BuildContext context, AsyncSnapshot<List<ImageModel>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _ErrorView(
              message: snapshot.error.toString(),
              onRetry: _refreshImages,
            );
          }

          final List<ImageModel> images = snapshot.data ?? <ImageModel>[];

          if (images.isEmpty) {
            return const Center(
              child: Text('No images found.'),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshImages,
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
    );
  }
}

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