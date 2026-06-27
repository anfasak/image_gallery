import 'package:dio/dio.dart';

import '../models/image_model.dart';

class ApiService {
  ApiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: _baseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 10),
                responseType: ResponseType.json,
              ),
            );

  static const String _baseUrl = 'https://picsum.photos';

  final Dio _dio;

  /// Fetches a list of images from the Picsum Photos API.
  ///
  /// Throws an [Exception] with a readable message if the request fails,
  /// the server returns an unexpected status code, or the response format
  /// cannot be parsed.
  Future<List<ImageModel>> fetchImages() async {
    try {
      final Response<dynamic> response = await _dio.get('/v2/list');

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch images. Status code: ${response.statusCode}.',
        );
      }

      final dynamic data = response.data;

      if (data is! List) {
        throw Exception('Failed to fetch images. Invalid response format.');
      }

      return data
          .map(
            (dynamic item) =>
                ImageModel.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false);
    } on DioException catch (error) {
      throw Exception(_getDioErrorMessage(error));
    } on TypeError catch (_) {
      throw Exception('Failed to fetch images. Invalid image data received.');
    } catch (error) {
      throw Exception('Failed to fetch images: $error');
    }
  }

  String _getDioErrorMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Request timed out. Please check your internet connection.';
      case DioExceptionType.badResponse:
        return 'Server error while fetching images. Status code: '
            '${error.response?.statusCode}.';
      case DioExceptionType.cancel:
        return 'Image request was cancelled.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Please try again later.';
      case DioExceptionType.badCertificate:
        return 'Could not verify the server certificate.';
      case DioExceptionType.unknown:
        return 'Unexpected network error while fetching images.';
    }
  }
}