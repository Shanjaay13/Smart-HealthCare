import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sejahtera_ng/core/widgets/glass_container.dart';
import 'package:my_sejahtera_ng/features/health_assistant/providers/appointment_provider.dart';
import 'package:intl/intl.dart';

class AppointmentCard extends ConsumerWidget {
  final Appointment appointment;

  const AppointmentCard({super.key, required this.appointment});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5), // Spacing for Carousel
      child: GlassContainer(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00C6FF).withOpacity(0.1),
                const Color(0xFF0072FF).withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: const Color(0xFF00C6FF).withOpacity(0.3)),
            borderRadius: BorderRadius.circular(20),
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C6FF).withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(LucideIcons.calendarClock, color: Color(0xFF00C6FF), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Upcoming Appointment",
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
                    ),
                    child: Text(
                      "CONFIRMED",
                      style: GoogleFonts.outfit(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
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
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          appointment.hospitalName,
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
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
                           backgroundColor: Colors.blueAccent.withOpacity(0.1),
                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(12),
                             side: BorderSide(color: Colors.blueAccent.withOpacity(0.3)),
                           ),
                         ),
                         child: Text(
                           "Edit Time",
                           style: GoogleFonts.outfit(
                             color: Colors.blueAccent,
                             fontWeight: FontWeight.bold,
                             fontSize: 12,
                           ),
                         ),
                       ),
                       const SizedBox(height: 8),
                       TextButton(
                         onPressed: () => _confirmCancel(context, ref),
                         style: TextButton.styleFrom(
                           backgroundColor: Colors.redAccent.withOpacity(0.1),
                           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                           shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(12),
                             side: BorderSide(color: Colors.redAccent.withOpacity(0.3)),
                           ),
                         ),
                         child: Text(
                           "Cancel",
                           style: GoogleFonts.outfit(
                             color: Colors.redAccent,
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
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildInfoColumn("Date", _formatDate(appointment.dateTime), LucideIcons.calendar),
                    Container(width: 1, height: 30, color: Colors.white10),
                    _buildInfoColumn("Time", _formatTime(appointment.dateTime), LucideIcons.clock),
                    Container(width: 1, height: 30, color: Colors.white10),
                    _buildInfoColumn("Service", appointment.type, LucideIcons.stethoscope),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmCancel(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text("Cancel Appointment?", style: TextStyle(color: Colors.white)),
        content: Text("Are you sure you want to cancel your appointment at ${appointment.hospitalName}?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("Keep", style: TextStyle(color: Colors.white54))
          ),
          TextButton(
            onPressed: () {
               ref.read(appointmentProvider.notifier).cancelAppointmentId(appointment.id);
               Navigator.pop(ctx);
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text("Appointment cancelled."))
               );
            }, 
            child: const Text("Yes, Cancel", style: TextStyle(color: Colors.redAccent))
          ),
        ],
      )
    );
  }

  Future<void> _editTime(BuildContext context, WidgetRef ref) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: appointment.dateTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null && context.mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(appointment.dateTime),
      );

      if (pickedTime != null && context.mounted) {
        final newDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        ref.read(appointmentProvider.notifier).updateAppointmentTime(appointment.id, newDateTime);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Appointment rescheduled successfully."))
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
              Icon(icon, color: Colors.white54, size: 12),
              const SizedBox(width: 6),
              Flexible(child: Text(label, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12), overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    return DateFormat.jm().format(date);
  }
  
  String _formatDate(DateTime date) {
    // Check if today
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return "Today";
    }
    return DateFormat.MMMd().format(date);
  }
}
