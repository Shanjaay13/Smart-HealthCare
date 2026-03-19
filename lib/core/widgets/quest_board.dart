import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_sejahtera_ng/core/theme/app_theme.dart';
import 'package:my_sejahtera_ng/features/gamification/providers/quest_provider.dart';
import 'package:my_sejahtera_ng/features/gamification/providers/user_progress_provider.dart';
import 'package:my_sejahtera_ng/features/hotspots/screens/hotspot_screen.dart';
import 'package:my_sejahtera_ng/features/health_assistant/screens/ai_chat_screen.dart';
import 'package:my_sejahtera_ng/features/vaccine/screens/vaccine_screen.dart';

class QuestBoard extends ConsumerWidget {
  const QuestBoard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(userProgressProvider);
    final quests = ref.watch(questProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Premium Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                   "Daily Goals", 
                   style: GoogleFonts.outfit(color: AppTheme.textDark, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1, height: 1.1)
                ),
                const SizedBox(height: 4),
                Text(
                   "${(progress.xp * 1000).toInt()} / 1000 XP to Level ${progress.level + 1}", 
                   style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 16, fontWeight: FontWeight.w600)
                ),
              ],
            ),
            // Beautiful XP Ring
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const CircularProgressIndicator(
                    value: 1.0,
                    color: Colors.white, 
                    strokeWidth: 8,
                  ),
                  ShaderMask(
                     shaderCallback: (rect) => const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFFCD34D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                     ).createShader(rect),
                     child: CircularProgressIndicator(
                        value: progress.xp,
                        color: Colors.white,
                        strokeWidth: 8,
                        strokeCap: StrokeCap.round,
                     )
                  ),
                  Center(
                    child: Text(
                      "${progress.level}", 
                      style: GoogleFonts.outfit(color: const Color(0xFFD97706), fontSize: 22, fontWeight: FontWeight.w900)
                    )
                  )
                ],
              ),
            )
          ],
        ),
        
        const SizedBox(height: 24),
        
        // Quests List
        ...quests.map((quest) {
           final isClaimed = quest.status == QuestStatus.claimed;
           final isCompleted = quest.status == QuestStatus.completed;
           
           return Container(
             margin: const EdgeInsets.only(bottom: 16),
             padding: const EdgeInsets.all(24),
             decoration: BoxDecoration(
               color: isClaimed ? Colors.transparent : Colors.white,
               borderRadius: BorderRadius.circular(32),
               border: isClaimed ? Border.all(color: Colors.grey.shade300, width: 2) : null,
               boxShadow: isClaimed ? [] : [
                 BoxShadow(
                   color: Colors.black.withOpacity(0.04),
                   blurRadius: 24,
                   offset: const Offset(0, 10),
                 )
               ]
             ),
             child: Row(
               children: [
                 // Striking Icon
                 Container(
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(
                     color: isClaimed ? AppTheme.bgLight : (isCompleted ? const Color(0xFFF59E0B).withOpacity(0.15) : AppTheme.primaryBlue.withOpacity(0.1)),
                     shape: BoxShape.circle,
                   ),
                   child: Icon(
                      isClaimed ? LucideIcons.checkCheck : quest.icon, 
                      color: isClaimed ? AppTheme.textMuted : (isCompleted ? const Color(0xFFD97706) : AppTheme.primaryBlue), 
                      size: 24
                   ),
                 ),
                 const SizedBox(width: 16),
                 Expanded(
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       Text(
                         quest.title, 
                         style: GoogleFonts.outfit(
                           color: isClaimed ? AppTheme.textMuted : AppTheme.textDark,
                           decoration: isClaimed ? TextDecoration.lineThrough : null,
                           fontWeight: FontWeight.bold,
                           fontSize: 16
                         )
                       ),
                       const SizedBox(height: 4),
                       Row(
                          children: [
                             Icon(LucideIcons.zap, size: 14, color: isClaimed ? AppTheme.textMuted : const Color(0xFFF59E0B)),
                             const SizedBox(width: 4),
                             Text(
                                "+${quest.xp} XP", 
                                style: GoogleFonts.outfit(color: isClaimed ? AppTheme.textMuted : const Color(0xFFD97706), fontSize: 14, fontWeight: FontWeight.w800)
                             ),
                          ]
                       )
                     ],
                   ),
                 ),
                 
                 const SizedBox(width: 12),
                 _buildActionButton(context, ref, quest),
               ],
             ),
           );
        })
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, WidgetRef ref, Quest quest) {
    switch (quest.status) {
      case QuestStatus.claimed:
        return const SizedBox.shrink();
        
      case QuestStatus.completed:
        return ElevatedButton(
          onPressed: () {
            ref.read(questProvider.notifier).claimQuest(quest.id, ref);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF59E0B),
            foregroundColor: Colors.white,
            elevation: 8,
            shadowColor: const Color(0xFFF59E0B).withOpacity(0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)
          ),
          child: Text("CLAIM", style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: 800.ms, begin: const Offset(1,1), end: const Offset(1.05, 1.05));
        
      case QuestStatus.pending:
        if (quest.type == QuestType.navigation) {
          return ElevatedButton(
             onPressed: () {
                _handleNavigation(context, ref, quest.actionId!);
             },
             style: ElevatedButton.styleFrom(
               backgroundColor: AppTheme.primaryBlue.withOpacity(0.1),
               foregroundColor: AppTheme.primaryBlue,
               elevation: 0,
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14)
             ),
             child: Text("GO", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14)),
           );
        } else {
           return ElevatedButton(
             onPressed: () {
                ref.read(questProvider.notifier).markManualComplete(quest.id);
             },
             style: ElevatedButton.styleFrom(
               backgroundColor: Colors.grey.shade100,
               foregroundColor: AppTheme.textMuted,
               elevation: 0,
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14)
             ),
             child: Text("DONE", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13)),
           );
        }
    }
  }

  void _handleNavigation(BuildContext context, WidgetRef ref, String actionId) {
    Widget targetScreen;
    if (actionId == 'nav_hotspots') {
      targetScreen = const HotspotScreen();
    } else if (actionId == 'nav_ai') {
      targetScreen = const AIChatScreen();
    } else if (actionId == 'nav_vaccine') {
      targetScreen = const VaccineScreen();
    } else {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => targetScreen),
    ).then((_) {
      ref.read(questProvider.notifier).completeQuestByAction(actionId);
    });
  }
}
