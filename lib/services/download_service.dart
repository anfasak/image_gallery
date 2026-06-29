import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../database/hive_service.dart';
import '../models/image_model.dart';

/// Result returned by [DownloadService.downloadImage].
class DownloadResult {
  const DownloadResult({
    required this.filePath,
    required this.alreadyDownloaded,
  });

  /// Absolute path to the local image file.
  final String filePath;

  /// `true`  → the file was already present; no network request was made.
  /// `false` → the file was freshly downloaded.
  final bool alreadyDownloaded;
}

class DownloadService {
  DownloadService._();

  static final Dio _dio = Dio();

  /// Downloads [image] into the app documents directory.
  ///
  /// • If the image has already been downloaded **and the file still exists**,
  ///   the cached path is returned immediately without a network request.
  /// • Otherwise the image is downloaded, the path is persisted in Hive, and
  ///   the path is returned.
  ///
  /// Throws an [Exception] with a human-readable message on failure.
  static Future<DownloadResult> downloadImage(ImageModel image) async {
    // ── 1. Check Hive for a previously stored path ──────────────────────────
    final String? storedPath = HiveService.getDownloadedPath(image.id);
    if (storedPath != null && File(storedPath).existsSync()) {
      return DownloadResult(filePath: storedPath, alreadyDownloaded: true);
    }

    // ── 2. Download the image ────────────────────────────────────────────────
    try {
      final Directory directory = await getApplicationDocumentsDirectory();
      final String filePath = '${directory.path}/picsum_${image.id}.jpg';

      await _dio.download(image.downloadUrl, filePath);

      // ── 3. Persist the path so the next call skips the download ────────────
      await HiveService.setDownloadedPath(image.id, filePath);

      return DownloadResult(filePath: filePath, alreadyDownloaded: false);
    } on DioException catch (error) {
      throw Exception(_getDioErrorMessage(error));
    } catch (error) {
      throw Exception('Failed to download image: $error');
    }
  }

  static String _getDioErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Download timed out. Please check your internet connection.';
      case DioExceptionType.badResponse:
        return 'Download failed. Status code: ${error.response?.statusCode}.';
      case DioExceptionType.cancel:
        return 'Download was cancelled.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please try again later.';
      case DioExceptionType.badCertificate:
        return 'Could not verify the server certificate.';
      case DioExceptionType.unknown:
        return 'Unexpected error while downloading image.';
    }
  }
}