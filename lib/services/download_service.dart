import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

import '../models/image_model.dart';

class DownloadService {
  DownloadService._();

  static final Dio _dio = Dio();

  /// Downloads the selected image into the app documents directory.
  ///
  /// Platform-specific gallery saving can be added later without changing
  /// the screen code, because all download behavior is isolated here.
  static Future<String> downloadImage(ImageModel image) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final String filePath = '${directory.path}/picsum_${image.id}.jpg';

      await _dio.download(image.downloadUrl, filePath);

      return filePath;
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