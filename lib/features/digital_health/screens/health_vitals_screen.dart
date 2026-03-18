import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text("Health Vitals", style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)), 
        backgroundColor: AppTheme.bgLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
        actions: [
          _buildConnectionToggle(context, ref, vitals.isDeviceConnected),
          const SizedBox(width: 16),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [                 
              // Always show BMI Status
              // 3D Avatar & BMI Status Visualizer
              Center(child: _buildBmiAvatar(vitals.bmiStatus)),
              const SizedBox(height: 32),

              // Show Live Data Indicator if Connected
              if (vitals.isDeviceConnected) ...[
                 Center(
                   child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.success.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.activity, color: AppTheme.success, size: 18)
                          .animate(onPlay: (c) => c.repeat()).fade(duration: 1.seconds),
                        const SizedBox(width: 8),
                        const Text("LIVE DEVICE DATA", style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 12)),
                      ],
                    ),
                                   ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),
                 ),
                 const SizedBox(height: 24),
              ],

              _buildChartCard(context, ref, "Heart Rate", "${vitals.heartRate} bpm", AppTheme.error, LucideIcons.heart, [70, 72, 75, 73, 78, 74, vitals.heartRate.toDouble()], 
                isLive: vitals.isDeviceConnected,
                onTap: () => _handleCardTap(context, ref, vitals.isDeviceConnected, "Heart Rate", (val) => ref.read(vitalsProvider.notifier).updateHeartRate(int.parse(val)))),
              const SizedBox(height: 20),
              _buildChartCard(context, ref, "Blood Pressure", "${vitals.systolicBP}/${vitals.diastolicBP} mmHg", AppTheme.primaryBlue, LucideIcons.activity, [118, 120, 119, 121, 122, 120, vitals.systolicBP.toDouble()],
                isLive: vitals.isDeviceConnected,
                onTap: () => vitals.isDeviceConnected ? _showDeviceToast(context) : _updateBP(context, ref)), 
              const SizedBox(height: 20),
               _buildChartCard(context, ref, "Weight", "${vitals.weight} kg", const Color(0xFFF59E0B), LucideIcons.scale, [66, 65.8, 65.5, 65.3, 65.1, 65.0, vitals.weight],
                 // Allow manual update for weight even if connected, usually scales are separate
                 onTap: () => _showUpdateSheet(context, ref, "Weight (kg)", (val) => ref.read(vitalsProvider.notifier).updateWeight(double.parse(val)))),
              const SizedBox(height: 20),
               _buildChartCard(context, ref, "Height", "${vitals.height} cm", const Color(0xFF8B5CF6), LucideIcons.ruler, [175, 175, 175, 175, 175, 175, vitals.height],
                 onTap: () => _showUpdateSheet(context, ref, "Height (cm)", (val) => ref.read(vitalsProvider.notifier).updateHeight(double.parse(val)))),
            ],
          ),
        ),
      ),
    );
  }

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
            color: isConnected ? AppTheme.success.withOpacity(0.1) : AppTheme.surfaceWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isConnected ? AppTheme.success.withOpacity(0.3) : Colors.black12),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.watch, color: isConnected ? AppTheme.success : AppTheme.textMuted, size: 16),
              const SizedBox(width: 8),
              Text(isConnected ? "Connected" : "Sync Watch", style: TextStyle(color: isConnected ? AppTheme.success : AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 12)),
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
        content: const Text("Reading from Smart Watch... Disable connection for manual input.", style: TextStyle(color: Colors.white)),
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
            Text("Update $title", style: const TextStyle(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.bold)),
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
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text("SAVE UPDATE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
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
             const Text("Update Blood Pressure", style: TextStyle(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.bold)),
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
             const SizedBox(height: 24),
             SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (sysCtrl.text.isNotEmpty && diaCtrl.text.isNotEmpty) {
                    ref.read(vitalsProvider.notifier).updateBP(int.parse(sysCtrl.text), int.parse(diaCtrl.text));
                    Navigator.pop(ctx);
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text("SAVE UPDATE", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              ),
             ),
             const SizedBox(height: 30),
          ],
        ),
      ));
  }

  Widget _buildChartCard(BuildContext context, WidgetRef ref, String title, String value, Color color, IconData icon, List<double> dataPoints, {VoidCallback? onTap, bool isLive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 14, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (isLive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.radio, size: 10, color: AppTheme.success).animate(onPlay: (c) => c.repeat()).fade(),
                        const SizedBox(width: 4),
                        const Text("LIVE", style: TextStyle(color: AppTheme.success, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                else
                  const Icon(LucideIcons.edit2, size: 16, color: AppTheme.textMuted),
              ],
            ),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(color: AppTheme.textDark, fontSize: 32, fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            // Real Chart Visualization
            SizedBox(
              height: 80,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: dataPoints.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                      isCurved: true,
                      color: color,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) {
                         if (index == dataPoints.length - 1) { // Show dot on last point
                           return FlDotCirclePainter(radius: 4, color: color, strokeWidth: 2, strokeColor: Colors.white);
                         }
                         return FlDotCirclePainter(radius: 0, color: Colors.transparent);
                      }),
                      belowBarData: BarAreaData(
                        show: true,
                        color: color.withOpacity(0.1), 
                        gradient: LinearGradient(
                           begin: Alignment.topCenter,
                           end: Alignment.bottomCenter,
                           colors: [color.withOpacity(0.2), color.withOpacity(0.0)]
                        )
                      ),
                    ),
                  ],
                  minX: 0,
                  maxX: dataPoints.length.toDouble() - 1,
                  minY: dataPoints.reduce((a, b) => a < b ? a : b) * 0.95,
                  maxY: dataPoints.reduce((a, b) => a > b ? a : b) * 1.05,
                ),
                duration: const Duration(milliseconds: 300), 
                curve: Curves.easeInOut,
              ),
            ),
          ],
        ),
      ).animate().fadeIn().slideY(duration: 400.ms, begin: 0.1),
    );
  }

  Widget _buildBmiAvatar(String status) {
    String assetPath;
    if (status == 'Underweight') {
      assetPath = 'assets/images/bmi_underweight.png';
    } else if (status == 'Obese' || status == 'Overweight') {
      assetPath = 'assets/images/bmi_overweight.png';
    } else {
      assetPath = 'assets/images/bmi_normal.png'; 
    }

    return Column(
      children: [
        SizedBox(
          height: 240, 
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child)),
            child: Container(
              key: ValueKey(status),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 30,
                    spreadRadius: 5,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.contain,
                    height: 200,
                    width: 200, 
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: _getBmiColor(status).withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: _getBmiColor(status).withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                status == 'Normal' ? LucideIcons.thumbsUp : (status == 'Underweight' ? LucideIcons.arrowDown : LucideIcons.arrowUp),
                color: _getBmiColor(status),
                size: 20
              ),
              const SizedBox(width: 8),
              Text(
                "BMI: $status",
                style: TextStyle(color: _getBmiColor(status), fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 0.5),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.3),
      ],
    );
  }
}
