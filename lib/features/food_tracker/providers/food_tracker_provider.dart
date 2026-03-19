import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_sejahtera_ng/core/services/supabase_service.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

// --- DATA MODELS ---
enum DrinkType { water, tea, coffee, juice, milk }

class FoodEntry {
  final int? id;
  final String name;
  final int calories;
  final DrinkType? type;
  final DateTime? createdAt;
  
  FoodEntry({
    this.id,
    required this.name, 
    required this.calories, 
    this.type,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'calories': calories,
      'entry_type': type != null ? 'drink' : 'food',
      'meta_data': type != null ? {'drink_type': type.toString().split('.').last} : {},
    };
  }

  factory FoodEntry.fromMap(Map<String, dynamic> map) {
    DrinkType? dType;
    if (map['entry_type'] == 'drink' && map['meta_data'] != null) {
      final typeStr = map['meta_data']['drink_type'];
      dType = DrinkType.values.firstWhere(
        (e) => e.toString().split('.').last == typeStr, 
        orElse: () => DrinkType.water
      );
    }
    
    return FoodEntry(
      id: map['id'],
      name: map['name'],
      calories: map['calories'],
      type: dType,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }
}

class FoodTrackerState {
  final int calorieTarget;
  final List<String> allergies;
  final List<FoodEntry> foods;
  final List<FoodEntry> drinks;
  final Map<String, int> dailyHistory;
  final bool isScanning;

  FoodTrackerState({
    this.calorieTarget = 2000,
    this.allergies = const [],
    this.foods = const [],
    this.drinks = const [],
    this.dailyHistory = const {},
    this.isScanning = false,
  });

  int get totalCalories =>
      foods.fold(0, (a, b) => a + b.calories) +
          drinks.fold(0, (a, b) => a + b.calories);

  int get waterCount => drinks.where((d) => 
      d.type == DrinkType.water || 
      d.type == DrinkType.tea || 
      d.type == DrinkType.juice || 
      d.type == DrinkType.milk
  ).length;

  // AI Insight Logic (Shared)
  String get currentInsight {
    final calPercent = totalCalories / calorieTarget;
    if (calPercent > 1.0) return "Warning: Calorie target exceeded!";
    if (calPercent > 0.8) return "Approaching daily limit.";
    if (waterCount < 3) return "Hydration Low: Drink more water.";
    return "You are on track today!";
  }

  FoodTrackerState copyWith({
    int? calorieTarget,
    List<String>? allergies,
    List<FoodEntry>? foods,
    List<FoodEntry>? drinks,
    Map<String, int>? dailyHistory,
    bool? isScanning,
  }) {
    return FoodTrackerState(
      calorieTarget: calorieTarget ?? this.calorieTarget,
      allergies: allergies ?? this.allergies,
      foods: foods ?? this.foods,
      drinks: drinks ?? this.drinks,
      dailyHistory: dailyHistory ?? this.dailyHistory,
      isScanning: isScanning ?? this.isScanning,
    );
  }
}

// --- STATE MANAGEMENT ---
final foodTrackerProvider = StateNotifierProvider<FoodTrackerNotifier, FoodTrackerState>((ref) => FoodTrackerNotifier());

class FoodTrackerNotifier extends StateNotifier<FoodTrackerState> {
  FoodTrackerNotifier() : super(FoodTrackerState()) {
    _supabase = SupabaseService().client;
    _init();
  }

  late final SupabaseClient _supabase;
  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<File> get _settingsFile async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/food_tracker_settings.json');
  }

