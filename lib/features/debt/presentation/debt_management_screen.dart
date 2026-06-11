import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/state/finance_provider.dart';
import '../../../core/models/debt.dart';
import '../../../core/widgets/debt_card.dart';
import 'debt_detail_screen.dart';

class DebtManagementScreen extends StatefulWidget {
  const DebtManagementScreen({super.key});

  @override
  State<DebtManagementScreen> createState() => _DebtManagementScreenState();
}

class _DebtManagementScreenState extends State<DebtManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);

    final iOweDebts = provider.debts.where((d) => d.isIOwe).toList();
    final theyOweMeDebts = provider.debts.where((d) => !d.isIOwe).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.bgGradient,
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Header
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 16),
                child: Text(
                  'Debts & Borrows',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              const SizedBox(height: 16),

              // Custom styled Glassmorphic TabBar Container
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.05),
                    width: 1.0,
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    gradient: AppColors.accentGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.arrow_downward_rounded, size: 16),
                          const SizedBox(width: 6),
                          Text('I Owe (₱${provider.totalIOwe.toStringAsFixed(0)})'),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.arrow_upward_rounded, size: 16),
                          const SizedBox(width: 6),
                          Text('Owes Me (₱${provider.totalOwedToMe.toStringAsFixed(0)})'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Tab View
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: I Owe List
                    _buildDebtList(context, iOweDebts, true),
                    // Tab 2: Owes Me List
                    _buildDebtList(context, theyOweMeDebts, false),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      // Floating Action Button to log a new debt/borrower
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Raise FAB above BottomNavBar
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.accentGradient,
          ),
          child: FloatingActionButton(
            onPressed: () => _showAddDebtDialog(context),
            backgroundColor: Colors.transparent,
            elevation: 0,
            shape: const CircleBorder(),
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildDebtList(BuildContext context, List<Debt> debts, bool isIOwe) {
    if (debts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isIOwe ? Icons.assignment_turned_in_rounded : Icons.check_circle_rounded,
                color: AppColors.textSecondary,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isIOwe ? 'You have no active debts!' : 'No one owes you money!',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap the (+) button below to log a record.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 90, top: 4),
      itemCount: debts.length,
      itemBuilder: (context, index) {
        final debt = debts[index];
        return DebtCard(
          debt: debt,
          onTap: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => DebtDetailScreen(debtId: debt.id),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  final tween = Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                      .chain(CurveTween(curve: Curves.easeOutCubic));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _showAddDebtDialog(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    bool isIOweOption = _tabController.index == 0;
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isIOweOption ? 'Record New Debt (I Owe)' : 'Record Borrower (They Owe)',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Option Segment selector
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => isIOweOption = true),
                          child: Container(
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isIOweOption ? AppColors.dangerRed.withOpacity(0.12) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isIOweOption ? AppColors.dangerRed : Colors.white.withOpacity(0.05),
                              ),
                            ),
                            child: const Text('I Owe', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => isIOweOption = false),
                          child: Container(
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: !isIOweOption ? AppColors.primaryBlue.withOpacity(0.12) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: !isIOweOption ? AppColors.primaryBlue : Colors.white.withOpacity(0.05),
                              ),
                            ),
                            child: const Text('Owes Me', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: isIOweOption ? 'Lender Name' : 'Borrower Name',
                      hintText: 'e.g., Ate Maria or Jose',
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount',
                      prefixText: '₱ ',
                      hintText: '0.00',
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  // Date Picker
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
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
                          selectedDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded, color: AppColors.primaryBlue),
                              const SizedBox(width: 12),
                              Text(
                                'Due Date: ${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
                                style: const TextStyle(color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          const Text(
                            'Change',
                            style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        final name = nameController.text.trim();
                        final amountText = amountController.text.trim().replaceAll(',', '');
                        final amount = double.tryParse(amountText) ?? 0.0;
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter a valid name.'),
                              backgroundColor: AppColors.dangerRed,
                            ),
                          );
                          return;
                        }
                        if (amount <= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter an amount greater than 0.'),
                              backgroundColor: AppColors.dangerRed,
                            ),
                          );
                          return;
                        }
                        provider.addDebt(
                          name: name,
                          amount: amount,
                          isIOwe: isIOweOption,
                          dueDate: selectedDate,
                        );
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Successfully logged debt for $name!'),
                            backgroundColor: AppColors.successGreen,
                          ),
                        );
                      },
                      child: const Text('Save Record'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
