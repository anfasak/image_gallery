import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery/database/hive_service.dart';
import 'package:image_gallery/models/image_model.dart';
import 'package:image_gallery/models/screens/image_detail_screen.dart';

/// Grid card that represents a single image in the gallery.
///
/// Uses [ValueNotifier] for the favourite state so only the heart icon
/// rebuilds on toggle, not the entire card.
class ImageCard extends StatefulWidget {
  const ImageCard({
    required this.image,
    super.key,
  });

  final ImageModel image;

  @override
  State<ImageCard> createState() => _ImageCardState();
}

class _ImageCardState extends State<ImageCard> {
  late final ValueNotifier<bool> _isFavNotifier;

  @override
  void initState() {
    super.initState();
    _isFavNotifier =
        ValueNotifier<bool>(HiveService.isFavorite(widget.image.id));
  }

  @override
  void dispose() {
    _isFavNotifier.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────

  Future<void> _toggleFavorite() async {
    final bool current = _isFavNotifier.value;
    try {
      if (current) {
        await HiveService.removeFavorite(widget.image.id);
      } else {
        await HiveService.addFavorite(widget.image);
      }
      // Update only the heart icon, not the whole card.
      _isFavNotifier.value = !current;

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              current ? 'Removed from favourites' : 'Added to favourites',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  Future<void> _openDetail() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) =>
            ImageDetailScreen(image: widget.image),
      ),
    );
    // Sync favourite state if it was changed inside the detail screen.
    if (mounted) {
      _isFavNotifier.value = HiveService.isFavorite(widget.image.id);
    }
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: InkWell(
        onTap: _openDetail,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  // ── Image (cached) ───────────────────────────────────────
                  CachedNetworkImage(
                    imageUrl: widget.image.downloadUrl,
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
                  // ── Favourite icon (only this rebuilds) ──────────────────
                  Positioned(
                    top: 8,
                    right: 8,
                    child: ValueListenableBuilder<bool>(
                      valueListenable: _isFavNotifier,
                      builder: (
                        BuildContext context,
                        bool isFav,
                        Widget? child,
                      ) {
                        return IconButton.filledTonal(
                          tooltip: isFav
                              ? 'Remove from favourites'
                              : 'Add to favourites',
                          onPressed: _toggleFavorite,
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            color: isFav ? Colors.red : null,
                          ),
                        );
                      },
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
                    widget.image.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.image.width} x ${widget.image.height}',
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