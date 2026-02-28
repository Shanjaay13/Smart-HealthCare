import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_sejahtera_ng/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AddVaccineSheet extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialRecord;
  final VoidCallback onSaved;

  const AddVaccineSheet({super.key, this.initialRecord, required this.onSaved});

  @override
  ConsumerState<AddVaccineSheet> createState() => _AddVaccineSheetState();
}

class _AddVaccineSheetState extends ConsumerState<AddVaccineSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _batchController = TextEditingController();
  final _locationController = TextEditingController();
  final _doseController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialRecord != null) {
      _nameController.text = widget.initialRecord!['vaccine_name'] ?? '';
      _batchController.text = widget.initialRecord!['batch_number'] ?? '';
      _locationController.text = widget.initialRecord!['location'] ?? '';
      _doseController.text = widget.initialRecord!['dose_number']?.toString() ?? '1';
      if (widget.initialRecord!['date_administered'] != null) {
        _selectedDate = DateTime.tryParse(widget.initialRecord!['date_administered']) ?? DateTime.now();
      }
    }
  }

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
        if (user == null) throw Exception("User not logged in");

        final data = {
          'user_id': user.id,
          'vaccine_name': _nameController.text.trim(),
          'batch_number': _batchController.text.trim(),
          'location': _locationController.text.trim(),
          'dose_number': int.tryParse(_doseController.text.trim()) ?? 1,
          'date_administered': _selectedDate.toIso8601String().split('T')[0],
          'status': 'Completed',
        };

        if (widget.initialRecord == null) {
          // Create new record
          await supabase.from('vaccine_records').insert(data);
        } else {
          // Update existing record
          await supabase.from('vaccine_records').update(data).eq('id', widget.initialRecord!['id']);
        }

        if (mounted) {
          widget.onSaved();
          Navigator.pop(context);
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

  Future<void> _deleteRecord() async {
    setState(() => _isLoading = true);
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('vaccine_records').delete().eq('id', widget.initialRecord!['id']);
      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF161B1E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: Colors.white10),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.initialRecord == null ? "Add Vaccine Record" : "Edit Vaccine Record",
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
                const SizedBox(height: 20),
                
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _buildTextField("Vaccine Name", LucideIcons.syringe, _nameController),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      flex: 1,
                      child: _buildTextField("Dose (1, 2...)", LucideIcons.hash, _doseController, isNumber: true),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                _buildTextField("Batch Number", LucideIcons.tag, _batchController),
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
                Row(
                  children: [
                    if (widget.initialRecord != null) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _deleteRecord,
                          icon: const Icon(LucideIcons.trash2, size: 18),
                          label: const Text("Delete"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(color: Colors.redAccent),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                    ],
                    Expanded(
                      flex: widget.initialRecord != null ? 1 : 2,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveRecord,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentTeal,
                          foregroundColor: AppTheme.primaryDark,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryDark))
                            : const Text("Save Record", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
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
