import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/state/finance_provider.dart';
import '../../../core/models/expense.dart';
import '../../../core/models/insight.dart';
import '../../../core/widgets/weekly_summary_card.dart';
import '../../../core/widgets/coach_recommendation_card.dart';
import '../../../core/widgets/expense_card.dart';
import '../../transaction/presentation/add_expense_screen.dart';
import '../../reflection/presentation/saturday_reflection_screen.dart';
import '../../settings/presentation/settings_screen.dart';
import '../../planning/presentation/sunday_planning_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final glassTheme = Theme.of(context).extension<GlassThemeExtension>();
    final recentExpenses = provider.expenses.take(3).toList();
    final firstInsight = provider.insights.isNotEmpty 
        ? provider.insights.first 
        : null;

    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.bgGradient,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi, ${provider.userName}!',
                            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formattedDate(),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const SettingsScreen()),
                          );
                        },
                        icon: const Icon(Icons.settings_outlined, color: AppColors.textSecondary, size: 20),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (provider.streakCount > 0) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.warningYellow.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.warningYellow.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.local_fire_department_rounded, color: AppColors.warningYellow, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                '${provider.streakCount}d Streak',
                                style: const TextStyle(color: AppColors.warningYellow, fontWeight: FontWeight.bold, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      GestureDetector(
                        onTap: () => _showDisciplineScoreBreakdown(context, provider),
                        child: _buildDisciplineScoreBadge(context, provider.disciplineScore),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Weekly Summary Metric Card
              WeeklySummaryCard(
                allowance: provider.allowance + provider.weeklyInflow,
                totalSpent: provider.totalSpent,
                remaining: provider.remainingAllowance,
                onReflectTap: () {
                  if (DateTime.now().weekday == DateTime.saturday) {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) => const SaturdayReflectionScreen(),
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
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Saturday Night Reflection is unlocked on Saturday night!'),
                        backgroundColor: AppColors.surface,
                      ),
                    );
                  }
                },
              ),
              if (provider.allowance == 0.0) ...[
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const SundayPlanningScreen()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primaryBlue, AppColors.accentCyan],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Sunday Allowance Planning',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tap to set allowance and generate budget plan!',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 14),
                      ],
                    ),
                  ),
                ),
              ] else if (!provider.expenses.any((e) {
                final now = DateTime.now();
                return e.date.year == now.year && e.date.month == now.month && e.date.day == now.day;
              }) && provider.lastLogDate != "${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}") ...[
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () {
                    provider.checkInNoSpendDay();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🎉 Streak Maintained! Checked in for a No-Spend Day. Keep saving!'),
                        backgroundColor: AppColors.successGreen,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.successGreen, AppColors.accentCyan],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.flash_on_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'No-Spend Day Check-In',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Tap to check-in as a No-Spend Day today and keep your streak alive!',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Quick Actions
              Text(
                'Quick Actions',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _buildQuickActionGrid(context),
              const SizedBox(height: 20),
              _buildQuickLogShortcuts(context, provider),
              const SizedBox(height: 24),

              // Coach Recommendation Card
              Text(
                'Coach Insights',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              if (provider.isGeneratingAI)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  alignment: Alignment.center,
                  decoration: glassTheme?.cardDecoration ?? BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      CircularProgressIndicator(color: AppColors.accentCyan),
                      SizedBox(height: 12),
                      Text(
                        'AI Coach is writing insights...',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                )
              else if (!provider.isModelDownloaded && provider.geminiApiKey.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: glassTheme?.cardDecoration ?? BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.warningYellow.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.psychology_rounded, color: AppColors.warningYellow),
                          const SizedBox(width: 8),
                          Text(
                            'AI Coach Offline',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.warningYellow,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Download the local AI Coach model in Settings to get private, 100% offline spending insights and reflections!',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (context) => const SettingsScreen()),
                          );
                        },
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.accentCyan),
                        label: const Text(
                          'Download in Settings',
                          style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                    ],
                  ),
                )
              else if (firstInsight != null)
                CoachRecommendationCard(
                  title: firstInsight.title,
                  recommendation: firstInsight.description,
                  accentColor: firstInsight.type.color,
                  icon: firstInsight.type.icon,
                )
              else
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  alignment: Alignment.center,
                  decoration: glassTheme?.cardDecoration ?? BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'No insights yet. Log some transactions to get feedback!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
              const SizedBox(height: 24),

              // Recent Transactions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Transactions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton(
                    onPressed: () {
                      provider.setNavigationIndex(1); // Redirect to History tab
                    },
                    child: const Text(
                      'See All',
                      style: TextStyle(color: AppColors.primaryBlue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (recentExpenses.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  width: double.infinity,
                  alignment: Alignment.center,
                  child: Text(
                    'No recent transactions.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                ...recentExpenses.map((expense) => ExpenseCard(expense: expense)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisciplineScoreBadge(BuildContext context, double score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryBlue.withValues(alpha: 0.25),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryBlue.withValues(alpha: 0.04),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: AppColors.primaryBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.psychology_rounded,
              color: Colors.white,
              size: 14,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'DISCIPLINES',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textSecondary,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                '$score/10',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDisciplineScoreBreakdown(BuildContext context, FinanceProvider provider) {
    final spentPenalty = provider.spentRatioPenalty;
    final wantsPenalty = provider.wantsRatioPenalty;
    final overduePenalty = provider.overdueDebtsPenalty;
    final score = provider.disciplineScore;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
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
              Text(
                'Discipline Score Breakdown',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Financial Rank: ${provider.disciplineLevel}',
                style: const TextStyle(
                  color: AppColors.accentCyan,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your score starts at 10.0 and is updated dynamically based on your spending habits and overdue debts.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
               ),
               const SizedBox(height: 20),
               
               // Base Score
               _buildBreakdownRow(context, 'Base Score', 10.0, Colors.white, isBase: true),
               const Divider(color: Colors.white10, height: 20),

               // weekly spent ratio penalty row
               _buildBreakdownRow(
                 context, 
                 'Weekly Allowance Limit', 
                 spentPenalty, 
                 spentPenalty < 0 ? AppColors.dangerRed : AppColors.successGreen,
                 subtitle: spentPenalty < 0 ? 'Overspent weekly allowance' : 'Stayed within weekly budget limit',
               ),
               const SizedBox(height: 12),

               // wants spending ratio penalty row
               _buildBreakdownRow(
                 context, 
                 'Wants Spending Ratio', 
                 wantsPenalty, 
                 wantsPenalty < 0 ? AppColors.dangerRed : AppColors.successGreen,
                 subtitle: wantsPenalty < 0 ? 'More than 30% spent on wants' : 'Wants kept under control',
               ),
               const SizedBox(height: 12),

               // overdue debts penalty row
               _buildBreakdownRow(
                 context, 
                 'Overdue Debts Penalty', 
                 overduePenalty, 
                 overduePenalty < 0 ? AppColors.dangerRed : AppColors.successGreen,
                 subtitle: overduePenalty < 0 ? '${(overduePenalty / -0.5).round()} overdue debts active' : 'No overdue debts',
               ),
               const Divider(color: Colors.white10, height: 20),

               // Final Score Row
               _buildBreakdownRow(context, 'Final Score', score, AppColors.accentCyan, isFinal: true),
               const SizedBox(height: 12),
             ],
           ),
         );
       },
     );
   }

   Widget _buildBreakdownRow(BuildContext context, String title, double val, Color valColor, {String? subtitle, bool isBase = false, bool isFinal = false}) {
     final valStr = isBase ? '10.0' : (isFinal ? '$val/10' : (val == 0.0 ? '0.0' : val.toStringAsFixed(1)));
     return Row(
       mainAxisAlignment: MainAxisAlignment.spaceBetween,
       children: [
         Expanded(
           child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               Text(
                 title,
                 style: TextStyle(
                   fontWeight: (isBase || isFinal) ? FontWeight.bold : FontWeight.normal,
                   fontSize: (isBase || isFinal) ? 14 : 13,
                   color: AppColors.textPrimary,
                 ),
               ),
               if (subtitle != null) ...[
                 const SizedBox(height: 2),
                 Text(
                   subtitle,
                   style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                 ),
               ],
             ],
           ),
         ),
         Text(
           valStr,
           style: TextStyle(
             fontWeight: FontWeight.bold,
             fontSize: (isBase || isFinal) ? 16 : 14,
             color: valColor,
           ),
         ),
       ],
     );
   }

  Widget _buildQuickActionGrid(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionBtn(
          context,
          'Add Expense',
          Icons.add_shopping_cart_rounded,
          AppColors.primaryBlue,
          () {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const AddExpenseScreen(),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  final tween = Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
                      .chain(CurveTween(curve: Curves.easeOutCubic));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
              ),
            );
          },
        ),
        _buildActionBtn(
          context,
          'Add Debt',
          Icons.output_rounded,
          AppColors.dangerRed,
          () => _showAddDebtDialog(context, true),
        ),
        _buildActionBtn(
          context,
          'Add Borrower',
          Icons.input_rounded,
          AppColors.successGreen,
          () => _showAddDebtDialog(context, false),
        ),
        _buildActionBtn(
          context,
          'Reflections',
          Icons.rate_review_rounded,
          AppColors.warningYellow,
          () {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const SaturdayReflectionScreen(),
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
        ),
      ],
    );
  }

  Widget _buildActionBtn(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final glassTheme = Theme.of(context).extension<GlassThemeExtension>();
    
    return SizedBox(
      width: (MediaQuery.of(context).size.width - 70) / 4,
      child: Column(
        children: [
          Container(
            height: 56,
            width: 56,
            decoration: glassTheme?.cardDecoration ?? BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: Center(
                  child: Icon(
                    icon,
                    color: color,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddDebtDialog(BuildContext context, bool isIOwe) {
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    final nameController = TextEditingController();
    final amountController = TextEditingController();
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
                        isIOwe ? 'Record New Debt (I Owe)' : 'Record Borrower (They Owe Me)',
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
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: isIOwe ? 'Lender Name' : 'Borrower Name',
                      hintText: 'e.g., Mark Reyes',
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
                  // Date Picker Selector
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
                        color: Colors.white.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
                          isIOwe: isIOwe,
                          dueDate: selectedDate,
                        );
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Successfully recorded debt for $name!'),
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

  String _formattedDate() {
    final now = DateTime.now();
    const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${days[now.weekday % 7]}, ${months[now.month - 1]} ${now.day}';
  }

  Widget _buildQuickLogShortcuts(BuildContext context, FinanceProvider provider) {
    final glassTheme = Theme.of(context).extension<GlassThemeExtension>();
    
    final List<Map<String, dynamic>> shortcuts = [
      {'name': 'Jeepney ₱15', 'amount': 15.0, 'cat': ExpenseCategory.transportation, 'note': 'Jeepney fare', 'icon': Icons.directions_bus_rounded},
      {'name': 'Coffee ₱50', 'amount': 50.0, 'cat': ExpenseCategory.wants, 'note': 'Coffee', 'icon': Icons.coffee_rounded},
      {'name': 'Lunch ₱100', 'amount': 100.0, 'cat': ExpenseCategory.food, 'note': 'School lunch', 'icon': Icons.lunch_dining_rounded},
      {'name': 'Internet ₱50', 'amount': 50.0, 'cat': ExpenseCategory.others, 'note': 'Mobile data load', 'icon': Icons.wifi_rounded},
      {'name': 'Snacks ₱30', 'amount': 30.0, 'cat': ExpenseCategory.food, 'note': 'Merenda snacks', 'icon': Icons.cookie_rounded},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.flash_on_rounded, color: AppColors.accentCyan, size: 18),
            const SizedBox(width: 6),
            Text(
              'Quick-Log (2-Second Log)',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: shortcuts.length,
            itemBuilder: (context, index) {
              final shortcut = shortcuts[index];
              final ExpenseCategory category = shortcut['cat'] as ExpenseCategory;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: InkWell(
                  onTap: () {
                    provider.addExpense(
                      amount: shortcut['amount'] as double,
                      category: category,
                      note: shortcut['note'] as String,
                      date: DateTime.now(),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Quick-logged: ₱${shortcut['amount']} for "${shortcut['note']}"!'),
                        backgroundColor: AppColors.successGreen,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: glassTheme?.cardDecoration ?? BoxDecoration(
                      color: AppColors.surface.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(shortcut['icon'] as IconData, size: 14, color: category.color),
                        const SizedBox(width: 6),
                        Text(
                          shortcut['name'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: category.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
