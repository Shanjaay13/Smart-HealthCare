import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_sejahtera_ng/core/widgets/glass_container.dart';
import 'package:my_sejahtera_ng/features/health_assistant/providers/appointment_provider.dart';

class NextAppointmentCard extends ConsumerWidget {
  const NextAppointmentCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appointmentState = ref.watch(appointmentProvider);
    
    // Check if there are any appointments
    if (appointmentState.appointments.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get the latest appointment (for demo, just take the last one)
    final appointment = appointmentState.appointments.last;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
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
                  Row(
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
                  Container( // Circular Avatar Placeholder
                     width: 48, height: 48,
                     decoration: BoxDecoration(
                       shape: BoxShape.circle,
                       color: Colors.white.withOpacity(0.1),
                       image: const DecorationImage(
                         image: NetworkImage("https://i.pravatar.cc/150?u=dr_aisyah"), // Demo image
                         fit: BoxFit.cover,
                       )
                     ),
                  ),
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
                    _buildInfoColumn("Date", "Today", LucideIcons.calendar),
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

  Widget _buildInfoColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white54, size: 12),
            const SizedBox(width: 6),
            Text(label, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  String _formatTime(DateTime date) {
    // Simple helper if we don't have intl package handy, or just use basic logic
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final ampm = date.hour >= 12 ? "PM" : "AM";
    final minute = date.minute.toString().padLeft(2, '0');
    return "$hour:$minute $ampm";
  }
}
