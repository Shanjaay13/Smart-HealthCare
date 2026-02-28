import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_sejahtera_ng/core/services/supabase_service.dart';

class UserSession {
  final String id; // Changed to String (UUID)
  final String username;
  final String fullName;
  final String icNumber;
  final String phone;
  final String bloodType;
  final String allergies;
  final String emergencyContact;
  final String medicalCondition;
  final String? email;

  UserSession({
    required this.id,
    required this.username,
    required this.fullName,
    required this.icNumber,
    required this.phone,
    this.bloodType = "Unknown",
    this.allergies = "None",
    this.emergencyContact = "Not Set",
    this.medicalCondition = "None",
    this.email,
  });

  factory UserSession.fromMap(Map<String, dynamic> map) {
    return UserSession(
      id: map['id'] ?? '',
      username: map['username'] ?? 'User',
      fullName: map['full_name'] ?? 'Unknown',
      icNumber: map['ic_number'] ?? '',
      phone: map['phone'] ?? '',
      bloodType: map['blood_type'] ?? "Unknown",
      allergies: map['allergies'] ?? "None",
      emergencyContact: map['emergency_contact'] ?? "Not Set",
      medicalCondition: map['medical_condition'] ?? "None",
      email: map['email'],
    );
  }

  UserSession copyWith({
    String? bloodType,
    String? allergies,
    String? emergencyContact,
    String? medicalCondition,
    String? phone,
  }) {
    return UserSession(
      id: id,
      username: username,
      fullName: fullName,
      icNumber: icNumber,
      phone: phone ?? this.phone,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      medicalCondition: medicalCondition ?? this.medicalCondition,
      email: email,
    );
  }
}

class UserNotifier extends Notifier<UserSession?> {
  late final SupabaseClient _supabase;

  @override
  UserSession? build() {
    _supabase = SupabaseService().client;
    
    // Listen to Auth State Changes
    _supabase.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        _loadProfile(session.user.id);
      } else if (event == AuthChangeEvent.signedOut) {
        state = null;
      }
    });

    // Initial check
    final session = _supabase.auth.currentSession;
    if (session != null) {
      _loadProfile(session.user.id);
    }
    
    return null;
  }

  Future<void> _loadProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      
      final currentUser = _supabase.auth.currentUser;
      final profileData = Map<String, dynamic>.from(response);
      
      // Inject email from Auth if missing in Profile
      if (profileData['email'] == null && currentUser?.email != null) {
        profileData['email'] = currentUser!.email;
      }

      state = UserSession.fromMap(profileData);
    } catch (e) {
      debugPrint("Error loading profile: $e");
      // Handle edge case: User exists in Auth but not in Profiles?
    }
  }

  Future<void> login(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);
    } catch (e) {
      debugPrint("Login Error: $e");
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String username,
    required String icNumber,
    required String phone,
    required String securityQuestion,
    required String securityAnswer,
  }) async {
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'username': username,
          'ic_number': icNumber,
          'phone': phone,
          'security_question': securityQuestion,
          'security_answer': securityAnswer,
        },
      );
    } catch (e) {
      debugPrint("Sign Up Error: $e");
      rethrow;
    }
  }

  Future<String?> getSecurityQuestion(String email) async {
    try {
      final res = await _supabase.rpc('get_security_question', params: {'email_input': email});
      return res as String?;
    } catch (e) {
      debugPrint("Get Question Error: $e");
      return null;
    }
  }

  Future<bool> verifySecurityAnswer(String email, String answer) async {
    try {
      final res = await _supabase.rpc('verify_security_answer', params: {'email_input': email, 'answer_input': answer});
      return res as bool;
    } catch (e) {
      debugPrint("Verify Answer Error: $e");
      return false;
    }
  }

  Future<void> resetPassword(String email, String newPassword) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      debugPrint("Reset Password Error: $e");
      rethrow;
    }
  }

  Future<void> logout() async {
    await _supabase.auth.signOut();
  }

  Future<void> deleteAccount() async {
    try {
      await _supabase.rpc('delete_user_account');
      await _supabase.auth.signOut();
      state = null;
    } catch (e) {
      debugPrint("Delete Account Error: $e");
      rethrow;
    }
  }

  Future<void> updateMedicalInfo({String? blood, String? allergy, String? contact, String? condition}) async {
    if (state == null) return;

    final updates = {
      if (blood != null) 'blood_type': blood,
      if (allergy != null) 'allergies': allergy,
      if (contact != null) 'emergency_contact': contact,
      if (condition != null) 'medical_condition': condition,
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      await _supabase.from('profiles').update(updates).eq('id', state!.id);
      
      // Optimistic update
      state = state!.copyWith(
        bloodType: blood,
        allergies: allergy,
        emergencyContact: contact,
        medicalCondition: condition,
      );
    } catch (e) {
      debugPrint("Update Error: $e");
      rethrow;
    }
  }

  Future<void> updateContactInfo(String newPhone) async {
    if (state == null) return;

    try {
      await _supabase.from('profiles').update({'phone': newPhone}).eq('id', state!.id);
      state = state!.copyWith(phone: newPhone); // Update local state
    } catch (e) {
      debugPrint("Update Phone Error: $e");
      rethrow;
    }
  }
}

final userProvider = NotifierProvider<UserNotifier, UserSession?>(UserNotifier.new);
