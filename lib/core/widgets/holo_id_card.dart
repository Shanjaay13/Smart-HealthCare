import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_sejahtera_ng/features/gamification/providers/user_progress_provider.dart';
import 'package:my_sejahtera_ng/core/providers/user_provider.dart';
import 'package:my_sejahtera_ng/core/theme/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HoloIdCard extends ConsumerStatefulWidget {
  final UserSession? userData;
  const HoloIdCard({super.key, this.userData});

  @override
  ConsumerState<HoloIdCard> createState() => _HoloIdCardState();
}

class _HoloIdCardState extends ConsumerState<HoloIdCard> {
  bool _showMedicalInfo = false;

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(userProgressProvider);
    final user = widget.userData ?? ref.watch(userProvider);
    final isOwner = widget.userData == null && user != null;

    return GestureDetector(
      onTap: () => setState(() => _showMedicalInfo = !_showMedicalInfo),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 650),
        curve: Curves.elasticOut,
        height: _showMedicalInfo ? 260 : 96,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_showMedicalInfo ? 36 : 100),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _showMedicalInfo
                ? const [Color(0xFFEF4444), Color(0xFF991B1B)] // Emergency Red
                : const [Color(0xFF0F172A), Color(0xFF1E293B)], // Sleek Slate
          ),
          boxShadow: [
            BoxShadow(
              color: (_showMedicalInfo ? const Color(0xFFEF4444) : const Color(0xFF0F172A)).withOpacity(0.3),
              blurRadius: 24,
              offset: const Offset(0, 12),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_showMedicalInfo ? 36 : 100),
          child: SingleChildScrollView(
            physics: const NeverScrollableScrollPhysics(),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
              child: _showMedicalInfo 
                  ? _buildExpandedMedical(user, isOwner) 
                  : _buildCompactIdentity(user, progress, isOwner),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactIdentity(UserSession? user, UserProgress progress, bool isOwner) {
    return Container(
      key: const ValueKey('compact'),
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 64, height: 64,
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white12),
            child: const Icon(LucideIcons.user, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  user?.fullName.toUpperCase() ?? "GUEST USER", 
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
                Text("IC: ${user?.icNumber ?? 'N/A'}", style: GoogleFonts.shareTechMono(color: Colors.white70, fontSize: 13)),
              ]
            ),
          ),
          _buildPillBadge("LVL ${progress.level}"),
          const SizedBox(width: 8),
          const Icon(LucideIcons.chevronDown, color: Colors.white54),
          const SizedBox(width: 8),
        ]
      )
    );
  }

  Widget _buildExpandedMedical(UserSession? user, bool isOwner) {
    return Container(
      key: const ValueKey('expanded'),
      height: 260,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Row(
                 children: [
                   const Icon(LucideIcons.heartPulse, color: Colors.white, size: 24),
                   const SizedBox(width: 12),
                   Text("EMERGENCY MEDICAL INFO", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5)),
                 ],
               ),
               Row(
                 children: [
                   if (isOwner)
                     GestureDetector(
                       onTap: () {
                         // Prevent collapse when hitting edit
                         _showEditDialog();
                       },
                       child: Container(
                         padding: const EdgeInsets.all(8),
                         decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                         child: const Icon(LucideIcons.pencil, color: Colors.white, size: 16),
                       ),
                     ),
                   const SizedBox(width: 16),
                   const Icon(LucideIcons.chevronUp, color: Colors.white54),
                 ]
               )
            ]
          ),
          const SizedBox(height: 32),
          Row(
            children: [
               Expanded(child: _buildMedField("BLOOD TYPE", user?.bloodType ?? "Unknown")),
               Expanded(child: _buildMedField("ALLERGIES", user?.allergies ?? "None")),
            ]
          ),
          const SizedBox(height: 24),
          Row(
            children: [
               Expanded(child: _buildMedField("CONDITION", user?.medicalCondition ?? "None")),
               Expanded(child: _buildMedField("EMERGENCY CONTACT", user?.emergencyContact ?? "Not Set")),
            ]
          ),
        ]
      )
    );
  }

  Widget _buildMedField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildPillBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text, style: GoogleFonts.outfit(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
    );
  }

  void _showEditDialog() {
    final user = ref.read(userProvider);
    if (user == null) return;

    final bloodCtrl = TextEditingController(text: user.bloodType);
    final allergyCtrl = TextEditingController(text: user.allergies);
    final conditionCtrl = TextEditingController(text: user.medicalCondition);
    final contactCtrl = TextEditingController(text: user.emergencyContact);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceWhite,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Update Medical ID", style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildEditField("Blood Type", bloodCtrl),
              _buildEditField("Allergies", allergyCtrl),
              _buildEditField("Medical Condition", conditionCtrl),
              _buildEditField("Emergency Contact", contactCtrl),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(userProvider.notifier).updateMedicalInfo(
                blood: bloodCtrl.text,
                allergy: allergyCtrl.text,
                condition: conditionCtrl.text,
                contact: contactCtrl.text
              );
              Navigator.pop(ctx);
            },
            child: const Text("SAVE"),
          ),
        ],
      ),
    );
  }

  Widget _buildEditField(String label, TextEditingController ctrl) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: ctrl,
        style: const TextStyle(color: AppTheme.textDark),
        decoration: InputDecoration(
          labelText: label,
        ),
      ),
    );
  }
}
