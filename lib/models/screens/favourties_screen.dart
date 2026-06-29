import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_gallery/database/hive_service.dart';
import 'package:image_gallery/models/image_model.dart';
import 'package:image_gallery/models/screens/image_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  static const String _favoritesBoxName = 'favorites';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        centerTitle: true,
      ),
      body: ValueListenableBuilder<Box<Map>>(
        valueListenable: Hive.box<Map>(_favoritesBoxName).listenable(),
        builder: (BuildContext context, Box<Map> box, Widget? child) {
          final List<ImageModel> favorites = HiveService.getFavorites();

          if (favorites.isEmpty) {
            return const _EmptyFavoritesView();
          }

          return GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: favorites.length,
            itemBuilder: (BuildContext context, int index) {
              return _FavoriteImageCard(image: favorites[index]);
            },
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Favourite card
// ─────────────────────────────────────────────────────────────────────────────

class _FavoriteImageCard extends StatelessWidget {
  const _FavoriteImageCard({required this.image});

  final ImageModel image;

  Future<void> _removeFavorite(BuildContext context) async {
    try {
      await HiveService.removeFavorite(image.id);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Removed from favourites'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => HiveService.addFavorite(image),
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    }
  }

  void _openImageDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => ImageDetailScreen(image: image),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: () => _openImageDetails(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  // ── Cached image ─────────────────────────────────────────
                  CachedNetworkImage(
                    imageUrl: image.downloadUrl,
                    fit: BoxFit.cover,
                    placeholder: (BuildContext context, String url) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                    errorWidget: (
                      BuildContext context,
                      String url,
                      Object error,
                    ) {
                      return const Center(
                        child: Icon(Icons.broken_image_outlined, size: 40),
                      );
                    },
                  ),
                  // ── Remove-favourite button ───────────────────────────────
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filledTonal(
                      tooltip: 'Remove from favourites',
                      onPressed: () => _removeFavorite(context),
                      icon: const Icon(Icons.favorite, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    image.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${image.width} x ${image.height}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyFavoritesView extends StatelessWidget {
  const _EmptyFavoritesView();

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.favorite_border,
              size: 64,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No favorites yet',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Images you mark as favorites will appear here.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}