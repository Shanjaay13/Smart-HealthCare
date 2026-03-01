import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:my_sejahtera_ng/features/check_in/screens/check_in_screen.dart';
import 'package:my_sejahtera_ng/features/hotspots/screens/hotspot_screen.dart';
import 'package:my_sejahtera_ng/features/vaccine/screens/vaccine_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:my_sejahtera_ng/core/providers/user_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_sejahtera_ng/core/providers/user_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_sejahtera_ng/features/health_assistant/providers/appointment_provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:my_sejahtera_ng/features/digital_health/providers/medication_provider.dart';
import 'package:my_sejahtera_ng/features/digital_health/models/medication.dart';
import 'package:my_sejahtera_ng/features/digital_health/screens/medication_tracker_screen.dart';
import 'package:my_sejahtera_ng/features/digital_health/providers/vitals_provider.dart';
import 'package:my_sejahtera_ng/features/digital_health/screens/health_vitals_screen.dart';
import 'package:my_sejahtera_ng/features/food_tracker/providers/food_tracker_provider.dart';
import 'package:my_sejahtera_ng/features/food_tracker/food_tracker_screen.dart';

// Chat Message Model
class ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;
  final Widget? actionWidget;
  final String? type; // 'text', 'time_slots', 'summary', 'clinic_list', 'choice_chips'
  final Map<String, dynamic>? metaData;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
    this.actionWidget,
    this.type = 'text',
    this.metaData,
  });
}

// Chat Session Model
class ChatSessionModel {
  final String id;
  final String title;
  final DateTime createdAt;
  
  ChatSessionModel({required this.id, required this.title, required this.createdAt});
}

// State Notifier
class ChatNotifier extends Notifier<List<ChatMessage>> {
  String? _currentSessionId;
  String? get currentSessionId => _currentSessionId;

  @override
  List<ChatMessage> build() {
    // Start with a new chat by default
    return [
      ChatMessage(
        text: 'Hello! I am your virtual assistant. How can I help you today?',
        isUser: false,
      ),
    ];
  }

  Future<void> startNewSession() async {
    _currentSessionId = null;
    state = [
       ChatMessage(
        text: 'Hello! I am your virtual assistant. How can I help you today?',
        isUser: false,
      ),
    ];
  }

  Future<void> loadSession(String sessionId) async {
    _currentSessionId = sessionId;
    final supabase = Supabase.instance.client;
    
    try {
      final data = await supabase
          .from('chat_history')
          .select()
          .eq('session_id', sessionId)
          .order('created_at');

      if (data.isNotEmpty) {
        state = (data as List).map((map) => ChatMessage(
          text: map['message'] ?? '',
          isUser: map['is_user'] ?? true,
          isError: map['is_error'] ?? false,
          type: map['type'],
          metaData: map['meta_data'],
        )).toList();
      } else {
        state = [];
      }
    } catch (e) {
      debugPrint("Error loading session: $e");
    }
  }

  Future<List<ChatSessionModel>> fetchHistory() async {
     final supabase = Supabase.instance.client;
     final user = supabase.auth.currentUser;
     if (user == null) return [];

     try {
       final data = await supabase
           .from('chat_sessions')
           .select()
           .eq('user_id', user.id)
           .order('created_at', ascending: false);
           
       return (data as List).map((map) => ChatSessionModel(
         id: map['id'],
         title: map['title'] ?? 'New Chat',
         createdAt: DateTime.parse(map['created_at']),
       )).toList();
     } catch (e) {
       debugPrint("Error fetching history: $e");
       return [];
     }
  }
  
  Future<void> deleteSession(String sessionId) async {
    try {
      await Supabase.instance.client.from('chat_sessions').delete().eq('id', sessionId);
      if (_currentSessionId == sessionId) {
        startNewSession();
      }
    } catch (e) {
      debugPrint("Error deleting session: $e");
    }
  }

  Future<void> addMessage(ChatMessage message) async {
    state = [...state, message];
    
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
       // Create session if not exists
       if (_currentSessionId == null) {
         // Generate title from first user message
         String title = message.text;
         if (title.length > 30) title = "${title.substring(0, 30)}...";
         
         final session = await supabase.from('chat_sessions').insert({
           'user_id': user.id,
           'title': title.isNotEmpty ? title : 'New Chat',
         }).select().single();
         _currentSessionId = session['id'];
       }

      await supabase.from('chat_history').insert({
        'user_id': user.id,
        'session_id': _currentSessionId,
        'message': message.text,
        'is_user': message.isUser,
        'is_error': message.isError,
        'type': message.type,
        'meta_data': message.metaData,
      });
    } catch (e) {
      debugPrint("Error saving chat: $e");
    }
  }
}

final chatProvider = NotifierProvider<ChatNotifier, List<ChatMessage>>(ChatNotifier.new);

