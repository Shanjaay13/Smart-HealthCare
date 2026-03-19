import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_sejahtera_ng/core/theme/app_theme.dart';
import 'package:my_sejahtera_ng/core/widgets/bouncing_button.dart';
import 'package:my_sejahtera_ng/features/food_tracker/providers/food_tracker_provider.dart';
import 'package:my_sejahtera_ng/features/food_tracker/food_tracker_screen.dart';

class CalorieInsightCard extends ConsumerWidget {
  const CalorieInsightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(foodTrackerProvider);
    final progress = (state.totalCalories / state.calorieTarget).clamp(0.0, 1.0);
    final remaining = state.calorieTarget - state.totalCalories;
    final isOver = remaining < 0;
    
    final gradientColors = isOver 
        ? const [Color(0xFFEF4444), Color(0xFF991B1B)] // Warning Red Gradient
        : const [Color(0xFFF59E0B), Color(0xFFEC4899)]; // Vibrant Orange-Pink Gradient

    return BouncingButton(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const FoodTrackerScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.12),
              blurRadius: 30,
              offset: const Offset(0, 15),
            )
          ]
        ),
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                  Row(
                    children: [
                       Icon(LucideIcons.flame, color: gradientColors[0], size: 20),
                       const SizedBox(width: 8),
                       Text("CALORIE INTAKE", style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ],
                  ),
                  const Icon(LucideIcons.chevronRight, color: AppTheme.textMuted, size: 20),
               ]
            ),
            const SizedBox(height: 24),
            
            // Main Content
            Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 // Left Typography
                 Expanded(
                   child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text(
                           "${state.totalCalories}", 
                           style: GoogleFonts.outfit(color: AppTheme.textDark, fontSize: 48, fontWeight: FontWeight.w900, height: 1.1, letterSpacing: -1),
                         ),
                         Text(
                           "/ ${state.calorieTarget} kcal", 
                           style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 18, fontWeight: FontWeight.w600),
                         ),
                      ]
                   ),
                 ),
                 
                 // Right Glowing Thick Ring
                 SizedBox(
                   width: 85, height: 85,
                   child: Stack(
                     fit: StackFit.expand,
                     children: [
                        CircularProgressIndicator(
                          value: 1.0,
                          color: AppTheme.bgLight,
                          strokeWidth: 10,
                        ),
                        ShaderMask(
                          shaderCallback: (rect) => LinearGradient(
                            colors: gradientColors,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(rect),
                          child: CircularProgressIndicator(
                            value: progress,
                            color: Colors.white,
                            strokeWidth: 10,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Center(
                          child: Text(
                             "${(progress * 100).toInt()}%",
                             style: GoogleFonts.outfit(color: AppTheme.textDark, fontWeight: FontWeight.w800, fontSize: 18),
                          )
                        ),
                     ]
                   )
                 )
               ]
            ),
            
            // AI Insight
            if (state.currentInsight.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 28),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                   color: gradientColors[0].withOpacity(0.08),
                   borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                   children: [
                      Icon(LucideIcons.sparkles, color: gradientColors[0], size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                           state.currentInsight,
                           style: GoogleFonts.outfit(color: gradientColors[0].withOpacity(0.8), fontWeight: FontWeight.bold, fontSize: 13),
                        )
                      )
                   ]
                )
              )
          ],
        )
      ),
    );
  }
}