  Future<void> _init() async {
    await _loadSettings();
    
    // Listen to auth changes: Supabase session restoration takes a few milliseconds on Hot Restart.
    // If we query instantly, currentUser is null and the logs disappear. This stream fixes that.
    _supabase.auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        debugPrint("Auth Session available. Loading Daily Logs...");
        _loadDailyLogs();
      }
    });

    // Fallback load if already initialized
    if (_supabase.auth.currentUser != null) {
      _loadDailyLogs();
    }
  }

  Future<void> _loadSettings() async {
    try {
      final file = await _settingsFile;
      if (await file.exists()) {
        final contents = await file.readAsString();
        final data = jsonDecode(contents);
        state = state.copyWith(
          calorieTarget: data['calorieTarget'] ?? 2000,
          allergies: List<String>.from(data['allergies'] ?? []),
        );
      }
    } catch (e) {
      debugPrint("Error loading Food Tracker settings: $e");
    }
  }

  Future<void> _saveSettings() async {
    try {
      final file = await _settingsFile;
      final data = {
        'calorieTarget': state.calorieTarget,
        'allergies': state.allergies,
      };
      await file.writeAsString(jsonEncode(data));
    } catch (e) {
      debugPrint("Error saving Food Tracker settings: $e");
    }
  }

  Future<void> _loadDailyLogs() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final today = DateTime.now();
      final sevenDaysAgo = today.subtract(const Duration(days: 6)); 

      // Fetch recent logs directly without PostgREST date formatting to guarantee no timezone mismatches
      final response = await _supabase
          .from('food_logs')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(200);

      final logs = (response as List).map((e) => FoodEntry.fromMap(e)).toList();
      debugPrint("Loaded ${logs.length} logs from Supabase. (Filtering by date locally)");
      
      final String todayKey = _todayKey;
      
      // Separate today's logs for state - IMPORTANT: use .toLocal() so UTC created_at matches phone timezone
      final todaysLogs = logs.where((log) {
        // If createdAt is null (e.g. column named 'createdAt' instead of 'created_at' in db), assume it is today to prevent missing data on hot restart!
        if (log.createdAt == null) return true; 
        return DateFormat('yyyy-MM-dd').format(log.createdAt!.toLocal()) == todayKey;
      }).toList();
      
      // Build 7-day history map
      Map<String, int> history = {};
      for (var log in logs) {
        if (log.createdAt != null && log.type == null) { // Only count food calories, not water
          final dateKey = DateFormat('yyyy-MM-dd').format(log.createdAt!.toLocal());
          history[dateKey] = (history[dateKey] ?? 0) + log.calories;
        }
      }

      state = state.copyWith(
        foods: todaysLogs.where((e) => e.type == null).toList(),
        drinks: todaysLogs.where((e) => e.type != null).toList(),
        dailyHistory: history,
      );

    } catch (e) {
      debugPrint("Error loading food logs: $e");
    }
  }

  void setTarget(int target) {
    state = state.copyWith(calorieTarget: target);
    _saveSettings();
  }

  void toggleAllergy(String allergy) {
    final list = List<String>.from(state.allergies);
    list.contains(allergy) ? list.remove(allergy) : list.add(allergy);
    state = state.copyWith(allergies: list);
    _saveSettings();
  }

  void reset() {
    state = FoodTrackerState();
    _loadDailyLogs();
  }

  // --- ALLERGEN DICTIONARY ---
  static const Map<String, List<String>> _allergenKeywords = {
    'Peanut': ['peanut', 'kacang tanah', 'satay', 'kuah kacang', 'groundnut'],
    'Milk & Dairy': ['milk', 'dairy', 'cheese', 'yogurt', 'cream', 'butter', 'latte', 'cappuccino', 'susu', 'keju', 'ghee', 'whey', 'casein'],
    'Sesame': ['sesame', 'tahini', 'bijan', 'benne'],
    'Wheat & Gluten': ['wheat', 'gluten', 'bread', 'roti', 'pasta', 'spaghetti', 'macaroni', 'noodle', 'mee', 'flour', 'tepung', 'biscuit', 'cake', 'kuih', 'barley', 'rye', 'seitan'],
    'Shellfish': ['shellfish', 'prawn', 'shrimp', 'crab', 'lobster', 'clam', 'mussel', 'oyster', 'scallop', 'squid', 'sotong', 'udang', 'ketam', 'kerang', 'lala'],
    'Fish': ['fish', 'salmon', 'tuna', 'ikan', 'sushi', 'sashimi', 'anchovy', 'bilis'],
    'Chicken': ['chicken', 'ayam', 'poultry', 'wing', 'breast', 'drumstick'],
    'Lamb': ['lamb', 'mutton', 'kambing'],
    'Beef': ['beef', 'steak', 'daging', 'lembu', 'burger', 'meatball'],
    'Soy': ['soy', 'tofu', 'tempeh', 'tauhu', 'kicap', 'edamame', 'miso'],
    'Egg': ['egg', 'telur', 'mayo', 'mayonnaise', 'meringue', 'ovalbumin'],
    'Tree Nuts': ['almond', 'cashew', 'walnut', 'pistachio', 'hazelnut', 'macadamia', 'pecan', 'gajus', 'buah keras'],
  };

  Future<String?> checkAllergyRisk(String name) async {
    state = state.copyWith(isScanning: true);
    await Future.delayed(500.ms); // Simulate quick check
    
    final lowerName = name.toLowerCase();
    
    for (final allergy in state.allergies) {
      final keywords = _allergenKeywords[allergy] ?? [allergy.toLowerCase()];
      
      // Check if food name contains any of the keywords for this allergy
      final match = keywords.firstWhere(
        (keyword) => lowerName.contains(keyword.toLowerCase()),
        orElse: () => '',
      );

      if (match.isNotEmpty) {
        state = state.copyWith(isScanning: false);
        return "⚠️ Risk Detected: '${name}' may contain '${allergy}' (Match: $match)";
      }
    }

    state = state.copyWith(isScanning: false);
    return null;
  }

  void _updateHistory() {
    final history = Map<String, int>.from(state.dailyHistory);
    history[_todayKey] = state.totalCalories;
    state = state.copyWith(dailyHistory: history);
  }

  Future<void> deleteFood(int id) async {
    try {
      await _supabase.from('food_logs').delete().eq('id', id);
      state = state.copyWith(foods: state.foods.where((f) => f.id != id).toList());
      _updateHistory();
    } catch (e) {
      debugPrint("Error deleting food: $e");
    }
  }

  Future<void> updateFood(int id, String newName, int newCal) async {
    try {
      final response = await _supabase.from('food_logs').update({
        'name': newName,
        'calories': newCal,
      }).eq('id', id).select().single();
      
      final updatedEntry = FoodEntry.fromMap(response);
      state = state.copyWith(
        foods: state.foods.map((f) => f.id == id ? updatedEntry : f).toList()
      );
      _updateHistory();
    } catch (e) {
      debugPrint("Error updating food: $e");
    }
  }

  Future<void> addFood(String name, int cal) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final entry = FoodEntry(name: name, calories: cal);
      final data = entry.toMap();
      data['user_id'] = user.id;

      final response = await _supabase
          .from('food_logs')
          .insert(data)
          .select()
          .single();

      final newEntry = FoodEntry.fromMap(response);
      state = state.copyWith(foods: [...state.foods, newEntry]);
      _updateHistory();
    } catch (e) {
      debugPrint("Error adding food: $e");
    }
  }

  Future<void> addDrink(String name, int cal, DrinkType type) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final validatedCal = (type == DrinkType.water) ? 0 : cal;
      final entry = FoodEntry(name: name, calories: validatedCal, type: type);
      final data = entry.toMap();
      data['user_id'] = user.id;

      final response = await _supabase
          .from('food_logs')
          .insert(data)
          .select()
          .single();

      final newEntry = FoodEntry.fromMap(response);
      state = state.copyWith(drinks: [...state.drinks, newEntry]);
      _updateHistory();
    } catch (e) {
      debugPrint("Error adding drink: $e");
    }
  }

  Future<Map<String, dynamic>?> analyzeFoodImage(XFile image) async {
    state = state.copyWith(isScanning: true);
    
    try {
      debugPrint("Starting AI Scan...");
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      // debugPrint("Image encoded: ${base64Image.length} bytes");
      
      String apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
         throw "AI Error: 401 - Missing GROQ_API_KEY in .env file";
      }

      debugPrint("Sending request to Groq...");
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "meta-llama/llama-4-maverick-17b-128e-instruct",
          "messages": [
            {
              "role": "user",
              "content": [
                {"type": "text", "text": "Analyze this food image. You are an expert in Malaysian cuisine. Identify the food item (e.g., Nasi Kandar, Nasi Lemak, Kuih) and estimate calories based on local portion sizes. Return ONLY valid JSON: {\"food_name\": \"string\", \"calories\": int, \"description\": \"string\"}. Do not include markdown formatting or explanations."},
                {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,$base64Image"}}
              ]
            }
          ],
          "max_tokens": 300,
          "temperature": 0.1,
          "response_format": {"type": "json_object"}
        }),
      ).timeout(const Duration(seconds: 15));

      debugPrint("Response Status: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'].toString();
        return jsonDecode(content) as Map<String, dynamic>;
      } else {
        throw "AI Error: ${response.statusCode} - ${response.body}";
      }
    } catch (e) {
      debugPrint("AI Scan Exception: $e");
      throw e.toString(); // Re-throw to be caught by UI
    } finally {
      state = state.copyWith(isScanning: false);
    }
  }

  Future<Map<String, dynamic>?> analyzeFoodText(String text) async {
    state = state.copyWith(isScanning: true);
    
    try {
      String apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
         throw "AI Error: 401 - Missing GROQ_API_KEY in .env file";
      }

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          "model": "llama-3.3-70b-versatile",
          "messages": [
            {
              "role": "system",
              "content": "You are a nutritionist AI specializing in Malaysian cuisine. Analyze the food description. If the user inputs a local dish (e.g., 'Nasi Kandar', 'Roti Canai'), estimate calories based on typical Malaysian serving sizes. Return ONLY valid JSON: {\"food_name\": \"string\", \"calories\": int, \"description\": \"string\"}."
            },
            {
              "role": "user",
              "content": text
            }
          ],
          "max_tokens": 300,
          "temperature": 0.1,
          "response_format": {"type": "json_object"}
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'].toString();
        return jsonDecode(content) as Map<String, dynamic>;
      }
      throw "AI Error: ${response.statusCode} - ${response.body}";
    } catch (e) {
      debugPrint("AI Text Error: $e");
      throw e.toString();
    } finally {
      state = state.copyWith(isScanning: false);
    }
  }
}
