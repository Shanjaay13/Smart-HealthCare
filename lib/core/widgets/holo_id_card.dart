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
      child: Container(
        height: 235,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(40),
          ),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF60A5FA), Color(0xFF2563EB)], // Softer Blue Gradient
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.2),
              blurRadius: 30,
              offset: const Offset(0, 15),
            )
          ],
        ),
        child: Stack(
          children: [
            // Decorative background curves
            Positioned(
              right: -50,
              top: -50,
              child: Opacity(
                opacity: 0.1,
                child: Container(
                  width: 200, height: 200,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -30,
              child: Opacity(
                opacity: 0.1,
                child: Container(
                  width: 140, height: 140,
                  decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: AnimatedSwitcher(
                duration: 400.ms,
                transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(anim), child: child)),
                child: _showMedicalInfo 
                    ? _buildMedicalInfo(user, isOwner) 
                    : _buildIdentityInfo(user, progress, isOwner),
              ),
            ),

            // Edit Button
            if (isOwner)
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: Icon(LucideIcons.pencil, color: Colors.white.withOpacity(0.7), size: 18),
                  onPressed: _showEditDialog,
                ),
              ),
              
            // Mode Indicator
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
                child: Text(_showMedicalInfo ? "MEDICAL" : "IDENTITY", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildIdentityInfo(UserSession? user, UserProgress progress, bool isOwner) {
    return Column(
      key: const ValueKey('identity'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.shieldCheck, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text("SMART HEALTH ID", style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold)),
          ],
        ),
        const Spacer(),
        Row(
          children: [
            Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(LucideIcons.user, color: Colors.white, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    user?.fullName.toUpperCase() ?? "GUEST USER", 
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  Text("IC: ${user?.icNumber ?? '----------------'}", style: GoogleFonts.shareTechMono(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildBadge("LVL ${progress.level}"),
                      _buildBadge("FULLY VACCINATED"),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildMedicalInfo(UserSession? user, bool isOwner) {
    return Column(
      key: const ValueKey('medical'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.cross, color: Colors.redAccent, size: 20),
            const SizedBox(width: 8),
            Text("EMERGENCY INFO", style: GoogleFonts.outfit(color: Colors.redAccent, fontSize: 14, letterSpacing: 2, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildMedicalField("BLOOD TYPE", user?.bloodType ?? "Unknown", Colors.white)),
            const SizedBox(width: 16),
            Expanded(child: _buildMedicalField("ALLERGIES", user?.allergies ?? "None", Colors.white)),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildMedicalField("CONDITION", user?.medicalCondition ?? "None", Colors.white)),
            const SizedBox(width: 16),
            Expanded(child: _buildMedicalField("CONTACT", user?.emergencyContact ?? "Not Set", Colors.white)),
          ],
        ),
      ],
    );
  }

  Widget _buildMedicalField(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold), maxLines: 2, overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text, style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
