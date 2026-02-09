import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/providers/purchase_providers.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/app_providers.dart';
import '../home/home_screen.dart';

// Solid background colors for neo-brutalist onboarding (no gradients)
const _pageColors = [
  Color(0xFF6366F1), // Indigo — Welcome
  Color(0xFF0F2027), // Dark teal — How it works
  Color(0xFFEC4899), // Pink — Camera
  Color(0xFF3B82F6), // Blue — Reminders
  Color(0xFF8B5CF6), // Violet — Paywall
];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _remindersEnabled = false;
  bool _isPurchasing = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  
  final int _totalPages = 5; // Welcome, How it works, Camera, Reminders, Paywall

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Solid color background — no gradients
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            color: _pageColors[_currentPage.clamp(0, _pageColors.length - 1)],
          ),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    children: [
                      _buildWelcomePage(context),
                      _buildHowItWorksPage(context),
                      _buildCameraPage(context),
                      _buildRemindersPage(context),
                      _buildPaywallPage(context),
                    ],
                  ),
                ),
                _buildBottomSection(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomePage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Neo-brutalist logo container
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            'Remember\nEvery Name',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.1,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
              ],
            ),
            child: Text(
              '👩‍🏫 Teachers  •  👔 Pros  •  🎉 Social',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Build stronger connections by never\nforgetting a face (or name) again!',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.95),
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksPage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Super Simple',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          _buildStepCard(context, '📸', 'Snap Photos', 'Add photos of people you want to remember'),
          const SizedBox(height: 16),
          _buildStepCard(context, '🎯', 'Practice Daily', 'Fun flashcard games with smart repetition'),
          const SizedBox(height: 16),
          _buildStepCard(context, '🏆', 'Never Forget', 'Lock names into long-term memory'),
        ],
      ),
    );
  }

  Widget _buildStepCard(BuildContext context, String emoji, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1A1A1A), width: 2.5),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
        ],
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A1A1A),
                      ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
              ],
            ),
            child: const Center(
              child: Text('📷', style: TextStyle(fontSize: 70)),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            'Quick Setup',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            'Take photos or import from your library.\nWe\'ll organize everything for you!',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.95),
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock, size: 18, color: Color(0xFF1A1A1A)),
                const SizedBox(width: 8),
                Text(
                  'Photos stay on your device',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemindersPage(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
              ],
            ),
            child: const Center(
              child: Text('⏰', style: TextStyle(fontSize: 70)),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            'Stay Consistent',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            'A few minutes daily is all it takes.\nWe can remind you to practice!',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.95),
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1A1A1A), width: 2.5),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Reminders',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A1A1A),
                                ),
                          ),
                          Text(
                            'Get a gentle nudge to practice',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _remindersEnabled,
                      onChanged: (value) => setState(() => _remindersEnabled = value),
                      activeColor: AppTheme.primaryColor,
                    ),
                  ],
                ),
                if (_remindersEnabled) ...[
                  const SizedBox(height: 16),
                  Divider(color: Colors.grey[300]),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _reminderTime,
                      );
                      if (picked != null) {
                        setState(() => _reminderTime = picked);
                      }
                    },
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: Color(0xFF1A1A1A), size: 22),
                        const SizedBox(width: 12),
                        Text(
                          'Reminder Time',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: const Color(0xFF1A1A1A),
                              ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.chipBlue,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF1A1A1A), width: 2),
                          ),
                          child: Text(
                            _reminderTime.format(context),
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: const Color(0xFF1A1A1A),
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaywallPage(BuildContext context) {
    final purchaseState = ref.watch(purchaseStateProvider);
    final priceString = purchaseState.priceString ?? '\$4.99';
    
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF1A1A1A), width: 3),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
              ],
            ),
            child: const Center(
              child: Text('⭐', style: TextStyle(fontSize: 70)),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Go Premium',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'One-time purchase, yours forever',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          _buildFeatureRow(context, '✓', 'Unlimited groups'),
          const SizedBox(height: 12),
          _buildFeatureRow(context, '✓', 'Unlimited people per group'),
          const SizedBox(height: 12),
          _buildFeatureRow(context, '✓', 'Support indie development ❤️'),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1A1A1A), width: 2.5),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(3, 3), blurRadius: 0),
              ],
            ),
            child: Column(
              children: [
                Text(
                  priceString,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: const Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'One-time payment',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF1A1A1A).withOpacity(0.7),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, String check, String text) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          check,
          style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }

  Widget _buildBottomSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Page indicators — chunky dots with borders
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_totalPages, (index) {
              final isActive = _currentPage == index;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 28 : 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isActive ? const Color(0xFF1A1A1A) : Colors.white.withOpacity(0.3),
                    width: isActive ? 2 : 1,
                  ),
                  boxShadow: isActive
                      ? const [BoxShadow(color: Colors.black, offset: Offset(2, 2), blurRadius: 0)]
                      : null,
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          // Buttons based on current page
          if (_currentPage == 2) // Camera page
            _buildCameraButtons(context)
          else if (_currentPage == 4) // Paywall page
            _buildPaywallButtons(context)
          else
            _buildContinueButton(context),
        ],
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1A1A1A), width: 2.5),
          boxShadow: const [
            BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: const Center(
              child: Text(
                'Continue',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1A1A1A), width: 2.5),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: () async {
                  final status = await Permission.camera.request();
                  debugPrint('Camera permission result: $status');
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: const Center(
                  child: Text(
                    'Enable Camera',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A)),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut,
            );
          },
          child: Text(
            'Skip for now',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaywallButtons(BuildContext context) {
    final purchaseState = ref.watch(purchaseStateProvider);
    final priceString = purchaseState.priceString ?? '\$4.99';
    
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1A1A1A), width: 2.5),
              boxShadow: const [
                BoxShadow(color: Colors.black, offset: Offset(4, 4), blurRadius: 0),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: _isPurchasing ? null : () => _showPurchase(context),
                borderRadius: BorderRadius.circular(14),
                child: Center(
                  child: _isPurchasing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Color(0xFF1A1A1A),
                          ),
                        )
                      : Text(
                          'Unlock Premium — $priceString',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isPurchasing ? null : () => _completeOnboarding(),
          child: Text(
            'Continue with free version',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showPurchase(BuildContext context) async {
    setState(() => _isPurchasing = true);
    
    try {
      final success = await ref.read(purchaseStateProvider.notifier).purchasePremium();
      
      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Thank you for going Premium!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _completeOnboarding();
      } else {
        if (mounted) {
          final purchaseState = ref.read(purchaseStateProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(purchaseState.errorMessage ?? 'Purchase cancelled or unavailable'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Purchase failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPurchasing = false);
      }
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefOnboardingComplete, true);
    
    // Save reminder preference and schedule notification
    if (_remindersEnabled) {
      await ref.read(settingsProvider.notifier).setNotifications(
            true,
            hour: _reminderTime.hour,
            minute: _reminderTime.minute,
          );
    }

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }
}
