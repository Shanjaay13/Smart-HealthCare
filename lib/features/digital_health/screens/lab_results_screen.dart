import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:my_sejahtera_ng/core/theme/app_theme.dart';

class LabResultsScreen extends StatelessWidget {
  const LabResultsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text("Lab Results", style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)), 
        backgroundColor: AppTheme.bgLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
             const SizedBox(height: 8),

             _buildReportCard("Blood Test - Full Blood Count", "12 Jan 2024", true),
             _buildReportCard("Urine Analysis", "10 Dec 2023", true),
             _buildReportCard("X-Ray Report", "05 Nov 2023", false),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(String title, String date, bool isNormal) {
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
                 color: AppTheme.primaryBlue.withOpacity(0.1),
                 borderRadius: BorderRadius.circular(12),
               ),
               child: const Icon(LucideIcons.fileText, color: AppTheme.primaryBlue, size: 24),
             ),
             const SizedBox(width: 16),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(title, style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 16)),
                   const SizedBox(height: 4),
                   Text(date, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                 ],
               ),
             ),
             Container(
               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
               decoration: BoxDecoration(
                 color: isNormal ? AppTheme.success.withOpacity(0.1) : const Color(0xFFF59E0B).withOpacity(0.1),
                 borderRadius: BorderRadius.circular(12),
               ),
               child: Text(isNormal ? "Normal" : "Review", 
                  style: TextStyle(color: isNormal ? AppTheme.success : const Color(0xFFF59E0B), fontWeight: FontWeight.bold, fontSize: 12)),
             )
          ],
        ),
      ).animate().fadeIn().slideX(),
    );
  }
}
