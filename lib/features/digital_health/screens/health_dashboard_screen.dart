import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_sejahtera_ng/core/theme/app_theme.dart';

import 'package:my_sejahtera_ng/features/food_tracker/food_tracker_screen.dart';
import 'package:my_sejahtera_ng/features/food_tracker/providers/food_tracker_provider.dart';
import 'package:my_sejahtera_ng/features/digital_health/providers/medication_provider.dart';
import 'package:my_sejahtera_ng/features/digital_health/providers/vitals_provider.dart';
import 'package:my_sejahtera_ng/features/digital_health/screens/medication_tracker_screen.dart';
import 'package:my_sejahtera_ng/features/digital_health/screens/health_vitals_screen.dart';
import 'package:my_sejahtera_ng/core/providers/user_provider.dart';

class HealthDashboardScreen extends ConsumerWidget {
  const HealthDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vitals = ref.watch(vitalsProvider);
    final medicationState = ref.watch(medicationProvider);
    final foodState = ref.watch(foodTrackerProvider);
    final user = ref.watch(userProvider);
    
    int healthScore = 0;
    if (vitals.bmiStatus == 'Normal') healthScore += 40;
    else if (vitals.bmiStatus == 'Overweight') healthScore += 30;
    else healthScore += 20;

    if (foodState.totalCalories > 0) {
       if (foodState.totalCalories <= foodState.calorieTarget) healthScore += 20;
       else healthScore += 10;
    }

    if (foodState.waterCount >= 8) healthScore += 20;
    else if (foodState.waterCount >= 4) healthScore += 10;

