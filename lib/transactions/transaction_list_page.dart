import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_app/services/api_service.dart';
import 'package:get_app/transactions/create_transaction_page.dart';

class TransactionListPage extends StatefulWidget {
  const TransactionListPage({super.key});

  @override
  State<TransactionListPage> createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  bool _isLoading = true;
  String? _errorMessage;

  // Filter state
  String _selectedTypeFilter = 'all'; // 'all', 'income', 'expense'

  // Summary state
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  double _balance = 0.0;

  // Transactions list
  List<dynamic> _transactions = [];

  // Category Icon Resolver
  static final Map<String, IconData> _categoryIcons = {
    'เงินเดือน': Icons.payments,
    'ธุรกิจส่วนตัว': Icons.storefront,
    'การลงทุน': Icons.trending_up,
    'งานฟรีแลนซ์': Icons.work,
    'ของขวัญ / โบนัส': Icons.card_giftcard,
    'รายได้อื่นๆ': Icons.add_circle_outline,
    'อาหารและเครื่องดื่ม': Icons.restaurant,
    'การเดินทาง / น้ำมัน': Icons.directions_car,
    'ช้อปปิ้ง': Icons.shopping_bag,
    'ค่าน้ำ/ค่าไฟ/เน็ต': Icons.receipt_long,
    'ค่าบ้าน / ค่าเช่า': Icons.home,
    'ความบันเทิง': Icons.movie,
    'สุขภาพ / ยา': Icons.medical_services,
    'การศึกษา': Icons.school,
    'รายจ่ายอื่นๆ': Icons.remove_circle_outline,
  };

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ApiService.getTransactions(
        type: _selectedTypeFilter == 'all' ? null : _selectedTypeFilter,
      );

      debugPrint('================ [TRANSACTION LIST DATA] ================');
      try {
        const encoder = JsonEncoder.withIndent('  ');
        debugPrint(encoder.convert(data));
      } catch (_) {}
      debugPrint('========================================================');

      final summary = data['summary'] ?? {};
      final list = data['transactions'] ?? [];

      setState(() {
        _totalIncome = (summary['totalIncome'] ?? 0).toDouble();
        _totalExpense = (summary['totalExpense'] ?? 0).toDouble();
        _balance = (summary['balance'] ?? 0).toDouble();
        _transactions = list;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Fetch Transactions Error: $e');
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmDelete(String id) async {
    final confirm = await Get.defaultDialog<bool>(
      title: 'ยืนยันการลบ',
      middleText: 'คุณต้องการลบรายการนี้ใช่หรือไม่?',
      textConfirm: 'ลบรายการ',
      textCancel: 'ยกเลิก',
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFFEF4444),
      cancelTextColor: const Color(0xFF64748B),
      onConfirm: () => Get.back(result: true),
      onCancel: () => Get.back(result: false),
    );

    if (confirm == true) {
      try {
        final res = await ApiService.deleteTransaction(id);
        Get.snackbar(
          'สำเร็จ',
          res['message'] ?? 'ลบรายการเรียบร้อยแล้ว',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF10B981),
          colorText: Colors.white,
        );
        _fetchTransactions();
      } catch (e) {
        Get.snackbar(
          'เกิดข้อผิดพลาด',
          e.toString().replaceAll('Exception: ', ''),
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFEF4444),
          colorText: Colors.white,
        );
      }
    }
  }

  String _formatCurrency(double num) {
    return num.toStringAsFixed(2).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'รายการบัญชี',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0F172A)),
            onPressed: _fetchTransactions,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Get.to(() => const CreateTransactionPage());
          if (result == true || result == null) {
            _fetchTransactions();
          }
        },
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'เพิ่มรายการ',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTransactions,
        color: const Color(0xFF0F172A),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Summary Cards Section
              _buildSummaryHeader(),

              const SizedBox(height: 20),

              // 2. Type Filter Chips
              _buildFilterChips(),

              const SizedBox(height: 16),

              // 3. Transactions List Section
              _buildTransactionList(),

              const SizedBox(height: 80), // Space for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryHeader() {
    return Column(
      children: [
        // Balance Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ยอดเงินคงเหลือสุทธิ (Balance)',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          size: 14,
                          color: Colors.white70,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'รวมทั้งหมด',
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '฿${_formatCurrency(_balance)}',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: _balance >= 0
                      ? const Color(0xFF34D399)
                      : const Color(0xFFF87171),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Income & Expense Rows
        Row(
          children: [
            // Income Summary Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFA7F3D0)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'รายรับรวม',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF047857),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '฿${_formatCurrency(_totalIncome)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF065F46),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Expense Summary Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_downward_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'รายจ่ายรวม',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB91C1C),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '฿${_formatCurrency(_totalExpense)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF991B1B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'id': 'all', 'label': 'ทั้งหมด'},
      {'id': 'income', 'label': 'รายรับ'},
      {'id': 'expense', 'label': 'รายจ่าย'},
    ];

    return Row(
      children: filters.map((filter) {
        final isSelected = _selectedTypeFilter == filter['id'];
        return Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: ChoiceChip(
            label: Text(filter['label']!),
            selected: isSelected,
            selectedColor: const Color(0xFF0F172A),
            backgroundColor: Colors.white,
            side: BorderSide(
              color: isSelected
                  ? const Color(0xFF0F172A)
                  : const Color(0xFFE2E8F0),
            ),
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF475569),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _selectedTypeFilter = filter['id']!;
                });
                _fetchTransactions();
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTransactionList() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF0F172A)),
        ),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 40),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF991B1B)),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _fetchTransactions,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
              ),
              child: const Text('ลองใหม่อีกครั้ง'),
            ),
          ],
        ),
      );
    }

    if (_transactions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Color(0xFF94A3B8),
            ),
            SizedBox(height: 12),
            Text(
              'ยังไม่มีรายการบัญชีในขณะนี้',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'กดปุ่ม "เพิ่มรายการ" ด้านล่างเพื่อเริ่มสร้างรายการแรกของคุณ',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _transactions.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = _transactions[index];
        final String id = item['id'] ?? '';
        final String type = item['type'] ?? 'expense';
        final bool isExpense = type == 'expense';
        final double amount =
            double.tryParse(item['amount']?.toString() ?? '0') ?? 0.0;
        final String category = item['category'] ?? 'ทั่วไป';
        final String description = item['description'] ?? '';
        final String date = item['date'] ?? '';

        final IconData icon =
            _categoryIcons[category] ??
            (isExpense
                ? Icons.remove_circle_outline
                : Icons.add_circle_outline);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.01),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isExpense
                    ? const Color(0xFFFEF2F2)
                    : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isExpense
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981),
                size: 24,
              ),
            ),
            title: Text(
              category,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${isExpense ? '-' : '+'} ฿${_formatCurrency(amount)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isExpense
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFF94A3B8),
                    size: 20,
                  ),
                  onPressed: () => _confirmDelete(id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
