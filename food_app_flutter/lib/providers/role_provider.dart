import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart'; // Required for kIsWeb

// Provider for role
final roleProvider = StateNotifierProvider<RoleNotifier, RoleState>((ref) {
  return RoleNotifier();
});

class RoleState {
  final List<dynamic> roles;
  final bool isLoading;
  final String? error;
  RoleState({this.roles = const [], this.isLoading = false, this.error});
  RoleState copyWith({List<dynamic>? roles, bool? isLoading, String? error}) {
    return RoleState(
      roles: roles ?? this.roles,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class RoleNotifier extends StateNotifier<RoleState> {
  RoleNotifier() : super(RoleState());
  Future<void> fetchRoles() async {
    final endpoint = kIsWeb
        ? 'http://127.0.0.1:3000/api/v1/roles/'
        : 'http://10.0.2.2:3000/api/v1/roles/';
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await http.get(Uri.parse(endpoint)).timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final roles = data['data']?['items'] ?? [];
        if (roles is List) {
          state = state.copyWith(roles: roles, isLoading: false);
        } else {
          state = state.copyWith(error: '❌ Lỗi dữ liệu không hợp lệ', isLoading: false);
        }
      } else {
        state = state.copyWith(error: '❌ API lỗi: ${response.statusCode}', isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(error: '❌ Lỗi kết nối hoặc CORS: ${e.toString()}', isLoading: false);
    }
  }
}