    final totalMeds = medicationState.medications.length;
    final takenMeds = medicationState.medications.where((m) => m.isTaken).length;
    if (totalMeds == 0) {
       healthScore += 20; 
    } else {
       double medCompliance = takenMeds / totalMeds;
       healthScore += (20 * medCompliance).toInt();
    }

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text("My Health Hub", style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: AppTheme.bgLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.bell),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text("Good Morning,", style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 16)),
              Text(user?.fullName ?? "User", style: GoogleFonts.outfit(color: AppTheme.textDark, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1)),
              const SizedBox(height: 30),

              // Hero: Massive Glowing Orb
              Center(child: _buildHealthOrb(healthScore)),

              const SizedBox(height: 40),
              Text("Your Trackers", style: GoogleFonts.outfit(color: AppTheme.textDark, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
              const SizedBox(height: 20),

              // The Organic Bento Box Layout
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Wavy banner + Cornered Square
                  Expanded(
                    flex: 11,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildNutritionWavyCard(context, foodState),
                        const SizedBox(height: 16),
                        _buildVitalsSquircle(context, vitals),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Right Column: Tall Capsule + Perfect Circle
                  Expanded(
                    flex: 9,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHydrationCapsule(context, foodState),
                        const SizedBox(height: 16),
                        _buildMedicationCircle(context, takenMeds, totalMeds),
                      ],
                    ),
                  )
                ],
              ),
              
              const SizedBox(height: 40),
              // Bottom Action Card
              _buildDailyInsightCard(vitals.bmiStatus, foodState.totalCalories > foodState.calorieTarget),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHealthOrb(int score) {
    bool isExcellent = score > 70;
    Color orbColor = isExcellent ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.surfaceWhite,
        boxShadow: [
          BoxShadow(
            color: orbColor.withOpacity(0.2),
            blurRadius: 40,
            spreadRadius: 10,
            offset: const Offset(0, 15)
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, 5)
          )
        ],
        border: Border.all(color: orbColor.withOpacity(0.3), width: 8),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isExcellent ? LucideIcons.activity : LucideIcons.alertTriangle, color: orbColor, size: 28),
            const SizedBox(height: 8),
            Text(
              "$score",
              style: GoogleFonts.outfit(color: AppTheme.textDark, fontSize: 64, fontWeight: FontWeight.w900, height: 1.0, letterSpacing: -2),
            ),
            Text(
              "HEALTH SCORE",
              style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
            ),
          ],
        ),
      ),
    ).animate()
     .fadeIn(duration: 800.ms)
     .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack)
     .shimmer(delay: 1000.ms, duration: 2000.ms, color: orbColor.withOpacity(0.2));
  }

  Widget _buildNutritionWavyCard(BuildContext context, dynamic foodState) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodTrackerScreen())),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7), // Amber 100
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(40),
          ),
          boxShadow: [
            BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), shape: BoxShape.circle),
              child: const Icon(LucideIcons.utensils, color: Color(0xFFD97706)),
            ),
            const SizedBox(height: 16),
            Text("${foodState.totalCalories}", style: GoogleFonts.outfit(color: const Color(0xFF92400E), fontSize: 32, fontWeight: FontWeight.w900, height: 1.0)),
            const SizedBox(height: 4),
            Text("kcal / ${foodState.calorieTarget}", style: GoogleFonts.outfit(color: const Color(0xFFB45309), fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
    );
  }

  Widget _buildHydrationCapsule(BuildContext context, dynamic foodState) {
    double fillPercent = (foodState.waterCount / 8).clamp(0.0, 1.0);
    
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodTrackerScreen(autoShowHydration: true))),
      child: Container(
        height: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE0F2FE), // Light Blue
          borderRadius: BorderRadius.circular(100), // Full pill
          boxShadow: [
            BoxShadow(color: const Color(0xFF0EA5E9).withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))
          ]
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
              child: const Icon(LucideIcons.droplets, color: Color(0xFF0284C7)),
            ),
            const Spacer(),
            Text("${foodState.waterCount}", style: GoogleFonts.outfit(color: const Color(0xFF0369A1), fontSize: 40, fontWeight: FontWeight.w900, height: 1.0)),
            const SizedBox(height: 4),
            Text("glasses", style: GoogleFonts.outfit(color: const Color(0xFF075985), fontSize: 13, fontWeight: FontWeight.bold)),
            const Spacer(),
            // Wave progress visual
            Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF38BDF8).withOpacity(0.3),
                borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(100), bottomRight: Radius.circular(100)),
              ),
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                duration: 600.ms,
                height: 60 * fillPercent,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xFF0EA5E9),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(100), bottomRight: Radius.circular(100)),
                ),
              ),
            )
          ],
        ),
      ).animate().fadeIn(delay: 200.ms).slideX(begin: 0.1),
    );
  }

  Widget _buildVitalsSquircle(BuildContext context, dynamic vitals) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HealthVitalsScreen())),
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFCE7F3), // Pink 100
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(40),
            bottomLeft: Radius.circular(40),
            bottomRight: Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(color: const Color(0xFFEC4899).withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.6), shape: BoxShape.circle),
              child: const Icon(LucideIcons.heartPulse, color: Color(0xFFDB2777)),
            ),
            const Spacer(),
            Text(vitals.bmi.toStringAsFixed(1), style: GoogleFonts.outfit(color: const Color(0xFF9D174D), fontSize: 32, fontWeight: FontWeight.w900, height: 1.0)),
            const SizedBox(height: 4),
            Text("BMI: ${vitals.bmiStatus}", style: GoogleFonts.outfit(color: const Color(0xFFBE185D), fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
    );
  }

  Widget _buildMedicationCircle(BuildContext context, int taken, int total) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MedicationTrackerScreen())),
      child: Container(
        height: 140, // Perfect circle logic with crossAxisAlignment.stretch needs constrained height or will follow width
        decoration: BoxDecoration(
          color: const Color(0xFFD1FAE5), // Mint 100
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: const Color(0xFF10B981).withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))
          ]
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.pill, color: Color(0xFF059669)),
              const SizedBox(height: 8),
              Text(total == 0 ? "0" : "$taken/$total", style: GoogleFonts.outfit(color: const Color(0xFF065F46), fontSize: 24, fontWeight: FontWeight.w900, height: 1.0)),
              Text("meds", style: GoogleFonts.outfit(color: const Color(0xFF047857), fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.8, 0.8)),
    );
  }

  Widget _buildDailyInsightCard(String bmiStatus, bool overCalories) {
    String message = "Your trackers look excellent! Keep maintaining this amazing healthy routine.";
    IconData icon = LucideIcons.thumbsUp;
    Color color = AppTheme.primaryBlue;

    if (bmiStatus != 'Normal') {
      message = "Your BMI sits outside the normal range. Adjust your routines and watch the dial turn!";
      icon = LucideIcons.alertCircle;
      color = const Color(0xFFF59E0B);
    } else if (overCalories) {
      message = "You've exceeded your calorie limit today. Try a short walk to balance it out!";
      icon = LucideIcons.utensils;
      color = AppTheme.error;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(10),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, offset: const Offset(0, 8))
        ],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24)
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Smart Insight", style: GoogleFonts.outfit(color: color, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Text(message, style: const TextStyle(color: AppTheme.textDark, height: 1.5, fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            )
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1);
  }
}
