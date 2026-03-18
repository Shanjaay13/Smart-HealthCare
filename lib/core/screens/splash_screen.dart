import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_sejahtera_ng/features/auth/screens/login_screen.dart';
import 'package:my_sejahtera_ng/features/dashboard/screens/dashboard_screen.dart';
import 'package:my_sejahtera_ng/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to Dashboard or Login after animation
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
         final session = Supabase.instance.client.auth.currentSession;
         final Widget nextScreen = session != null ? const DashboardScreen() : const LoginScreen();

         Navigator.of(context).pushReplacement(
           PageRouteBuilder(
             pageBuilder: (_, __, ___) => nextScreen,
             transitionsBuilder: (_, animation, __, child) {
               return FadeTransition(opacity: animation, child: child);
             },
             transitionDuration: const Duration(milliseconds: 800),
           ),
         );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight, 
      body: Stack(
        children: [
          // 1. Dynamic Background Gradient (Subtle pulse)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.bgLight, const Color(0xFFF0FDF4), const Color(0xFFEFF6FF)],
              ),
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scale(begin: const Offset(1,1), end: const Offset(1.1, 1.1), duration: 5.seconds),
           
          // 2. Center Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icon Animation
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.15),
                        blurRadius: 40,
                        spreadRadius: 10,
                        offset: const Offset(0, 15)
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: const Offset(0, 5)
                      )
                    ]
                  ),
                  child: const Icon(LucideIcons.heartPulse, color: AppTheme.primaryBlue, size: 70),
                ).animate()
                 .scale(duration: 1200.ms, curve: Curves.easeOutBack, begin: const Offset(0,0), end: const Offset(1,1))
                 .shimmer(delay: 1200.ms, duration: 1500.ms, color: AppTheme.primaryBlue.withOpacity(0.2))
                 .then() 
                 .boxShadow(begin: BoxShadow(color: AppTheme.primaryBlue.withOpacity(0)), end: BoxShadow(color: AppTheme.primaryBlue.withOpacity(0.2), blurRadius: 40, spreadRadius: 15, offset: const Offset(0, 15)), duration: 1000.ms),

                const SizedBox(height: 35),

                // Text Animation "Smart HealthCare"
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Smart",
                      style: GoogleFonts.outfit(
                        color: AppTheme.primaryBlue,
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "HealthCare",
                      style: GoogleFonts.outfit(
                        color: AppTheme.textDark,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ).animate()
                 .fadeIn(delay: 600.ms, duration: 800.ms)
                 .slideY(begin: 0.3, end: 0, duration: 800.ms, curve: Curves.easeOutCubic)
              ],
            ),
          ),
          
          // 3. Bottom Loading Indicator
          Positioned(
            bottom: 60,
            left: 0, right: 0,
            child: Center(
              child: SizedBox(
                width: 40, height: 40,
                child: const CircularProgressIndicator(
                  color: AppTheme.primaryBlue,
                  strokeWidth: 3,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 1500.ms),
        ],
      ),
    );
  }
}
