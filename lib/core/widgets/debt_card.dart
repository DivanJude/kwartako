import 'package:flutter/material.dart';
import '../models/debt.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

class DebtCard extends StatelessWidget {
  final Debt debt;
  final VoidCallback? onTap;

  const DebtCard({
    super.key,
    required this.debt,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final glassTheme = Theme.of(context).extension<GlassThemeExtension>();
    final progress = debt.progressPercentage;
    final isPaid = debt.status == DebtStatus.paid;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Name and Owed direction tag
                    Expanded(
                      child: Row(
                        children: [
                          // Direction indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: debt.isIOwe 
                                  ? AppColors.dangerRed.withOpacity(0.1) 
                                  : AppColors.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: debt.isIOwe 
                                    ? AppColors.dangerRed.withOpacity(0.3) 
                                    : AppColors.primaryBlue.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              debt.isIOwe ? 'I Owe' : 'Owes Me',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: debt.isIOwe ? AppColors.dangerRed : AppColors.primaryBlue,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              debt.name,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Status Tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: debt.status.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: debt.status.color.withOpacity(0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        debt.status.displayName,
                        style: TextStyle(
                          color: debt.status.color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Owed amount display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPaid ? 'Original Amount' : 'Remaining Balance',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₱${(isPaid ? debt.originalAmount : debt.remainingAmount).toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: isPaid ? AppColors.successGreen : AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                              ),
                        ),
                      ],
                    ),
                    if (!isPaid)
                      Text(
                        'of ₱${debt.originalAmount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 6,
                    backgroundColor: Colors.white.withOpacity(0.05),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isPaid 
                          ? AppColors.successGreen 
                          : (debt.isIOwe ? AppColors.dangerRed : AppColors.primaryBlue),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Due date warning row
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: debt.status == DebtStatus.overdue 
                          ? AppColors.dangerRed 
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isPaid 
                          ? 'Settled' 
                          : 'Due: ${_formatDate(debt.dueDate)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: debt.status == DebtStatus.overdue 
                                ? AppColors.dangerRed 
                                : AppColors.textSecondary,
                            fontWeight: debt.status == DebtStatus.overdue ? FontWeight.w600 : null,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) {
      return 'Today';
    } else if (checkDate == tomorrow) {
      return 'Tomorrow';
    } else {
      return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }
}
