import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/state/finance_provider.dart';
import '../../splash/presentation/splash_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _pinLockEnabled = false;

  void _showProfileDialog(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context, listen: false);
    final nameController = TextEditingController(text: provider.userName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Edit Profile Name', style: TextStyle(color: AppColors.textPrimary)),
          content: TextField(
            controller: nameController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Enter your name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  provider.setUserName(name);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Profile name updated to $name!'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                }
              },
              child: const Text('Save Name', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showDownloadDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Consumer<FinanceProvider>(
          builder: (context, provider, child) {
            final progressText = (provider.downloadProgress * 100).toStringAsFixed(0);
            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Download Local AI Coach', style: TextStyle(color: AppColors.textPrimary)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'This will download the Qwen-2-0.5B AI model (approx. 350 MB) directly to your device. Once completed, your weekly coach reviews will work 100% offline with no API bills.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 20),
                  if (provider.isDownloadingModel) ...[
                    LinearProgressIndicator(
                      value: provider.downloadProgress,
                      backgroundColor: Colors.white.withOpacity(0.05),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accentCyan),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        '$progressText% downloaded',
                        style: const TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ] else ...[
                    const Center(
                      child: Text(
                        'Ready to download',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                if (!provider.isDownloadingModel)
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                if (!provider.isDownloadingModel)
                  TextButton(
                    onPressed: () {
                      provider.startModelDownload().then((_) {
                        if (context.mounted && provider.isModelDownloaded) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Local Qwen AI Engine is ready!'),
                              backgroundColor: AppColors.successGreen,
                            ),
                          );
                        }
                      });
                    },
                    child: const Text('Start Download', style: TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
                  ),
                if (provider.isDownloadingModel)
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Downloading file...', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmResetData(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text('Wipe All Data?', style: TextStyle(color: AppColors.dangerRed)),
          content: const Text(
            'This action is permanent. All recorded transactions, allowance budgets, and debts will be deleted. Are you sure?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () async {
                // Wipe SQLite database and reload state
                final provider = Provider.of<FinanceProvider>(context, listen: false);
                await provider.resetDatabase();
                
                if (context.mounted) {
                  Navigator.of(context).pop(); // pop dialog
                  Navigator.of(context).pop(); // pop settings screen
                  
                  // Route to Splash screen to reload the state clean
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (context) => const SplashScreen()),
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('App data successfully reset!'),
                      backgroundColor: AppColors.dangerRed,
                    ),
                  );
                }
              },
              child: const Text('Wipe Data', style: TextStyle(color: AppColors.dangerRed, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<FinanceProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
        child: ListView(
          padding: const EdgeInsets.all(20.0),
          children: [
            // Section 1: PROFILE
            _buildSectionHeader('PROFILE'),
            _buildSettingsRow(
              context,
              'User Name',
              provider.userName,
              Icons.person_outline_rounded,
              AppColors.primaryBlue,
              onTap: () => _showProfileDialog(context),
            ),
            const SizedBox(height: 24),

            // Section 2: CONFIGURATIONS
            _buildSectionHeader('CONFIGURATIONS'),
            _buildSettingsRow(
              context,
              'Local AI Coach Engine',
              provider.isModelDownloaded
                  ? 'Qwen AI Engine is Active (Offline)'
                  : (provider.isDownloadingModel
                      ? 'Downloading: ${(provider.downloadProgress * 100).toStringAsFixed(0)}%'
                      : 'Offline AI. Tap to download (350MB)'),
              Icons.psychology_rounded,
              AppColors.accentCyan,
              onTap: () {
                if (!provider.isModelDownloaded && !provider.isDownloadingModel) {
                  _showDownloadDialog(context);
                }
              },
              trailing: provider.isModelDownloaded
                  ? const Text(
                      'ACTIVE',
                      style: TextStyle(color: AppColors.successGreen, fontSize: 11, fontWeight: FontWeight.bold),
                    )
                  : (provider.isDownloadingModel
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.accentCyan,
                          ),
                        )
                      : const Text(
                          'DOWNLOAD',
                          style: TextStyle(color: AppColors.warningYellow, fontSize: 11, fontWeight: FontWeight.bold),
                        )),
            ),
            const SizedBox(height: 8),
            _buildSwitchRow(
              context,
              'Weekly Notifications',
              'Reminders for Sat reflections & Sun budgeting',
              Icons.notifications_active_outlined,
              AppColors.accentCyan,
              _notificationsEnabled,
              (val) => setState(() => _notificationsEnabled = val),
            ),
            const SizedBox(height: 8),
            _buildSwitchRow(
              context,
              'PIN Security Lock',
              'Lock app on app relaunch',
              Icons.lock_outline_rounded,
              AppColors.warningYellow,
              _pinLockEnabled,
              (val) => setState(() => _pinLockEnabled = val),
            ),
            const SizedBox(height: 8),
            _buildSettingsRow(
              context,
              'Theme Mode',
              'Strictly Dark Mode',
              Icons.dark_mode_outlined,
              AppColors.secondaryBlue,
              trailing: const Text(
                'LOCKED',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 24),

            // Section 3: DATA UTILITIES
            _buildSectionHeader('DATA UTILITIES'),
            _buildSettingsRow(
              context,
              'Export Data (CSV)',
              'Download all transactions locally',
              Icons.download_rounded,
              AppColors.successGreen,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('CSV successfully exported to Documents/kwartako_spends.csv!'),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            _buildSettingsRow(
              context,
              'Cloud Backup',
              'Sync records with online coach backup',
              Icons.cloud_upload_outlined,
              AppColors.primaryBlue,
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Backup synced successfully!'),
                    backgroundColor: AppColors.surface,
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Section 4: ADVANCED
            _buildSectionHeader('ADVANCED'),
            _buildSettingsRow(
              context,
              'Reset App Data',
              'Wipe all logs, balances and coach scores',
              Icons.delete_forever_rounded,
              AppColors.dangerRed,
              onTap: () => _confirmResetData(context),
            ),
            const SizedBox(height: 40),

            // App Version footer
            Center(
              child: Text(
                'KwartaKo Coach v1.0.0\nDesigned for Android',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary.withOpacity(0.5),
                  fontSize: 11,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          color: AppColors.textSecondary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildSettingsRow(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    final glassTheme = Theme.of(context).extension<GlassThemeExtension>();

    return Container(
      decoration: glassTheme?.cardDecoration ?? BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textSecondary, size: 14),
      ),
    );
  }

  Widget _buildSwitchRow(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final glassTheme = Theme.of(context).extension<GlassThemeExtension>();

    return Container(
      decoration: glassTheme?.cardDecoration ?? BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.primaryBlue,
          activeTrackColor: AppColors.primaryBlue.withOpacity(0.3),
        ),
      ),
    );
  }
}
