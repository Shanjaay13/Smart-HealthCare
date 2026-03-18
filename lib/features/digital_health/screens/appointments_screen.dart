import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:my_sejahtera_ng/core/theme/app_theme.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text("Book Appointment", style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)), 
        backgroundColor: AppTheme.bgLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: const TextField(
                  style: TextStyle(color: AppTheme.textDark),
                  decoration: InputDecoration(
                      hintText: "Search clinics, hospitals...",
                      hintStyle: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                      prefixIcon: Icon(LucideIcons.search, color: AppTheme.textMuted)
                    ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceWhite,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))
                        ]
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(LucideIcons.building, color: AppTheme.primaryBlue, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Clinic Care Plus ${index + 1}", 
                                    style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                const Text("General Practice • 2km away", 
                                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
                                const SizedBox(height: 8),
                                Row(
                                  children: List.generate(5, (i) => Icon(LucideIcons.star, color: i < 4 ? const Color(0xFFF59E0B) : AppTheme.bgLight, size: 14)),
                                )
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: const Text("Book", style: TextStyle(fontWeight: FontWeight.bold)),
                          )
                        ],
                      ),
                    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.2, end: 0),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
