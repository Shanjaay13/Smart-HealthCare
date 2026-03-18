import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:my_sejahtera_ng/core/theme/app_theme.dart';
import 'package:my_sejahtera_ng/features/gamification/providers/quest_provider.dart';
import 'package:my_sejahtera_ng/features/gamification/providers/user_progress_provider.dart';
import 'package:my_sejahtera_ng/features/gamification/models/voucher.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(userProgressProvider);
    final quests = ref.watch(questProvider);
    final shopInventory = UserProgressNotifier.shopInventory;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Rewards & Shop', style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: true,
        backgroundColor: AppTheme.bgLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        actions: [
           IconButton(
            onPressed: () {
              ref.read(userProgressProvider.notifier).cheatLevelUp();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text("Cheater! XP & Points Added!"),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                )
              );
            },
            icon: const Icon(LucideIcons.zap, color: Color(0xFFF59E0B)),
          ).animate().shimmer(delay: 5.seconds, duration: 2.seconds)
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Points & Level Header
            _buildPointsHeader(progress).animate().fadeIn().slideY(begin: 0.1),
            const SizedBox(height: 32),

            // Dynamic Daily Quests (Modified Header)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFFF59E0B).withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(LucideIcons.flame, color: Color(0xFFF59E0B), size: 18)
                ),
                const SizedBox(width: 12),
                const Text("Daily Quests", style: TextStyle(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 16),

            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  if (quests.isEmpty)
                     const Padding(
                       padding: EdgeInsets.all(16.0),
                       child: Text("No quests available right now.", style: TextStyle(color: AppTheme.textMuted)),
                     ),
                  
                  ...quests.asMap().entries.map((entry) {
                    final index = entry.key;
                    final quest = entry.value;
                    return Column(
                      children: [
                        _buildQuestRow(
                          quest.title, 
                          "+${quest.xp} XP • +${quest.points} Pts", 
                          quest.status == QuestStatus.completed || quest.status == QuestStatus.claimed, 
                          quest.icon,
                          _getQuestColor(index),
                          onTap: () {
                            if (quest.status == QuestStatus.pending) {
                              ref.read(questProvider.notifier).markManualComplete(quest.id);
                            } else if (quest.status == QuestStatus.completed) {
                              ref.read(questProvider.notifier).claimQuest(quest.id, ref);
                            }
                          }
                        ),
                        if (index < quests.length - 1)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: Colors.black12),
                          ),
                      ],
                    );
                  }),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideX(),
            
            const SizedBox(height: 40),
            
            // Points Shop
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(LucideIcons.shoppingBag, color: AppTheme.primaryBlue, size: 18)
                ),
                const SizedBox(width: 12),
                const Text("Rewards Shop", style: TextStyle(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ).animate().fadeIn(delay: 300.ms),
            const SizedBox(height: 16),
            
            // Vertical List of Vouchers
            ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: shopInventory.length,
                itemBuilder: (context, index) {
                  final voucher = shopInventory[index];
                  final isRedeemed = progress.redeemedVoucherIds.contains(voucher.id);
                  final canAfford = progress.points >= voucher.cost;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _buildVoucherShopCard(context, ref, voucher, isRedeemed, canAfford)
                        .animate().fadeIn(delay: (300 + (index * 100)).ms).slideX(),
                  );
                },
            ),
            const SizedBox(height: 20),
          ],
        ),
      )),
    );
  }

  Color _getQuestColor(int index) {
    const colors = [AppTheme.primaryBlue, Color(0xFFF59E0B), AppTheme.success, Color(0xFF8B5CF6), Color(0xFFEC4899)];
    return colors[index % colors.length];
  }

  Widget _buildPointsHeader(UserProgress progress) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue,
         gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryBlue, Color(0xFF1E40AF)]
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.3), 
            blurRadius: 24, 
            offset: const Offset(0, 10)
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("YOUR POINTS", style: TextStyle(color: Colors.white70, letterSpacing: 1.5, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text("${progress.points}", style: GoogleFonts.outfit(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900)),
                      const Text(" pts", style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.coins, color: Color(0xFFFCD34D), size: 36),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress.xp, // Level progress
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Level ${progress.level}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              const Text("Next Level", style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildVoucherShopCard(BuildContext context, WidgetRef ref, Voucher voucher, bool isRedeemed, bool canAfford) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: voucher.brandColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: voucher.brandColor.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(LucideIcons.tag, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(voucher.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(voucher.description, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    if (isRedeemed)
                       Container(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(voucher.discountCode, style: TextStyle(color: voucher.brandColor, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                            Icon(LucideIcons.copy, size: 18, color: voucher.brandColor),
                          ],
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: canAfford ? () => _confirmRedemption(context, ref, voucher) : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: voucher.brandColor,
                          disabledBackgroundColor: Colors.black26,
                          disabledForegroundColor: Colors.white38,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(canAfford ? "Redeem" : "Locked", style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Container(width: 2, height: 12, color: canAfford ? voucher.brandColor.withOpacity(0.3) : Colors.white24),
                            const SizedBox(width: 8),
                            Text("${voucher.cost} pts", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: canAfford ? voucher.brandColor.withOpacity(0.8) : Colors.white38)),
                          ],
                        ),
                      )
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmRedemption(BuildContext context, WidgetRef ref, Voucher voucher) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Redeem Reward?", style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)),
        content: Text("Spend ${voucher.cost} points to unlock '${voucher.title}'?", style: const TextStyle(color: AppTheme.textMuted, height: 1.4)),
        actions: [
          TextButton(
            child: const Text("Cancel", style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
            ),
            child: const Text("Confirm", style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
               final success = ref.read(userProgressProvider.notifier).redeemVoucher(voucher.id);
               Navigator.pop(ctx);
               if (success) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text("Voucher Redeemed! Check your shop."),
                    backgroundColor: AppTheme.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                 ));
               } else {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: const Text("Not enough points!"),
                    backgroundColor: AppTheme.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                 ));
               }
            },
          ),
        ],
      )
    );
  }

  Widget _buildQuestRow(String title, String subtitle, bool isCompleted, IconData icon, Color color, {Function()? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title, 
                  style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 15)
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          if (isCompleted)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.success.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                   Icon(LucideIcons.checkCheck, color: AppTheme.success, size: 14),
                   SizedBox(width: 4),
                   Text("DONE", style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 10)),
                ],
              ),
            ).animate().scale(curve: Curves.elasticOut)
          else
            Container(
               width: 24, height: 24,
               decoration: BoxDecoration(
                 border: Border.all(color: Colors.black12, width: 2),
                 shape: BoxShape.circle
               ),
            ),
        ],
      ),
    );
  }
}
