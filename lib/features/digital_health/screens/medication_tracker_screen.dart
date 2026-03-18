import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:my_sejahtera_ng/features/digital_health/models/medication.dart';
import 'package:my_sejahtera_ng/features/digital_health/services/notification_service.dart';
import 'package:my_sejahtera_ng/features/digital_health/screens/widgets/add_medication_sheet.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:my_sejahtera_ng/features/digital_health/providers/medication_provider.dart';
import 'package:my_sejahtera_ng/core/theme/app_theme.dart';
import 'package:my_sejahtera_ng/features/gamification/providers/user_progress_provider.dart';

class MedicationTrackerScreen extends ConsumerStatefulWidget {
  const MedicationTrackerScreen({super.key});

  @override
  ConsumerState<MedicationTrackerScreen> createState() => _MedicationTrackerScreenState();
}

class _MedicationTrackerScreenState extends ConsumerState<MedicationTrackerScreen> {
  @override
  Widget build(BuildContext context) {
    final medicationState = ref.watch(medicationProvider);
    final medications = medicationState.medications;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text("Medication Tracker", style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.bold)), // Title moved to body
        backgroundColor: AppTheme.bgLight,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textDark),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show next dose logic
              Builder(
                builder: (context) {
                  if (medications.isEmpty) {
                     return const SizedBox(height: 100, child: Center(child: Text("No medications added yet", style: TextStyle(color: AppTheme.textMuted))));
                  }
                  
                  final sortedMeds = List<Medication>.from(medications)..sort((a, b) => a.time.compareTo(b.time));
                  final nextMed = sortedMeds.cast<Medication?>().firstWhere(
                    (m) => !m!.isTaken && m.time.isAfter(DateTime.now().subtract(const Duration(minutes: 15))),
                    orElse: () => null,
                  );
                  
                  final effectiveNextMed = nextMed ?? sortedMeds.cast<Medication?>().firstWhere((m) => !m!.isTaken, orElse: () => null);

                  if (effectiveNextMed != null) {
                     return _buildDosageCard(effectiveNextMed).animate().fadeIn().slideY(begin: 0.1);
                  } else {
                     return _buildAllCaughtUpCard().animate().fadeIn().slideY(begin: 0.1);
                  }
                }
              ),

              const SizedBox(height: 32),
              const Text("Your Meds", style: TextStyle(color: AppTheme.textDark, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Expanded(
                child: medications.isEmpty 
                ? const Center(child: Text("Tap + to add medications", style: TextStyle(color: AppTheme.textMuted)))
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'test_btn',
            mini: true,
            backgroundColor: const Color(0xFFF59E0B),
            foregroundColor: Colors.white,
            elevation: 2,
            child: const Icon(LucideIcons.bellRing, size: 18),
            onPressed: () async {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Scheduling test for 5s... ⏳")));
               
               await NotificationService().scheduleOneTimeNotification(
                 id: 999123, 
                 title: "Test Reminder 🔔",
                 body: "If you see this, notifications are working!",
                 time: DateTime.now().add(const Duration(seconds: 5)),
               );
            },
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'add_btn',
            onPressed: (){
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppTheme.surfaceWhite,
                  shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
                  builder: (context) => AddMedicationSheet(onSave: (med) => ref.read(medicationProvider.notifier).addMedication(med)),
                );
            },
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 4,
            child: const Icon(LucideIcons.plus),
          ),
        ],
      ),
    );
  }

  Widget _buildAllCaughtUpCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ]
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 const Text("Daily Progress", style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 8),
                 const Text("All Caught Up!", style: TextStyle(color: AppTheme.textDark, fontSize: 26, fontWeight: FontWeight.w900)),
                 const SizedBox(height: 12),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                   decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                   child: const Text("Great job keeping healthy!", style: TextStyle(color: AppTheme.success, fontWeight: FontWeight.bold, fontSize: 12)),
                 )
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppTheme.success.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(LucideIcons.checkCircle, color: AppTheme.success, size: 36),
          )
        ],
      ),
    );
  }

  Widget _buildDosageCard(Medication medication) {
    return Container(
      padding: const EdgeInsets.all(24),
       decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ]
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 const Text("Next Dose", style: TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 8),
                 Text(DateFormat.jm().format(medication.time), style: const TextStyle(color: AppTheme.textDark, fontSize: 32, fontWeight: FontWeight.w900)),
                 const SizedBox(height: 12),
                 Container(
                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                   decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                   child: Text("${medication.name} (${medication.dosage})", style: const TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                 )
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppTheme.primaryBlue.withOpacity(0.1), shape: BoxShape.circle),
            child: const Icon(LucideIcons.pill, color: AppTheme.primaryBlue, size: 36),
          )
        ],
      ),
    ); 
  }

  Widget _buildMedItem(Medication med) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
         decoration: BoxDecoration(
          color: med.isTaken ? AppTheme.bgLight : AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: med.isTaken ? Colors.transparent : Colors.black.withOpacity(0.05)),
          boxShadow: med.isTaken ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ]
        ),
        child: InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: AppTheme.surfaceWhite,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
              builder: (context) => AddMedicationSheet(
                initialData: med,
                onSave: (updatedMed) => ref.read(medicationProvider.notifier).updateMedication(updatedMed),
                onDelete: med.id != null ? () => ref.read(medicationProvider.notifier).deleteMedication(med.id!) : null,
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: med.isTaken ? Colors.black12 : AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12)
                ),
                child: Icon(LucideIcons.tablets, color: med.isTaken ? AppTheme.textMuted : AppTheme.primaryBlue, size: 20)
              ),
              title: Text(
                  med.name, 
                  style: TextStyle(
                      color: med.isTaken ? AppTheme.textMuted : AppTheme.textDark, 
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      decoration: med.isTaken ? TextDecoration.lineThrough : null
                  )
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                    "${med.dosage} • Take ${med.pillsToTake}", 
                    style: const TextStyle(color: AppTheme.textMuted)
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                    Text(DateFormat.jm().format(med.time), style: TextStyle(color: med.isTaken ? AppTheme.textMuted : AppTheme.textDark, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    IconButton(
                        icon: Icon(
                            med.isTaken ? Icons.check_circle : Icons.circle_outlined,
                            color: med.isTaken ? AppTheme.success : AppTheme.textMuted,
                            size: 28,
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
        ),
      ).animate().fadeIn().slideX(),
    );
  }
}