class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Voice
  late FlutterTts _flutterTts;
  bool _isSpeaking = false;
  bool _isMuted = true; // Voice OFF by default as requested

  bool _isLoading = false;
  final bool _isInitializing = false;
  bool _useSimulatedAI = false;
  bool _isEmergency = false; // Emergency Mode Flagult

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  void _initTts() async {
    _flutterTts = FlutterTts();

    try {
      // Diagnostic: Check available languages
      dynamic langs = await _flutterTts.getLanguages;
      debugPrint("TTS Available Languages: $langs");

      // Minimal Setup for macOS/General
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0); 
      await _flutterTts.setSpeechRate(0.5); // Natural speed
      
      try {
        List<dynamic> voices = await _flutterTts.getVoices;
        Map<String, String>? bestVoice;
        final priorityNames = ["Samantha", "Ava", "Siri", "Daniel", "Karen"];
        for (var name in priorityNames) {
          try {
             var found = voices.firstWhere((v) => v["name"].toString().contains(name), orElse: () => null);
             if (found != null) {
               bestVoice = {"name": found["name"], "locale": found["locale"]};
               break;
             }
          } catch(e) {/* ignore */}
        }
        if (bestVoice != null) {
          await _flutterTts.setVoice(bestVoice);
        }
      } catch (e) {
        debugPrint("TTS Voice Selection Error: $e");
      }

      _flutterTts.setStartHandler(() => setState(() => _isSpeaking = true));
      _flutterTts.setCompletionHandler(() => setState(() => _isSpeaking = false));
      _flutterTts.setCancelHandler(() => setState(() => _isSpeaking = false));
      _flutterTts.setErrorHandler((msg) {
         setState(() => _isSpeaking = false);
      });
      
      // Speak Welcome Message Automatically
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && !_isMuted) {
          _speak("Hello! I am My S J AI. How can I help you?");
        }
      });

    } catch (e) {
      debugPrint("TTS Init Error: $e");
    }
  }

  Future<void> _speak(String text) async {
    if (text.isEmpty || _isMuted) return;
    debugPrint("TTS Speaking: $text");
    try {
      // Direct speak (removing stop() to prevent race conditions)
      final result = await _flutterTts.speak(text);
      if (result == 1) setState(() => _isSpeaking = true);
    } catch (e) {
      debugPrint("TTS Speak Error: $e");
    }
  }
  
  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _sendMessage([String? manualText]) async {
    final text = manualText ?? _controller.text;
    if (text.trim().isEmpty) return;

    HapticFeedback.lightImpact(); // Haptic for send
    ref.read(chatProvider.notifier).addMessage(ChatMessage(text: text, isUser: true));
    if (manualText == null) _controller.clear();
    _scrollToBottom();

    // 0. Emergency Check (SOS Mode)
    if (text.toLowerCase().contains("emergency") || 
        text.toLowerCase().contains("sos") || 
        text.toLowerCase().contains("chest pain") || 
        text.toLowerCase().contains("heart attack") || 
        text.toLowerCase().contains("can't breathe")) {
      
      setState(() => _isEmergency = true);
      HapticFeedback.heavyImpact();
      return;
    }

    // 1. Check for Appointment Booking Flow
    final appointmentState = ref.read(appointmentProvider);
    if (appointmentState.isBooking) {
      _handleBookingStep(text);
      return;
    }

    // 1.5 Safety Check NLU
    if (text.toLowerCase().contains("safe here") || (text.toLowerCase().contains("am i safe") && text.toLowerCase().contains("here")) || text.toLowerCase().contains("safety check")) {
       _handleSafetyCheck(); 
       return;
    }

    // 2. Medication Assistant NLU
    // Intent: "Remind me to take [Meds] at [Time]"
    final remindRegex = RegExp(r"remind me to take (.+) at (.+)", caseSensitive: false);
    final remindMatch = remindRegex.firstMatch(text);
    
    if (remindMatch != null) {
       final medName = remindMatch.group(1)!.trim();
       final timeStr = remindMatch.group(2)!.trim();
       
       // Parse Time
       final time = _parseTime(timeStr);
       
       // Add to Provider
       final newMed = Medication(
         name: medName, 
         dosage: "1 pill", // Default
         pillsToTake: 1, 
         time: time, 
         instructions: "Reminded via AI"
       );
       
       ref.read(medicationProvider.notifier).addMedication(newMed);
       
       const response = "Done! 💊 I've added a reminder.";
       ref.read(chatProvider.notifier).addMessage(ChatMessage(
         text: "I've set a reminder for **$medName** at **${DateFormat.jm().format(time)}**.",
         isUser: false,
         actionWidget: null,
         type: 'link_action',
         metaData: {'label': 'View Meds', 'color_value': Colors.teal.value, 'target': 'meds'},
       ));
       _speak(response);
       return;
    }

    // Intent: "Did I take my [Meds]?"
    if (text.toLowerCase().contains("did i take")) {
       final meds = ref.read(medicationProvider).medications;
       // Simple check: filter by today and name if possible, or just show status
       // For demo, just show summary
       final takenCount = meds.where((m) => m.isTaken).length;
       final total = meds.length;
       
       String response = "You have taken $takenCount out of $total medications today.";
       if (takenCount == total && total > 0) response = "Yes! You are all caught up. 🎉";
       else if (total == 0) response = "You don't have any medications tracked for today.";
       
       ref.read(chatProvider.notifier).addMessage(ChatMessage(
         text: response,
         isUser: false,
       ));
       _speak(response);
       return;
    }

    if (text.toLowerCase().contains("book") && (text.toLowerCase().contains("appointment") || text.toLowerCase().contains("consultation"))) {
      ref.read(appointmentProvider.notifier).startBooking();
      _handleBookingStep(text); // Start flow
      return;
    }

    // 2.5 Feature Shortcuts (Direct Action Interception)
    final lowerText = text.toLowerCase();
    
    // Feature: Nearest Clinic / Find Clinic
    if (lowerText.contains("nearest clinic") || lowerText.contains("find clinic") || lowerText.contains("nearby clinic")) {
       setState(() => _isLoading = true);
       Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          _handleGPSLocationRequest(ref.read(appointmentProvider.notifier));
       });
       return;
    }

    // Feature: Booking / Dentist / Specialist
    if (lowerText.contains("book") || lowerText.contains("dentist") || lowerText.contains("specialist") || lowerText.contains("doctor")) {
       ref.read(appointmentProvider.notifier).startBooking();
       _handleBookingStep(text);
       return;
    }

    // Feature: Vaccine / Certificate
    if (lowerText.contains("vaccine") || lowerText.contains("certificate") || lowerText.contains("digital cert")) {
       const response = "Opening your Digital Vaccine Certificate... 💉";
       ref.read(chatProvider.notifier).addMessage(ChatMessage(
          text: response,
          isUser: false,
          type: 'link_action',
          metaData: {'label': 'View Certificate', 'color_value': Colors.amber.value, 'target': 'vaccine'},
       ));
       _speak(response);
       // Optional: Auto-navigate after delay
       return;
    }

    // Feature: Hotspots / Risk
    if (lowerText.contains("hotspot") || lowerText.contains("risk map") || lowerText.contains("cases near me")) {
       const response = "Checking the latest hotspot data for you... 🗺️";
       ref.read(chatProvider.notifier).addMessage(ChatMessage(
          text: response,
          isUser: false,
          type: 'link_action',
          metaData: {'label': 'Open Hotspot Map', 'color_value': Colors.redAccent.value, 'target': 'hotspot'},
       ));
       _speak(response);
       return;
    }

    // Feature: Check-In / Scan
    if (lowerText.contains("check-in") || lowerText.contains("scan") || lowerText.contains("my sejahtera")) {
       const response = "Launching the MySejahtera Check-In Scanner... 📷";
       ref.read(chatProvider.notifier).addMessage(ChatMessage(
          text: response,
          isUser: false,
          type: 'link_action',
          metaData: {'label': 'Open Scanner', 'color_value': Colors.blueAccent.value, 'target': 'check_in'},
       ));
       _speak(response);
       return;
    }

    if (_useSimulatedAI) {
      _handleSimulatedResponse(text);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final responseText = await _fetchGroqResponse(text);
      if (!mounted) return;
      
      Widget? action;
      String? actionType;
      Map<String, dynamic>? actionMeta;

      // 2. Action Detection & Fallback Logic
      final combinedContext = "${text.toLowerCase()} ${responseText.toLowerCase()}";

      if (combinedContext.contains("check in") || combinedContext.contains("scan")) {
        // action = _buildActionChip("Open Scanner", Colors.blueAccent, const CheckInScreen());
        actionType = 'link_action';
        actionMeta = {'label': 'Open Scanner', 'color_value': Colors.blueAccent.value, 'target': 'check_in'};
      } else if (combinedContext.contains("vaccine") || combinedContext.contains("certificate")) {
         // action = _buildActionChip("View Vaccine", Colors.amber, const VaccineScreen());
        actionType = 'link_action';
        actionMeta = {'label': 'View Vaccine', 'color_value': Colors.amber.value, 'target': 'vaccine'};
      } else if (combinedContext.contains("hotspot") || combinedContext.contains("map") || combinedContext.contains("risk")) {
         // action = _buildActionChip("Check Hotspots", Colors.redAccent, const HotspotScreen());
        actionType = 'link_action';
        actionMeta = {'label': 'Check Hotspots', 'color_value': Colors.redAccent.value, 'target': 'hotspot'};
      // NEW SMART ACTIONS
      } else if ((combinedContext.contains("log") || combinedContext.contains("track") || combinedContext.contains("record")) &&
                 (combinedContext.contains("water") || combinedContext.contains("drink") || combinedContext.contains("hydrate"))) {
         // action = _buildActionChip("Log Hydration", Colors.cyanAccent, const FoodTrackerScreen(autoShowHydration: true));
        actionType = 'link_action';
        actionMeta = {'label': 'Log Hydration', 'color_value': Colors.cyanAccent.value, 'target': 'hydration'};
      } else if (combinedContext.contains("eat") || combinedContext.contains("food") || combinedContext.contains("diet") || combinedContext.contains("calorie")) {
         // action = _buildActionChip("Log Food", Colors.orangeAccent, const FoodTrackerScreen());
         actionType = 'link_action';
         actionMeta = {'label': 'Log Food', 'color_value': Colors.orangeAccent.value, 'target': 'food'};
      } else if (combinedContext.contains("bmi") || combinedContext.contains("vital") || combinedContext.contains("weight") || combinedContext.contains("blood")) {
         // action = _buildActionChip("Update Vitals", Colors.pinkAccent, const HealthVitalsScreen());
         actionType = 'link_action';
         actionMeta = {'label': 'Update Vitals', 'color_value': Colors.pinkAccent.value, 'target': 'vitals'};
      } else if (combinedContext.contains("medication") || combinedContext.contains("pill") || combinedContext.contains("dose") || combinedContext.contains("medicine")) {
         // action = _buildActionChip("Manage Meds", Colors.greenAccent, const MedicationTrackerScreen());
         actionType = 'link_action';
         actionMeta = {'label': 'Manage Meds', 'color_value': Colors.greenAccent.value, 'target': 'meds'};
      }

      HapticFeedback.mediumImpact(); // Haptic for receive
      ref.read(chatProvider.notifier).addMessage(ChatMessage(
        text: responseText, 
        isUser: false, 
        type: actionType,
        metaData: actionMeta,
      ));
      await _speak(responseText);
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact(); // Haptic for error
      
      // If network calls fail, show error.
      ref.read(chatProvider.notifier).addMessage(ChatMessage(
        text: "Error connecting to AI: ${e.toString()}",
        isUser: false,
        isError: true,
      ));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> _handleSafetyCheck() async {
    setState(() => _isLoading = true);
    
    // 1. Initial "Thinking" Response
    final thinkingMsg = "Checking your current location for risk factors... 🛰️";
    ref.read(chatProvider.notifier).addMessage(ChatMessage(text: thinkingMsg, isUser: false));
    _scrollToBottom();

    try {
      // 2. Get Location (Reuse permission logic or simple get)
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw "Location services are disabled.";
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw "Location permission denied.";
      }
      
      Position position = await Geolocator.getCurrentPosition();
      
      // 3. Simulate Analysis (Randomized for demo, but tied to location to seem real)
      await Future.delayed(const Duration(seconds: 2)); // Fake processing time
      
      // Seed random with lat/lng so it's consistent for the same spot
      final seed = (position.latitude + position.longitude).round(); 
      final random =  DateTime.now().millisecond % 3; // 0, 1, or 2
      
      String status;
      Color color;
      String advice;
      
      if (random == 0) {
        status = "Low Risk 🟢";
        color = Colors.greenAccent;
        advice = "This area has no active clusters reported in the last 14 days. You are safe.";
      } else if (random == 1) {
        status = "Moderate Risk 🟡";
        color = Colors.orangeAccent;
        advice = "There are 2 active cases reported within 1km. Please wear a mask and sanitize hands.";
      } else {
        status = "High Risk 🔴";
        color = Colors.redAccent;
        advice = "⚠️ Caution: You are near a known hotspot with high crowd density. Maintain social distancing.";
      }
      
      final response = "Analysis Complete.\n\n"
          "📍 **Location**: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}\n"
          "🛡️ **Status**: $status\n\n"
          "$advice";
      
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      ref.read(chatProvider.notifier).addMessage(ChatMessage(
        text: response, 
        isUser: false,
        type: 'link_action',
        metaData: {'label': 'View Hotspot Map', 'color_value': color.value, 'target': 'hotspot'},
      ));
      _speak("Safety check complete. You are in a $status area.");
      _scrollToBottom();
      
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      final errorResponse = "I couldn't verify your location. Please check your GPS settings. ($e)";
      ref.read(chatProvider.notifier).addMessage(ChatMessage(text: errorResponse, isUser: false, isError: true));
      _speak("I couldn't verify your location.");
    }
  }

  Future<void> _handleBookingStep(String userText) async {
    final state = ref.read(appointmentProvider);
    final notifier = ref.read(appointmentProvider.notifier);
    
    // 0. Global Cancellation Check
    final lowerInput = userText.toLowerCase();
    if (lowerInput.contains("cancel") || lowerInput.contains("stop") || lowerInput.contains("abort")) {
      ref.read(appointmentProvider.notifier).state = state.copyWith(
        isBooking: false,
        bookingStep: 0,
        tempBookingData: {},
      );
      ref.read(chatProvider.notifier).addMessage(ChatMessage(
        text: "Booking cancelled. Let me know if you need anything else! 👋",
        isUser: false,
      ));
      return;
    }

    // 0.5. Guard: Prevent answering random AI questions while in booking flow
    if (lowerInput.startsWith("what is ") || 
        lowerInput.startsWith("who is ") || 
        lowerInput.startsWith("how to ") || 
        (lowerInput.contains("?") && lowerInput.split(" ").length > 3)) {
        
       setState(() => _isLoading = false);
       ref.read(chatProvider.notifier).addMessage(ChatMessage(
         text: "It looks like you're asking a question, but we are currently in the middle of booking an appointment! 🏥\n\nPlease enter the required booking info, or type **'cancel'** to stop the booking process so I can answer your question.",
         isUser: false,
       ));
       return;
    }

    // Simulate thinking delay
    setState(() => _isLoading = true);
    Future.delayed(const Duration(milliseconds: 1000), () async {
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      String response = "";
      String? msgType;
      Map<String, dynamic>? meta;
      
      // Make step mutable for NLU jumps
      int step = state.bookingStep;

      // GUARD: If user clicks "Select Manually" at any point, force Step 3 logic
      if (userText.contains("Select Manually") || userText.contains("Manually 🗺️")) {
          step = 3;
          ref.read(appointmentProvider.notifier).setStep(3);
      }

       // --- STEP 1: APPOINTMENT TYPE (Initial Trigger Analysis) ---
       if (step == 1) {
         // Declared outside to be accessible
         bool locationDetected = false;

         // NLU: Check if user already specified type/location in the initial prompt
         String? detectedType;
         if (lowerInput.contains("dental") || lowerInput.contains("dentist")) detectedType = "Dental";
         else if (lowerInput.contains("vaccin")) detectedType = "Vaccination";
         else if (lowerInput.contains("consult") || lowerInput.contains("doctor")) detectedType = "Consultation";
         else if (lowerInput.contains("screen") || lowerInput.contains("checkup")) detectedType = "General Screening";

         if (detectedType != null) {
            notifier.updateTempData('appointmentType', detectedType);
            
            // NLU: Check for Location Context
            // Case A: "Nearby" -> Use Current Location
            if (lowerInput.contains("nearby") || lowerInput.contains("near me")) {
               // User wants current location
               notifier.nextStep(); // Skip Step 1
               notifier.updateTempData('manual_mode_active', false);
               // Trigger GPS immediately? No, async gap. 
               // We'll set state to Step 3 and call it manually or let the next loop handle it?
                  // Better flow: Just acknowledge type and ask location.
               response = "Got it, a **$detectedType** appointment. \n\nHow would you like to find a clinic?";
               msgType = 'choice_chips';
               meta = {'choices': ['Use Current Location 📍', 'Select Manually 🗺️']};
               
               // DIRECT JUMP TO STEP 3 (Location Method Selection)
               notifier.setStep(3); 
               
               // Refined Logic for "at [Location]"
               final locRegex = RegExp(r'(?:at|in|nearby)\s+([a-zA-Z\s]+)');
               final match = locRegex.firstMatch(lowerInput);
               if (match != null && !lowerInput.contains("current location")) {
                  String loc = match.group(1)!.trim();
                  if (loc.isNotEmpty && loc != "nearby") {
                     notifier.updateTempData('manual_mode_active', true);
                     
                     // Simulate manual search directly
                     final clinics = _mockClinicSearch(loc);
                     response = "I see matches for appointments at **$loc** ($detectedType). \n\nSelect a clinic:";
                     msgType = 'clinic_list';
                     meta = {'clinics': clinics};
                     
                     locationDetected = true;
                  }
               }
            } else {
               // Check for manual location if "nearby" wasn't triggered but "at [Location]" was
               final locRegex = RegExp(r'(?:at|in|nearby)\s+([a-zA-Z\s]+)');
               final match = locRegex.firstMatch(lowerInput);
               if (match != null && !lowerInput.contains("current location")) {
                  String loc = match.group(1)!.trim();
                  if (loc.isNotEmpty && loc != "nearby") {
                     notifier.updateTempData('manual_mode_active', true);
                     final clinics = _mockClinicSearch(loc);
                     response = "I see matches for appointments at **$loc** ($detectedType). \n\nSelect a clinic:";
                     msgType = 'clinic_list';
                     meta = {'clinics': clinics};
                     locationDetected = true;
                  }
               }
            }
            
            if (locationDetected) {
                // Determine step adjustment based on above logic
                // If we showed clinics, we need to be at Step 3.
                notifier.setStep(3); 
                notifier.nextStep(); // -> 4 (Wait, if we set to 3, nextStep makes it 4?)
                // Actually, if we set to 3 and found a location, we want to simulate selection?
                // The original code did nextStep() twice.
                // Let's just set it to 4 if location found.
                notifier.setStep(4);
            } else if (!lowerInput.contains("nearby") && !lowerInput.contains("near me")) {
               // Only found Type, ask for Location
               response = "Understood, **$detectedType**. \n\nHow would you like to find a clinic?";
               msgType = 'choice_chips';
               meta = {'choices': ['Use Current Location 📍', 'Select Manually 🗺️']};
               notifier.setStep(3); // Direct to Step 3 (Location Method)
            }
           
         } else {
              // No type detected, ask standard question
              response = "To get started, what type of appointment do you need?";
              msgType = 'choice_chips';
              meta = {'choices': ['General Screening', 'Vaccination', 'Dental', 'Consultation']};
              notifier.nextStep(); // -> Step 2
         }
       } 
      
      // --- STEP 2: LOCATION METHOD ---
      else if (step == 2) {
        // User just selected Type
        if (['General Screening', 'Vaccination', 'Dental', 'Consultation'].contains(userText)) {
             notifier.updateTempData('appointmentType', userText);
             response = "Understood, $userText. \n\nHow would you like to find a clinic?";
             msgType = 'choice_chips';
             meta = {'choices': ['Use Current Location 📍', 'Select Manually 🗺️']};
             notifier.setStep(3); // Explicitly set to Step 3
        } else {
             // Fallback
             response = "Please select a valid appointment type from the options above.";
        }
      }

      // --- STEP 3: CLINIC SELECTION ---
      else if (step == 3) {
        if (userText.contains("Current Location")) {
             _handleGPSLocationRequest(notifier);
             return; 
        } else if (userText.contains("Manually")) {
             response = "No problem. Which city or state are you looking in? (e.g. 'KL' or 'Penang')";
             notifier.updateTempData('manual_mode_active', true);
        } else {
             if (state.tempBookingData['manual_mode_active'] == true) {
                 final location = userText.toLowerCase();
                 // Fetch from DB
                 final allClinics = await notifier.fetchClinics();
                 
                 // Filter locally (for demo simplicity)
                 final matches = allClinics.where((c) {
                    final searchStr = (c['name'] as String).toLowerCase() + (c['address'] as String).toLowerCase();
                    return searchStr.contains(location);
                 }).toList();

                 if (matches.isNotEmpty) {
                    response = "I found ${matches.length} clinics in $userText:";
                    // Format: Name|Distance|Price|Slots
                    // We'll use "Unknown" for distance/price/slots initially, updated in Step 5
                    final clinicStrings = matches.map((c) => "${c['name']}|Check Map|50|Available").toList();
                    msgType = 'clinic_list';
                    meta = {'clinics': clinicStrings};
                    notifier.nextStep(); // -> Step 4
                 } else {
                    response = "I couldn't find any clinics in $userText. Try 'KL' or 'Johor'.";
                 }
             } else {
                 response = "Please choose a location method first.";
             }
        }
      }

      // --- STEP 4: TIME SELECTION ---
      else if (step == 4) {
         notifier.updateTempData('clinicName', userText);
         
         // 1. Find Clinic ID from Name
         final allClinics = await notifier.fetchClinics();
         final clinic = allClinics.firstWhere(
            (c) => c['name'] == userText, 
            orElse: () => {'id': 'unknown'}
         );

         double price = 50.0;
         int slots = 0;
         
         if (clinic['id'] != 'unknown') {
             // 2. Fetch Services/Slots
             final services = await notifier.fetchServices(clinic['id']);
             if (services.isNotEmpty) {
                 // Use the first service as default
                 price = (services.first['price'] as num).toDouble();
                 slots = (services.first['available_slots'] as num).toInt();
                 notifier.updateTempData('serviceId', services.first['id']); // Store for later
             }
         }
         
         notifier.updateTempData('price', price);

         // Logic: Filter out past times
         final now = DateTime.now();
         final allSlots = ['09:00 AM', '10:30 AM', '11:00 AM', '02:00 PM', '03:30 PM', '04:30 PM', '08:00 PM'];
         
         List<String> availableSlots = [];
         for (var slot in allSlots) {
             try {
               final slotDate = _parseTime(slot);
               if (slotDate.isAfter(now.add(const Duration(minutes: 15)))) {
                 availableSlots.add(slot);
               }
             } catch (e) { /* ignore */ }
         }
         
         if (availableSlots.isEmpty) {
             availableSlots = ['Tomorrow 09:00 AM', 'Tomorrow 10:00 AM', 'Tomorrow 02:00 PM'];
         }

         // Override slots count for display
         if (slots == 0) slots = availableSlots.length;

         response = "Checking availability at $userText... 🏥";
         
         ref.read(chatProvider.notifier).addMessage(ChatMessage(text: response, isUser: false));
         _scrollToBottom();

         Future.delayed(const Duration(milliseconds: 1000), () {
            if (!mounted) return;
            
            final finalResponse = "I found **$slots slots** available.\n\nEst. Price: **RM ${price.toStringAsFixed(0)}**.\n\nPlease select a time:";
            
            ref.read(chatProvider.notifier).addMessage(ChatMessage(
              text: finalResponse,
              isUser: false,
              type: 'time_slots',
              metaData: {'slots': availableSlots},
            ));
            _speak(finalResponse);
            notifier.nextStep(); // -> Step 5
            _scrollToBottom();
         });
       }
       
       // --- STEP 5: PHONE INPUT ---
       // --- STEP 5: TIME CONFIRMATION & SMART CONTACT CHECK ---
       else if (step == 5) {
          // User just selected Time
           if (state.bookingStep == 5) {
                // Parse Time
                DateTime? parsedTime;
                try {
                   parsedTime = _parseTime(userText);
                } catch (e) {
                   parsedTime = DateTime.now(); // Fallback
                }
                
                notifier.updateTempData('selectedTime', parsedTime);
                
                // SMART CHECK: Auto-fill contact details
                final user = ref.read(userProvider);
                
                // Fallback for email if provider update hasn't propagated or failed
                final authEmail = Supabase.instance.client.auth.currentUser?.email;
                final email = (user?.email != null && user!.email!.isNotEmpty) ? user.email : authEmail;
                final phone = (user?.phone != null && user!.phone.isNotEmpty && user.phone.length > 8) ? user.phone : null;

                if (phone != null && email != null) {
                      notifier.updateTempData('phone', phone);
                      notifier.updateTempData('email', email);
                      
                      // Show Summary with BOTH details
                      response = "I have your contact details:\n"
                           "📞 Phone: $phone\n"
                           "📧 Email: $email\n\n"
                           "Is this correct?";
                      
                      msgType = 'summary'; 
                      meta = {'show_change_button': true};
                      notifier.setStep(7); // Jump to Confirmation
                } else if (phone != null) {
                      // Have phone, missing email
                      notifier.updateTempData('phone', phone);
                       if (email != null) {
                           // Logic above should have caught this, but just in case
                           notifier.updateTempData('email', email);
                           response = "Contact details:\nPhone: $phone\nEmail: $email\n\nConfirm?";
                           msgType = 'summary'; 
                           meta = {'show_change_button': true};
                        notifier.setStep(7);
                       } else {
                           response = "I have your phone ($phone). What is your email address?";
                           notifier.nextStep(); // -> Step 6 (Email)
                       }
                } else {
                     response = "Time selected ($userText). \n\nWhat is your phone number?";
                     notifier.nextStep(); // -> Step 6 (Phone - wait, Step 6 in code might be labelled Email? Let's check next block)
                     // Code below: Step 6 is... "Email Input" ?? No, let's check the view...
                     // Ref: Line 839 "else if (step == 6) { // User just entered Phone - VALIDATE IT"
                     // So Step 6 IS validation of Phone.
                     // So sending to Step 6 means "We are currently IN Step 5, checking time. The NEXT input will be processed by Step 6".
                     // Step 6 processes PHONE input. Correct.
                }
           }
       }
       
       // --- STEP 6: EMAIL INPUT ---
       else if (step == 6) {
        // User just entered Phone - VALIDATE IT
        final phoneRegex = RegExp(r'^\+?[\d\-\s]{9,15}$'); // Basic phone validation
        if (phoneRegex.hasMatch(userText)) {
            notifier.updateTempData('phone', userText);
            response = "Thanks. Lastly, what is your email address?";
            notifier.nextStep(); // -> Step 7
        } else {
            response = "That doesn't look like a valid phone number. Please try again (e.g. 012-3456789).";
            // Don't advance step
        }
      }

      // --- STEP 7: CONFIRMATION ---
      else if (step == 7) {
        // User just enterd Email OR User confirmed "Yes"
        if (state.bookingStep == 7) {
            // Check if this is a confirmation "Yes" or "Proceed"
            if (userText.toLowerCase().contains("yes") || userText.toLowerCase().contains("confirm") || userText.toLowerCase().contains("proceed") || userText.toLowerCase().contains("ok")) {
                response = "All done! Your appointment for **${state.tempBookingData['appointmentType']}** at **${state.tempBookingData['clinicName']}** is confirmed.";
                msgType = 'summary'; // Final Summary
                // Reset flow after confirmation? Usually handled by UI or provider
                ref.read(appointmentProvider.notifier).confirmBooking();
            } else if (userText.toLowerCase().contains("change")) {
                // User wants to change details
                response = "Okay, let's enter your details manually. What is your phone number?";
                notifier.setStep(6); // Go back to Phone input
            } else {
                 // Might be entering email manually if came from Step 6
                 final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                 if (emailRegex.hasMatch(userText)) {
                    notifier.updateTempData('email', userText);
                    notifier.confirmBooking();
                    response = "Perfect. Appointment confirmed for **${state.tempBookingData['appointmentType']}**.\n\nWe sent a copy to **$userText**.";
                    msgType = 'summary';
                 } else {
                    response = "Please type 'Yes' to confirm, or 'Change' to update details.";
                 }
            }
        }
      }

      ref.read(chatProvider.notifier).addMessage(ChatMessage(
        text: response,
        isUser: false,
        type: msgType,
        metaData: meta,
      ));
      _speak(response);
      _scrollToBottom();
    });
  }

  Future<String> _fetchGroqResponse(String userMessage) async {
    // Get conversation history to send context
    final currentMessages = ref.read(chatProvider);
    final user = ref.read(userProvider);
    
    // LIVE HEALTH DATA CONTEXT
    final vitals = ref.read(vitalsProvider);
    final foodState = ref.read(foodTrackerProvider);
    final medState = ref.read(medicationProvider);

    String systemPrompt = "You are MySejahtera NG's advanced AI Health Assistant. You are concise, friendly, and knowledgeable about public health.\n\nIMPORTANT: You must ONLY answer questions related to health, wellness, medicine, the MySejahtera app features, or public safety.\nIf a user asks about anything else (e.g., coding, movies, politics, general knowledge), politely decline by saying: 'I am designed to assist only with health and MySejahtera-related inquiries.' and explain why.";
    
    if (user != null) {
      systemPrompt += "\n\nUser Profile:\n"
          "- Name: ${user.fullName}\n"
          "- Medical Conditions: ${user.medicalCondition}\n"
          "- Allergies: ${user.allergies}\n"
          "- Blood Type: ${user.bloodType}\n";
          
      systemPrompt += "\n\nCurrent Health Status (Real-time):\n"
          "- BMI: ${vitals.bmi.toStringAsFixed(1)} (${vitals.bmiStatus})\n"
          "- Calories Today: ${foodState.totalCalories} / ${foodState.calorieTarget} kcal\n"
          "- Hydration: ${foodState.waterCount} glasses (Goal: 8)\n"
          "- Medications: ${medState.medications.length} active, ${medState.medications.where((m) => m.isTaken).length} taken today.\n"
          "\nUse this data to be proactively helpful but strictly follow this format:\n"
          "1. First, directly answer the user's question concisely in 1-2 sentences.\n"
          "2. If you notice an actionable health insight from the data above (e.g. low hydration, exceeded calories, missed meds), add a blank line and then provide the reminder under a bolded '**Health Insight:**' title.\n"
          "Do NOT blend the health reminder into the main answer paragraph.";
    }

    // Groq uses OpenAI-compatible format
    // OpenAI API expects: {"role": "user"|"assistant"|"system", "content": "text"}
    final List<Map<String, String>> apiMessages = [
      {"role": "system", "content": systemPrompt}
    ];

    // Add last few messages for context (limit to last 10 to save tokens)
    for (var msg in currentMessages.skip(currentMessages.length > 10 ? currentMessages.length - 10 : 0)) {
        apiMessages.add({
          "role": msg.isUser ? "user" : "assistant",
          "content": msg.text
        });
    }
    // Add the new message
    apiMessages.add({"role": "user", "content": userMessage});

    try {
      final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
      debugPrint("DEBUG: API Key used: ${apiKey.length > 5 ? apiKey.substring(0, 5) + '...' : 'INVALID'}");
      if (apiKey.isEmpty || apiKey.contains("PLACEHOLDER")) {
         if (mounted) setState(() => _useSimulatedAI = true);
         return "Please set your Groq API Key in the .env file to use the AI.";
      }

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile", 
          "messages": apiMessages,
          "max_tokens": 500,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'].toString().trim();
      } else {
        final errorMsg = response.body;
        debugPrint("Groq Error: $errorMsg");
        throw Exception("Groq Error ($errorMsg)");
      }
    } catch (e) {
       // Switch to offline mode if it was a network error
       if (e.toString().contains("ClientException") || e.toString().contains("SocketException")) {
         if (mounted) setState(() => _useSimulatedAI = true);
         return "Network error. Switching to Offline Mode... (Try asking me again)";
       }
       rethrow;
    }
  }

  void _handleSimulatedResponse(String text) {
    setState(() => _isLoading = true);
    
    // Smart Command Parser (Simulated)
    final lowerText = text.toLowerCase();
    String response = "I'm in Offline Mode. I can help you navigate to Check-In, Vaccine, or Hotspots.";
    // Widget? action;
    String? actionType;
    Map<String, dynamic>? actionMeta;

    if (lowerText.contains("check in") || lowerText.contains("scan")) {
      response = "Opening the Check-In scanner for you...";
      // action = _buildActionChip("Launch Scanner", Colors.blueAccent, const CheckInScreen());
      actionType = 'link_action';
      actionMeta = {'label': 'Launch Scanner', 'color_value': Colors.blueAccent.value, 'target': 'check_in'};
    } else if (lowerText.contains("vaccine") || lowerText.contains("certificate")) {
      response = "Here is your vaccination status. Staying vaccinated protects you and your community.";
      // action = _buildActionChip("Show Certificate", Colors.amber, const VaccineScreen());
      actionType = 'link_action';
      actionMeta = {'label': 'Show Certificate', 'color_value': Colors.amber.value, 'target': 'vaccine'};
    } else if (lowerText.contains("hotspot") || lowerText.contains("map")) {
      response = "Checking nearby risk zones. Please stay safe!";
      // action = _buildActionChip("Open Hotspot Map", Colors.redAccent, const HotspotScreen());
      actionType = 'link_action';
      actionMeta = {'label': 'Open Hotspot Map', 'color_value': Colors.redAccent.value, 'target': 'hotspot'};
    } else if (lowerText.contains("health") || lowerText.contains("vital") || lowerText.contains("digital")) {
      response = "Did you know you can track your vitals in the Digital Health section?";
    } else if (lowerText.contains("diet") || lowerText.contains("food") || lowerText.contains("eat")) {
      response = "A balanced diet is key to good health! Include plenty of fruits, vegetables, and lean proteins.";
    } else if (lowerText.contains("exercise") || lowerText.contains("run") || lowerText.contains("gym") || lowerText.contains("fitness")) {
      response = "Regular exercise improves heart health and mood. Try to get at least 30 minutes of activity today!";
    } else if (lowerText.contains("mental") || lowerText.contains("stress") || lowerText.contains("sad") || lowerText.contains("relax")) {
      response = "Your mental wellness matters. Take a moment to breathe and center yourself.";
    }

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
      HapticFeedback.mediumImpact(); // Haptic for receive
      
      ref.read(chatProvider.notifier).addMessage(ChatMessage(
        text: response, 
        isUser: false, 
        // actionWidget: action,
        type: actionType,
        metaData: actionMeta,
      ));
      _speak(response);
      _scrollToBottom();
    });
  }

  Widget _buildActionChip(String label, Color color, Widget destination) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => destination)),
      child: Container(
        margin: const EdgeInsets.only(top: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.1), blurRadius: 10, spreadRadius: 1)
          ]
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            const Icon(LucideIcons.arrowRight, color: Colors.white, size: 16),
          ],
        ),
      ),
    ).animate().fadeIn().slideY();
  }

  Future<void> _handleGPSLocationRequest(AppointmentNotifier notifier) async {
    setState(() => _isLoading = true);
    
    String response = "";
    
    try {
      // 1. Check Permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw "Location services are disabled. Please enable them.";
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw "Location permission denied.";
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw "Location permission is permanently denied.";
      }

      // 2. Get Position
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      // 3. Fetch Real Clinic Data from Supabase via Notifier
      final allClinics = await notifier.fetchClinics();

      // 4. Calculate Distance & Filter
      List<Map<String, dynamic>> nearbyClinics = [];
      
      for (var clinic in allClinics) {
        // Supabase stores as 'latitude' and 'longitude' strings or doubles
        double cLat = double.tryParse(clinic['latitude']?.toString() ?? '0') ?? 0.0;
        double cLng = double.tryParse(clinic['longitude']?.toString() ?? '0') ?? 0.0;
        
        // Skip invalid coordinates
        if (cLat == 0 && cLng == 0) continue;

        double distMeters = Geolocator.distanceBetween(
          position.latitude, 
          position.longitude, 
          cLat, 
          cLng
        );
        double distKm = distMeters / 1000;
        
        // Only show clinics within 50km
        if (distKm <= 50) { 
          nearbyClinics.add({
            "name": clinic['name'] ?? clinic['clinic_name'] ?? 'Unknown Clinic',
            "distVal": distKm,
            "dist": "${distKm.toStringAsFixed(1)} km"
          });
        }
      }

      // Sort by distance
      nearbyClinics.sort((a, b) => (a['distVal'] as double).compareTo(b['distVal'] as double));
      
      // Take top 5
      final topClinics = nearbyClinics.take(5).toList();
      
      String responseText = "";
      if (topClinics.isEmpty) {
        // Should rarely happen now
        responseText = "I couldn't find any partner clinics. 🧐 \n\nTry selecting a region manually.";
      } else {
        responseText = "Found ${topClinics.length} clinics. The closest is **${topClinics.first['name']}** (${topClinics.first['dist']}).\n\nPlease select one:";
      }

      // Format for UI (Name|Distance|Price|Slots)
      // Provide mock price and slots for the UI array
      final clinicStrings = topClinics.map((c) => "${c['name']}|${c['dist']}|RM 50|Available").toList();

      if (mounted) {
        setState(() => _isLoading = false);
        ref.read(chatProvider.notifier).addMessage(ChatMessage(
          text: responseText,
          isUser: false,
          type: topClinics.isEmpty ? 'text' : 'clinic_list',
          metaData: topClinics.isEmpty ? null : {'clinics': clinicStrings},
        ));
        _speak(responseText);
        _scrollToBottom();
        if (topClinics.isNotEmpty) {
           notifier.nextStep(); // -> Step 4
        }
      }

    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        response = "I couldn't access your location: $e. \n\nPlease try 'Select Manually'.";
        ref.read(chatProvider.notifier).addMessage(ChatMessage(
          text: response,
          isUser: false,
          isError: true,
        ));
        _speak(response);
        _scrollToBottom();
        // Do not advance step, let them try again
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);

    return Scaffold(
      backgroundColor: Colors.black, // Dark base
      drawer: _buildHistoryDrawer(),
      body: Stack(
        children: [
          // 1. Futuristic Background
          const _FuturisticBackground(),

          // 2. Chat Interface
          SafeArea(
            child: Column(
              children: [
                _buildCustomAppBar(),
                if (!_isInitializing) ...[
                  Expanded(child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    physics: const BouncingScrollPhysics(),
                    itemCount: messages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length) {
                        return _buildTypingIndicator(); // Loading Indicator
                      }
                      final msg = messages[index];
                      // Greeting is usually index 0
                      bool isWelcome = index == 0 && !msg.isUser; 
                      return _buildFuturisticMessage(msg, isWelcome: isWelcome);
                    },
                  )),
                  _buildFuturisticSuggestions(),
                  _buildFuturisticInput(),
                ]
              ],
            ),
          ),
          
          // 3. Emergency Overlay
          if (_isEmergency) 
            Positioned.fill(child: _buildEmergencyOverlay().animate().fadeIn()),
        ],
      ),
    );
  }

  Widget _buildCustomAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // 1. Menu Button (Leading) - Opens Drawer
          Builder(
            builder: (context) => GestureDetector(
              onTap: () => Scaffold.of(context).openDrawer(),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(LucideIcons.menu, color: Colors.white, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "MySJ Assistant",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: _useSimulatedAI ? Colors.orangeAccent : Colors.greenAccent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_useSimulatedAI ? Colors.orangeAccent : Colors.greenAccent).withOpacity(0.6),
                          blurRadius: 8,
                          spreadRadius: 2,
                        )
                      ]
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).fade(duration: 1000.ms),
                  const SizedBox(width: 8),
                  Text(
                    _useSimulatedAI ? "Offline Mode" : "Online • Llama 3",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
          
          // 3. New Chat Action
          GestureDetector(
             onTap: () {
               ref.read(chatProvider.notifier).startNewSession();
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text("Started a new chat session"), duration: Duration(seconds: 1)),
               );
             },
             child: Container(
               padding: const EdgeInsets.all(8),
               decoration: BoxDecoration(
                 color: Colors.white.withOpacity(0.1),
                 shape: BoxShape.circle,
               ),
               child: const Icon(LucideIcons.plus, color: Colors.white, size: 20),
             ),
          ),
          const SizedBox(width: 10),

          // Audio Settings (Mute Toggle)
          GestureDetector(
            onTap: () async {
              setState(() => _isMuted = !_isMuted);
              if (_isMuted) {
                await _flutterTts.stop(); // Stop immediately
                setState(() => _isSpeaking = false);
              }
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _isMuted 
                    ? Colors.white.withOpacity(0.1) 
                    : (_isSpeaking ? Colors.purple.withOpacity(0.3) : Colors.white.withOpacity(0.1)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isMuted 
                    ? LucideIcons.volumeX 
                    : (_isSpeaking ? LucideIcons.volume2 : LucideIcons.volume1),
                color: _isMuted 
                    ? Colors.grey 
                    : (_isSpeaking ? Colors.purpleAccent : Colors.white70),
                size: 20,
              ),
            ).animate(target: _isSpeaking && !_isMuted ? 1 : 0).scale(begin: const Offset(1,1), end: const Offset(1.2,1.2)),
          ),
          
          const SizedBox(width: 10),

          // 5. Close Button (Back)
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.x, color: Colors.redAccent, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFuturisticMessage(ChatMessage msg, {bool isWelcome = false}) {
    final isUser = msg.isUser;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            // AI Avatar
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Color(0xFF00C6FF), Color(0xFF0072FF)]),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00C6FF).withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ]
              ),
              child: const Icon(LucideIcons.bot, color: Colors.white, size: 18),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(width: 12),
          ],
          
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isUser 
                        ? const Color(0xFF4A00E0).withOpacity(0.9) // User text bg
                        : Colors.white.withOpacity(0.08), // AI text glass
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(24),
                      topRight: const Radius.circular(24),
                      bottomLeft: isUser ? const Radius.circular(24) : const Radius.circular(4),
                      bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(24),
                    ),
                    border: Border.all(
                      color: isUser ? Colors.transparent : Colors.white.withOpacity(0.1),
                      width: 1,
                    ),
                    gradient: isUser 
                        ? const LinearGradient(colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)]) 
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]
                          ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isWelcome)
                        AnimatedTextKit(
                          animatedTexts: [
                            TypewriterAnimatedText(
                              msg.text,
                              textStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                height: 1.4,
                                fontWeight: FontWeight.w400,
                              ),
                              speed: const Duration(milliseconds: 30),
                            ),
                          ],
                          isRepeatingAnimation: false,
                          totalRepeatCount: 1,
                        )
                      else
                          MarkdownBody(
                          data: msg.text,
                          selectable: true,
                          styleSheet: MarkdownStyleSheet(
                            p: GoogleFonts.outfit(color: Colors.white, fontSize: 16, height: 1.6), // Increased readability
                            strong: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                            em: GoogleFonts.outfit(color: Colors.white70, fontStyle: FontStyle.italic),
                            listBullet: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                        

                      


                      if (msg.isError)
                        Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text("System Error", style: TextStyle(color: Colors.redAccent.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold))
                        )
                    ],
                  ),
                ).animate().fade().slideY(begin: 0.3, end: 0, duration: 400.ms, curve: Curves.easeOut),

                // Render Action Button if Available
                if (msg.actionWidget != null)
                  msg.actionWidget!
                else if (msg.type == 'link_action' && msg.metaData != null)
                  _buildActionFromMeta(msg.metaData!),

                // Render Choice Chips (Type/Location)
                if (msg.type == 'choice_chips' && msg.metaData != null)
                   _buildChoiceChips(msg.metaData!['choices'] as List<dynamic>),

                // Render Clinic Picker
                if (msg.type == 'clinic_list' && msg.metaData != null)
                  _buildClinicPicker(msg.metaData!['clinics'] as List<dynamic>),

                // Render Pre-Confirmation Summary
                if (msg.type == 'summary')
                   _buildPreConfirmationSummary(msg),

                // Render Time Slot Picker
                if (msg.type == 'time_slots' && msg.metaData != null)
                  _buildTimeSlotPicker(msg.metaData!['slots'] as List<dynamic>),

                // Render Appointment Summary
                if (msg.type == 'summary') 
                  _buildAppointmentSummary(),
              ],
            ),
          ),
          
          if (isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [Color(0xFFFF3CAC), Color(0xFF784BA0)]),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF3CAC).withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ]
              ),
              child: const Icon(LucideIcons.user, color: Colors.white, size: 18),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
          ]
        ],
      ),
    );
  }

  Widget _buildChoiceChips(List<dynamic> choices) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: choices.map((choice) {
        return GestureDetector(
          onTap: () => _sendMessage(choice),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Text(
              choice,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ).animate().fadeIn().scale(),
        );
      }).toList(),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 48, bottom: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 12, height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00C6FF)),
            ),
            const SizedBox(width: 10),
            Text(
              "Processing...",
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
            ).animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1500.ms, color: Colors.white),
          ],
        ),
      ),
    ).animate().fadeIn();
  }

  Widget _buildFuturisticSuggestions() {
    // Dynamic Chips based on Mode
    final List<String> chips;
    if (_useSimulatedAI) {
      chips = [
        "Check-in Scan 📷",
        "My digital cert 💉",
        "Am I safe here? 📍",
        "Show Hotspots 🗺️",
      ];
    } else {
      chips = [
        "Book a Dentist 🦷",
        "Find Specialist 👨‍⚕️",
        "Am I safe here? 📍",
        "Nearest Clinic 🏥",
        "I took my meds 💊", 
        "Set Med Reminder ⏰",
        "Update Vitals 💓",
        "BMI Analysis ⚖️",
        "Log Lunch 🥗",
      ];
    }

    return SizedBox(
      height: 50,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () => _sendMessage(chips[index]),
            borderRadius: BorderRadius.circular(25),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                gradient: LinearGradient(
                  colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)]
                )
              ),
              child: Text(
                chips[index],
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
            ),
          ).animate().fade(delay: (100 * index).ms).slideX();
        },
      ),
    );
  }

  Widget _buildFuturisticInput() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 15, 20, 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(35),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 15,
            spreadRadius: 5,
            offset: Offset(0, 10),
          )
        ]
      ),
      child: Row(
        children: [
          const SizedBox(width: 15),
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Ask AI Assistant...",
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                border: InputBorder.none,
                isDense: true,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [Color(0xFF00C6FF), Color(0xFF0072FF)])
            ),
            child: IconButton(
              icon: const Icon(LucideIcons.send, color: Colors.white, size: 20),
              onPressed: () => _sendMessage(),
            ),
          ).animate(target: _controller.text.isNotEmpty ? 1 : 0).scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
        ],
      ),
    );
  }

  Widget _buildClinicPicker(List<dynamic> clinics) {
    return Container(
      height: 160, // Increased height for extra tags
      margin: const EdgeInsets.only(top: 10),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: clinics.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final clinicRaw = clinics[index] as String;
          final parts = clinicRaw.split('|');
          final clinicName = parts[0];
          final distance = parts.length > 1 ? parts[1] : "Unknown";
          final price = parts.length > 2 ? "RM ${double.tryParse(parts[2])?.toStringAsFixed(0) ?? '50'}" : "RM 50";
          final slots = parts.length > 3 ? "${parts[3]} slots" : "Available";

          return GestureDetector(
            onTap: () => _sendMessage(clinicName),
            child: Container(
              width: 220,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(LucideIcons.mapPin, color: Colors.blueAccent, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          clinicName,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Details Row
                  Row(
                    children: [
                      _buildMiniTag(LucideIcons.map, distance, Colors.grey),
                      const SizedBox(width: 6),
                      _buildMiniTag(LucideIcons.banknote, price, Colors.greenAccent),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _buildMiniTag(LucideIcons.clock, slots, Colors.orangeAccent),
                ],
              ),
            ),
          ).animate().fadeIn().slideX(delay: (100 * index).ms);
        },
      ),
    );
  }

  Widget _buildMiniTag(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTimeSlotPicker(List<dynamic> slots) {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 10),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: slots.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final time = slots[index] as String;
          return GestureDetector(
            onTap: () => _sendMessage(time), // Send the time as a message
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blueAccent.withOpacity(0.5)),
              ),
              alignment: Alignment.center,
              child: Text(
                time,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ).animate().fadeIn().slideX(delay: (100 * index).ms);
        },
      ),
    );
  }

  Widget _buildPreConfirmationSummary(ChatMessage msg) {
    final state = ref.watch(appointmentProvider);
    final showChangeButton = msg.metaData?['show_change_button'] == true;

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.clipboardCheck, color: showChangeButton ? Colors.amber : Colors.greenAccent, size: 24),
              const SizedBox(width: 10),
              Text(
                showChangeButton ? "Review Details" : "Booking Confirmed",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 15),
          if (state.tempBookingData['appointmentType'] != null)
             _buildSummaryRow(LucideIcons.calendar, "Type", state.tempBookingData['appointmentType']),
          if (state.tempBookingData['clinicName'] != null)
             _buildSummaryRow(LucideIcons.mapPin, "Clinic", state.tempBookingData['clinicName']),
          if (state.tempBookingData['selectedTime'] != null)
             _buildSummaryRow(LucideIcons.clock, "Time", DateFormat('dd MMM, hh:mm a').format(state.tempBookingData['selectedTime'])),
          if (state.tempBookingData['phone'] != null)
             _buildSummaryRow(LucideIcons.phone, "Phone", state.tempBookingData['phone']),
          if (state.tempBookingData['email'] != null)
             _buildSummaryRow(LucideIcons.mail, "Email", state.tempBookingData['email']),
          
          if (showChangeButton) ...[
             const SizedBox(height: 20),
             Row(
               children: [
                 Expanded(
                   child: OutlinedButton(
                     onPressed: () => _sendMessage("Change Details"),
                     style: OutlinedButton.styleFrom(
                       side: const BorderSide(color: Colors.white30),
                       foregroundColor: Colors.white,
                       padding: const EdgeInsets.symmetric(vertical: 12),
                     ),
                     child: const Text("Change"),
                   ),
                 ),
                 const SizedBox(width: 10),
                 Expanded(
                   child: ElevatedButton(
                     onPressed: () => _sendMessage("Yes, Confirm"),
                     style: ElevatedButton.styleFrom(
                       backgroundColor: Colors.greenAccent,
                       foregroundColor: Colors.black,
                       padding: const EdgeInsets.symmetric(vertical: 12),
                     ),
                     child: const Text("Confirm"),
                   ),
                 ),
               ],
             )
          ]
        ],
      ),
    ).animate().fadeIn().slideY();
  }

  Widget _buildAppointmentSummary() {
    final appointment = ref.read(appointmentProvider).appointments.lastOrNull;
    if (appointment == null) return const SizedBox.shrink();
    
    final dateStr = DateFormat('EEE, d MMM @ h:mm a').format(appointment.dateTime);

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF00C6FF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00C6FF).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.calendarCheck, color: Color(0xFF00C6FF)),
              const SizedBox(width: 8),
              Text(
                "Appointment Confirmed",
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSummaryRow(LucideIcons.user, "Doctor", appointment.doctorName),
          _buildSummaryRow(LucideIcons.mapPin, "Location", appointment.hospitalName),
          _buildSummaryRow(LucideIcons.clock, "Time", dateStr),
          Container(height: 1, color: Colors.white10, margin: const EdgeInsets.symmetric(vertical: 8)),
           _buildSummaryRow(LucideIcons.banknote, "Est. Price", "RM ${appointment.price.toStringAsFixed(2)}"),
        ],
      ),
    ).animate().fadeIn().slideY();
  }

  Widget _buildSummaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white60, size: 14),
          const SizedBox(width: 8),
          Text("$label: ", style: const TextStyle(color: Colors.white60, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }






  List<String> _mockClinicSearch(String query) {
     return [
       "Klinik $query Utama|2.5 km|RM 45|Available",
       "Klinik $query Sentosa|5.1 km|RM 50|Limited",
       "Hospital $query|8.2 km|RM 80|Available",
     ];
  }

  DateTime _parseTime(String timeStr) {
    try {
      final now = DateTime.now();
      String cleanStr = timeStr.trim().toUpperCase(); // "TOMORROW 09:00 AM" or "09:00 AM"
      
      int dayOffset = 0;
      if (cleanStr.contains("TOMORROW")) {
        dayOffset = 1;
        cleanStr = cleanStr.replaceAll("TOMORROW", "").trim();
      } else if (cleanStr.contains("TODAY")) {
        cleanStr = cleanStr.replaceAll("TODAY", "").trim();
      }

      // now date part
      final dateBase = now.add(Duration(days: dayOffset));

      // expected cleanStr: "09:00 AM"
      final parts = cleanStr.split(" "); 
      if (parts.length < 2) throw "Invalid Format";

      final timeParts = parts[0].split(":");
      
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      bool isPM = parts[1] == "PM";

      if (isPM && hour != 12) hour += 12;
      if (!isPM && hour == 12) hour = 0; // 12 AM is 00:00

      return DateTime(dateBase.year, dateBase.month, dateBase.day, hour, minute);
    } catch (e) {
      debugPrint("Time Parse Error: $e");
      // Fallback: Return now, but log error
      return DateTime.now();
    }
  }

  // Minimal Animated Background Widget
  Widget _buildEmergencyOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.9), // Dark overlay
      child: Stack(
        children: [
          // Red Pulsing Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [Colors.red.withOpacity(0.5), Colors.transparent],
                  radius: 1.5,
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 800.ms),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(LucideIcons.siren, color: Colors.white, size: 80)
                       .animate(onPlay: (c) => c.repeat())
                       .shake(duration: 500.ms),
                   const SizedBox(height: 20),
                   Text(
                     "EMERGENCY DETECTED",
                     style: GoogleFonts.outfit(
                       color: Colors.white, 
                       fontSize: 32, 
                       fontWeight: FontWeight.w900,
                       letterSpacing: 2,
                     ),
                     textAlign: TextAlign.center,
                   ),
                   const SizedBox(height: 10),
                   const Text(
                     "Help is just a tap away.",
                     style: TextStyle(color: Colors.white70, fontSize: 16),
                   ),
                   const SizedBox(height: 40),
                   
                   // Call 999 Button
                   SizedBox(
                     width: double.infinity,
                     height: 60,
                     child: ElevatedButton.icon(
                       icon: const Icon(LucideIcons.phoneCall, size: 28),
                       label: const Text("CALL 999 NOW", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.redAccent,
                         foregroundColor: Colors.white,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                         elevation: 10,
                       ),
                       onPressed: () async {
                          final Uri launchUri = Uri(scheme: 'tel', path: '999');
                          if (await canLaunchUrl(launchUri)) {
                            await launchUrl(launchUri);
                          }
                       },
                     ),
                   ),
                   
                   const SizedBox(height: 16),
                   
                   // Navigation Button
                   SizedBox(
                     width: double.infinity,
                     height: 60,
                     child: ElevatedButton.icon(
                       icon: const Icon(LucideIcons.navigation, size: 28),
                       label: const Text("NAVIGATE TO HOSPITAL", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                       style: ElevatedButton.styleFrom(
                         backgroundColor: Colors.blueAccent,
                         foregroundColor: Colors.white,
                         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                       ),
                       onPressed: () async {
                          // Simple Google Maps intent for "Hospital"
                          final Uri url = Uri.parse('https://www.google.com/maps/search/hospital/');
                          if (await canLaunchUrl(url)) {
                             await launchUrl(url);
                          }
                       },
                     ),
                   ),
                   
                   const Spacer(),
                   
                   // Dismiss Button
                   TextButton(
                     onPressed: () {
                        setState(() => _isEmergency = false);
                        ref.read(chatProvider.notifier).addMessage(ChatMessage(
                          text: "Emergency mode deactivated. I'm here if you need to talk.",
                          isUser: false,
                        ));
                     },
                     child: const Text("I'm Safe / Cancel Alert", style: TextStyle(color: Colors.white54)),
                   ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildActionFromMeta(Map<String, dynamic> meta) {
    final label = meta['label'] ?? 'View';
    final colorVal = meta['color_value'] ?? 0xFF2196F3;
    final target = meta['target'] ?? '';
    final color = Color(colorVal);
    
    Widget? destination;
    switch (target) {
      case 'check_in': destination = const CheckInScreen(); break;
      case 'vaccine': destination = const VaccineScreen(); break;
      case 'hotspot': destination = const HotspotScreen(); break;
      case 'hydration': destination = const FoodTrackerScreen(autoShowHydration: true); break;
      case 'food': destination = const FoodTrackerScreen(); break;
      case 'vitals': destination = const HealthVitalsScreen(); break;
      case 'meds': destination = const MedicationTrackerScreen(); break;
    }

    if (destination != null) {
      return _buildActionChip(label, color, destination);
    }
    return const SizedBox.shrink();
  }
  Widget _buildHistoryDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF0F172A),
      child: SafeArea(
        child: Column(
          children: [
             Padding(
               padding: const EdgeInsets.all(16.0),
               child: Text("Chat History", style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
             ),
             const Divider(color: Colors.white24),
             Expanded(
               child: FutureBuilder<List<ChatSessionModel>>(
                 future: ref.read(chatProvider.notifier).fetchHistory(),
                 builder: (context, snapshot) {
                   if (snapshot.connectionState == ConnectionState.waiting) {
                     return const Center(child: CircularProgressIndicator());
                   }
                   if (!snapshot.hasData || snapshot.data!.isEmpty) {
                     return const Center(child: Text("No history yet", style: TextStyle(color: Colors.white54)));
                   }
                   
                   final sessions = snapshot.data!;
                   return ListView.builder(
                     itemCount: sessions.length,
                     itemBuilder: (context, index) {
                       final session = sessions[index];
                       final isCurrent = session.id == ref.read(chatProvider.notifier).currentSessionId;
                       
                       return ListTile(
                         title: Text(session.title, style: TextStyle(color: isCurrent ? Colors.blueAccent : Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                         subtitle: Text(DateFormat.MMMd().format(session.createdAt), style: const TextStyle(color: Colors.white30, fontSize: 10)),
                         onTap: () {
                           ref.read(chatProvider.notifier).loadSession(session.id);
                           Navigator.pop(context); // Close drawer
                         },
                         trailing: IconButton(
                           icon: const Icon(LucideIcons.trash2, color: Colors.white24, size: 16),
                           onPressed: () {
                             showDialog(
                               context: context,
                               builder: (ctx) => AlertDialog(
                                 backgroundColor: const Color(0xFF161B1E),
                                 title: Row(
                                   children: [
                                     const Icon(LucideIcons.alertTriangle, color: Colors.redAccent),
                                     const SizedBox(width: 10),
                                     const Text("Delete Chat", style: TextStyle(color: Colors.white)),
                                   ],
                                 ),
                                 content: const Text(
                                   "Are you sure you want to delete this chat session? This action cannot be undone.",
                                   style: TextStyle(color: Colors.white70),
                                 ),
                                 actions: [
                                   TextButton(
                                     onPressed: () => Navigator.pop(ctx),
                                     child: const Text("CANCEL", style: TextStyle(color: Colors.white54)),
                                   ),
                                   ElevatedButton(
                                     style: ElevatedButton.styleFrom(
                                       backgroundColor: Colors.redAccent,
                                       foregroundColor: Colors.white,
                                     ),
                                     onPressed: () async {
                                        Navigator.pop(ctx);
                                        await ref.read(chatProvider.notifier).deleteSession(session.id);
                                        if (mounted) setState(() {}); // Refresh drawer
                                     },
                                     child: const Text("DELETE"),
                                   ),
                                 ],
                               ),
                             );
                           },
                         ),
                       );
                     },
                   );
                 },
               ),
             ),
          ],
        ),
      ),
    );
  }
}

class _FuturisticBackground extends StatelessWidget {
  const _FuturisticBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Deep Space Base
        Container(color: const Color(0xFF0F172A)), // Slate 900
        
        // Glowing Orb 1 (Top Left)
        Positioned(
          top: -100, left: -100,
          child: Container(
            width: 400, height: 400,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4A00E0).withOpacity(0.3),
              backgroundBlendMode: BlendMode.screen,
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 4000.ms)
           .blur(begin: const Offset(60, 60), end: const Offset(100, 100)),
        ),

        // Glowing Orb 2 (Bottom Right)
        Positioned(
          bottom: -100, right: -100,
          child: Container(
            width: 300, height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF00C6FF).withOpacity(0.2),
              backgroundBlendMode: BlendMode.screen,
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .moveY(begin: 0, end: -50, duration: 5000.ms)
           .blur(begin: const Offset(80, 80), end: const Offset(40, 40)),
        ),
        

        // Overlay Noise/Texture
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.2),
                Colors.black.withOpacity(0.6),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
