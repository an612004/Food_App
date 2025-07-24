import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart'; // Required for kIsWeb

final userProvider = StateNotifierProvider<UserNotifier, UserState>(
  (ref) => UserNotifier(),
);

class UserState {
  final List<dynamic> users;
  final bool isLoading;
  final String? error;
  UserState({this.users = const [], this.isLoading = false, this.error});
  UserState copyWith({List<dynamic>? users, bool? isLoading, String? error}) {
    return UserState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  UserNotifier() : super(UserState());
  Future<void> fetchUsers() async {
    final endpoint = kIsWeb
        ? 'http://127.0.0.1:3000/api/v1/users/'
        : 'http://10.0.2.2:3000/api/v1/users/';
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await http
          .get(Uri.parse(endpoint))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final users = data['data']?['items'] ?? [];
        if (users is List) {
          state = state.copyWith(users: users, isLoading: false);
        } else {
          state = state.copyWith(
            error: '❌ Lỗi dữ liệu không hợp lệ',
            isLoading: false,
          );
        }
      } else {
        state = state.copyWith(
          error: '❌ API lỗi: ${response.statusCode}',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        error: '❌ Lỗi kết nối hoặc CORS: ${e.toString()}',
        isLoading: false,
      );
    }
  }
}
