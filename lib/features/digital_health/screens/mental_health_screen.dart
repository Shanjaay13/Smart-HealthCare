import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:my_sejahtera_ng/core/theme/app_theme.dart';
import 'package:my_sejahtera_ng/features/gamification/providers/user_progress_provider.dart';

class MentalHealthScreen extends ConsumerStatefulWidget {
  const MentalHealthScreen({super.key});

  @override
  ConsumerState<MentalHealthScreen> createState() => _MentalHealthScreenState();
}

class _MentalHealthScreenState extends ConsumerState<MentalHealthScreen> {
  int _selectedMood = 2; // 0-4

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text("Mental Wellness", style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)), 
        backgroundColor: AppTheme.bgLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              const Text("How are you feeling today?", 
                 style: TextStyle(color: AppTheme.textDark, fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 24),
              Container(
                 decoration: BoxDecoration(
                   color: AppTheme.surfaceWhite,
                   borderRadius: BorderRadius.circular(24),
                   boxShadow: [
                     BoxShadow(
                       color: Colors.black.withOpacity(0.04),
                       blurRadius: 20,
                       offset: const Offset(0, 8),
                     )
                   ]
                 ),
                 padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                 child: Row(
                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                   children: List.generate(5, (index) {
                     return GestureDetector(
                       onTap: () {
                         setState(() => _selectedMood = index);
                         ref.read(userProgressProvider.notifier).completeQuest('mood');
                       },
                       child: AnimatedContainer(
                         duration: 300.ms,
                         padding: const EdgeInsets.all(12),
                         decoration: BoxDecoration(
                           color: _selectedMood == index ? _getMoodColor(index).withOpacity(0.1) : Colors.transparent,
                           shape: BoxShape.circle,
                           border: Border.all(color: _selectedMood == index ? _getMoodColor(index).withOpacity(0.3) : Colors.transparent, width: 2)
                         ),
                         child: Icon(
                           _getMoodIcon(index), 
                           color: _selectedMood == index ? _getMoodColor(index) : AppTheme.textMuted.withOpacity(0.5), 
                           size: _selectedMood == index ? 40 : 30
                         ),
                       ),
                     );
                   }),
                 ),
              ).animate().fadeIn().scale(),
              const SizedBox(height: 40),
              const Text("Resources for you", 
                 style: TextStyle(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildResourceCard("Meditation Guide", "10 mins • Calm & Focus", LucideIcons.headphones, const Color(0xFF8B5CF6)),
              _buildResourceCard("Breathing Exercise", "5 mins • Relax", LucideIcons.wind, const Color(0xFF0EA5E9)),
              _buildResourceCard("Talk to a Counselor", "Available now", LucideIcons.phone, AppTheme.success),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getMoodIcon(int index) {
    switch (index) {
      case 0: return LucideIcons.frown;
      case 1: return LucideIcons.meh;
      case 2: return LucideIcons.smile;
      case 3: return LucideIcons.laugh;
      case 4: return LucideIcons.partyPopper;
      default: return LucideIcons.smile;
    }
  }

  Color _getMoodColor(int index) {
    switch (index) {
      case 0: return AppTheme.error;
      case 1: return const Color(0xFFF59E0B);
      case 2: return const Color(0xFF8B5CF6);
      case 3: return const Color(0xFF0EA5E9);
      case 4: return AppTheme.success;
      default: return AppTheme.primaryBlue;
    }
  }

  Widget _buildResourceCard(String title, String subtitle, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
             BoxShadow(
               color: Colors.black.withOpacity(0.03),
               blurRadius: 10,
               offset: const Offset(0, 4),
             )
          ]
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            )
          ],
        ),
      ).animate().fadeIn().slideX(),
    );
  }
}
