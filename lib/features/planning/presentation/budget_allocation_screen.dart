import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/state/finance_provider.dart';
import '../../../core/widgets/budget_allocation_card.dart';
import '../../../core/models/expense.dart';

class BudgetAllocationScreen extends StatefulWidget {
  final double allowanceAmount;
  final double initialFoodRatio;
  final double initialTransRatio;
  final double initialSchoolRatio;
  final double initialSavingsRatio;
  final double initialOthersRatio;

  const BudgetAllocationScreen({
    super.key,
    required this.allowanceAmount,
    required this.initialFoodRatio,
    required this.initialTransRatio,
    required this.initialSchoolRatio,
    required this.initialSavingsRatio,
    required this.initialOthersRatio,
  });

  @override
  State<BudgetAllocationScreen> createState() => _BudgetAllocationScreenState();
}

class _BudgetAllocationScreenState extends State<BudgetAllocationScreen> {
  late double _foodRatio;
  late double _transRatio;
  late double _schoolRatio;
  late double _savingsRatio;
  late double _othersRatio;

  @override
  void initState() {
    super.initState();
    _foodRatio = widget.initialFoodRatio;
    _transRatio = widget.initialTransRatio;
    _schoolRatio = widget.initialSchoolRatio;
    _savingsRatio = widget.initialSavingsRatio;
    _othersRatio = widget.initialOthersRatio;
  }

  double get _totalRatio => _foodRatio + _transRatio + _schoolRatio + _savingsRatio + _othersRatio;
  double get _allocatedAmount => widget.allowanceAmount * _totalRatio;
  double get _remainingAmount => widget.allowanceAmount - _allocatedAmount;

  void _saveTunedBudget() {
    if (_totalRatio > 1.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Total allocations cannot exceed 100%! Please reduce spends.'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }

    final provider = Provider.of<FinanceProvider>(context, listen: false);
    provider.saveBudgetPlan(
      allowance: widget.allowanceAmount,
      food: _foodRatio,
      trans: _transRatio,
      school: _schoolRatio,
      savings: _savingsRatio,
      others: _othersRatio,
    );
    
    Navigator.of(context).pop(); // pop tuner
    Navigator.of(context).pop(); // pop planning input
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tuned budget activated! Saved ₱${(widget.allowanceAmount * _savingsRatio).toStringAsFixed(0)} immediately to Savings.'),
        backgroundColor: AppColors.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glassTheme = Theme.of(context).extension<GlassThemeExtension>();
    final isOverLimit = _totalRatio > 1.0;
    final totalPercentage = (_totalRatio * 100).toStringAsFixed(0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spends Tuner'),
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
        child: Column(
          children: [
            // 1. Fixed Header remaining tracker
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              padding: const EdgeInsets.all(20),
              decoration: glassTheme?.accentCardDecoration ?? BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('REMAINING BUDGET', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, letterSpacing: 1.0)),
                          const SizedBox(height: 4),
                          Text(
                            '₱${_remainingAmount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isOverLimit ? AppColors.dangerRed : (_remainingAmount == 0 ? AppColors.successGreen : AppColors.textPrimary),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('ALLOCATED', style: TextStyle(fontSize: 10, color: AppColors.textSecondary, letterSpacing: 1.0)),
                          const SizedBox(height: 4),
                          Text(
                            '$totalPercentage% / 100%',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isOverLimit ? AppColors.dangerRed : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isOverLimit) ...[
                    const SizedBox(height: 12),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: AppColors.dangerRed, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Warning: Allocations exceed 100% allowance!',
                          style: TextStyle(color: AppColors.dangerRed, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // 2. Adjuster list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                children: [
                  BudgetAllocationCard(
                    category: ExpenseCategory.food,
                    allocatedAmount: widget.allowanceAmount * _foodRatio,
                    percentage: _foodRatio,
                    onChanged: (val) {
                      setState(() {
                        _foodRatio = double.parse(val.toStringAsFixed(2));
                      });
                    },
                  ),
                  BudgetAllocationCard(
                    category: ExpenseCategory.school,
                    allocatedAmount: widget.allowanceAmount * _schoolRatio,
                    percentage: _schoolRatio,
                    onChanged: (val) {
                      setState(() {
                        _schoolRatio = double.parse(val.toStringAsFixed(2));
                      });
                    },
                  ),
                  BudgetAllocationCard(
                    category: ExpenseCategory.savings,
                    allocatedAmount: widget.allowanceAmount * _savingsRatio,
                    percentage: _savingsRatio,
                    onChanged: (val) {
                      setState(() {
                        _savingsRatio = double.parse(val.toStringAsFixed(2));
                      });
                    },
                  ),
                  BudgetAllocationCard(
                    category: ExpenseCategory.transportation,
                    allocatedAmount: widget.allowanceAmount * _transRatio,
                    percentage: _transRatio,
                    onChanged: (val) {
                      setState(() {
                        _transRatio = double.parse(val.toStringAsFixed(2));
                      });
                    },
                  ),
                  BudgetAllocationCard(
                    category: ExpenseCategory.others,
                    allocatedAmount: widget.allowanceAmount * _othersRatio,
                    percentage: _othersRatio,
                    onChanged: (val) {
                      setState(() {
                        _othersRatio = double.parse(val.toStringAsFixed(2));
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),

            // 3. CTA Save Button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: isOverLimit ? null : AppColors.accentGradient,
                    color: isOverLimit ? Colors.white.withOpacity(0.04) : null,
                  ),
                  child: ElevatedButton(
                    onPressed: isOverLimit ? null : _saveTunedBudget,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'Save Tuned Budget',
                      style: TextStyle(
                        color: isOverLimit ? AppColors.textSecondary.withOpacity(0.4) : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
