import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/state/finance_provider.dart';
import '../../../core/models/expense.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  
  ExpenseCategory _selectedCategory = ExpenseCategory.food;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _saveExpense() {
    final amountText = _amountController.text.trim().replaceAll(',', '');
    final amount = double.tryParse(amountText) ?? 0.0;
    final note = _noteController.text.trim();

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount greater than 0'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }

    final provider = Provider.of<FinanceProvider>(context, listen: false);

    // Check if category budget is exceeded
    if (provider.allowance > 0.0) {
      final budget = provider.getCategoryBudget(_selectedCategory);
      final currentSpent = provider.getCategorySpent(_selectedCategory);
      if (currentSpent + amount > budget) {
        final overspend = (currentSpent + amount) - budget;
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('⚠️ Budget Warning', style: TextStyle(color: AppColors.warningYellow)),
              content: Text(
                'This expense will exceed your weekly budget for ${_selectedCategory.displayName} by ₱${overspend.toStringAsFixed(2)}.\n\nAre you sure you want to log it?',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // close warning dialog
                    _executeSave(provider, amount, note);
                  },
                  child: const Text('Log Anyway', style: TextStyle(color: AppColors.dangerRed, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
        return;
      }
    }

    _executeSave(provider, amount, note);
  }

  void _executeSave(FinanceProvider provider, double amount, String note) {
    provider.addExpense(
      amount: amount,
      category: _selectedCategory,
      note: note.isEmpty ? _selectedCategory.displayName : note,
      date: _selectedDate,
    );

    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged ₱${amount.toStringAsFixed(2)} under ${_selectedCategory.displayName}!'),
        backgroundColor: AppColors.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final glassTheme = Theme.of(context).extension<GlassThemeExtension>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Expense'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.bgGradient,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Amount Display Section
              Center(
                child: Column(
                  children: [
                    Text(
                      'HOW MUCH DID YOU SPEND?',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 12),
                    // Glassmorphic Amount input box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: glassTheme?.inputDecoration ?? BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      width: size.width * 0.8,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            '₱',
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentCyan,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _amountController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              textAlign: TextAlign.center,
                              autofocus: true,
                              style: const TextStyle(
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                hintText: '0.00',
                                hintStyle: TextStyle(color: AppColors.textSecondary),
                                filled: false,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 2. Horizontal Category Selector
              Text(
                'Category',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 52,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: ExpenseCategory.values.length,
                  itemBuilder: (context, index) {
                    final category = ExpenseCategory.values[index];
                    final isSelected = _selectedCategory == category;
                    final catColor = category.color;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedCategory = category;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? catColor.withOpacity(0.12) : AppColors.surface.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? catColor : Colors.white.withOpacity(0.05),
                            width: 1.2,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: catColor.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ] : null,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              category.icon,
                              color: isSelected ? catColor : AppColors.textSecondary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              category.displayName,
                              style: TextStyle(
                                color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // 3. Note Text Field
              Text(
                'Note',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                maxLength: 100,
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                decoration: const InputDecoration(
                  hintText: 'What did you buy? e.g., Chicken Joy, Jeepney, Books',
                ),
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 24),

              // 4. Date Picker Selection
              Text(
                'Date',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now(),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.dark(
                            primary: AppColors.primaryBlue,
                            surface: AppColors.surface,
                            onPrimary: Colors.white,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedDate = picked;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, color: AppColors.accentCyan),
                          const SizedBox(width: 12),
                          Text(
                            '${_getMonthName(_selectedDate.month)} ${_selectedDate.day}, ${_selectedDate.year}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // 5. Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: AppColors.accentGradient,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryBlue.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _saveExpense,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Save Transaction',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }
}
