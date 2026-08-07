import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_app/services/api_service.dart';

class CreateTransactionPage extends StatefulWidget {
  const CreateTransactionPage({super.key});

  @override
  State<CreateTransactionPage> createState() => _CreateTransactionPageState();
}

class _CreateTransactionPageState extends State<CreateTransactionPage> {
  final _formKey = GlobalKey<FormState>();

  // Transaction fields
  String _selectedType = 'expense'; // 'expense' or 'income'
  String? _selectedCategory;
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  bool _isLoading = false;

  // Categories list
  static const Map<String, IconData> _expenseCategories = {
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

  static const Map<String, IconData> _incomeCategories = {
    'เงินเดือน': Icons.payments,
    'ธุรกิจส่วนตัว': Icons.storefront,
    'การลงทุน': Icons.trending_up,
    'งานฟรีแลนซ์': Icons.work,
    'ของขวัญ / โบนัส': Icons.card_giftcard,
    'รายได้อื่นๆ': Icons.add_circle_outline,
  };

  Map<String, IconData> get _currentCategories =>
      _selectedType == 'expense' ? _expenseCategories : _incomeCategories;

  @override
  void initState() {
    super.initState();
    // Default to first category in the selected type list
    _selectedCategory = _currentCategories.keys.first;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _formatDateYMD(DateTime dt) {
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatDateDMY(DateTime dt) {
    final y = dt.year.toString();
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$d/$m/$y';
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _selectedType == 'expense'
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF10B981),
              onPrimary: Colors.white,
              onSurface: const Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _clearForm() {
    _amountController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _selectedCategory = _currentCategories.keys.first;
    });
    _formKey.currentState?.reset();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      Get.snackbar(
        'แจ้งเตือน',
        'กรุณาเลือกหมวดหมู่รายการ',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFF59E0B),
        colorText: Colors.white,
      );
      return;
    }

    final double? amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      Get.snackbar(
        'แจ้งเตือน',
        'กรุณากรอกจำนวนเงินที่ถูกต้อง (ต้องมากกว่า 0)',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFF59E0B),
        colorText: Colors.white,
      );
      return;
    }

    final String dateFormatted = _formatDateYMD(_selectedDate);
    final String description = _descriptionController.text.trim();

    setState(() {
      _isLoading = true;
    });

    debugPrint('================ [CREATE TRANSACTION LOG] ================');
    debugPrint('Initiating Create Transaction...');
    debugPrint('Type:        $_selectedType');
    debugPrint('Amount:      $amount');
    debugPrint('Category:    $_selectedCategory');
    debugPrint('Description: $description');
    debugPrint('Date:        $dateFormatted');
    debugPrint('==========================================================');

    try {
      final result = await ApiService.createTransaction(
        type: _selectedType,
        amount: amount,
        category: _selectedCategory!,
        description: description.isNotEmpty ? description : null,
        date: dateFormatted,
      );

      debugPrint('================ [CREATE TRANSACTION SUCCESS] ================');
      debugPrint('Result: $result');
      try {
        const encoder = JsonEncoder.withIndent('  ');
        debugPrint('Formatted Response JSON:\n${encoder.convert(result)}');
      } catch (_) {}
      debugPrint('=============================================================');

      Get.snackbar(
        'บันทึกสำเร็จ',
        result['message'] ?? 'เพิ่มรายการเรียบร้อยแล้ว',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFF10B981),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      );

      // Clear all form inputs after successful creation
      _clearForm();
    } catch (e, stackTrace) {
      debugPrint('================ [CREATE TRANSACTION ERROR] ================');
      debugPrint('Error: $e');
      debugPrint('StackTrace:\n$stackTrace');
      debugPrint('============================================================');

      final errorMessage = e.toString().replaceAll('Exception: ', '');
      Get.snackbar(
        'บันทึกไม่สำเร็จ',
        errorMessage,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFEF4444),
        colorText: Colors.white,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _selectedType == 'expense'
        ? const Color(0xFFEF4444) // Red for Expense
        : const Color(0xFF10B981); // Green for Income

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'เพิ่มรายการใหม่',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF0F172A),
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Transaction Type Segment (Income / Expense)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedType = 'expense';
                            _selectedCategory = _expenseCategories.keys.first;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedType == 'expense'
                                ? const Color(0xFFEF4444)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _selectedType == 'expense'
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFEF4444)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.remove_circle_outline,
                                color: _selectedType == 'expense'
                                    ? Colors.white
                                    : const Color(0xFF64748B),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'รายจ่าย (Expense)',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedType == 'expense'
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedType = 'income';
                            _selectedCategory = _incomeCategories.keys.first;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedType == 'income'
                                ? const Color(0xFF10B981)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: _selectedType == 'income'
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF10B981)
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_circle_outline,
                                color: _selectedType == 'income'
                                    ? Colors.white
                                    : const Color(0xFF64748B),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'รายรับ (Income)',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: _selectedType == 'income'
                                      ? Colors.white
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. Amount Input Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'จำนวนเงิน (บาท)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: themeColor,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        hintStyle: const TextStyle(color: Color(0xFFCBD5E1)),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            '฿',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: themeColor,
                            ),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 0,
                          minHeight: 0,
                        ),
                        border: InputBorder.none,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'กรุณากรอกจำนวนเงิน';
                        }
                        final num = double.tryParse(value.trim());
                        if (num == null) {
                          return 'กรุณากรอกตัวเลขที่ถูกต้อง';
                        }
                        if (num <= 0) {
                          return 'จำนวนเงินต้องมากกว่า 0';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 3. Category Selection
              const Text(
                'หมวดหมู่',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    items: _currentCategories.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: themeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                entry.value,
                                size: 20,
                                color: themeColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              entry.key,
                              style: const TextStyle(
                                fontSize: 15,
                                color: Color(0xFF0F172A),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedCategory = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 4. Date Picker Selection
              const Text(
                'วันที่ทำรายการ',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 20,
                            color: themeColor,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _formatDateDMY(_selectedDate),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _formatDateYMD(_selectedDate),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 5. Description Field (Optional)
              const Text(
                'รายละเอียดเพิ่มเติม (ถ้ามี)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  hintText: 'เช่น ค่าอาหารกลางวัน, โบนัสประจำเดือน...',
                  hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: themeColor,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 6. Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              _selectedType == 'expense'
                                  ? 'บันทึกรายจ่าย'
                                  : 'บันทึกรายรับ',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
