import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
    
    final accentColor = isOver ? AppTheme.error : AppTheme.primaryBlue;

    return BouncingButton(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => FoodTrackerScreen()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFEF3C7),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(50),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(50),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            )
          ]
        ),
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            // Circular Progress
            SizedBox(
              height: 70,
              width: 70,
              child: Stack(
                children: [
                  Center(
                    child: SizedBox(
                      height: 70,
                      width: 70,
                      child: CircularProgressIndicator(
                        value: progress,
                        backgroundColor: AppTheme.bgLight,
                        color: accentColor,
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                  ),
                  Center(
                    child: Icon(
                      LucideIcons.flame,
                      color: accentColor,
                      size: 28,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            
            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Calorie Intake",
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        "${state.totalCalories}",
                        style: const TextStyle(
                          color: AppTheme.textDark,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        " / ${state.calorieTarget} kcal",
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // AI Insight Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.sparkles,
                          size: 12,
                          color: accentColor,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            state.currentInsight,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: accentColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Chevron
            const Icon(
              LucideIcons.chevronRight,
              color: AppTheme.textMuted,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}
