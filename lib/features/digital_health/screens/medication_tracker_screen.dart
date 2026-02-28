import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_sejahtera_ng/core/widgets/glass_container.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:my_sejahtera_ng/features/digital_health/models/medication.dart';
import 'package:my_sejahtera_ng/features/digital_health/services/notification_service.dart';
import 'package:my_sejahtera_ng/features/digital_health/screens/widgets/add_medication_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sejahtera_ng/features/digital_health/providers/medication_provider.dart';
import 'package:my_sejahtera_ng/core/providers/theme_provider.dart';
import 'package:my_sejahtera_ng/core/theme/app_themes.dart';
import 'package:my_sejahtera_ng/features/gamification/providers/user_progress_provider.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MedicationTrackerScreen extends ConsumerStatefulWidget {
  const MedicationTrackerScreen({super.key});

  @override
  ConsumerState<MedicationTrackerScreen> createState() => _MedicationTrackerScreenState();
}

class _MedicationTrackerScreenState extends ConsumerState<MedicationTrackerScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // Watch theme provider for changes
    final currentTheme = ref.watch(themeProvider);
    final medicationState = ref.watch(medicationProvider);
    final medications = medicationState.medications;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(""), // Title moved to body
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppThemes.getBackgroundGradient(currentTheme),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Animated Title
                Center(
                  child: Text(
                    "Medication Tracker",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      shadows: [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ).animate()
                 .scale(duration: 600.ms, curve: Curves.elasticOut)
                 .fadeIn(duration: 400.ms),
                const SizedBox(height: 24),
                // Show next dose logic
                Builder(
                  builder: (context) {
                    if (medications.isEmpty) {
                       return const SizedBox(height: 100, child: Center(child: Text("No medications added yet", style: TextStyle(color: Colors.white))));
                    }
                    
                    // sorting done on add/toggle, or here cheaply
                    final sortedMeds = List<Medication>.from(medications)..sort((a, b) => a.time.compareTo(b.time));
                    final nextMed = sortedMeds.cast<Medication?>().firstWhere(
                      (m) => !m!.isTaken && m.time.isAfter(DateTime.now().subtract(const Duration(minutes: 15))), // Allow slight buffer or show all future
                      orElse: () => null,
                    );
                    
                    // Fallback: just show the first untaken one even if "past" but not marked taken? 
                    // Or if all taken, show "All done"
                    final effectiveNextMed = nextMed ?? sortedMeds.cast<Medication?>().firstWhere((m) => !m!.isTaken, orElse: () => null);

                    if (effectiveNextMed != null) {
                       return _buildDosageCard(effectiveNextMed).animate().fadeIn().slideY();
                    } else {
                       return _buildAllCaughtUpCard().animate().fadeIn().slideY();
                    }
                  }
                ),

                const SizedBox(height: 24),
                Text("Your Meds", 
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Expanded(
                  child: medications.isEmpty 
                  ? const Center(child: Text("Tap + to add medications", style: TextStyle(color: Colors.white70)))
                  : ListView.builder(
                    itemCount: medications.length,
                    itemBuilder: (context, index) {
                      final med = medications[index];
                      return _buildMedItem(med);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'test_btn',
            mini: true,
            backgroundColor: Colors.orangeAccent,
            child: const Icon(LucideIcons.bellRing, size: 18),
            onPressed: () async {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Scheduling test for 5s... ⏳")));
               
               // Simple 5s test using the new robust system
               await NotificationService().scheduleOneTimeNotification(
                 id: 999123, 
                 title: "Test Reminder 🔔",
                 body: "If you see this, notifications are working!",
                 time: DateTime.now().add(const Duration(seconds: 5)),
               );
            },
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'add_btn',
            onPressed: (){
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => AddMedicationSheet(onSave: (med) => ref.read(medicationProvider.notifier).addMedication(med)),
                );
            },
            backgroundColor: Colors.white,
            child: const Icon(LucideIcons.plus, color: Colors.teal),
          ),
        ],
      ),
    );
  }

  Widget _buildAllCaughtUpCard() {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 const Text("Daily Progress", style: TextStyle(color: Colors.white70)),
                 const SizedBox(height: 8),
                 const Text("All Caught Up!", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 8),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                   decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                   child: const Text("Great job keeping healthy!", style: TextStyle(color: Colors.white)),
                 )
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.greenAccent.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: const Icon(LucideIcons.checkCircle, color: Colors.greenAccent, size: 40),
          )
        ],
      ),
    );
  }

  Widget _buildDosageCard(Medication medication) {
    return GlassContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 const Text("Next Dose", style: TextStyle(color: Colors.white70)),
                 const SizedBox(height: 8),
                 Text(DateFormat.jm().format(medication.time), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 8),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                   decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                   child: Text("${medication.name} (${medication.dosage})", style: const TextStyle(color: Colors.white)),
                 )
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: const Icon(LucideIcons.pill, color: Colors.white, size: 40),
          )
        ],
      ),
    ); 
  }

  Widget _buildMedItem(Medication med) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        color: med.isTaken ? Colors.green.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => AddMedicationSheet(
                initialData: med,
                onSave: (updatedMed) => ref.read(medicationProvider.notifier).updateMedication(updatedMed),
                onDelete: med.id != null ? () => ref.read(medicationProvider.notifier).deleteMedication(med.id!) : null,
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: ListTile(
            leading: Icon(LucideIcons.tablets, color: med.isTaken ? Colors.white70 : Colors.white),
            title: Text(
                med.name, 
                style: TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold,
                    decoration: med.isTaken ? TextDecoration.lineThrough : null
                )
            ),
            subtitle: Text(
                "${med.dosage} • Take ${med.pillsToTake}", 
                style: const TextStyle(color: Colors.white70)
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                  Text(DateFormat.jm().format(med.time), style: const TextStyle(color: Colors.white)),
                  const SizedBox(width: 8),
                  IconButton(
                      icon: Icon(
                          med.isTaken ? Icons.check_circle : Icons.circle_outlined,
                          color: med.isTaken ? Colors.white : Colors.white70,
                      ),
                      onPressed: () {
                           if (med.id != null) {
                               ref.read(medicationProvider.notifier).toggleMedication(med.id!);
                           }
                           if (!med.isTaken) {
                              ref.read(userProgressProvider.notifier).completeQuest('meds');
                           }
                      },
                  )
              ],
            ),
          ),
        ),
      ).animate().fadeIn().slideX(),
    );
  }
}
