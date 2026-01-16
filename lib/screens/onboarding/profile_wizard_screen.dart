import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../services/calorie_calculator.dart';

/// Profil ve Hedef Sihirbazı
/// İlk kurulum için kullanıcı bilgilerini toplar
class ProfileWizardScreen extends StatefulWidget {
  final bool isEditing;

  const ProfileWizardScreen({super.key, this.isEditing = false});

  @override
  State<ProfileWizardScreen> createState() => _ProfileWizardScreenState();
}

class _ProfileWizardScreenState extends State<ProfileWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 5;

  // Form değerleri
  String _gender = 'erkek';
  DateTime _birthDate = DateTime(1990, 1, 1);
  double _height = 170.0;
  double _weight = 70.0;
  String _activityLevel = 'orta_aktif';
  String _goalType = 'koru';
  double _weeklyGoal = 0.5;

  // Hesaplama sonucu
  CalorieCalculationResult? _calculationResult;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loadExistingProfile();
    }
  }

  void _loadExistingProfile() {
    final provider = context.read<AppProvider>();
    final profile = provider.userProfile;
    if (profile != null) {
      setState(() {
        _gender = profile.gender;
        _birthDate = profile.birthDate;
        _height = profile.heightCm;
        _weight = profile.weightKg;
        _activityLevel = profile.activityLevel;
        _goalType = profile.goalType;
        _weeklyGoal = profile.weeklyGoal;
      });
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: AppConstants.animationNormal,
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep++;
        if (_currentStep == _totalSteps - 1) {
          _calculateCalories();
        }
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: AppConstants.animationNormal,
        curve: Curves.easeInOut,
      );
      setState(() {
        _currentStep--;
      });
    }
  }

  void _calculateCalories() {
    setState(() {
      _calculationResult = CalorieCalculatorService.calculateCalories(
        gender: _gender,
        birthDate: _birthDate,
        heightCm: _height,
        weightKg: _weight,
        activityLevel: _activityLevel,
        goalType: _goalType,
      );
    });
  }

  Future<void> _saveProfile() async {
    final provider = context.read<AppProvider>();
    await provider.saveProfile(
      gender: _gender,
      birthDate: _birthDate,
      heightCm: _height,
      weightKg: _weight,
      activityLevel: _activityLevel,
      goalType: _goalType,
      weeklyGoal: _weeklyGoal,
    );

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            _buildProgressIndicator(),

            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildGenderStep(),
                  _buildBirthDateStep(),
                  _buildBodyMeasurementsStep(),
                  _buildActivityStep(),
                  _buildGoalStep(),
                ],
              ),
            ),

            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Adım ${_currentStep + 1} / $_totalSteps',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Text(
                _getStepTitle(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (_currentStep + 1) / _totalSteps,
            backgroundColor: Colors.grey.shade200,
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Cinsiyet';
      case 1:
        return 'Doğum Tarihi';
      case 2:
        return 'Boy & Kilo';
      case 3:
        return 'Aktivite';
      case 4:
        return 'Hedef';
      default:
        return '';
    }
  }

  Widget _buildGenderStep() {
    return _buildStepContainer(
      title: 'Cinsiyetiniz nedir?',
      subtitle: 'Kalori hesaplaması için gereklidir',
      child: Row(
        children: [
          Expanded(
            child: _GenderCard(
              icon: Icons.male,
              label: 'Erkek',
              isSelected: _gender == 'erkek',
              onTap: () => setState(() => _gender = 'erkek'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _GenderCard(
              icon: Icons.female,
              label: 'Kadın',
              isSelected: _gender == 'kadin',
              onTap: () => setState(() => _gender = 'kadin'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBirthDateStep() {
    final age = DateTime.now().year - _birthDate.year;
    return _buildStepContainer(
      title: 'Doğum tarihiniz?',
      subtitle: 'Yaşınız: $age',
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: CalendarDatePicker(
              initialDate: _birthDate,
              firstDate: DateTime(1920),
              lastDate: DateTime.now().subtract(
                const Duration(days: 365 * AppConstants.minAge),
              ),
              onDateChanged: (date) {
                setState(() => _birthDate = date);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyMeasurementsStep() {
    return _buildStepContainer(
      title: 'Fiziksel ölçüleriniz',
      subtitle: 'Boy ve kilonuzu girin',
      child: Column(
        children: [
          // Boy
          _buildMeasurementSlider(
            label: 'Boy',
            value: _height,
            min: AppConstants.minHeight,
            max: AppConstants.maxHeight,
            unit: 'cm',
            onChanged: (value) => setState(() => _height = value),
          ),
          const SizedBox(height: 32),
          // Kilo
          _buildMeasurementSlider(
            label: 'Kilo',
            value: _weight,
            min: AppConstants.minWeight,
            max: AppConstants.maxWeight,
            unit: 'kg',
            onChanged: (value) => setState(() => _weight = value),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${value.round()} $unit',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppTheme.primaryColor,
            inactiveTrackColor: Colors.grey.shade200,
            thumbColor: AppTheme.primaryColor,
            overlayColor: AppTheme.primaryColor.withOpacity(0.2),
            trackHeight: 8,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityStep() {
    return _buildStepContainer(
      title: 'Aktivite seviyeniz?',
      subtitle: 'Günlük fiziksel aktivitenizi seçin',
      child: Column(
        children: AppConstants.activityLabels.entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ActivityCard(
              title: entry.value,
              isSelected: _activityLevel == entry.key,
              onTap: () => setState(() => _activityLevel = entry.key),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGoalStep() {
    return _buildStepContainer(
      title: 'Hedefiniz nedir?',
      subtitle: _calculationResult != null
          ? 'Günlük kalori hedefiniz: ${_calculationResult!.targetCalories} kcal'
          : 'Kilo hedefinizi seçin',
      child: Column(
        children: [
          // Hedef türü seçimi
          ...AppConstants.goalLabels.entries.map((entry) {
            IconData icon;
            switch (entry.key) {
              case 'kilo_ver':
                icon = Icons.trending_down;
                break;
              case 'kilo_al':
                icon = Icons.trending_up;
                break;
              default:
                icon = Icons.balance;
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _GoalCard(
                icon: icon,
                title: entry.value,
                isSelected: _goalType == entry.key,
                onTap: () {
                  setState(() => _goalType = entry.key);
                  _calculateCalories();
                },
              ),
            );
          }),

          // Kalori sonucu gösterimi
          if (_calculationResult != null) ...[
            const SizedBox(height: 24),
            _buildCalorieResultCard(),
          ],

          // Uyarı
          if (_calculationResult?.showLowCalorieWarning == true) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.warningColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bu kalori hedefi düşük. Sağlığınız için bir uzmana danışmanızı öneririz.',
                      style: TextStyle(color: Colors.orange.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCalorieResultCard() {
    if (_calculationResult == null) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(24),
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
          const Text(
            'Günlük Kalori Hedefiniz',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_calculationResult!.targetCalories}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Text(
            'kcal',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCalorieDetail('BMR', '${_calculationResult!.bmr.round()}'),
              _buildCalorieDetail('TDEE', '${_calculationResult!.tdee.round()}'),
              _buildCalorieDetail('Yaş', '${_calculationResult!.age}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieDetail(String label, String value) {
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
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildStepContainer({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 32),
          child,
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            OutlinedButton(
              onPressed: _previousStep,
              child: const Icon(Icons.arrow_back),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: ElevatedButton(
              onPressed: _currentStep == _totalSteps - 1 ? _saveProfile : _nextStep,
              child: Text(
                _currentStep == _totalSteps - 1 ? 'Başla' : 'Devam',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== HELPER WIDGETS ====================

class _GenderCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.animationFast,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 64,
              color: isSelected ? Colors.white : Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.animationFast,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? Colors.white : Colors.grey.shade400,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalCard({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppConstants.animationFast,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.primaryColor,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? Colors.white : Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }
}
