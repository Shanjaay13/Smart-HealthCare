import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Daily Goals", style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontSize: 20
            )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withOpacity(0.15), 
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text("LVL ${progress.level}", style: const TextStyle(color: Color(0xFFD97706), fontWeight: FontWeight.bold)),
            )
          ],
        ),
        const SizedBox(height: 16),
        
        // XP Bar
        Container(
          height: 12, 
          width: double.infinity,
          decoration: BoxDecoration(color: AppTheme.bgLight, borderRadius: BorderRadius.circular(6)),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.xp,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: const Color(0xFFF59E0B),
              ),
            ),
          ).animate(target: progress.xp == 1 ? 1 : 0).shimmer(duration: 1.seconds),
        ),
        const SizedBox(height: 8),
        Text("${(progress.xp * 1000).toInt()} / 1000 XP", style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
        
        const SizedBox(height: 24),
        
        // Quests List
        ...quests.map((quest) {
           return Padding(
             padding: const EdgeInsets.only(bottom: 16),
             child: Container(
               decoration: BoxDecoration(
                 color: AppTheme.surfaceWhite,
                 borderRadius: BorderRadius.circular(40),
                 boxShadow: [
                   BoxShadow(
                     color: const Color(0xFF6366F1).withOpacity(0.1),
                     blurRadius: 20,
                     offset: const Offset(0, 8),
                   )
                 ]
               ),
               padding: const EdgeInsets.all(16),
               child: Row(
                 children: [
                   Container(
                     padding: const EdgeInsets.all(12),
                     decoration: BoxDecoration(
                       color: quest.status == QuestStatus.claimed ? AppTheme.success.withOpacity(0.1) : AppTheme.bgLight,
                       shape: BoxShape.circle
                     ),
                     child: Icon(
                        quest.status == QuestStatus.claimed ? LucideIcons.check : quest.icon, 
                        color: quest.status == QuestStatus.claimed ? AppTheme.success : AppTheme.textDark, 
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
                           style: TextStyle(
                             color: quest.status == QuestStatus.claimed ? AppTheme.textMuted : AppTheme.textDark,
                             decoration: quest.status == QuestStatus.claimed ? TextDecoration.lineThrough : null,
                             fontWeight: FontWeight.w600,
                             fontSize: 15
                           )
                         ),
                         const SizedBox(height: 4),
                         Text(
                            "+${quest.xp} XP", 
                            style: const TextStyle(color: Color(0xFFD97706), fontSize: 13, fontWeight: FontWeight.bold)
                         ),
                       ],
                     ),
                   ),
                   
                   _buildActionButton(context, ref, quest),
                 ],
               ),
             ),
           );
        })
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, WidgetRef ref, Quest quest) {
    switch (quest.status) {
      case QuestStatus.claimed:
        return const SizedBox.shrink(); // Hide button if claimed
        
      case QuestStatus.completed:
        return ElevatedButton(
          onPressed: () {
            ref.read(questProvider.notifier).claimQuest(quest.id, ref);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF59E0B),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
          ),
          child: const Text("Claim"),
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
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
             ),
             child: const Text("GO", style: TextStyle(fontWeight: FontWeight.bold)),
           );
        } else {
          return ElevatedButton(
             onPressed: () {
                ref.read(questProvider.notifier).markManualComplete(quest.id);
             },
             style: ElevatedButton.styleFrom(
               backgroundColor: AppTheme.bgLight,
               foregroundColor: AppTheme.textMuted,
               elevation: 0,
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
             ),
             child: const Text("Done"),
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
