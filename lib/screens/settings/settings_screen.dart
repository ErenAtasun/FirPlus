import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';

/// Ayarlar ekranı
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final profile = provider.userProfile;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Ayarlar'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Profil özeti kartı
              if (profile != null) _buildProfileCard(context, profile, provider),

              const SizedBox(height: 24),

              // Ayarlar listesi
              _buildSectionTitle(context, 'Uygulama'),
              _buildSettingItem(
                context,
                icon: Icons.person_outline,
                title: 'Profili Düzenle',
                subtitle: 'Boy, kilo ve hedeflerinizi güncelleyin',
                onTap: () {
                  Navigator.of(context).pushNamed('/profile-wizard', arguments: {'isEditing': true});
                },
              ),
              _buildSettingItem(
                context,
                icon: Icons.flag_outlined,
                title: 'Hedef Güncelle',
                subtitle: 'Günlük kalori hedefiniz: ${profile?.targetCalories ?? 0} kcal',
                onTap: () {
                  Navigator.of(context).pushNamed('/profile-wizard', arguments: {'isEditing': true});
                },
              ),

              const SizedBox(height: 16),
              _buildSectionTitle(context, 'Hakkında'),
              _buildSettingItem(
                context,
                icon: Icons.info_outline,
                title: 'Uygulama Bilgisi',
                subtitle: 'Versiyon ${AppConstants.appVersion}',
                onTap: () => _showAboutDialog(context),
              ),

              const SizedBox(height: 24),

              // İstatistikler
              if (profile != null) _buildStatsCard(context, provider),

              const SizedBox(height: 24),

              // Tehlikeli işlemler
              _buildSectionTitle(context, 'Veri Yönetimi'),
              _buildSettingItem(
                context,
                icon: Icons.delete_forever,
                title: 'Tüm Verileri Sil',
                subtitle: 'Tüm kayıtlarınız silinecek',
                isDestructive: true,
                onTap: () => _confirmClearData(context, provider),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(BuildContext context, dynamic profile, AppProvider provider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(
                  profile.gender == 'erkek' ? Icons.male : Icons.female,
                  size: 36,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Günlük Hedefiniz',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${profile.targetCalories} kcal',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildProfileStat('Boy', '${profile.heightCm.round()} cm'),
              _buildProfileStat('Kilo', '${profile.weightKg.round()} kg'),
              _buildProfileStat('Yaş', '${profile.age}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(BuildContext context, AppProvider provider) {
    final stats = provider.getWeeklyStats();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bu Haftanın Özeti',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                icon: Icons.restaurant,
                value: '${stats['averageCalories']}',
                label: 'Ort. kcal',
                color: AppTheme.primaryColor,
              ),
              _buildStatItem(
                context,
                icon: Icons.check_circle,
                value: '${stats['greenDays']}',
                label: 'Başarılı',
                color: AppTheme.successColor,
              ),
              _buildStatItem(
                context,
                icon: Icons.warning,
                value: '${stats['redDays']}',
                label: 'Aşılan',
                color: AppTheme.errorColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.grey.shade600,
            ),
      ),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isDestructive ? AppTheme.errorColor : AppTheme.primaryColor,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDestructive ? AppTheme.errorColor : null,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: AppConstants.appName,
      applicationVersion: AppConstants.appVersion,
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.restaurant, color: Colors.white, size: 32),
      ),
      children: [
        const Text(
          'Günlük kalori takibi ve sağlıklı beslenme hedeflerinize ulaşmanızı sağlayan uygulama.',
        ),
      ],
    );
  }

  void _confirmClearData(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tüm Verileri Sil'),
        content: const Text(
          'Bu işlem geri alınamaz. Tüm kayıtlarınız (yemekler, günlük loglar, profil) silinecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: Implement clear data
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Bu özellik henüz aktif değil'),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
}
