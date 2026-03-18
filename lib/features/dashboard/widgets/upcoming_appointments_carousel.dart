import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sejahtera_ng/features/health_assistant/providers/appointment_provider.dart';
import 'package:my_sejahtera_ng/features/dashboard/widgets/appointment_card.dart';

class UpcomingAppointmentsCarousel extends ConsumerStatefulWidget {
  const UpcomingAppointmentsCarousel({super.key});

  @override
  ConsumerState<UpcomingAppointmentsCarousel> createState() => _UpcomingAppointmentsCarouselState();
}

class _UpcomingAppointmentsCarouselState extends ConsumerState<UpcomingAppointmentsCarousel> {
  final PageController _controller = PageController(viewportFraction: 0.92);
  int _currentIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appointmentState = ref.watch(appointmentProvider);
    final now = DateTime.now();
    final appointments = appointmentState.appointments
        .where((a) => a.dateTime.isAfter(now))
        .toList();

    if (appointments.isEmpty) {
      return const SizedBox.shrink();
    }

    if (appointments.length == 1) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: AppointmentCard(appointment: appointments.first),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          SizedBox(
            height: 345, // Increased height to prevent pixel overflow
            child: PageView.builder(
              controller: _controller,
              itemCount: appointments.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                return AppointmentCard(appointment: appointments[index]);
              },
            ),
          ),
          const SizedBox(height: 12),
          // Custom Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(appointments.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentIndex == index ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentIndex == index ? Colors.blueAccent : Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
