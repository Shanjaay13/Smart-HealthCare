import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_sejahtera_ng/core/theme/app_theme.dart';
import 'package:my_sejahtera_ng/core/widgets/glass_container.dart';
import 'package:my_sejahtera_ng/features/auth/screens/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class VaccineSetupScreen extends ConsumerStatefulWidget {
  const VaccineSetupScreen({super.key});

  @override
  ConsumerState<VaccineSetupScreen> createState() => _VaccineSetupScreenState();
}

class _VaccineSetupScreenState extends ConsumerState<VaccineSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _batchController = TextEditingController();
  final _locationController = TextEditingController();
  final _doseController = TextEditingController(text: "1");
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.accentTeal,
              onPrimary: Colors.black,
              surface: Color(0xFF161B1E),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveRecord() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final supabase = Supabase.instance.client;
        final user = supabase.auth.currentUser;
        
        // If auto-confirm is off, they might not be logged in yet.
        if (user != null) {
          final data = {
            'user_id': user.id,
            'vaccine_name': _nameController.text.trim(),
            'batch_number': _batchController.text.trim(),
            'location': _locationController.text.trim(),
            'dose_number': int.tryParse(_doseController.text.trim()) ?? 1,
            'date_administered': _selectedDate.toIso8601String().split('T')[0],
            'status': 'Completed',
          };
          await supabase.from('vaccine_records').insert(data);
        } else {
          // In case user hasn't generated a session yet due to email confirm
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("Cannot save records until email is confirmed and you are logged in."))
          );
        }

        if (mounted) {
           _finishSetup();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _finishSetup() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Setup complete! You can now login.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.primaryDark, AppTheme.primaryBlue],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                const Icon(LucideIcons.syringe, color: AppTheme.accentTeal, size: 48),
                const SizedBox(height: 20),
                const Text(
                  "Add Vaccine Record",
                  style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                  "You can set up your vaccination certificate now, or skip and do it later from the Dashboard.",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 30),
                
                GlassContainer(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: _buildTextField("Vaccine Name", LucideIcons.shieldCheck, _nameController),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              flex: 1,
                              child: _buildTextField("Dose", LucideIcons.hash, _doseController, isNumber: true),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        _buildTextField("Batch Number", LucideIcons.barcode, _batchController),
                        const SizedBox(height: 15),
                        _buildTextField("Location Given", LucideIcons.mapPin, _locationController),
                        const SizedBox(height: 15),
                        
                        // Date Picker
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.calendar, color: Colors.white54),
                                const SizedBox(width: 15),
                                Text(
                                  DateFormat('dd MMM yyyy').format(_selectedDate),
                                  style: const TextStyle(color: Colors.white, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveRecord,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accentTeal,
                              foregroundColor: AppTheme.primaryDark,
                            ),
                            child: _isLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryDark))
                                : const Text("Save & Continue", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: TextButton(
                            onPressed: _isLoading ? null : _finishSetup,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white70,
                            ),
                            child: const Text("Skip for now", style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, TextEditingController controller, {bool isNumber = false}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: (val) => val == null || val.isEmpty ? "Required" : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white54),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white12), borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: AppTheme.accentTeal), borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
