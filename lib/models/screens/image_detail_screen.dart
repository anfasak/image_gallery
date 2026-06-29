import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery/database/hive_service.dart';
import 'package:image_gallery/models/image_model.dart';
import 'package:image_gallery/services/download_service.dart';

class ImageDetailScreen extends StatefulWidget {
  const ImageDetailScreen({
    required this.image,
    super.key,
  });

  final ImageModel image;

  @override
  State<ImageDetailScreen> createState() => _ImageDetailScreenState();
}

class _ImageDetailScreenState extends State<ImageDetailScreen> {
  late bool _isFavorite;
  bool _isUpdatingFavorite = false;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = HiveService.isFavorite(widget.image.id);
  }

  // ─────────────────────────────────────────────
  // Favourite toggle
  // ─────────────────────────────────────────────

  Future<void> _toggleFavorite() async {
    if (_isUpdatingFavorite) return;

    setState(() => _isUpdatingFavorite = true);

    try {
      if (_isFavorite) {
        await HiveService.removeFavorite(widget.image.id);
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from favourites')),
          );
        }
      } else {
        await HiveService.addFavorite(widget.image);
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to favourites')),
          );
        }
      }

      if (mounted) {
        setState(() => _isFavorite = !_isFavorite);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingFavorite = false);
      }
    }
  }

  // ─────────────────────────────────────────────
  // Download
  // ─────────────────────────────────────────────

  Future<void> _downloadImage() async {
    if (_isDownloading) return;

    setState(() => _isDownloading = true);

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Downloading image...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      // Request storage permission on Android (SDK ≤ 32).
      // On SDK 33+ the READ_MEDIA_IMAGES permission is required instead, but
      // saving to the app-documents directory does NOT need any permission at
      // all, so we only request the legacy permission when it is relevant.
      if (Theme.of(context).platform == TargetPlatform.android) {
        final PermissionStatus status = await Permission.storage.request();
        if (!status.isGranted && !status.isLimited) {
          throw Exception('Storage permission denied.');
        }
      }

      final DownloadResult result =
          await DownloadService.downloadImage(widget.image);

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.alreadyDownloaded
                ? 'Image already downloaded.'
                : 'Image downloaded successfully.',
          ),
          backgroundColor:
              result.alreadyDownloaded ? null : Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Details'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            tooltip: _isFavorite ? 'Remove from favourites' : 'Add to favourites',
            onPressed: _isUpdatingFavorite ? null : _toggleFavorite,
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
          ),
          IconButton(
            tooltip: 'Download image',
            onPressed: _isDownloading ? null : _downloadImage,
            icon: _isDownloading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: _ZoomableImage(imageUrl: widget.image.downloadUrl),
            ),
            _ImageInfoPanel(image: widget.image),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Zoomable image
// ─────────────────────────────────────────────────────────────────────────────

class _ZoomableImage extends StatelessWidget {
  const _ZoomableImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      color: colorScheme.surfaceContainerHighest,
      child: InteractiveViewer(
        minScale: 1,
        maxScale: 4,
        child: Center(
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (BuildContext context, String url) {
              return const Center(child: CircularProgressIndicator());
            },
            errorWidget: (BuildContext context, String url, Object error) {
              return const Center(
                child: Icon(Icons.broken_image_outlined, size: 56),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info panel
// ─────────────────────────────────────────────────────────────────────────────

class _ImageInfoPanel extends StatelessWidget {
  const _ImageInfoPanel({required this.image});

  final ImageModel image;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            image.author,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              const Icon(Icons.photo_size_select_large_outlined, size: 20),
              const SizedBox(width: 8),
              Text(
                '${image.width} x ${image.height}',
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
