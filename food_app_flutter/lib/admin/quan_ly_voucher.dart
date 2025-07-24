import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class QuanLyVoucher extends StatefulWidget {
  const QuanLyVoucher({super.key});

  @override
  State<QuanLyVoucher> createState() => _QuanLyVoucherState();
}

class _QuanLyVoucherState extends State<QuanLyVoucher> {
  List<dynamic> _vouchers = [];
  final List<String> _statuses = ['Tất cả', 'Còn hạn', 'Hết hạn', 'Đã sử dụng'];
  String _selectedStatus = 'Tất cả';
  String _search = '';
  bool _sortAsc = true;
  bool _loading = true;

  Future<void> fetchVouchers() async {
    setState(() => _loading = true);
    final endpoint = 'http://10.0.2.2:3000/api/v1/vouchers';
    try {
      final response = await http.get(Uri.parse(endpoint));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _vouchers = data['data']?['items'] ?? [];
      }
    } catch (e) {}
    setState(() => _loading = false);
  }

  List<dynamic> get filteredVouchers {
    var list = _selectedStatus == 'Tất cả'
        ? _vouchers
        : _vouchers.where((e) => e['status'] == _selectedStatus).toList();
    if (_search.isNotEmpty) {
      list = list
          .where((e) =>
              (e['code'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(_search.toLowerCase()) ||
              (e['name'] ?? '')
                  .toString()
                  .toLowerCase()
                  .contains(_search.toLowerCase()))
          .toList();
    }
    list.sort((a, b) => _sortAsc
        ? (a['value'] ?? 0).compareTo(b['value'] ?? 0)
        : (b['value'] ?? 0).compareTo(a['value'] ?? 0));
    return list;
  }

  Future<void> addOrEditVoucher([Map<String, dynamic>? voucher]) async {
    final codeController = TextEditingController(text: voucher?['code'] ?? '');
    final nameController = TextEditingController(text: voucher?['name'] ?? '');
    final valueController =
        TextEditingController(text: voucher?['value']?.toString() ?? '');
    final expireController =
        TextEditingController(text: voucher?['expireDate'] ?? '');
    final isEdit = voucher != null;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Sửa voucher' : 'Thêm voucher'),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Mã voucher'),
              ),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tên voucher'),
              ),
              TextField(
                controller: valueController,
                decoration:
                    const InputDecoration(labelText: 'Giá trị giảm (%)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: expireController,
                decoration: const InputDecoration(
                    labelText: 'Ngày hết hạn (yyyy-mm-dd)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Hủy'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () async {
              final data = {
                'code': codeController.text,
                'name': nameController.text,
                'value': int.tryParse(valueController.text) ?? 0,
                'expireDate': expireController.text,
              };
              final endpoint = isEdit
                  ? 'http://10.0.2.2:3000/api/v1/vouchers/${voucher['id']}'
                  : 'http://10.0.2.2:3000/api/v1/vouchers';
              final method = isEdit ? 'PUT' : 'POST';
              try {
                final request = http.Request(method, Uri.parse(endpoint))
                  ..headers['Content-Type'] = 'application/json'
                  ..body = jsonEncode(data);
                final streamed = await request.send();
                if (streamed.statusCode == 200 || streamed.statusCode == 201) {
                  Navigator.pop(context);
                  await fetchVouchers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(isEdit ? 'Đã lưu!' : 'Đã thêm!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi: ${streamed.statusCode}')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Lỗi: $e')),
                );
              }
            },
            child: Text(isEdit ? 'Lưu' : 'Thêm'),
          ),
        ],
      ),
    );
  }

  Future<void> deleteVoucher(Map<String, dynamic> voucher) async {
    final endpoint = 'http://10.0.2.2:3000/api/v1/vouchers/${voucher['id']}';
    try {
      final response = await http.delete(Uri.parse(endpoint));
      if (response.statusCode == 200) {
        await fetchVouchers();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa voucher!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchVouchers();
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator(color: Colors.orange))
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Quản Lý Voucher',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange)),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange),
                      icon: const Icon(Icons.add, color: Colors.white),
                      label: const Text('Thêm',
                          style: TextStyle(color: Colors.white)),
                      onPressed: () => addOrEditVoucher(),
                    ),
                  ],
                ),
              ),
              // Bộ lọc trạng thái
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _statuses
                      .map((status) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: ChoiceChip(
                              label: Text(status),
                              selected: _selectedStatus == status,
                              selectedColor: Colors.orange,
                              onSelected: (v) {
                                setState(() => _selectedStatus = status);
                              },
                              labelStyle: TextStyle(
                                  color: _selectedStatus == status
                                      ? Colors.white
                                      : Colors.orange),
                            ),
                          ))
                      .toList(),
                ),
              ),
              // Sắp xếp theo giá trị
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Text('Sắp xếp theo giá trị:',
                        style:
                            TextStyle(fontSize: 16, color: Colors.deepOrange)),
                    IconButton(
                      icon: Icon(
                          _sortAsc ? Icons.arrow_upward : Icons.arrow_downward,
                          color: Colors.orange),
                      onPressed: () => setState(() => _sortAsc = !_sortAsc),
                    ),
                    // Tìm kiếm
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm mã/tên voucher...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (v) => setState(() => _search = v),
                      ),
                    ),
                  ],
                ),
              ),
              // Danh sách voucher
              Expanded(
                child: filteredVouchers.isEmpty
                    ? const Center(child: Text('Không có voucher!'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredVouchers.length,
                        itemBuilder: (context, i) {
                          final voucher = filteredVouchers[i];
                          return Card(
                            color: Colors.orange.shade100,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 3,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: const Icon(Icons.card_giftcard,
                                  color: Colors.deepOrange, size: 40),
                              title: Text(voucher['name'] ?? 'Không tên',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.deepOrange)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Mã: ${voucher['code'] ?? ''}',
                                      style: const TextStyle(
                                          color: Colors.orange)),
                                  Text(
                                      'Giá trị: ${voucher['value']?.toString() ?? '0'}%',
                                      style: const TextStyle(
                                          color: Colors.deepOrange)),
                                  Text('Hạn: ${voucher['expireDate'] ?? ''}',
                                      style: const TextStyle(
                                          color: Colors.orange)),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(voucher['status'] ?? '',
                                      style: const TextStyle(
                                          color: Colors.deepOrange,
                                          fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () => addOrEditVoucher(voucher),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete,
                                        color: Colors.red),
                                    onPressed: () => deleteVoucher(voucher),
                                  ),
                                ],
                              ),
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text(voucher['name'] ?? 'Không tên'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text('Mã: ${voucher['code'] ?? ''}'),
                                        Text(
                                            'Giá trị: ${voucher['value']?.toString() ?? '0'}%'),
                                        Text(
                                            'Hạn: ${voucher['expireDate'] ?? ''}'),
                                        Text(
                                            'Trạng thái: ${voucher['status'] ?? ''}'),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        child: const Text('Đóng'),
                                        onPressed: () => Navigator.pop(context),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
  }
}
