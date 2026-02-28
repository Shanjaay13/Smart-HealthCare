import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_sejahtera_ng/core/providers/user_provider.dart';
import 'package:my_sejahtera_ng/core/theme/app_theme.dart';
import 'package:my_sejahtera_ng/core/widgets/glass_container.dart';
import 'package:my_sejahtera_ng/core/widgets/holo_id_card.dart';
import 'package:my_sejahtera_ng/features/auth/screens/sign_up_screen.dart';
import 'package:my_sejahtera_ng/features/dashboard/screens/dashboard_screen.dart';
import 'package:my_sejahtera_ng/features/auth/screens/forgot_password_screen.dart';
import 'package:my_sejahtera_ng/features/vaccine/screens/vaccine_setup_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_sejahtera_ng/core/utils/ui_utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    // Listen for Deep Links (Email Verification)
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        // Automatically route user upon email verification deep link
        if (mounted && Navigator.canPop(context) == false) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Email verified! Logging you in automatically..."),
              backgroundColor: Colors.green,
            ),
          );
          _handleLoginSuccess();
        }
      }
    });

    // Check if the link already verified the user before this screen fully launched
    if (Supabase.instance.client.auth.currentSession != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleLoginSuccess();
      });
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLoginSuccess() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && mounted) {
      try {
        final records = await Supabase.instance.client
            .from('vaccine_records')
            .select()
            .eq('user_id', user.id);
            
        if (records.isEmpty) {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const VaccineSetupScreen()),
          );
        } else {
          Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
           Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
        }
      }
    }
  }

  void _handleLogin() async {
    // Basic validation
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter both email and password"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Use Supabase Auth
      await ref.read(userProvider.notifier).login(
            _usernameController.text.trim(),
            _passwordController.text.trim(),
          );

      if (!mounted) return;

      await _handleLoginSuccess();
      
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString();
      if (errorMsg.contains("Invalid login credentials") || errorMsg.contains("400")) {
        showElegantErrorDialog(
          context,
          title: "Login Failed",
          message: "The email or password you entered is incorrect. Please check your credentials and try again.",
          buttonText: "Try Again",
          icon: LucideIcons.alertCircle,
        );
      } else {
        showElegantErrorDialog(
          context,
          title: "Login Failed",
          message: getFriendlyErrorMessage(e),
          buttonText: "Try Again",
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToSignUp() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo / Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.05),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentTeal.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        )
                      ]
                    ),
                    child: const Icon(LucideIcons.shieldCheck, size: 60, color: AppTheme.accentTeal),
                  )
                  .animate()
                  .scale(duration: 800.ms, curve: Curves.easeOutBack)
                  .then()
                  .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.5)),

                  const SizedBox(height: 30),

                  // Title
                  Column(
                    children: [
                      Text(
                        "Welcome Back",
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Sign in to continue",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0, duration: 600.ms),

                  const SizedBox(height: 40),

                  // Login Form
                  GlassContainer(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      children: [
                          _buildTextField(
                            label: "Email",
                            icon: LucideIcons.mail,
                            controller: _usernameController,
                            delay: 400.ms,
                          ),
                        const SizedBox(height: 20),
                        _buildTextField(
                          label: "Password",
                          icon: LucideIcons.lock,
                          isPassword: true,
                          controller: _passwordController,
                          delay: 500.ms,
                        ),
                        const SizedBox(height: 15),
                        
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()));
                            },
                            child: const Text("Forgot Password?", style: TextStyle(color: Colors.white60)),
                          ),
                        ).animate().fadeIn(delay: 600.ms),

                        const SizedBox(height: 25),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentTeal,
                              foregroundColor: AppTheme.primaryDark,
                              elevation: 10,
                              shadowColor: AppTheme.accentTeal.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: AppTheme.primaryDark, strokeWidth: 3),
                                  )
                                : const Text(
                                    "Login",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ),
                        ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0),
                      ],
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0, duration: 800.ms),

                  const SizedBox(height: 30),

                  // Footer
                  Column(
                    children: [
                      TextButton(
                        onPressed: _navigateToSignUp,
                        child: const Text.rich(
                          TextSpan(
                            text: "Don't have an account? ",
                            style: TextStyle(color: Colors.white60),
                            children: [
                              TextSpan(
                                text: "Create Account",
                                style: TextStyle(color: AppTheme.accentTeal, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      IconButton(
                        onPressed: _showEmergencySearch,
                        icon: const Icon(LucideIcons.siren, color: Colors.redAccent, size: 28),
                        tooltip: "Emergency Medical Access",
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.red.withOpacity(0.1),
                          padding: const EdgeInsets.all(12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.redAccent.withOpacity(0.5))),
                        ),
                      ).animate().fade(duration: 2.seconds).scale(),
                      const SizedBox(height: 5),
                      const Text("EMERGENCY ACCESS", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    ],
                  ).animate().fadeIn(delay: 900.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEmergencySearch() {
    final icCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B1E),
        title: Row(children: [const Icon(LucideIcons.siren, color: Colors.redAccent), const SizedBox(width: 10), const Text("Emergency Access", style: TextStyle(color: Colors.white))]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Authorized Personnel Only. Enter IC Number to view medical ID.", style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 20),
            TextField(
              controller: icCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: "IC Number",
                labelStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(LucideIcons.search, color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Navigator.pop(ctx);
              // In a real app, this would query the backend. 
              // For prototype, we show a dummy "found" user if IC is not empty.
              if (icCtrl.text.isNotEmpty) {
                _showEmergencyCard(icCtrl.text);
              }
            }, 
            child: const Text("ACCESS DATA")
          ),
        ],
      ),
    );
  }

  void _showEmergencyCard(String ic) {
    // Mock user for emergency display
    final emergencyUser = UserSession(
      id: "0",
      username: "emergency_view",
      fullName: "CITIZEN $ic",
      icNumber: ic,
      phone: "N/A",
      bloodType: "O+",
      allergies: "Penicillin, Peanuts",
      medicalCondition: "Asthma, Diabetes Type 2",
      emergencyContact: "+6012-999-9999 (Mother)",
    );

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)),
              child: const Text("EMERGENCY MEDICAL RECORD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
            const SizedBox(height: 20),
            // We use standard HoloIdCard but pass the mock user data
            // We explicitly import HoloIdCard in the file header next
            SizedBox(
              height: 230,
              child: HoloIdCard(userData: emergencyUser),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(LucideIcons.x, size: 16),
              label: const Text("CLOSE RECORD"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white24, foregroundColor: Colors.white),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    bool isPassword = false,
    required Duration delay,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white60),
        prefixIcon: Icon(icon, color: Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.08),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          borderRadius: BorderRadius.circular(16),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppTheme.accentTeal, width: 2),
          borderRadius: BorderRadius.circular(16),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    ).animate().fadeIn(delay: delay).slideX(begin: -0.1, end: 0, duration: 600.ms);
  }
}
