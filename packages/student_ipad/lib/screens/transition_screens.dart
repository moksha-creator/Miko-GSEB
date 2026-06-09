import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_core/shared_core.dart';
import 'student_profiles_screen.dart';

class BeReadyScreen extends ConsumerStatefulWidget {
  const BeReadyScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BeReadyScreen> createState() => _BeReadyScreenState();
}

class _BeReadyScreenState extends ConsumerState<BeReadyScreen> {
  int _secondsLeft = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 1) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        _timer?.cancel();
        context.go('/quiz');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(selectedStudentProvider);
    final studentName = student?.name ?? 'Adventurer';
    final avatarColor = student != null
        ? _colorFromHex(student.avatarColor)
        : AppColors.primary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              avatarColor.withOpacity(0.25),
              AppColors.background,
            ],
            center: Alignment.center,
            radius: 1.2,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Playful dynamic island badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: const Text(
                  'UPCOMING QUEST 🌟',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                    letterSpacing: 1.5,
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2, end: 0),
              
              const SizedBox(height: 48),

              // Animated profile circle
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: avatarColor, width: 6),
                  image: student != null ? DecorationImage(
                    image: AssetImage('assets/avatars/${student.name.toLowerCase().split(' ')[0]}.png'),
                    fit: BoxFit.cover,
                  ) : null,
                  boxShadow: [
                    BoxShadow(
                      color: avatarColor.withOpacity(0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
              ).animate().scale(delay: 200.ms, duration: 500.ms, curve: Curves.elasticOut),

              const SizedBox(height: 32),

              // Big friendly name
              Text(
                studentName,
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 12),

              const Text(
                'Get ready for your oral evaluation! Miko is setting up... 🚀',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 64),

              // Pulsing countdown digits
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$_secondsLeft',
                    key: ValueKey<int>(_secondsLeft),
                    style: TextStyle(
                      fontSize: 64,
                      fontWeight: FontWeight.w900,
                      color: avatarColor,
                    ),
                  )
                      .animate(key: ValueKey<int>(_secondsLeft))
                      .scale(begin: const Offset(0.5, 0.5), end: const Offset(1.0, 1.0), duration: 250.ms, curve: Curves.easeOutBack)
                      .fadeIn(duration: 200.ms),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NextStudentTransitionScreen extends ConsumerStatefulWidget {
  const NextStudentTransitionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NextStudentTransitionScreen> createState() => _NextStudentTransitionScreenState();
}

class _NextStudentTransitionScreenState extends ConsumerState<NextStudentTransitionScreen> {
  int _secondsLeft = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 1) {
        setState(() {
          _secondsLeft--;
        });
      } else {
        _timer?.cancel();
        context.go('/quiz');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(selectedStudentProvider);
    final studentName = student?.name ?? 'Next Student';
    final avatarColor = student != null
        ? _colorFromHex(student.avatarColor)
        : AppColors.primary;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.background,
              avatarColor.withOpacity(0.15),
              AppColors.background,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Transition sticker
              const Text(
                '🔄 TRANSITIONING',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textSecondary,
                  letterSpacing: 2.0,
                ),
              ).animate().fadeIn(),

              const SizedBox(height: 24),

              const Text(
                'Now evaluating...',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 32),

              // Student avatar with outer pulsing rings
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      color: avatarColor.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                  ).animate(onPlay: (controller) => controller.repeat()).scale(
                    begin: const Offset(0.85, 0.85),
                    end: const Offset(1.15, 1.15),
                    duration: 1.5.seconds,
                    curve: Curves.easeInOut,
                  ).fadeIn(duration: 400.ms).fadeOut(delay: 800.ms, duration: 400.ms),
                  
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: avatarColor, width: 5),
                      image: student != null ? DecorationImage(
                        image: AssetImage('assets/avatars/${student.name.toLowerCase().split(' ')[0]}.png'),
                        fit: BoxFit.cover,
                      ) : null,
                      boxShadow: [
                        BoxShadow(
                          color: avatarColor.withOpacity(0.2),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 32),

              // Riya Patel
              Text(
                studentName,
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.15, end: 0),

              const SizedBox(height: 48),

              // 5-second countdown progress ring
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 70,
                    height: 70,
                    child: CircularProgressIndicator(
                      value: _secondsLeft / 5,
                      strokeWidth: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(avatarColor),
                    ),
                  ),
                  Text(
                    '$_secondsLeft',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms),
            ],
          ),
        ),
      ),
    );
  }
}

Color _colorFromHex(String hexColor) {
  hexColor = hexColor.replaceAll('#', '');
  if (hexColor.length == 6) {
    hexColor = 'FF$hexColor';
  }
  return Color(int.parse(hexColor, radix: 16));
}
