import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:my_sejahtera_ng/core/providers/user_provider.dart';
import 'package:my_sejahtera_ng/core/theme/app_theme.dart';
import 'package:my_sejahtera_ng/core/utils/ui_utils.dart';

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
              username: _usernameController.text.trim().split('@')[0],
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
            Navigator.pop(context);
          },
        );
        
      } catch (e) {
        if (!mounted) return;
        final rawError = e.toString();
        
        if (rawError.contains("User already registered") || rawError.contains("already exists")) {
          showDialog(
            context: context,
            builder: (ctx) => Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.userX, color: AppTheme.warning, size: 48),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Account Exists",
                        style: Theme.of(context).textTheme.displayMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "An account with this email is already registered. What would you like to do?",
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            Navigator.pop(context);
                          },
                          child: const Text("Login Instead"),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _usernameController.clear();
                          },
                          child: const Text("Use Different Email", style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        } else {
          showElegantErrorDialog(
            context,
            title: "Registration Failed",
            message: getFriendlyErrorMessage(e),
            buttonText: "Try Again",
            icon: LucideIcons.alertTriangle,
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Create Account"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppTheme.surfaceWhite,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  )
                ]
              ),
              child: Column(
                children: [
                  _buildTextField("Full Name", LucideIcons.user, _nameController),
                  const SizedBox(height: 20),
                  _buildTextField("IC Number", LucideIcons.creditCard, _icController, 
                      validator: (val) {
                        if (val == null || val.isEmpty) return "Required";
                        if (!RegExp(r'^\d{6}-\d{2}-\d{4}$').hasMatch(val) && val.length < 12) return "Enter valid IC (e.g. 990101-14-1234)";
                        return null;
                      }),
                  const SizedBox(height: 20),
                  _buildTextField("Phone Number", LucideIcons.phone, _phoneController,
                      validator: (val) {
                        if (val == null || val.isEmpty) return "Required";
                        if (!RegExp(r'^\+?[\d\-\s]{9,15}$').hasMatch(val)) return "Enter valid phone number";
                        return null;
                      }),
                  const SizedBox(height: 20),
                  _buildTextField("Email", LucideIcons.mail, _usernameController,
                      validator: (val) {
                        if (val == null || val.isEmpty) return "Required";
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) return "Enter valid email";
                        return null;
                      }),
                  const SizedBox(height: 20),
                  _buildTextField("Password", LucideIcons.lock, _passwordController, isPassword: true,
                      validator: (val) {
                        if (val == null || val.isEmpty) return "Required";
                        if (val.length < 6) return "At least 6 characters";
                        return null;
                      }),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.black12),
                  const SizedBox(height: 24),
                  
                  // Security Question Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedSecurityQuestion,
                    dropdownColor: AppTheme.surfaceWhite,
                    style: const TextStyle(color: AppTheme.textDark),
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: "Security Question",
                      prefixIcon: Icon(LucideIcons.shieldQuestion, color: AppTheme.primaryBlue),
                    ),
                    items: _securityQuestions.map((q) => DropdownMenuItem(value: q, child: Text(q, overflow: TextOverflow.ellipsis, maxLines: 1))).toList(),
                    onChanged: (val) => setState(() => _selectedSecurityQuestion = val!),
                  ),

                  const SizedBox(height: 20),
                  _buildTextField("Answer", LucideIcons.keyRound, _securityAnswerController,
                      validator: (val) => val == null || val.isEmpty ? "Please answer the security question" : null),
                  
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSignUp,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Register", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ).animate().slideY(begin: 0.1, end: 0, duration: 600.ms, curve: Curves.easeOutCubic).fadeIn(),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {bool isPassword = false, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(color: AppTheme.textDark),
      validator: validator ?? (value) => value!.isEmpty ? "Required" : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryBlue),
      ),
    );
  }
}
