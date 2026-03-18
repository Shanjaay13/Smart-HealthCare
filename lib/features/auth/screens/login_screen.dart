import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_sejahtera_ng/core/providers/user_provider.dart';
import 'package:my_sejahtera_ng/core/theme/app_theme.dart';
import 'package:my_sejahtera_ng/core/widgets/holo_id_card.dart';
import 'package:my_sejahtera_ng/features/auth/screens/sign_up_screen.dart';
import 'package:my_sejahtera_ng/features/dashboard/screens/dashboard_screen.dart';
import 'package:my_sejahtera_ng/features/auth/screens/forgot_password_screen.dart';
import 'package:my_sejahtera_ng/features/vaccine/screens/vaccine_setup_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_sejahtera_ng/core/utils/ui_utils.dart';
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
        if (mounted && Navigator.canPop(context) == false) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Email verified! Logging you in automatically..."),
              backgroundColor: AppTheme.success,
            ),
          );
          _handleLoginSuccess();
        }
      }
    });

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
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter both email and password"),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryBlue.withOpacity(0.1),
                  ),
                  child: const Icon(LucideIcons.heartPulse, size: 60, color: AppTheme.primaryBlue),
                ).animate().scale(duration: 800.ms, curve: Curves.easeOutCubic),

                const SizedBox(height: 32),

                // Title
                Column(
                  children: [
                    Text(
                      "Smart HealthCare",
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 28,
                            color: AppTheme.primaryBlue,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Sign in to your account",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textMuted,
                          ),
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOutCubic),

                const SizedBox(height: 48),

                // Login Form Card
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceWhite,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryBlue.withOpacity(0.05),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      )
                    ]
                  ),
                  child: Column(
                    children: [
                      _buildTextField(
                        label: "Email",
                        icon: LucideIcons.mail,
                        controller: _usernameController,
                        delay: 300.ms,
                      ),
                      const SizedBox(height: 20),
                      _buildTextField(
                        label: "Password",
                        icon: LucideIcons.lock,
                        isPassword: true,
                        controller: _passwordController,
                        delay: 400.ms,
                      ),
                      const SizedBox(height: 12),
                      
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()));
                          },
                          child: const Text("Forgot Password?", style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w600)),
                        ),
                      ).animate().fadeIn(delay: 500.ms),

                      const SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                )
                              : const Text(
                                  "Login",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
                    ],
                  ),
                ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1, end: 0, duration: 800.ms, curve: Curves.easeOutCubic),

                const SizedBox(height: 32),

                // Footer
                Column(
                  children: [
                    TextButton(
                      onPressed: _navigateToSignUp,
                      child: const Text.rich(
                        TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(color: AppTheme.textMuted),
                          children: [
                            TextSpan(
                              text: "Create Account",
                              style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    IconButton(
                      onPressed: _showEmergencySearch,
                      icon: const Icon(LucideIcons.siren, color: AppTheme.error, size: 28),
                      tooltip: "Emergency Medical Access",
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.error.withOpacity(0.1),
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ).animate().fade(duration: 2.seconds).scale(),
                    const SizedBox(height: 8),
                    const Text("EMERGENCY ACCESS", style: TextStyle(color: AppTheme.error, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                  ],
                ).animate().fadeIn(delay: 800.ms),
              ],
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
        backgroundColor: AppTheme.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(children: [const Icon(LucideIcons.siren, color: AppTheme.error), const SizedBox(width: 12), const Text("Emergency Access", style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold))]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Authorized Personnel Only. Enter IC Number to view medical ID.", style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
            const SizedBox(height: 24),
            TextField(
              controller: icCtrl,
              style: const TextStyle(color: AppTheme.textDark),
              decoration: InputDecoration(
                labelText: "IC Number",
                prefixIcon: const Icon(LucideIcons.search, color: AppTheme.textMuted),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL", style: TextStyle(color: AppTheme.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () {
              Navigator.pop(ctx);
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
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(color: AppTheme.error, borderRadius: BorderRadius.circular(24)),
              child: const Text("EMERGENCY MEDICAL RECORD", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 230,
              child: HoloIdCard(userData: emergencyUser),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(ctx),
              icon: const Icon(LucideIcons.x, size: 18),
              label: const Text("CLOSE RECORD"),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.surfaceWhite, foregroundColor: AppTheme.textDark),
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
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: AppTheme.textDark, fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
      ),
    ).animate().fadeIn(delay: delay).slideX(begin: -0.05, end: 0, duration: 600.ms, curve: Curves.easeOutCubic);
  }
}
