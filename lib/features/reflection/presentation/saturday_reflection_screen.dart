import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/state/finance_provider.dart';
import '../../../core/models/reflection.dart';
import '../../settings/presentation/settings_screen.dart';

class SaturdayReflectionScreen extends StatelessWidget {
  const SaturdayReflectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);
    final reflection = provider.reflection;
    final glassTheme = Theme.of(context).extension<GlassThemeExtension>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekly Reflection'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (provider.isModelDownloaded)
            provider.isGeneratingAI
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: AppColors.accentCyan, strokeWidth: 2),
                      ),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.accentCyan),
                    onPressed: () {
                      provider.generateAICoachFeedback();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('AI Coach is reviewing your week...'),
                          backgroundColor: AppColors.surface,
                        ),
                      );
                    },
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
          padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Tagline
              Center(
                child: Column(
                  children: [
                    Text(
                      'SATURDAY NIGHT REVIEW',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.accentCyan,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Reflect to Grow',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reviewing the week with your finance coach.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 1. Summary Metric Grid Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: glassTheme?.cardDecoration ?? BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSummaryItem(context, 'Allowance', '₱${reflection.allowance.toStringAsFixed(0)}', AppColors.textPrimary),
                        _buildSummaryItem(context, 'Total Spent', '₱${provider.totalSpent.toStringAsFixed(0)}', AppColors.dangerRed),
                        _buildSummaryItem(context, 'Saved', '₱${reflection.savings.toStringAsFixed(0)}', AppColors.successGreen),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Divider(color: Colors.white.withOpacity(0.05), height: 1),
                    const SizedBox(height: 12),
                    // Comparison banner
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.trending_down_rounded, color: AppColors.successGreen, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          reflection.comparisonText,
                          style: const TextStyle(
                            color: AppColors.successGreen,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. Spending Trends Chart (Custom Painted)
              Text(
                'Daily Spending Trend',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 180,
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                decoration: glassTheme?.cardDecoration ?? BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: CustomPaint(
                  painter: ReflectionChartPainter(spending: reflection.dailySpendingTrend),
                ),
              ),
              const SizedBox(height: 24),

              // 3. Top Categories Breakdown
              Text(
                'Top Categories',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: glassTheme?.cardDecoration ?? BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: reflection.topCategories.entries.map((entry) {
                    final percentage = entry.value / (provider.totalSpent > 0 ? provider.totalSpent : 1.0);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                '₱${entry.value.toStringAsFixed(0)} (${(percentage * 100).toStringAsFixed(0)}%)',
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage,
                              minHeight: 6,
                              backgroundColor: Colors.white.withOpacity(0.05),
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryBlue),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 24),

              // 4. Bulletins (Went Well vs Needs Improvement)
              Text(
                'Weekly Coach Bulletin',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _buildBulletinsBox(context, reflection),
              const SizedBox(height: 24),

              // 5. Coach Suggestions
              Text(
                'AI Coach Action Steps',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _buildSuggestionsBox(context, reflection),
              const SizedBox(height: 32),

              // 6. Footer Quote
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    reflection.motivationalQuote,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary.withOpacity(0.7),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(BuildContext context, String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildBulletinsBox(BuildContext context, WeeklyReflection reflection) {
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    final glassTheme = Theme.of(context).extension<GlassThemeExtension>();

    if (provider.isGeneratingAI) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 36),
        alignment: Alignment.center,
        decoration: glassTheme?.cardDecoration ?? BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const CircularProgressIndicator(color: AppColors.accentCyan),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: glassTheme?.cardDecoration ?? BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WHAT WENT WELL',
            style: TextStyle(fontSize: 10, letterSpacing: 1.0, color: AppColors.successGreen, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...reflection.whatWentWell.map((w) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline_rounded, color: AppColors.successGreen, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(w, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary))),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          const Text(
            'NEEDS IMPROVEMENT',
            style: TextStyle(fontSize: 10, letterSpacing: 1.0, color: AppColors.dangerRed, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...reflection.needsImprovement.map((n) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.dangerRed, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(n, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildSuggestionsBox(BuildContext context, WeeklyReflection reflection) {
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    final glassTheme = Theme.of(context).extension<GlassThemeExtension>();

    if (provider.isGeneratingAI) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 36),
        alignment: Alignment.center,
        decoration: glassTheme?.cardDecoration ?? BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const CircularProgressIndicator(color: AppColors.accentCyan),
      );
    }

    if (!provider.isModelDownloaded) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: glassTheme?.cardDecoration ?? BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.warningYellow.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.psychology_rounded, color: AppColors.warningYellow),
                const SizedBox(width: 8),
                Text(
                  'Local AI Coach Offline',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.warningYellow,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Download the local Qwen AI model to get private, 100% offline weekly coach suggestions based on your actual spending!',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 16),
            if (provider.isDownloadingModel) ...[
              LinearProgressIndicator(
                value: provider.downloadProgress,
                backgroundColor: Colors.white.withOpacity(0.05),
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentCyan),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Downloading: ${(provider.downloadProgress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ] else ...[
              ElevatedButton.icon(
                onPressed: () {
                  provider.startModelDownload().then((_) {
                    if (context.mounted && provider.isModelDownloaded) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Local Qwen AI Engine is ready!'),
                          backgroundColor: AppColors.successGreen,
                        ),
                      );
                    }
                  });
                },
                icon: const Icon(Icons.download_rounded, size: 16),
                label: const Text('Download AI Model (350 MB)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentCyan.withOpacity(0.12),
                  foregroundColor: AppColors.accentCyan,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ],
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
        children: reflection.aiCoachSuggestions.map((s) => Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline_rounded, color: AppColors.warningYellow, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s,
                      style: const TextStyle(fontSize: 13, height: 1.3, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            )).toList(),
      ),
    );
  }
}

// Custom Painter to paint a gorgeous smooth line chart with fade gradients
class ReflectionChartPainter extends CustomPainter {
  final List<double> spending;

  ReflectionChartPainter({required this.spending});

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine = Paint()
      ..color = AppColors.primaryBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final paintDot = Paint()
      ..color = AppColors.accentCyan
      ..style = PaintingStyle.fill;

    final paintGrid = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Draw reference horizontal grid lines (max 800 budget helper)
    final gridCount = 4;
    final chartHeight = size.height - 20; // reserve space for text
    for (int i = 0; i <= gridCount; i++) {
      final y = i * (chartHeight / gridCount);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paintGrid);
    }

    if (spending.isEmpty) return;

    // Get max spending to scale graph
    double maxSpent = spending.fold(100.0, (max, val) => val > max ? val : max);
    // Add 15% padding on top
    maxSpent *= 1.15;

    final dayWidth = size.width / 6.0; // 7 days (index 0 to 6)
    final points = <Offset>[];

    for (int i = 0; i < spending.length; i++) {
      final x = i * dayWidth;
      // Flip coordinate since canvas 0 is at top
      final y = chartHeight - (spending[i] / maxSpent) * chartHeight;
      points.add(Offset(x, y));
    }

    // Paint fading gradient under line
    final pathGradient = Path()..moveTo(points.first.dx, chartHeight);
    for (int i = 0; i < points.length; i++) {
      pathGradient.lineTo(points[i].dx, points[i].dy);
    }
    pathGradient.lineTo(points.last.dx, chartHeight);
    pathGradient.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primaryBlue.withOpacity(0.25),
          AppColors.primaryBlue.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, chartHeight))
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(pathGradient, fillPaint);

    // Paint Spline line
    final pathLine = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final controlX = p1.dx + (p2.dx - p1.dx) / 2;
      pathLine.cubicTo(controlX, p1.dy, controlX, p2.dy, p2.dx, p2.dy);
    }
    canvas.drawPath(pathLine, paintLine);

    // Paint Dots & Day Labels
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    for (int i = 0; i < points.length; i++) {
      // Draw Dot
      canvas.drawCircle(points[i], 4, paintDot);
      
      // Draw Glow circle
      paintDot.color = AppColors.accentCyan.withOpacity(0.2);
      canvas.drawCircle(points[i], 8, paintDot);
      paintDot.color = AppColors.accentCyan;

      // Draw Day Label at bottom
      textPainter.text = TextSpan(
        text: days[i],
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(points[i].dx - textPainter.width / 2, size.height - 12));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
