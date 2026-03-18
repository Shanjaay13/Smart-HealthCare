import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_sejahtera_ng/core/theme/app_theme.dart';
import 'package:my_sejahtera_ng/features/gamification/providers/user_progress_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_sejahtera_ng/features/check_in/services/check_in_service.dart';
import 'package:my_sejahtera_ng/core/utils/ui_utils.dart';

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key});

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> with SingleTickerProviderStateMixin {
  late AnimationController _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.black, // true camera background is mostly black
      appBar: AppBar(
        leading: const BackButton(color: Colors.white),
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("Safe Entry", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
             icon: const Icon(LucideIcons.history, color: Colors.white),
             onPressed: () async {
               final history = await CheckInService().getHistory();
               if (!context.mounted) return;
               
               showDialog(
                 context: context,
                 builder: (ctx) => AlertDialog(
                   backgroundColor: AppTheme.surfaceWhite,
                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                   title: const Text("Check-In History", style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)),
                   content: SizedBox(
                     width: double.maxFinite,
                     child: history.isEmpty 
                     ? const Text("No recent check-ins found.", style: TextStyle(color: AppTheme.textMuted))
                     : ListView.builder(
                       shrinkWrap: true,
                       itemCount: history.length,
                       itemBuilder: (ctx, i) {
                         final item = history[i];
                         final time = DateTime.parse(item['check_in_time']).toLocal();
                         return ListTile(
                           leading: Container(
                             padding: const EdgeInsets.all(10),
                             decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                             child: const Icon(LucideIcons.mapPin, color: AppTheme.primaryBlue),
                           ),
                           title: Text(item['location_name'] ?? "Unknown", style: const TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)),
                           subtitle: Text("${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2,'0')}", style: const TextStyle(color: AppTheme.textMuted)),
                         );
                       },
                     ),
                   ),
                   actions: [
                     ElevatedButton(
                       onPressed: () => Navigator.pop(ctx), 
                       style: ElevatedButton.styleFrom(backgroundColor: AppTheme.bgLight, foregroundColor: AppTheme.textDark, elevation: 0),
                       child: const Text("CLOSE", style: TextStyle(fontWeight: FontWeight.bold))
                     )
                   ],
                 ),
               );
             },
          )
        ],
      ),
      body: Stack(
        children: [
          // 1. Full Screen Camera Placeholder with Gradient Overlay
          Container(
            color: Colors.black,
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black54, Colors.transparent, Colors.black54],
              ).createShader(bounds),
              blendMode: BlendMode.darken,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  ),
                ),
                child: const Center(
                  child: Text("Camera Preview", style: TextStyle(color: Colors.white10, fontSize: 30, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
          
          // 2. Scanner UI
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                // Scanner Frame
                Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glass Frame
                      Container(
                        width: 280, height: 280,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                          color: Colors.black.withOpacity(0.2),
                        ),
                      ),
                      
                      // Active Corners
                      _buildCornerFrame(),
                      
                      // Moving Laser
                      AnimatedBuilder(
                        animation: _scannerController,
                        builder: (context, child) {
                          return Positioned(
                            top: 20 + (240 * _scannerController.value),
                            child: Container(
                              width: 240,
                              height: 3,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryBlue,
                                boxShadow: [
                                  BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.6), blurRadius: 15, spreadRadius: 3)
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
                
                const SizedBox(height: 30),
                Text(
                  "Align QR Code within the frame",
                  style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16),
                ).animate().fadeIn(delay: 500.ms),
                const Spacer(),
                
                // Bottom Controls
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceWhite,
                      borderRadius: BorderRadius.circular(50),
                      boxShadow: [
                         BoxShadow(
                           color: Colors.black.withOpacity(0.1),
                           blurRadius: 20,
                           offset: const Offset(0, 10),
                         )
                      ]
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(onPressed: (){}, icon: const Icon(LucideIcons.zap, color: AppTheme.textMuted)),
                        const SizedBox(width: 24),
                        // Simulate Scan Button
                        GestureDetector(
                          onTap: () async {
                             try {
                               final mockPlaces = ["Sunway Pyramid", "Mid Valley", "KLCC", "Pavilion", "One Utama"];
                               final place = (mockPlaces..shuffle()).first;
                               
                               await CheckInService().checkIn(place, "Kuala Lumpur");
                               
                               if (!context.mounted) return;
                               ScaffoldMessenger.of(context).showSnackBar(
                                 SnackBar(
                                   content: Text("Checked in at $place!", style: const TextStyle(fontWeight: FontWeight.bold)), 
                                   backgroundColor: AppTheme.success,
                                   behavior: SnackBarBehavior.floating,
                                   shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                 ),
                               );
                               ref.read(userProgressProvider.notifier).completeQuest('checkIn');
                               Navigator.pop(context);
                             } catch (e) {
                               showElegantErrorDialog(
                                 context,
                                 title: "Check-in Failed",
                                 message: getFriendlyErrorMessage(e),
                                 buttonText: "OK",
                               );
                             }
                          },
                          child: Container(
                            width: 70, height: 70,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryBlue,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 4))
                              ]
                            ),
                            child: const Icon(LucideIcons.scanLine, color: Colors.white, size: 30),
                          ),
                        ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1,1), end: const Offset(1.05,1.05)),
                        const SizedBox(width: 24),
                        IconButton(onPressed: (){}, icon: const Icon(LucideIcons.image, color: AppTheme.textMuted)),
                      ],
                    ),
                  ),
                ).animate().slideY(begin: 1, end: 0, delay: 300.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCornerFrame() {
    const double size = 30;
    const double thickness = 5;
    const color = AppTheme.primaryBlue;
    
    return SizedBox(
      width: 280, height: 280,
      child: Stack(
        children: [
          Positioned(top: 0, left: 0, child: Container(width: size, height: thickness, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)))),
          Positioned(top: 0, left: 0, child: Container(width: thickness, height: size, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)))),
          
          Positioned(top: 0, right: 0, child: Container(width: size, height: thickness, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)))),
          Positioned(top: 0, right: 0, child: Container(width: thickness, height: size, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)))),
          
          Positioned(bottom: 0, left: 0, child: Container(width: size, height: thickness, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)))),
          Positioned(bottom: 0, left: 0, child: Container(width: thickness, height: size, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)))),
          
          Positioned(bottom: 0, right: 0, child: Container(width: size, height: thickness, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)))),
          Positioned(bottom: 0, right: 0, child: Container(width: thickness, height: size, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)))),
        ],
      ),
    );
  }
}
