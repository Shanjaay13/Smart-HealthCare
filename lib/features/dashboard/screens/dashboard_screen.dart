import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_sejahtera_ng/core/widgets/feature_detail_screen.dart';
import 'package:my_sejahtera_ng/core/widgets/holo_id_card.dart';
import 'package:my_sejahtera_ng/core/widgets/quest_board.dart';
import 'package:my_sejahtera_ng/core/widgets/bouncing_button.dart';
import 'package:my_sejahtera_ng/features/check_in/screens/check_in_screen.dart';
import 'package:my_sejahtera_ng/features/health_assistant/screens/ai_chat_screen.dart';
import 'package:my_sejahtera_ng/features/hotspots/screens/hotspot_screen.dart';
import 'package:my_sejahtera_ng/features/profile/screens/account_screen.dart';
import 'package:my_sejahtera_ng/features/vaccine/screens/vaccine_screen.dart';
import 'package:my_sejahtera_ng/features/digital_health/screens/health_dashboard_screen.dart';
import 'package:my_sejahtera_ng/features/food_tracker/food_tracker_screen.dart';
import 'package:my_sejahtera_ng/features/dashboard/widgets/health_insight_banner.dart';
import 'package:my_sejahtera_ng/features/dashboard/widgets/calorie_insight_card.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sejahtera_ng/features/gamification/providers/quest_provider.dart';
import 'package:my_sejahtera_ng/core/theme/app_theme.dart';
import 'package:my_sejahtera_ng/features/dashboard/widgets/upcoming_appointments_carousel.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              backgroundColor: AppTheme.bgLight,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              pinned: true,
              expandedHeight: 80,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                title: Text(
                  "Summary",
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 28),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(LucideIcons.bell, color: AppTheme.textDark, size: 28),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(LucideIcons.userCircle2, color: AppTheme.primaryBlue, size: 30),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen()));
                  },
                ),
                const SizedBox(width: 16),
              ],
            ),
            SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 850;
                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: isDesktop 
                            ? _buildDesktopLayout(context, ref)
                            : _buildMobileLayout(context, ref),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AIChatScreen()),
          ).then((_) {
             ref.read(questProvider.notifier).completeQuestByAction('nav_ai');
          });
        },
        backgroundColor: AppTheme.primaryBlue,
        icon: const Icon(LucideIcons.bot, color: Colors.white),
        label: const Text("Ask AI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ).animate().scale(delay: 1000.ms, duration: 500.ms, curve: Curves.elasticOut),
    );
  }

  Widget _buildMobileLayout(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle(context, "Medical Profile").animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
        const SizedBox(height: 16),
        const HoloIdCard().animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0, duration: 800.ms, curve: Curves.easeOutCubic).scale(begin: const Offset(0.9, 0.9), delay: 200.ms),
        
        const SizedBox(height: 32),
        const UpcomingAppointmentsCarousel().animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0).flipH(begin: 0.1, end: 0),
        
        const SizedBox(height: 16),
        const HealthInsightBanner().animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0).shimmer(delay: 1.seconds, duration: 2.seconds, blendMode: BlendMode.overlay, color: Colors.white24),
        
        const SizedBox(height: 24),
        const CalorieInsightCard().animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),

        const SizedBox(height: 32),
        _buildSectionTitle(context, "Quick Access").animate().fadeIn(delay: 600.ms).slideX(begin: -0.1, end: 0),
        const SizedBox(height: 24),
        _buildOrganicQuickAccess(context, ref).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1, end: 0),
        
        const SizedBox(height: 48),
        const QuestBoard().animate().fadeIn(delay: 800.ms).slideY(begin: 0.1, end: 0),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column (ID + Insights)
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionTitle(context, "Medical Profile").animate().fadeIn(delay: 100.ms).slideX(begin: -0.1, end: 0),
                  const SizedBox(height: 16),
                  const HoloIdCard().animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0, duration: 1000.ms, curve: Curves.easeOutCubic).scale(begin: const Offset(0.9, 0.9)),
                  
                  const SizedBox(height: 32),
                  const HealthInsightBanner().animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0).flipH(begin: -0.05, end: 0),
                  
                  const SizedBox(height: 32),
                  const CalorieInsightCard().animate().fadeIn(delay: 500.ms).slideY(begin: 0.1, end: 0),
                ],
              ),
            ),
            const SizedBox(width: 40),
            // Right Column (Appointments + Quick Access + Quests)
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const UpcomingAppointmentsCarousel().animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 24),
                  
                  _buildSectionTitle(context, "Quick Access").animate().fadeIn(delay: 600.ms).slideX(begin: -0.1, end: 0),
                  const SizedBox(height: 24),
                  _buildOrganicQuickAccess(context, ref).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 48),
                  const QuestBoard().animate().fadeIn(delay: 800.ms).slideY(begin: 0.1, end: 0),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.displayMedium?.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w900,
        color: AppTheme.textDark,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildOrganicQuickAccess(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 24,
      runSpacing: 24,
      alignment: WrapAlignment.center,
      children: [
        _buildActionCircle(context, ref, 'Check-In', LucideIcons.qrCode, AppTheme.primaryBlue),
        _buildActionCircle(context, ref, 'Vaccine', LucideIcons.syringe, const Color(0xFF10B981)),
        _buildActionCircle(context, ref, 'Hotspots', LucideIcons.mapPin, const Color(0xFFF59E0B)),
        _buildActionCircle(context, ref, 'Health', LucideIcons.stethoscope, const Color(0xFFEC4899)),
        _buildActionCircle(context, ref, 'Food', LucideIcons.apple, const Color(0xFF8B5CF6)),
      ],
    );
  }

  void _navigateToAction(BuildContext context, WidgetRef ref, String label) {
    Widget targetScreen;
    String? questActionId;

    if (label == 'Check-In') {
      targetScreen = const CheckInScreen();
    } else if (label == 'Vaccine') {
      targetScreen = const VaccineScreen();
      questActionId = 'nav_vaccine';
    } else if (label == 'Hotspots') {
      targetScreen = const HotspotScreen();
      questActionId = 'nav_hotspots';
    } else if (label == 'Health') {
      targetScreen = const HealthDashboardScreen();
    } else if (label == 'Food') {
      targetScreen = const FoodTrackerScreen();
    } else {
      targetScreen = FeatureDetailScreen(
        title: label,
        icon: LucideIcons.alertCircle,
        description: 'Access your $label records.',
      );
    }

    Navigator.push(context, MaterialPageRoute(builder: (context) => targetScreen)).then((_) {
      if (questActionId != null) {
        ref.read(questProvider.notifier).completeQuestByAction(questActionId);
      }
    });
  }

  Widget _buildActionPill(BuildContext context, WidgetRef ref, String label, IconData icon, Color color, {required double flexWidth}) {
    return BouncingButton(
      onTap: () => _navigateToAction(context, ref, label),
      child: Container(
        width: flexWidth,
        height: 70,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(35),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8)]),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 15)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildActionCircle(BuildContext context, WidgetRef ref, String label, IconData icon, Color color) {
    return BouncingButton(
      onTap: () => _navigateToAction(context, ref, label),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 105,
            height: 105,
            decoration: BoxDecoration(
              color: AppTheme.surfaceWhite,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.18), blurRadius: 28, offset: const Offset(0, 10))
              ],
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 38),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(label, style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w800, fontSize: 15)),
        ],
      )
    );
  }
}
