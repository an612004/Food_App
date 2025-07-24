import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart'; // Required for kIsWeb

final statisticProvider =
    StateNotifierProvider<StatisticNotifier, StatisticState>(
      (ref) => StatisticNotifier(),
    );

class StatisticState {
  final Map<String, dynamic> stats;
  final bool isLoading;
  final String? error;
  StatisticState({this.stats = const {}, this.isLoading = false, this.error});
  StatisticState copyWith({
    Map<String, dynamic>? stats,
    bool? isLoading,
    String? error,
  }) {
    return StatisticState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class StatisticNotifier extends StateNotifier<StatisticState> {
  StatisticNotifier() : super(StatisticState());
  Future<void> fetchStats() async {
    final endpoint = kIsWeb
        ? 'http://127.0.0.1:3000/api/v1/statistics/'
        : 'http://10.0.2.2:3000/api/v1/statistics/';
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await http
          .get(Uri.parse(endpoint))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final stats = data['data'] ?? {};
        if (stats is Map) {
          state = state.copyWith(
            stats: Map<String, dynamic>.from(stats),
            isLoading: false,
          );
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
