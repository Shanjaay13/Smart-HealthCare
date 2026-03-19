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
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A), // Deep Slate Dark Mode
        borderRadius: BorderRadius.circular(64), // Extremely Round Shape
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(64),
        child: Padding(
          padding: const EdgeInsets.all(28),
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
                         style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                       ),
                       const SizedBox(height: 2),
                       const Text("You're doing great!", style: TextStyle(color: Colors.white70, fontSize: 13)),
                     ],
                   ),
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                     decoration: BoxDecoration(
                       color: Colors.cyanAccent.withOpacity(0.15),
                       borderRadius: BorderRadius.circular(20),
                       border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                     ),
                     child: const Row(
                       children: [
                         Icon(LucideIcons.trendingUp, color: Colors.cyanAccent, size: 16),
                         SizedBox(width: 6),
                         Text("+12%", style: TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                       ],
                     ),
                   ),
                ],
              ),
              const SizedBox(height: 24),
              
              // Chart
              SizedBox(
                height: 120, // Reduced height to stop vertical stretch
                child: LineChart(
                  LineChartData(
                    minY: 0, // Gives floor padding so line doesn't hit text
                    maxY: 8, // Gives ceiling padding
                    minX: -0.2, // Gives left breathing room
                    maxX: 6.2, // Gives right breathing room
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
                            if (value < 0 || value > 6 || value % 1 != 0) {
                              return const SizedBox.shrink();
                            }

                            const style = TextStyle(
                              color: Colors.white54,
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
                              default: return const SizedBox.shrink();
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
                        color: Colors.cyanAccent,
                        barWidth: 6,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        shadow: const Shadow(color: Colors.cyanAccent, blurRadius: 10, offset: Offset(0, 4)),
                        belowBarData: BarAreaData(
                          show: true,
                          color: Colors.cyanAccent.withOpacity(0.1),
                          gradient: LinearGradient(
                            colors: [
                              Colors.cyanAccent.withOpacity(0.4),
                              Colors.cyanAccent.withOpacity(0.0),
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
                  Expanded(child: _buildStatItem(LucideIcons.moon, "7h 30m", "Sleep", const Color(0xFF8B5CF6))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatItem(LucideIcons.footprints, "8,432", "Steps", const Color(0xFFF59E0B))),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatItem(LucideIcons.activity, "72 bpm", "Vitals", const Color(0xFFEF4444))),
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
          color: Color(0xFF1E293B), // Seamless integration with parent aesthetic
          borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Center(child: Container(width: 48, height: 6, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(3)))),
             const SizedBox(height: 32),
             Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               children: [
                 Text(dayName, style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                   decoration: BoxDecoration(color: Colors.cyanAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(24)),
                   child: Text("Score: $score", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16)),
                 )
               ],
             ),
             const SizedBox(height: 12),
             Text(guidance, style: const TextStyle(color: Colors.white70, fontSize: 16)),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
