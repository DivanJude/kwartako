import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/state/finance_provider.dart';
import '../../../core/models/expense.dart';
import '../../../core/widgets/insight_card.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);

    // Calculate category spending breakdown
    final Map<ExpenseCategory, double> catSpent = {};
    for (final exp in provider.weeklyExpenses) {
      catSpent[exp.category] = (catSpent[exp.category] ?? 0.0) + exp.amount;
    }

    // Determine most expensive category
    ExpenseCategory? mostExpCategory;
    double maxExpAmount = 0.0;
    catSpent.forEach((cat, amt) {
      if (amt > maxExpAmount) {
        maxExpAmount = amt;
        mostExpCategory = cat;
      }
    });

    // Count small expenses (< ₱50)
    final smallExpenses = provider.weeklyExpenses.where((e) => e.amount < 50.0).toList();
    final totalSmallSum = smallExpenses.fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.bgGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Title
                Text(
                  'Diagnostic Insights',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),

                // Grid layout of analysis blocks
                _buildAnalysisGrid(context, mostExpCategory, maxExpAmount, smallExpenses.length, totalSmallSum, provider.totalIOwe, provider.streakCount),
                const SizedBox(height: 24),

                // Segment title
                Text(
                  'Coach Recommendations',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),

                // Render dynamic Coach Insight Cards from Provider
                if (provider.insights.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Text(
                        'Your finances look healthy! No diagnostic alerts today.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  ...provider.insights.map((insight) => InsightCard(insight: insight)),
                
                const SizedBox(height: 24),

                // Spend category breakdown list
                Text(
                  'Spending Category Breakdown',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                _buildCategoryBreakdownList(context, provider, catSpent, provider.totalSpent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisGrid(
    BuildContext context,
    ExpenseCategory? topCat,
    double topAmt,
    int smallCount,
    double smallSum,
    double overdueAmt,
    int streakCount,
  ) {
    final glassTheme = Theme.of(context).extension<GlassThemeExtension>();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.15,
      children: [
        // Card 1: Most Expensive Category
        _buildGridCard(
          context,
          'Top Spending',
          topCat != null ? topCat.displayName : 'None',
          '₱${topAmt.toStringAsFixed(0)} logged',
          Icons.shopping_bag_rounded,
          AppColors.dangerRed,
          glassTheme,
        ),
        // Card 2: Small Expense Detector
        _buildGridCard(
          context,
          'Micro-Leaks',
          '$smallCount Spends < ₱50',
          'Totaling ₱${smallSum.toStringAsFixed(0)}',
          Icons.warning_amber_rounded,
          AppColors.warningYellow,
          glassTheme,
        ),
        // Card 3: Logging Streak
        _buildGridCard(
          context,
          'Logging Streak',
          '$streakCount Day${streakCount == 1 ? "" : "s"}',
          streakCount > 0 ? 'Keep logging daily! 🔥' : 'Log daily to start a streak',
          Icons.local_fire_department_rounded,
          AppColors.warningYellow,
          glassTheme,
        ),
        // Card 4: Urgent Debt Reminders
        _buildGridCard(
          context,
          'Owed Reminders',
          '₱${overdueAmt.toStringAsFixed(0)} Owed',
          overdueAmt > 0 ? 'Urgent settle due' : 'All clear',
          Icons.alarm_rounded,
          overdueAmt > 0 ? AppColors.dangerRed : AppColors.successGreen,
          glassTheme,
        ),
      ],
    );
  }

  Widget _buildGridCard(
    BuildContext context,
    String label,
    String value,
    String subtitle,
    IconData icon,
    Color accentColor,
    GlassThemeExtension? glassTheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: glassTheme?.cardDecoration ?? BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              ),
              Icon(icon, color: accentColor, size: 20),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.8), fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdownList(
    BuildContext context,
    FinanceProvider provider,
    Map<ExpenseCategory, double> catSpent,
    double totalSpent,
  ) {
    final glassTheme = Theme.of(context).extension<GlassThemeExtension>();
    
    // Sort categories by amount descending
    final sortedEntries = catSpent.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedEntries.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        alignment: Alignment.center,
        child: const Text(
          'No expenditures logged yet.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: glassTheme?.cardDecoration ?? BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: sortedEntries.map((entry) {
          final category = entry.key;
          final amount = entry.value;

          // Check if category has a finite budget limit
          final budget = provider.getCategoryBudget(category);
          final bool hasBudget = provider.allowance > 0 && budget > 0 && budget != double.infinity;
          final bool isOverspent = hasBudget && amount > budget;

          final double ratio;
          final String trailingText;
          final Color barColor;

          if (hasBudget) {
            ratio = (amount / budget).clamp(0.0, 1.0);
            trailingText = '₱${amount.toStringAsFixed(0)} of ₱${budget.toStringAsFixed(0)}';
            barColor = isOverspent ? AppColors.dangerRed : category.color;
          } else {
            final percentageRatio = totalSpent > 0 ? amount / totalSpent : 0.0;
            ratio = percentageRatio;
            final percentageStr = (percentageRatio * 100).toStringAsFixed(0);
            trailingText = '₱${amount.toStringAsFixed(0)} ($percentageStr%)';
            barColor = category.color;
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              children: [
                // Category Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: barColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(category.icon, color: barColor, size: 16),
                ),
                const SizedBox(width: 12),
                // Text details & progress bar
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                category.displayName,
                                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              if (isOverspent) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppColors.dangerRed.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.dangerRed.withValues(alpha: 0.3), width: 0.8),
                                  ),
                                  child: const Text(
                                    'OVERSPENT',
                                    style: TextStyle(color: AppColors.dangerRed, fontSize: 8, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            trailingText,
                            style: TextStyle(
                              color: isOverspent ? AppColors.dangerRed : AppColors.textSecondary,
                              fontWeight: isOverspent ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio,
                          minHeight: 4,
                          backgroundColor: Colors.white.withValues(alpha: 0.04),
                          valueColor: AlwaysStoppedAnimation<Color>(barColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
