import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:my_sejahtera_ng/features/digital_health/models/medication.dart';
import 'package:my_sejahtera_ng/core/utils/ui_utils.dart';
import 'package:my_sejahtera_ng/core/theme/app_theme.dart';

class AddMedicationSheet extends StatefulWidget {
  final Future<void> Function(Medication) onSave;
  final Medication? initialData; // Added for editing
  final Future<void> Function()? onDelete; // Optional delete action

  const AddMedicationSheet({
    super.key, 
    required this.onSave, 
    this.initialData,
    this.onDelete,
  });

  @override
  State<AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends State<AddMedicationSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late final TextEditingController _pillsController;
  late final TextEditingController _instructionsController;
  
  // Custom Timer State
  bool _isTimerMode = false;
  DateTime _selectedTime = DateTime.now();
  int _selectedDurationMinutes = 5; // Default 5 mins

  @override
  void initState() {
    super.initState();
    final init = widget.initialData;
    _nameController = TextEditingController(text: init?.name ?? '');
    _dosageController = TextEditingController(text: init?.dosage ?? '');
    _pillsController = TextEditingController(text: init?.pillsToTake.toString() ?? '');
    _instructionsController = TextEditingController(text: init?.instructions ?? '');
    
    if (init != null) {
      _selectedTime = init.time;
      _isTimerMode = init.isOneTime;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _pillsController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedTime),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryBlue,
              onPrimary: Colors.white,
              surface: AppTheme.surfaceWhite,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        final now = DateTime.now();
        _selectedTime = DateTime(
            now.year, now.month, now.day, picked.hour, picked.minute);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 24,
        right: 24,
        top: 24,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.initialData == null ? "Add Medication" : "Edit Medication",
                    style: GoogleFonts.outfit(
                      color: AppTheme.textDark,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn().slideY(begin: 0.3),
                  if (widget.onDelete != null)
                    IconButton(
                      icon: const Icon(LucideIcons.trash2, color: AppTheme.error),
                      onPressed: () async {
                        await widget.onDelete!();
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                widget.initialData == null ? "Set reminders to stay on track." : "Update your medication details.",
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
              ).animate().fadeIn().slideY(begin: 0.3, delay: 100.ms),
              const SizedBox(height: 30),

              // Inputs
              _buildModernTextField(
                controller: _nameController,
                label: "Medicine Name",
                hint: "e.g., Paracetamol",
                icon: LucideIcons.pill,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ).animate().fadeIn().slideX(delay: 200.ms),
              
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildModernTextField(
                      controller: _dosageController,
                      label: "Dosage",
                      hint: "e.g., 500mg",
                      icon: LucideIcons.flaskConical,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildModernTextField(
                      controller: _pillsController,
                      label: "Quantity",
                      hint: "Count",
                      icon: LucideIcons.hash,
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ).animate().fadeIn().slideX(delay: 300.ms),
              
              const SizedBox(height: 16),
              
              // Toggle: Specific Time vs Timer
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.bgLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isTimerMode = false),
                        child: AnimatedContainer(
                          duration: 300.ms,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isTimerMode ? AppTheme.primaryBlue.withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: !_isTimerMode ? AppTheme.primaryBlue : Colors.transparent),
                          ),
                          alignment: Alignment.center,
                          child: Text("Specific Time", style: TextStyle(color: !_isTimerMode ? AppTheme.primaryBlue : AppTheme.textMuted, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isTimerMode = true),
                        child: AnimatedContainer(
                          duration: 300.ms,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isTimerMode ? const Color(0xFFF59E0B).withOpacity(0.1) : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _isTimerMode ? const Color(0xFFF59E0B) : Colors.transparent),
                          ),
                          alignment: Alignment.center,
                          child: Text("Timer (Countdown)", style: TextStyle(color: _isTimerMode ? const Color(0xFFF59E0B) : AppTheme.textMuted, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideX(delay: 350.ms),

              const SizedBox(height: 16),

              // Time Selection Area
              AnimatedSwitcher(
                duration: 300.ms,
                child: _isTimerMode 
                  ? _buildTimerSelector() 
                  : _buildTimePicker(),
              ),
              
              const SizedBox(height: 16),
              
              _buildModernTextField(
                controller: _instructionsController,
                label: "Instructions (Optional)",
                hint: "e.g., After lunch",
                icon: LucideIcons.fileText,
              ).animate().fadeIn().slideX(delay: 500.ms),

              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                      () async {
                        try {
                          DateTime finalTime = _selectedTime;
                          if (_isTimerMode) {
                            finalTime = DateTime.now().add(Duration(minutes: _selectedDurationMinutes));
                          }
                          
                          final Medication medToSave = Medication(
                            id: widget.initialData?.id,
                            name: _nameController.text.isEmpty ? "Quick Timer" : _nameController.text,
                            dosage: _dosageController.text.isEmpty ? "General" : _dosageController.text,
                            pillsToTake: int.tryParse(_pillsController.text) ?? 1,
                            time: finalTime,
                            instructions: _instructionsController.text, 
                            isOneTime: _isTimerMode,
                            isTaken: widget.initialData?.isTaken ?? false, 
                          );
                          
                          await widget.onSave(medToSave); 
                          
                          if (!context.mounted) return;
                          
                          // Show Feedback
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: _isTimerMode ? const Color(0xFFF59E0B) : AppTheme.primaryBlue,
                              content: Row(
                                children: [
                                  Icon(_isTimerMode ? LucideIcons.timer : LucideIcons.bell, color: Colors.white, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _isTimerMode 
                                        ? "Timer set for ${_selectedDurationMinutes}m! We'll remind you." 
                                        : "Reminder set for ${DateFormat.jm().format(finalTime)} daily.",
                                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)
                                    ),
                                  ),
                                ],
                              ),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            )
                          );
                          
                          Navigator.pop(context);
                        } catch (e) {
                          if (!context.mounted) return;
                          showElegantErrorDialog(
                            context,
                            title: "Failed to Add",
                            message: "Could not save medication: $e",
                            buttonText: "OK",
                          );
                        }
                      }();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                    shadowColor: AppTheme.primaryBlue.withOpacity(0.4),
                  ),
                  child: Text(
                    "Save & Notify Me",
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ).animate().fadeIn().scale(delay: 600.ms),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: AppTheme.textDark),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppTheme.bgLight,
        labelText: label,
        labelStyle: const TextStyle(color: AppTheme.textMuted),
        hintText: hint,
        hintStyle: TextStyle(color: AppTheme.textMuted.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: AppTheme.textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
  
  Widget _buildTimePicker() {
    return GestureDetector(
      onTap: () => _selectTime(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.bgLight,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.clock, color: AppTheme.primaryBlue),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Daily Reminder at", style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
                Text(
                  DateFormat.jm().format(_selectedTime),
                  style: GoogleFonts.outfit(color: AppTheme.textDark, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Spacer(),
            const Icon(LucideIcons.chevronDown, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text("Remind me in:", style: TextStyle(color: Color(0xFFF59E0B), fontSize: 13, fontWeight: FontWeight.bold)),
        ),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [2, 5, 15, 30, 60, 120].map((mins) {
             final isSelected = _selectedDurationMinutes == mins;
             return GestureDetector(
               onTap: () => setState(() => _selectedDurationMinutes = mins),
               child: AnimatedContainer(
                 duration: 200.ms,
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                 decoration: BoxDecoration(
                   color: isSelected ? const Color(0xFFF59E0B) : AppTheme.bgLight,
                   borderRadius: BorderRadius.circular(12),
                   border: Border.all(color: isSelected ? const Color(0xFFF59E0B) : Colors.transparent),
                   boxShadow: isSelected ? [BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.3), blurRadius: 8)] : []
                 ),
                 child: Text(
                   mins >= 60 ? "${mins ~/ 60} hr" : "$mins min",
                   style: GoogleFonts.outfit(
                     color: isSelected ? Colors.white : AppTheme.textDark,
                     fontWeight: FontWeight.bold,
                   ),
                 ),
               ),
             );
          }).toList(),
        ),
      ],
    );
  }
}
