import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/state/finance_provider.dart';
import '../../../core/models/debt.dart';

class DebtDetailScreen extends StatelessWidget {
  final String debtId;

  const DebtDetailScreen({
    super.key,
    required this.debtId,
  });

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final glassTheme = Theme.of(context).extension<GlassThemeExtension>();

    // Retrieve active debt
    final debtIndex = provider.debts.indexWhere((d) => d.id == debtId);
    if (debtIndex == -1) {
      return Scaffold(
        appBar: AppBar(title: const Text('Debt Not Found')),
        body: const Center(child: Text('Requested record could not be found.')),
      );
    }
    
    final debt = provider.debts[debtIndex];
    final isPaid = debt.status == DebtStatus.paid;
    final progress = debt.progressPercentage;

    void confirmDeleteDebt(BuildContext context, FinanceProvider provider) {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text('Delete this record?', style: TextStyle(color: AppColors.dangerRed)),
            content: const Text(
              'This action is permanent and will wipe this debt ledger and all payment logs.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
              ),
              TextButton(
                onPressed: () {
                  provider.deleteDebt(debtId);
                  Navigator.of(context).pop(); // pop dialog
                  Navigator.of(context).pop(); // pop detail screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Debt record deleted successfully.'),
                      backgroundColor: AppColors.dangerRed,
                    ),
                  );
                },
                child: const Text('Delete', style: TextStyle(color: AppColors.dangerRed, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(debt.isIOwe ? 'Debt Details' : 'Borrower Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever_rounded, color: AppColors.dangerRed),
            onPressed: () => confirmDeleteDebt(context, provider),
          ),
        ],
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Hero Balance Details Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: glassTheme?.cardDecoration ?? BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    // Icon indicator
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (debt.isIOwe ? AppColors.dangerRed : AppColors.primaryBlue).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        debt.isIOwe ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        color: debt.isIOwe ? AppColors.dangerRed : AppColors.primaryBlue,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Name and Tag
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          debt.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                        ),
                        const SizedBox(width: 8),
                        // Status Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: debt.status.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: debt.status.color.withOpacity(0.3)),
                          ),
                          child: Text(
                            debt.status.displayName,
                            style: TextStyle(color: debt.status.color, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Remaining vs Original Amounts
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricDisplay(
                          context,
                          'REMAINDER',
                          '₱${debt.remainingAmount.toStringAsFixed(2)}',
                          isPaid ? AppColors.successGreen : AppColors.textPrimary,
                        ),
                        Container(width: 1, height: 40, color: Colors.white.withOpacity(0.05)),
                        _buildMetricDisplay(
                          context,
                          'ORIGINAL',
                          '₱${debt.originalAmount.toStringAsFixed(2)}',
                          AppColors.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Progress line
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.white.withOpacity(0.05),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isPaid 
                              ? AppColors.successGreen 
                              : (debt.isIOwe ? AppColors.dangerRed : AppColors.primaryBlue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}% paid off',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // 2. Vertical Payment History Timeline
              Text(
                'Payment History',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              if (debt.payments.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  alignment: Alignment.center,
                  child: Text(
                    'No payments recorded yet.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                _buildTimelineList(context, debt.payments, debt.isIOwe, provider),
              
              const SizedBox(height: 40),

              // 3. Action Buttons Section
              if (!isPaid) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showPayDialog(context, provider, debt),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.primaryBlue),
                        ),
                        child: const Text('Pay Partial', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _confirmFullPay(context, provider),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppColors.successGreen,
                        ),
                        child: const Text('Mark Fully Paid', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricDisplay(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, letterSpacing: 1.0, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
        ),
      ],
    );
  }

  Widget _buildTimelineList(BuildContext context, List<DebtPayment> payments, bool isIOwe, FinanceProvider provider) {
    return Column(
      children: List.generate(payments.length, (index) {
        final payment = payments[index];
        final isLast = index == payments.length - 1;

        return Dismissible(
          key: Key(payment.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.dangerRed.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.dangerRed.withOpacity(0.2)),
            ),
            child: const Icon(Icons.delete_forever_rounded, color: AppColors.dangerRed),
          ),
          confirmDismiss: (direction) async {
            return await showDialog<bool>(
              context: context,
              builder: (context) {
                return AlertDialog(
                  backgroundColor: AppColors.surface,
                  title: const Text('Delete Payment Record?', style: TextStyle(color: AppColors.dangerRed)),
                  content: Text(
                    'Are you sure you want to delete this payment of ₱${payment.amount.toStringAsFixed(2)}? This will restore the outstanding balance.',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Delete', style: TextStyle(color: AppColors.dangerRed, fontWeight: FontWeight.bold)),
                    ),
                  ],
                );
              },
            ) ?? false;
          },
          onDismissed: (direction) {
            provider.deleteDebtPayment(debtId, payment.id);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Deleted payment of ₱${payment.amount.toStringAsFixed(2)}'),
                backgroundColor: AppColors.dangerRed,
              ),
            );
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Node indicator
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: AppColors.successGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 48,
                      color: Colors.white.withOpacity(0.08),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              // Right Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isIOwe ? 'Payment Made' : 'Payment Received',
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '₱${payment.amount.toStringAsFixed(2)}',
                          style: const TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${payment.date.month}/${payment.date.day}/${payment.date.year}',
                      style: TextStyle(color: AppColors.textSecondary.withOpacity(0.7), fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  void _showPayDialog(BuildContext context, FinanceProvider provider, Debt debt) {
    final payController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Add Partial Payment', style: TextStyle(color: AppColors.textPrimary)),
          content: TextField(
            controller: payController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              prefixText: '₱ ',
              hintText: '0.00',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                final amountText = payController.text.trim().replaceAll(',', '');
                final amount = double.tryParse(amountText) ?? 0.0;
                if (amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid amount greater than 0'),
                      backgroundColor: AppColors.dangerRed,
                    ),
                  );
                  return;
                }
                if (amount > debt.remainingAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Payment cannot exceed outstanding balance of ₱${debt.remainingAmount.toStringAsFixed(2)}'),
                      backgroundColor: AppColors.dangerRed,
                    ),
                  );
                  return;
                }
                provider.payPartialDebt(debtId, amount);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Successfully logged payment of ₱${amount.toStringAsFixed(2)}!'),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              },
              child: const Text('Save Payment', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _confirmFullPay(BuildContext context, FinanceProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Mark as Fully Paid', style: TextStyle(color: AppColors.textPrimary)),
          content: const Text('Are you sure you want to mark this debt as settled? This will record the remaining balance as paid.', style: TextStyle(color: AppColors.textSecondary)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                provider.markDebtAsPaid(debtId);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Debt marked as fully paid!'),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              },
              child: const Text('Settle', style: TextStyle(color: AppColors.successGreen, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
