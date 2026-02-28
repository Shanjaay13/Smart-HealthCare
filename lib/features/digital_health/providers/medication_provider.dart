import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_sejahtera_ng/core/services/supabase_service.dart';
import 'package:my_sejahtera_ng/features/digital_health/models/medication.dart';
import 'package:my_sejahtera_ng/features/digital_health/services/notification_service.dart';

class MedicationState {
  final List<Medication> medications;
  
  MedicationState({this.medications = const []});
  
  MedicationState copyWith({List<Medication>? medications}) {
    return MedicationState(medications: medications ?? this.medications);
  }
}

class MedicationNotifier extends StateNotifier<MedicationState> {
  final NotificationService _notificationService = NotificationService();
  late final SupabaseClient _supabase;

  MedicationNotifier() : super(MedicationState()) {
    _supabase = SupabaseService().client;
    _loadMedications();
  }

  Future<void> _loadMedications() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final response = await _supabase
          .from('medications')
          .select()
          .eq('user_id', user.id)
          .order('time', ascending: true);

      final meds = (response as List).map((e) => Medication.fromMap(e)).toList();
      state = state.copyWith(medications: meds);
    } catch (e) {
      debugPrint("Error loading medications: $e");
    }
  }

  Future<void> addMedication(Medication medication) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw "User not logged in";

      final medData = medication.toMap();
      medData['user_id'] = user.id; // Add user_id manually

      final response = await _supabase
          .from('medications')
          .insert(medData)
          .select()
          .single();

      final newMedication = Medication.fromMap(response);
      
      state = state.copyWith(medications: [...state.medications, newMedication]);

      // Notifications Logic (Keep local)
      if (newMedication.isOneTime) {
          await _notificationService.scheduleOneTimeNotification(
            id: newMedication.id ?? 0,
            title: 'Medication Timer: ${newMedication.name} ⏳',
            body: 'Time to take ${newMedication.pillsToTake} pills now! ${newMedication.instructions}',
            time: newMedication.time,
          );
      } else {
          await _notificationService.scheduleDailyNotification(
            id: newMedication.id ?? 0,
            title: 'Time to take ${newMedication.name} 💊',
            body: 'Take ${newMedication.pillsToTake} pills. ${newMedication.instructions}',
            time: newMedication.time,
          );
      }
    } catch (e) {
      debugPrint("Error adding medication: $e");
    }
  }

  Future<void> toggleMedication(int id) async {
    // Optimistic Update
    final oldState = state;
    final updatedList = state.medications.map((med) {
      if (med.id == id) {
        return med.copyWith(isTaken: !med.isTaken);
      }
      return med;
    }).toList();
    
    state = state.copyWith(medications: updatedList);

    try {
      final med = updatedList.firstWhere((m) => m.id == id);
      await _supabase
          .from('medications')
          .update({'is_taken': med.isTaken})
          .eq('id', id);
    } catch (e) {
      debugPrint("Error toggling medication: $e");
      state = oldState; // Revert on error
    }
  }

  Future<void> deleteMedication(int id) async {
    try {
      await _supabase.from('medications').delete().eq('id', id);
      state = state.copyWith(
        medications: state.medications.where((m) => m.id != id).toList()
      );
      // We would also cancel scheduled notifications here using _notificationService
    } catch (e) {
      debugPrint("Error deleting medication: $e");
    }
  }

  Future<void> updateMedication(Medication updatedMedication) async {
    if (updatedMedication.id == null) return;
    try {
      final response = await _supabase.from('medications').update(
        updatedMedication.toMap()
      ).eq('id', updatedMedication.id!).select().single();

      final editedMedication = Medication.fromMap(response);

      state = state.copyWith(
        medications: state.medications.map((m) => m.id == editedMedication.id ? editedMedication : m).toList()
      );
      
      // We would reschedule notification here using _notificationService based on updated data
    } catch (e) {
      debugPrint("Error updating medication: $e");
    }
  }
}

final medicationProvider = StateNotifierProvider<MedicationNotifier, MedicationState>((ref) {
  return MedicationNotifier();
});
