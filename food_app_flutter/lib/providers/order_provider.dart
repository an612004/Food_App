import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart'; // Required for kIsWeb

final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>(
  (ref) => OrderNotifier(),
);

class OrderState {
  final List<dynamic> orders;
  final bool isLoading;
  final String? error;
  OrderState({this.orders = const [], this.isLoading = false, this.error});
  OrderState copyWith({List<dynamic>? orders, bool? isLoading, String? error}) {
    return OrderState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class OrderNotifier extends StateNotifier<OrderState> {
  OrderNotifier() : super(OrderState());
  Future<void> fetchOrders() async {
    final endpoint = kIsWeb
        ? 'http://127.0.0.1:3000/api/v1/orders/'
        : 'http://10.0.2.2:3000/api/v1/orders/';
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await http
          .get(Uri.parse(endpoint))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final orders = data['data']?['items'] ?? [];
        if (orders is List) {
          state = state.copyWith(orders: orders, isLoading: false);
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
