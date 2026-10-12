import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../errors/app_exception.dart';

class ApiClient {
  ApiClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.apiBaseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 15),
                sendTimeout: const Duration(seconds: 10),
                headers: const {'Accept': 'application/json'},
              ),
            );

  final Dio _dio;

  Future<Map<String, dynamic>> getMap(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await _dio.get<Object?>(path, queryParameters: queryParameters);
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      throw const AppException(code: 'INVALID_RESPONSE', message: 'A API retornou uma resposta inválida.');
    } on DioException catch (error) {
      throw _mapDioError(error);
    }
  }

  AppException _mapDioError(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      return AppException(
        code: map['code']?.toString() ?? 'HTTP_ERROR',
        message: map['message']?.toString() ?? _fallbackMessage(error),
        statusCode: statusCode,
        correlationId: map['correlationId']?.toString(),
      );
    }
    return AppException(
      code: error.type == DioExceptionType.connectionError ? 'CONNECTION_ERROR' : 'HTTP_ERROR',
      message: _fallbackMessage(error),
      statusCode: statusCode,
    );
  }

  String _fallbackMessage(DioException error) => switch (error.type) {
        DioExceptionType.connectionTimeout || DioExceptionType.receiveTimeout || DioExceptionType.sendTimeout => 'A conexão demorou mais que o esperado.',
        DioExceptionType.connectionError => 'Não foi possível conectar ao servidor.',
        _ => 'Não foi possível concluir a solicitação.',
      };
}
