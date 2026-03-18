import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sejahtera_ng/core/theme/app_theme.dart';
import 'package:my_sejahtera_ng/features/health_assistant/providers/appointment_provider.dart';
import 'package:intl/intl.dart';

class AppointmentCard extends ConsumerWidget {
  final Appointment appointment;

  const AppointmentCard({super.key, required this.appointment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(50),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(50),
          ),
          border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryBlue.withOpacity(0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.calendarClock, color: AppTheme.primaryBlue, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Upcoming Appointment",
                          style: GoogleFonts.outfit(
                            color: AppTheme.primaryBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "CONFIRMED",
                    style: GoogleFonts.outfit(
                      color: AppTheme.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Doctor & Hospital
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appointment.doctorName,
                        style: GoogleFonts.outfit(
                          color: AppTheme.textDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appointment.hospitalName,
                        style: GoogleFonts.outfit(
                          color: AppTheme.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                 // Action Buttons Row
                 Column(
                   crossAxisAlignment: CrossAxisAlignment.end,
                   children: [
                     TextButton(
                       onPressed: () => _editTime(context, ref),
                       style: TextButton.styleFrom(
                         backgroundColor: AppTheme.primaryBlue.withOpacity(0.05),
                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(16),
                         ),
                       ),
                       child: Text(
                         "Edit Time",
                         style: GoogleFonts.outfit(
                           color: AppTheme.primaryBlue,
                           fontWeight: FontWeight.bold,
                           fontSize: 12,
                         ),
                       ),
                     ),
                     const SizedBox(height: 8),
                     TextButton(
                       onPressed: () => _confirmCancel(context, ref),
                       style: TextButton.styleFrom(
                         backgroundColor: AppTheme.error.withOpacity(0.05),
                         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(16),
                         ),
                       ),
                       child: Text(
                         "Cancel",
                         style: GoogleFonts.outfit(
                           color: AppTheme.error,
                           fontWeight: FontWeight.bold,
                           fontSize: 12,
                         ),
                       ),
                     ),
                   ],
                 )
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Date & Time Grid
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildInfoColumn("Date", _formatDate(appointment.dateTime), LucideIcons.calendar),
                  Container(width: 1, height: 30, color: Colors.grey.shade300),
                  _buildInfoColumn("Time", _formatTime(appointment.dateTime), LucideIcons.clock),
                  Container(width: 1, height: 30, color: Colors.grey.shade300),
                  _buildInfoColumn("Service", appointment.type, LucideIcons.stethoscope),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text("Cancel Appointment?", style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to cancel your appointment at ${appointment.hospitalName}?", style: const TextStyle(color: AppTheme.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("Keep", style: TextStyle(color: AppTheme.textMuted))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            onPressed: () {
               ref.read(appointmentProvider.notifier).cancelAppointmentId(appointment.id);
               Navigator.pop(ctx);
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text("Appointment cancelled."))
               );
            }, 
            child: const Text("Yes, Cancel")
          ),
        ],
      )
    );
  }

  Future<void> _editTime(BuildContext context, WidgetRef ref) async {
    try {
      final now = DateTime.now();
      final DateTime safeInitialDate = appointment.dateTime.isBefore(now) ? now : appointment.dateTime;
      final DateTime safeFirstDate = appointment.dateTime.isBefore(now) ? appointment.dateTime : now;

      final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: safeInitialDate,
        firstDate: safeFirstDate,
        lastDate: now.add(const Duration(days: 365)),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppTheme.primaryBlue,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedDate == null) return;

      if (!context.mounted) return;
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(appointment.dateTime),
        builder: (context, child) {
          return Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppTheme.primaryBlue,
              ),
            ),
            child: child!,
          );
        },
      );

      if (pickedTime == null) return;

      final newDateTime = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );

      if (context.mounted) {
        await ref.read(appointmentProvider.notifier).updateAppointmentTime(appointment.id, newDateTime);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Appointment rescheduled successfully.")),
        );
      }
    } catch (e) {
      if (context.mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Error: $e")),
         );
      }
    }
  }

  Widget _buildInfoColumn(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppTheme.textMuted, size: 14),
              const SizedBox(width: 6),
              Flexible(child: Text(label, style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 12), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: GoogleFonts.outfit(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    return DateFormat.jm().format(date);
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return "Today";
    }
    return DateFormat.MMMd().format(date);
  }
}
