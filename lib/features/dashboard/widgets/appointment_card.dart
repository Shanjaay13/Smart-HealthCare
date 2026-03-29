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
    final isPassed = appointment.dateTime.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 40,
            offset: const Offset(0, 10),
          )
        ]
      ),
      padding: const EdgeInsets.all(28),
      child: Column(
        children: [
          // Top: "Confirmed" Pill and Service
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(LucideIcons.calendarClock, color: AppTheme.primaryBlue, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isPassed ? "PASSED APPOINTMENT" : "UPCOMING APPOINTMENT", 
                        style: GoogleFonts.outfit(color: isPassed ? AppTheme.error : AppTheme.textMuted, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isPassed ? AppTheme.error.withOpacity(0.1) : AppTheme.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isPassed ? "ACTION NEEDED" : "CONFIRMED",
                  style: GoogleFonts.outfit(
                    color: isPassed ? AppTheme.error : AppTheme.success,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ]
          ),
          
          const Spacer(),
          
          // Middle: Date/Time and Doctor info
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Date Cube
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isPassed ? Colors.grey[600] : AppTheme.primaryBlue,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                     BoxShadow(
                       color: isPassed ? Colors.transparent : AppTheme.primaryBlue.withOpacity(0.3), 
                       blurRadius: 16, 
                       offset: const Offset(0, 8)
                     )
                  ]
                ),
                child: Column(
                  children: [
                    Text(
                      DateFormat('MMM').format(appointment.dateTime).toUpperCase(), 
                      style: GoogleFonts.outfit(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)
                    ),
                    Text(
                      DateFormat('dd').format(appointment.dateTime), 
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 32, height: 1.1)
                    ),
                  ]
                )
              ),
              
              const SizedBox(width: 20),
              
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(DateFormat('hh:mm a').format(appointment.dateTime), style: GoogleFonts.outfit(color: AppTheme.primaryBlue, fontWeight: FontWeight.w900, fontSize: 28)),
                    const SizedBox(height: 2),
                    Text(appointment.doctorName, style: GoogleFonts.outfit(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(appointment.hospitalName, style: GoogleFonts.outfit(color: AppTheme.textMuted, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ]
                )
              )
            ]
          ),
          
          const Spacer(),
          
          // Bottom Action buttons
          Row(
             children: isPassed ? [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () {
                         ref.read(appointmentProvider.notifier).markCompleted(appointment.id);
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Appointment marked as completed.")));
                    },
                    icon: const Icon(LucideIcons.checkCircle2, size: 18, color: Colors.white),
                    label: Text("Mark Complete", style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.success,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    )
                  )
                )
             ] : [
               Expanded(
                 child: TextButton.icon(
                   onPressed: () => _editTime(context, ref),
                   icon: const Icon(LucideIcons.calendarClock, size: 18, color: AppTheme.textDark),
                   label: Text("Reschedule", style: GoogleFonts.outfit(color: AppTheme.textDark, fontWeight: FontWeight.bold, fontSize: 14)),
                   style: TextButton.styleFrom(
                     padding: const EdgeInsets.symmetric(vertical: 16),
                     backgroundColor: AppTheme.bgLight,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                   )
                 )
               ),
               const SizedBox(width: 12),
               Expanded(
                 child: TextButton.icon(
                   onPressed: () => _confirmCancel(context, ref),
                   icon: const Icon(LucideIcons.x, size: 18, color: AppTheme.error),
                   label: Text("Cancel", style: GoogleFonts.outfit(color: AppTheme.error, fontWeight: FontWeight.bold, fontSize: 14)),
                   style: TextButton.styleFrom(
                     padding: const EdgeInsets.symmetric(vertical: 16),
                     backgroundColor: AppTheme.error.withOpacity(0.1),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                   )
                 )
               )
             ]
          )
        ]
      )
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


}
