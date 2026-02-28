import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:my_sejahtera_ng/core/providers/user_provider.dart';
import 'package:my_sejahtera_ng/core/theme/app_theme.dart';
import 'package:my_sejahtera_ng/core/widgets/glass_container.dart';
import 'package:my_sejahtera_ng/core/utils/ui_utils.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_sejahtera_ng/features/vaccine/screens/vaccine_setup_screen.dart';

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _icController = TextEditingController();
  final _phoneController = TextEditingController();
  final _securityAnswerController = TextEditingController();

  final List<String> _securityQuestions = [
    "What is your favorite local food (e.g. Nasi Lemak)?",
    "Where did you go for primary school?",
    "What is your childhood nickname?",
    "In what city did your parents meet?",
    "What is the name of your first pet?",
  ];
  String _selectedSecurityQuestion = "What is your favorite local food (e.g. Nasi Lemak)?";

  bool _isLoading = false;

  void _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await ref.read(userProvider.notifier).signUp(
              email: _usernameController.text.trim(),
              password: _passwordController.text.trim(),
              fullName: _nameController.text.trim(),
              username: _usernameController.text.trim().split('@')[0], // Extract username from email
              icNumber: _icController.text.trim(),
              phone: _phoneController.text.trim(),
              securityQuestion: _selectedSecurityQuestion,
              securityAnswer: _securityAnswerController.text.trim(),
            );

        if (!mounted) return;

        showElegantSuccessDialog(
          context,
          title: "Registration Successful!",
          message: "Your account has been created. A verification link has been sent to your email. Please verify your email before logging in.",
          buttonText: "Go to Login",
          onPressed: () {
            Navigator.pop(context); // Go back to login screen
          },
        );
        
      } catch (e) {
        if (!mounted) return;
        final errorMsg = e.toString();
        showElegantErrorDialog(
          context,
          title: "Registration Failed",
          message: getFriendlyErrorMessage(e),
          buttonText: "Try Again",
          icon: LucideIcons.alertTriangle,
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Create Account"),
        leading: const BackButton(color: Colors.white),
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryDark, AppTheme.primaryBlue],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: GlassContainer(
                child: Column(
                  children: [
                    _buildTextField("Full Name", LucideIcons.user, _nameController),
                    const SizedBox(height: 15),
                    _buildTextField("IC Number", LucideIcons.creditCard, _icController, 
                        validator: (val) {
                          if (val == null || val.isEmpty) return "Required";
                          if (!RegExp(r'^\d{6}-\d{2}-\d{4}$').hasMatch(val) && val.length < 12) return "Enter valid IC (e.g. 990101-14-1234)";
                          return null;
                        }),
                    const SizedBox(height: 15),
                    _buildTextField("Phone Number", LucideIcons.phone, _phoneController,
                        validator: (val) {
                          if (val == null || val.isEmpty) return "Required";
                          if (!RegExp(r'^\+?[\d\-\s]{9,15}$').hasMatch(val)) return "Enter valid phone number";
                          return null;
                        }),
                    const SizedBox(height: 15),
                    _buildTextField("Email", LucideIcons.mail, _usernameController,
                        validator: (val) {
                          if (val == null || val.isEmpty) return "Required";
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) return "Enter valid email";
                          return null;
                        }),
                    const SizedBox(height: 15),
                    _buildTextField("Password", LucideIcons.lock, _passwordController, isPassword: true,
                        validator: (val) {
                          if (val == null || val.isEmpty) return "Required";
                          if (val.length < 6) return "At least 6 characters";
                          return null;
                        }),
                    const SizedBox(height: 15),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 10),
                    
                    // Security Question Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedSecurityQuestion,
                      dropdownColor: const Color(0xFF161B1E),
                      style: const TextStyle(color: Colors.white),
                      isExpanded: true, // Prevents text overflow
                      decoration: InputDecoration(
                        labelText: "Security Question",
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(LucideIcons.shieldQuestion, color: Colors.white70),
                        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white30), borderRadius: BorderRadius.circular(12)),
                        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.accentTeal), borderRadius: BorderRadius.circular(12)),
                      ),
                      items: _securityQuestions.map((q) => DropdownMenuItem(value: q, child: Text(q, overflow: TextOverflow.ellipsis, maxLines: 1))).toList(),
                      onChanged: (val) => setState(() => _selectedSecurityQuestion = val!),
                    ),

                    const SizedBox(height: 15),
                    _buildTextField("Answer", LucideIcons.keyRound, _securityAnswerController,
                        validator: (val) => val == null || val.isEmpty ? "Please answer the security question" : null),
                    
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? _handleSignUp : _handleSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentTeal,
                          foregroundColor: AppTheme.primaryDark,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator()
                            : const Text("Register", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ).animate().slideY(begin: 0.2, end: 0),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {bool isPassword = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: Colors.white),
      validator: validator ?? (value) => value!.isEmpty ? "Required" : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white30),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: AppTheme.accentTeal),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
