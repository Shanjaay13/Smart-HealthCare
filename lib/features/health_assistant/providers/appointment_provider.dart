import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class Appointment {
  final String id;
  final String doctorName;
  final String hospitalName;
  final DateTime dateTime;
  final String type; // e.g., "General Checkup", "Vaccination"
  final String? notes;
  final double price;

  Appointment({
    required this.id,
    required this.doctorName,
    required this.hospitalName,
    required this.dateTime,
    required this.type,
    this.price = 0.0,
    this.notes,
  });
}

class AppointmentState {
  final List<Appointment> appointments;
  final bool isBooking;
  final int bookingStep; 
  // 1: Type, 2: LocationMethod, 3: Clinic, 4: Time, 5: Phone, 6: Email, 7: Confirm
  final Map<String, dynamic> tempBookingData;

  AppointmentState({
    this.appointments = const [],
    this.isBooking = false,
    this.bookingStep = 0,
    this.tempBookingData = const {},
  });

  AppointmentState copyWith({
    List<Appointment>? appointments,
    bool? isBooking,
    int? bookingStep,
    Map<String, dynamic>? tempBookingData,
  }) {
    return AppointmentState(
      appointments: appointments ?? this.appointments,
      isBooking: isBooking ?? this.isBooking,
      bookingStep: bookingStep ?? this.bookingStep,
      tempBookingData: tempBookingData ?? this.tempBookingData,
    );
  }
}



// ... existing imports ...

class AppointmentNotifier extends Notifier<AppointmentState> {
  final _supabase = Supabase.instance.client;

  @override
  AppointmentState build() {
    _loadAppointments();
    return AppointmentState();
  }

  Future<void> _loadAppointments() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await _supabase
          .from('appointments')
          .select()
          .eq('user_id', user.id)
          .order('appointment_time');

      final List<Appointment> loadedParams = (response as List).map((data) {
        return Appointment(
          id: data['id'],
          doctorName: "Dr. Assigned", // Placeholder until we have doctors table
          hospitalName: data['clinic_name'] ?? 'Unknown Clinic',
          dateTime: DateTime.parse(data['appointment_time']),
          type: data['service_name'] ?? 'General',
          price: (data['price'] as num).toDouble(),
          // status: data['status']
        );
      }).toList();

      state = state.copyWith(appointments: loadedParams);
    } catch (e) {
      debugPrint("Error loading appointments: $e");
    }
  }

  // Fetch Clinics for Step 3
  Future<List<Map<String, dynamic>>> fetchClinics() async {
    try {
      final response = await _supabase.from('clinics').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error fetching clinics: $e");
      return [];
    }
  }
  
  // Fetch Services for Step X
  Future<List<Map<String, dynamic>>> fetchServices(String clinicId) async {
    try {
      final response = await _supabase
          .from('clinic_services')
          .select()
          .eq('clinic_id', clinicId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint("Error fetching services: $e");
      return [];
    }
  }

  void startBooking() {
    state = state.copyWith(
      isBooking: true,
      bookingStep: 1, 
      tempBookingData: {},
    );
  }

  void updateTempData(String key, dynamic value) {
    final newData = Map<String, dynamic>.from(state.tempBookingData);
    newData[key] = value;
    state = state.copyWith(tempBookingData: newData);
  }

  void nextStep() {
    state = state.copyWith(bookingStep: state.bookingStep + 1);
  }

  void setStep(int step) {
    state = state.copyWith(bookingStep: step);
  }

  Future<void> confirmBooking() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final data = state.tempBookingData;
    final clinicName = data['clinicName'] ?? "Unknown Clinic";
    final serviceName = data['appointmentType'] ?? "General Checkup";
    final time = data['selectedTime'] as DateTime? ?? DateTime.now();
    final price = (data['price'] as num?)?.toDouble() ?? 50.0;

    try {
      // 1. Save to Supabase
      final response = await _supabase.from('appointments').insert({
        'user_id': user.id,
        'clinic_name': clinicName,
        'service_name': serviceName,
        'appointment_time': time.toIso8601String(),
        'price': price,
        'status': 'Confirmed'
      }).select().single();

      // 2. Update Local State
      final newAppointment = Appointment(
        id: response['id'],
        doctorName: "Dr. Assigned",
        hospitalName: clinicName,
        dateTime: time,
        type: serviceName,
        price: price,
      );

      state = state.copyWith(
        appointments: [...state.appointments, newAppointment],
        isBooking: false,
        bookingStep: 0,
        tempBookingData: {},
      );
    } catch (e) {
      debugPrint("Error confirming booking: $e");
      // Optionally handle error state
    }
  }

  Future<void> cancelAppointmentId(String id) async {
    try {
      await _supabase.from('appointments').delete().eq('id', id);
      
      state = state.copyWith(
        appointments: state.appointments.where((a) => a.id != id).toList(),
      );
    } catch (e) {
      debugPrint("Error cancelling appointment: $e");
    }
  }

  Future<void> updateAppointmentTime(String id, DateTime newTime) async {
    try {
      final response = await _supabase
          .from('appointments')
          .update({'appointment_time': newTime.toIso8601String()})
          .eq('id', id)
          .select()
          .single();

      final updatedAppointments = state.appointments.map((a) {
        if (a.id == id) {
          return Appointment(
            id: a.id,
            doctorName: a.doctorName,
            hospitalName: a.hospitalName,
            dateTime: newTime,
            type: a.type,
            price: a.price,
            notes: a.notes,
          );
        }
        return a;
      }).toList();

      state = state.copyWith(appointments: updatedAppointments);
    } catch (e) {
      debugPrint("Error updating appointment: $e");
    }
  }

  void cancelBooking() {
    state = state.copyWith(
      isBooking: false,
      bookingStep: 0,
      tempBookingData: {},
    );
  }
}

final appointmentProvider = NotifierProvider<AppointmentNotifier, AppointmentState>(AppointmentNotifier.new);
