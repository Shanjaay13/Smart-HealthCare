import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_sejahtera_ng/core/theme/app_theme.dart';

class HealthInsightBanner extends ConsumerStatefulWidget {
  const HealthInsightBanner({super.key});

  @override
  ConsumerState<HealthInsightBanner> createState() => _HealthInsightBannerState();
}

class _HealthInsightBannerState extends ConsumerState<HealthInsightBanner> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 280,
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(50),
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(50),
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Weekly Score",
                        style: GoogleFonts.outfit(
                          color: AppTheme.textDark,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "You're doing great!",
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.trendingUp, color: AppTheme.success, size: 16),
                        const SizedBox(width: 4),
                        const Text("+12%", style: TextStyle(color: AppTheme.success, fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Chart
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          reservedSize: 22,
                          getTitlesWidget: (value, meta) {
                            const style = TextStyle(
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            );
                            String text;
                            switch (value.toInt()) {
                              case 0: text = 'M'; break;
                              case 1: text = 'T'; break;
                              case 2: text = 'W'; break;
                              case 3: text = 'T'; break;
                              case 4: text = 'F'; break;
                              case 5: text = 'S'; break;
                              case 6: text = 'S'; break;
                              default: return Container();
                            }
                            return Text(text, style: style);
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    lineTouchData: LineTouchData(
                    handleBuiltInTouches: true, // We still want tooltips
                      touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
                        if (event is FlTapUpEvent && touchResponse != null && touchResponse.lineBarSpots != null) {
                          final spotIndex = touchResponse.lineBarSpots!.first.spotIndex;
                          _showDailyDetails(context, spotIndex);
                        }
                      },
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) => AppTheme.textDark,
                        fitInsideHorizontally: true,
                        fitInsideVertically: true,
                        tooltipPadding: const EdgeInsets.all(12),
                        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                          return touchedBarSpots.map((barSpot) {
                            return LineTooltipItem(
                              'Score: ${barSpot.y.toInt()}',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: '\nTap for details',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 10,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                              ],
                            );
                          }).toList();
                        },
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: const [
                          FlSpot(0, 3),
                          FlSpot(1, 4),
                          FlSpot(2, 3.5),
                          FlSpot(3, 5),
                          FlSpot(4, 4.5),
                          FlSpot(5, 6),
                          FlSpot(6, 6.5)
                        ],
                        isCurved: true,
                        color: AppTheme.primaryBlue,
                        barWidth: 4,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppTheme.primaryBlue.withOpacity(0.2),
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.primaryBlue.withOpacity(0.3),
                              AppTheme.primaryBlue.withOpacity(0.0),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Stats Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem(LucideIcons.moon, "7h 30m", "Sleep", const Color(0xFF8B5CF6)),
                  _buildStatItem(LucideIcons.footprints, "8,432", "Steps", const Color(0xFFF59E0B)),
                  _buildStatItem(LucideIcons.activity, "72 bpm", "Vitals", const Color(0xFFEF4444)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDailyDetails(BuildContext context, int dayIndex) {
    // Mock Data for demonstration
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final dayName = days[dayIndex];
    final score = [3, 4, 3.5, 5, 4.5, 6, 6.5][dayIndex];
    
    final steps = (score * 1500).toInt(); 
    final sleep = "${(score + 4).toInt()}h 30m";
    final bpm = 60 + (score * 2).toInt();
    final guidance = _getGuidance(dayIndex);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Center(child: Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3)))),
             const SizedBox(height: 32),
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text(dayName, style: GoogleFonts.outfit(color: AppTheme.textDark, fontSize: 28, fontWeight: FontWeight.bold)),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                   decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(24)),
                   child: Text("Score: $score", style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 16)),
                 )
               ],
             ),
             const SizedBox(height: 12),
             Text(guidance, style: const TextStyle(color: AppTheme.textMuted, fontSize: 16)),
             const SizedBox(height: 32),
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 _buildDetailCard(LucideIcons.footprints, "$steps", "Steps", const Color(0xFFF59E0B)),
                 _buildDetailCard(LucideIcons.moon, sleep, "Sleep", const Color(0xFF8B5CF6)),
                 _buildDetailCard(LucideIcons.activity, "$bpm", "BPM", const Color(0xFFEF4444)),
               ],
             ),
             const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(IconData icon, String value, String label, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _getGuidance(int dayIndex) {
    switch (dayIndex) {
      case 0: return "Start the week strong! A bit more walking needed.";
      case 1: return "Good effort. Try to get to bed earlier.";
      case 2: return "Mid-week slump? Hydrate and stretch.";
      case 3: return "Great momentum! Keep it up.";
      case 4: return "Fri-yay! Watch the sodium intake.";
      case 5: return "Solid weekend activity. Cardio looking good.";
      case 6: return "Perfect Sunday recovery. You're ready for next week!";
      default: return "";
    }
  }

  Widget _buildStatItem(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(value, style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
