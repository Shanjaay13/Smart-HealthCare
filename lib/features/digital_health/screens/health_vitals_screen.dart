import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:my_sejahtera_ng/core/theme/app_theme.dart';
import 'package:my_sejahtera_ng/features/digital_health/providers/vitals_provider.dart';

class HealthVitalsScreen extends ConsumerWidget {
  const HealthVitalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vitals = ref.watch(vitalsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // AppTheme.bgLight
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            backgroundColor: const Color(0xFFF8FAFC),
            elevation: 0,
            pinned: true,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
              title: Text(
                "Health Vitals",
                style: GoogleFonts.outfit(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w900,
                  fontSize: 32,
                  letterSpacing: -1,
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: _buildConnectionToggle(context, ref, vitals.isDeviceConnected),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildPremiumBmiCard(vitals),
                const SizedBox(height: 32),
                
                if (vitals.isDeviceConnected) ...[
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.success.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                        boxShadow: [
                           BoxShadow(color: AppTheme.success.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))
                        ]
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.activity, color: AppTheme.success, size: 18)
                            .animate(onPlay: (c) => c.repeat()).fade(duration: 1.seconds),
                          const SizedBox(width: 8),
                          Text("LIVE SENSOR SYNC ACTIVE", style: GoogleFonts.outfit(color: AppTheme.success, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 12)),
                        ],
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),
                  ),
                  const SizedBox(height: 32),
                ],

                Text(
                  "KEY METRICS",
                  style: GoogleFonts.outfit(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 16),

                _buildBackgroundChartCard(
                  context, ref, 
                  "Heart Rate", "${vitals.heartRate}", "BPM", 
                  const Color(0xFFEF4444), LucideIcons.heartPulse, 
                  [70, 72, 75, 73, 78, 74, vitals.heartRate.toDouble()], 
                  isLive: vitals.isDeviceConnected,
                  onTap: () => _handleCardTap(context, ref, vitals.isDeviceConnected, "Heart Rate", (val) => ref.read(vitalsProvider.notifier).updateHeartRate(int.parse(val)))
                ),

                _buildBackgroundChartCard(
                  context, ref, 
                  "Blood Pressure", "${vitals.systolicBP}/${vitals.diastolicBP}", "mmHg", 
                  const Color(0xFF3B82F6), LucideIcons.activity, 
                  [118, 120, 119, 121, 122, 120, vitals.systolicBP.toDouble()],
                  isLive: vitals.isDeviceConnected,
                  onTap: () => vitals.isDeviceConnected ? _showDeviceToast(context) : _updateBP(context, ref)
                ), 

                _buildBackgroundChartCard(
                  context, ref, 
                  "Body Weight", "${vitals.weight}", "kg", 
                  const Color(0xFFF59E0B), LucideIcons.scale, 
                  [66, 65.8, 65.5, 65.3, 65.1, 65.0, vitals.weight],
                  onTap: () => _showUpdateSheet(context, ref, "Weight (kg)", (val) => ref.read(vitalsProvider.notifier).updateWeight(double.parse(val)))
                ),

                _buildBackgroundChartCard(
                  context, ref, 
                  "Height", "${vitals.height}", "cm", 
                  const Color(0xFF8B5CF6), LucideIcons.ruler, 
                  [175, 175, 175, 175, 175, 175, vitals.height],
                  onTap: () => _showUpdateSheet(context, ref, "Height (cm)", (val) => ref.read(vitalsProvider.notifier).updateHeight(double.parse(val)))
                ),
                
                const SizedBox(height: 48),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumBmiCard(dynamic vitals) {
    Color ringColor = _getBmiColor(vitals.bmiStatus);
    
    String assetPath;
    if (vitals.bmiStatus == 'Underweight') {
      assetPath = 'assets/images/bmi_underweight.png';
    } else if (vitals.bmiStatus == 'Obese' || vitals.bmiStatus == 'Overweight') {
      assetPath = 'assets/images/bmi_overweight.png';
    } else {
      assetPath = 'assets/images/bmi_normal.png'; 
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: ringColor.withOpacity(0.12),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Left: Animated 3D Avatar
          Image.asset(
            assetPath,
            height: 140,
            width: 100,
            fit: BoxFit.contain,
          ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(begin: -5, end: 5, duration: 2.seconds),
          
          // Right: Info
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Your BMI",
                style: GoogleFonts.outfit(
                  color: AppTheme.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    vitals.bmi.toStringAsFixed(1),
                    style: GoogleFonts.outfit(
                      color: AppTheme.textDark,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: ringColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      vitals.bmiStatus == 'Normal' ? LucideIcons.checkCircle2 : LucideIcons.alertCircle,
                      color: ringColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      vitals.bmiStatus,
                      style: GoogleFonts.outfit(
                        color: ringColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildBackgroundChartCard(
      BuildContext context, WidgetRef ref, 
      String title, String value, String unit,
      Color color, IconData icon, List<double> dataPoints, 
      {VoidCallback? onTap, bool isLive = false}) {
      
    // Create soft gradient for background sparkline
    final gradientColors = [color.withOpacity(0.2), color.withOpacity(0.0)];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 170, // Slightly taller for more dramatic chart
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: Colors.white, width: 2), // Gives a subtle bevel
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.06), // Very soft tinted shadow
              blurRadius: 24,
              offset: const Offset(0, 10),
            )
          ]
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            children: [
              // Background Chart rendering filling the bottom half
              Positioned.fill(
                top: 50, 
                bottom: -10, // Let it bleed out the bottom
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineTouchData: const LineTouchData(enabled: false), // Disable touches to let GestureDetector handle it
                    lineBarsData: [
                       LineChartBarData(
                         spots: dataPoints.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                         isCurved: true,
                         color: color.withOpacity(0.3), // Soft line
                         barWidth: 4,
                         isStrokeCapRound: true,
                         dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) {
                            if (index == dataPoints.length - 1) { 
                              return FlDotCirclePainter(radius: 5, color: color, strokeWidth: 2, strokeColor: Colors.white);
                            }
                            return FlDotCirclePainter(radius: 0, color: Colors.transparent);
                         }),
                         belowBarData: BarAreaData(
                           show: true,
                           gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: gradientColors,
                           )
                         ),
                       ),
                    ],
                    minX: 0,
                    maxX: dataPoints.length.toDouble() - 1,
                    // Dynamic scaling to make chart look prominent but not overlapping text
                    minY: dataPoints.reduce((a, b) => a < b ? a : b) * 0.95,
                    maxY: dataPoints.reduce((a, b) => a > b ? a : b) * 1.05,
                  ),
                ),
              ),
              
              // Foreground Content Overlay
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(icon, color: color, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              title,
                              style: GoogleFonts.outfit(
                                color: AppTheme.textMuted,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (isLive)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.radio, size: 12, color: AppTheme.success).animate(onPlay: (c) => c.repeat()).fade(),
                                const SizedBox(width: 4),
                                const Text("LIVE", style: TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          )
                        else
                          Icon(LucideIcons.plus, color: AppTheme.textMuted.withOpacity(0.3), size: 20),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          value,
                          style: GoogleFonts.outfit(
                            color: AppTheme.textDark,
                            fontSize: 44,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          unit,
                          style: GoogleFonts.outfit(
                            color: AppTheme.textMuted.withOpacity(0.7),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn().slideY(begin: 0.1),
    );
  }

  // --- Utility & Bottom Sheets ---

  Widget _buildConnectionToggle(BuildContext context, WidgetRef ref, bool isConnected) {
    return GestureDetector(
      onTap: () {
        ref.read(vitalsProvider.notifier).toggleDeviceConnection(!isConnected);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isConnected ? "Device Disconnected. Switched to Manual Mode." : "Smart Watch Connected! Receiving Live Data...", style: const TextStyle(color: Colors.white)),
            backgroundColor: isConnected ? AppTheme.textMuted : AppTheme.success,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            behavior: SnackBarBehavior.floating,
          )
        );
      },
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isConnected ? AppTheme.success.withOpacity(0.15) : AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isConnected ? AppTheme.success.withOpacity(0.3) : Colors.black12),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.watch, color: isConnected ? AppTheme.success : AppTheme.textMuted, size: 16),
              const SizedBox(width: 8),
              Text(isConnected ? "Syncing" : "Pair Watch", style: GoogleFonts.outfit(color: isConnected ? AppTheme.success : AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  void _handleCardTap(BuildContext context, WidgetRef ref, bool isConnected, String title, Function(String) onSave) {
    if (isConnected) {
      _showDeviceToast(context);
    } else {
      _showUpdateSheet(context, ref, title, onSave);
    }
  }

  void _showDeviceToast(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Reading from Smart Watch. Disable connection for manual input.", style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.textDark,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      )
    );
  }

  Color _getBmiColor(String status) {
    if (status == 'Normal') return AppTheme.success;
    if (status == 'Overweight') return const Color(0xFFF59E0B);
    if (status == 'Obese') return AppTheme.error;
    return AppTheme.primaryBlue; 
  }

  void _showUpdateSheet(BuildContext context, WidgetRef ref, String title, Function(String) onSave) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Update $title", style: GoogleFonts.outfit(color: AppTheme.textDark, fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppTheme.textDark),
              decoration: InputDecoration(
                hintText: "Enter new value",
                hintStyle: const TextStyle(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.bgLight,
                enabledBorder: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(16)),
                focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.primaryBlue, width: 2), borderRadius: BorderRadius.circular(16)),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    onSave(controller.text);
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                child: Text("SAVE METRIC", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _updateBP(BuildContext context, WidgetRef ref) {
     final sysCtrl = TextEditingController();
     final diaCtrl = TextEditingController();
     showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text("Update Blood Pressure", style: GoogleFonts.outfit(color: AppTheme.textDark, fontSize: 24, fontWeight: FontWeight.w900)),
             const SizedBox(height: 24),
             Row(
               children: [
                 Expanded(
                   child: TextField(
                     controller: sysCtrl, 
                     keyboardType: TextInputType.number, 
                     style: const TextStyle(color: AppTheme.textDark), 
                     decoration: InputDecoration(
                       labelText: "Systolic", 
                       labelStyle: const TextStyle(color: AppTheme.textMuted),
                       filled: true,
                       fillColor: AppTheme.bgLight,
                       border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(16)),
                     )
                   )
                 ),
                 const SizedBox(width: 16),
                 Expanded(
                   child: TextField(
                     controller: diaCtrl, 
                     keyboardType: TextInputType.number, 
                     style: const TextStyle(color: AppTheme.textDark), 
                     decoration: InputDecoration(
                       labelText: "Diastolic", 
                       labelStyle: const TextStyle(color: AppTheme.textMuted),
                       filled: true,
                       fillColor: AppTheme.bgLight,
                       border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: BorderRadius.circular(16)),
                     )
                   )
                 ),
               ],
             ),
             const SizedBox(height: 32),
             SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (sysCtrl.text.isNotEmpty && diaCtrl.text.isNotEmpty) {
                    ref.read(vitalsProvider.notifier).updateBP(int.parse(sysCtrl.text), int.parse(diaCtrl.text));
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                child: Text("SAVE READINGS", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 16)),
              ),
             ),
             const SizedBox(height: 30),
          ],
        ),
      ));
  }
}
