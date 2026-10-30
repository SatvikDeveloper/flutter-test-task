import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_task/core/network/api_client.dart';
import 'package:test_task/core/network/api_exception.dart';
import 'package:test_task/core/storage/token_storage.dart';
import 'package:test_task/features/auth/domain/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(dioProvider),
    ref.watch(tokenStorageProvider),
  );
});

class AuthRepository {
  AuthRepository(this._dio, this._tokenStorage);

  final Dio _dio;
  final TokenStorage _tokenStorage;

  Future<AuthUser> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/login',
        data: {'username': username, 'password': password},
      );
      final data = response.data;
      if (data == null) {
        throw const ApiException('Login failed. Please try again.');
      }

      final token = data['accessToken'] as String?;
      if (token == null || token.isEmpty) {
        throw const ApiException(
          'Login succeeded but no access token was returned.',
        );
      }

      await _tokenStorage.writeAccessToken(token);
      return AuthUser.fromJson(data);
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }

  Future<bool> hasSession() async {
    final token = await _tokenStorage.readAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> logout() {
    return _tokenStorage.deleteAccessToken();
  }
}
