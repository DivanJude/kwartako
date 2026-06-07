import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/state/finance_provider.dart';
import '../../../core/widgets/budget_allocation_card.dart';
import '../../../core/models/expense.dart';
import 'budget_allocation_screen.dart';

class SundayPlanningScreen extends StatefulWidget {
  const SundayPlanningScreen({super.key});

  @override
  State<SundayPlanningScreen> createState() => _SundayPlanningScreenState();
}

class _SundayPlanningScreenState extends State<SundayPlanningScreen> {
  final TextEditingController _allowanceController = TextEditingController();
  bool _planGenerated = false;
  double _allowanceAmount = 0.0;

  // Initial recommended allocation ratios
  double _foodRatio = 0.35;
  double _transRatio = 0.15;
  double _schoolRatio = 0.25;
  double _savingsRatio = 0.15;
  double _othersRatio = 0.10;

  @override
  void dispose() {
    _allowanceController.dispose();
    super.dispose();
  }

  void _generatePlan() {
    final amountText = _allowanceController.text.trim();
    final amount = double.tryParse(amountText) ?? 0.0;

    if (amount <= 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an allowance amount greater than ₱100'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
      return;
    }

    setState(() {
      _allowanceAmount = amount;
      _planGenerated = true;
    });
    FocusScope.of(context).unfocus();
  }

  void _saveBudgetPlan() {
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    provider.setAllowance(_allowanceAmount);
    
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New weekly allowance budget of ₱${_allowanceAmount.toStringAsFixed(0)} is active!'),
        backgroundColor: AppColors.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glassTheme = Theme.of(context).extension<GlassThemeExtension>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sunday Planning'),
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
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header description
              Center(
                child: Column(
                  children: [
                    Text(
                      'SUNDAY BUDGET BUILDER',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.accentCyan,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Allowance Planner',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Set and allocate your budget before the week starts.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 1. Allowance Hero Entry Box
              if (!_planGenerated) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: glassTheme?.cardDecoration ?? BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'How much allowance do you have this week?',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      // Large styled text field
                      Row(
                        children: [
                          const Text(
                            '₱',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentCyan,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _allowanceController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                hintText: '0',
                                contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Generate button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _generatePlan,
                          child: const Text('Generate Budget Plan'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Coach Advice Banner
                _buildCoachTipBanner(context),
              ] else ...[
                // Plan is generated, display allocations summary
                _buildGeneratedPlanView(context, glassTheme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoachTipBanner(BuildContext context) {
    final glassTheme = Theme.of(context).extension<GlassThemeExtension>();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: glassTheme?.accentCardDecoration ?? BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, color: AppColors.accentCyan, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coach Tip',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary, fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  'Based on your last 4 weeks, allocating 35% of your allowance to food and saving 15% immediately is recommended.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedPlanView(BuildContext context, GlassThemeExtension? glassTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Total Allowance Display
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: glassTheme?.cardDecoration ?? BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WEEKLY ALLOWANCE TARGET',
                      style: TextStyle(fontSize: 10, letterSpacing: 1.0, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₱${_allowanceAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _planGenerated = false;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text('Edit Amount', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Title and Detailed Adjuster trigger
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recommended Allocations',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => BudgetAllocationScreen(
                      allowanceAmount: _allowanceAmount,
                      initialFoodRatio: _foodRatio,
                      initialTransRatio: _transRatio,
                      initialSchoolRatio: _schoolRatio,
                      initialSavingsRatio: _savingsRatio,
                      initialOthersRatio: _othersRatio,
                    ),
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
              child: const Row(
                children: [
                  Text('Tune Spends', style: TextStyle(color: AppColors.primaryBlue)),
                  Icon(Icons.tune_rounded, color: AppColors.primaryBlue, size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Allocation cards preview
        BudgetAllocationCard(
          category: ExpenseCategory.food,
          allocatedAmount: _allowanceAmount * _foodRatio,
          percentage: _foodRatio,
        ),
        BudgetAllocationCard(
          category: ExpenseCategory.school,
          allocatedAmount: _allowanceAmount * _schoolRatio,
          percentage: _schoolRatio,
        ),
        BudgetAllocationCard(
          category: ExpenseCategory.savings, // mapping emergency color
          allocatedAmount: _allowanceAmount * _savingsRatio,
          percentage: _savingsRatio,
        ),
        BudgetAllocationCard(
          category: ExpenseCategory.transportation,
          allocatedAmount: _allowanceAmount * _transRatio,
          percentage: _transRatio,
        ),
        BudgetAllocationCard(
          category: ExpenseCategory.others,
          allocatedAmount: _allowanceAmount * _othersRatio,
          percentage: _othersRatio,
        ),

        const SizedBox(height: 30),

        // CTA buttons
        SizedBox(
          width: double.infinity,
          height: 56,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: AppColors.accentGradient,
            ),
            child: ElevatedButton(
              onPressed: _saveBudgetPlan,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text(
                'Activate Budget Plan',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
