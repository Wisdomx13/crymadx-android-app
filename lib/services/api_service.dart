import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';

/// API Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;
  final String? message;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.error,
    this.message,
    this.statusCode,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromJson,
  ) {
    // Check if there's an error field
    final hasError = json.containsKey('error');

    return ApiResponse(
      success: !hasError,
      data: fromJson != null ? fromJson(json) : json as T?,
      error: json['error']?.toString(),
      message: json['message']?.toString(),
      statusCode: json['statusCode'] as int?,
    );
  }

  factory ApiResponse.success(T? data, {String? message}) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
    );
  }

  factory ApiResponse.error(String error, {int? statusCode}) {
    return ApiResponse(
      success: false,
      error: error,
      statusCode: statusCode,
    );
  }
}

/// Paginated response wrapper
class PaginatedResponse<T> {
  final List<T> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  PaginatedResponse({
    required this.items,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.totalPages,
  });

  factory PaginatedResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return PaginatedResponse(
      items: (json['items'] as List).map((e) => fromJson(e)).toList(),
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      pageSize: json['pageSize'] ?? json['limit'] ?? 20,
      totalPages: json['totalPages'] ?? 1,
    );
  }
}

/// API Error class
class ApiError implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;
  final String? code;

  ApiError({
    required this.message,
    this.statusCode,
    this.data,
    this.code,
  });

  @override
  String toString() => message;
}

/// Main API Service
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isRefreshing = false;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: Duration(milliseconds: ApiConfig.timeout),
        receiveTimeout: Duration(milliseconds: ApiConfig.timeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onResponse: _onResponse,
        onError: _onError,
      ),
    );
  }

  /// Request interceptor - add auth token
  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _storage.read(key: ApiConfig.accessTokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  /// Response interceptor
  void _onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    handler.next(response);
  }

  /// Error interceptor - handle 401 and refresh token
  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    if (error.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshed = await _refreshToken();
        if (refreshed) {
          // Retry the original request
          final token = await _storage.read(key: ApiConfig.accessTokenKey);
          error.requestOptions.headers['Authorization'] = 'Bearer $token';
          final response = await _dio.fetch(error.requestOptions);
          _isRefreshing = false;
          return handler.resolve(response);
        }
      } catch (e) {
        _isRefreshing = false;
      }
    }
    handler.next(error);
  }

  /// Refresh access token
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: ApiConfig.refreshTokenKey);
      if (refreshToken == null) return false;

      final response = await _dio.post(
        ApiConfig.refreshToken,
        data: {'refreshToken': refreshToken},
        options: Options(headers: {'Authorization': null}),
      );

      final data = response.data;
      if (data != null && data['tokens'] != null) {
        await _storage.write(
          key: ApiConfig.accessTokenKey,
          value: data['tokens']['accessToken'],
        );
        if (data['tokens']['refreshToken'] != null) {
          await _storage.write(
            key: ApiConfig.refreshTokenKey,
            value: data['tokens']['refreshToken'],
          );
        }
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Save tokens after login
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: ApiConfig.accessTokenKey, value: accessToken);
    await _storage.write(key: ApiConfig.refreshTokenKey, value: refreshToken);
  }

  /// Save user ID
  Future<void> saveUserId(String userId) async {
    await _storage.write(key: ApiConfig.userIdKey, value: userId);
  }

  /// Get saved user ID
  Future<String?> getUserId() async {
    return await _storage.read(key: ApiConfig.userIdKey);
  }

  /// Clear tokens on logout
  Future<void> clearTokens() async {
    await _storage.delete(key: ApiConfig.accessTokenKey);
    await _storage.delete(key: ApiConfig.refreshTokenKey);
    await _storage.delete(key: ApiConfig.userIdKey);
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _storage.read(key: ApiConfig.accessTokenKey);
    return token != null;
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    return await _storage.read(key: ApiConfig.accessTokenKey);
  }

  /// GET request - returns raw response data
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// POST request - returns raw response data
  Future<dynamic> post(
    String path, {
    dynamic data,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(path, data: data, options: options);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PUT request - returns raw response data
  Future<dynamic> put(
    String path, {
    dynamic data,
  }) async {
    try {
      final response = await _dio.put(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PATCH request - returns raw response data
  Future<dynamic> patch(
    String path, {
    dynamic data,
  }) async {
    try {
      final response = await _dio.patch(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE request - returns raw response data
  Future<dynamic> delete(
    String path, {
    dynamic data,
  }) async {
    try {
      final response = await _dio.delete(path, data: data);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Upload file with multipart form data
  Future<dynamic> uploadMultipart(
    String path, {
    required FormData formData,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Handle Dio errors
  ApiError _handleError(DioException error) {
    String message = 'An error occurred';
    String? code;
    int? statusCode = error.response?.statusCode;

    if (error.response?.data != null) {
      final data = error.response!.data;
      if (data is Map<String, dynamic>) {
        // Handle nested error object: {error: {code, message}}
        if (data['error'] is Map<String, dynamic>) {
          final errorObj = data['error'] as Map<String, dynamic>;
          message = errorObj['message'] ?? message;
          code = errorObj['code']?.toString();
        } else if (data['error'] is String) {
          message = data['error'];
        } else {
          message = data['message'] ?? message;
        }
        code ??= data['code']?.toString();
      } else if (data is String) {
        message = data;
      }
    } else {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message = 'Connection timeout. Please try again.';
          break;
        case DioExceptionType.connectionError:
          message = 'Unable to connect to server. Please check your internet connection.';
          break;
        case DioExceptionType.cancel:
          message = 'Request cancelled.';
          break;
        default:
          message = error.message ?? message;
      }
    }

    // Map common error codes/messages to user-friendly messages
    message = _mapErrorMessage(message, code, statusCode);

    return ApiError(
      message: message,
      statusCode: statusCode,
      data: error.response?.data,
      code: code,
    );
  }

  /// Map error codes and messages to user-friendly messages
  String _mapErrorMessage(String message, String? code, int? statusCode) {
    final lowerMessage = message.toLowerCase();
    final lowerCode = code?.toLowerCase() ?? '';

    // Duplicate email
    if (lowerMessage.contains('already exist') ||
        lowerMessage.contains('already registered') ||
        lowerMessage.contains('duplicate') ||
        lowerCode.contains('duplicate') ||
        lowerCode.contains('conflict') ||
        (statusCode == 409)) {
      return 'This email is already registered. Please sign in or use a different email.';
    }

    // Email not verified
    if (lowerMessage.contains('not verified') ||
        lowerMessage.contains('verify your email') ||
        lowerCode.contains('unverified')) {
      return 'Email not verified. Please check your email for verification code.';
    }

    // Invalid credentials
    if (lowerMessage.contains('invalid credentials') ||
        lowerMessage.contains('invalid password') ||
        lowerMessage.contains('wrong password') ||
        lowerCode.contains('invalid_credentials')) {
      return 'Invalid email or password. Please try again.';
    }

    // User not found
    if (lowerMessage.contains('user not found') ||
        lowerMessage.contains('no user') ||
        lowerCode.contains('user_not_found')) {
      return 'No account found with this email. Please register first.';
    }

    // Internal server error
    if (lowerMessage.contains('internal') && statusCode == 500) {
      return 'Something went wrong. Please try again later.';
    }

    return message;
  }
}

/// Global API instance
final api = ApiService();
