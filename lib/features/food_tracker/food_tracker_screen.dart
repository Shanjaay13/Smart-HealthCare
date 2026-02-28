import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:my_sejahtera_ng/core/widgets/glass_container.dart';
import 'package:intl/intl.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_sejahtera_ng/features/food_tracker/providers/food_tracker_provider.dart';
import 'package:my_sejahtera_ng/core/utils/ui_utils.dart';



// --- MAIN UI ---
// --- MAIN UI ---
class FoodTrackerScreen extends ConsumerStatefulWidget {
  final bool autoShowHydration;
  const FoodTrackerScreen({super.key, this.autoShowHydration = false});

  @override
  ConsumerState<FoodTrackerScreen> createState() => _FoodTrackerScreenState();
}

class _FoodTrackerScreenState extends ConsumerState<FoodTrackerScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _hydrationKey = GlobalKey();

  final List<String> suggestions = [
    "🥗 Try a Balanced Lunch: Grilled chicken, brown rice, and steamed broccoli.",
    "💧 Reduce Sugar: Swap sugary sodas with plain water and a slice of lemon.",
    "🍎 Snack Smart: A handful of raw almonds and an apple provides sustained energy.",
    "🍵 Metabolism Boost: Switch your afternoon coffee for antioxidant-rich green tea.",
    "🥣 Fiber Focus: Add chia seeds or flaxseeds to your breakfast for better digestion."
  ];

  static const List<String> availableAllergens = ['Peanut', 'Milk & Dairy', 'Sesame', 'Wheat & Gluten', 'Shellfish', 'Fish', 'Chicken', 'Lamb', 'Beef', 'Soy', 'Egg', 'Tree Nuts'];

  @override
  void initState() {
    super.initState();
    if (widget.autoShowHydration) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Scroll to hydration panel
        if (_hydrationKey.currentContext != null) {
             Scrollable.ensureVisible(_hydrationKey.currentContext!, duration: 800.ms, curve: Curves.easeInOut);
        }
        // Auto-open drink logger
        Future.delayed(500.ms, () => _logEntry(context, ref, true));
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(foodTrackerProvider);
    final randomSuggestion = suggestions[Random().nextInt(suggestions.length)];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("FOOD INTAKE MONITOR", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Colors.amberAccent)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [_buildConfigMenu(context, ref, state)],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F2027), Color(0xFF2C5364)],
          ),
        ),
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(20, 120, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProgressCard(state),
                  const SizedBox(height: 20),
                  _buildCalorieChart(state),
                  const SizedBox(height: 25),
                  
                  // Hydration Panel
                  Container(key: _hydrationKey, child: _buildHydrationPanel(state)),
                  const SizedBox(height: 25),

                  _sectionHeader("TODAY'S LOGS"),
                  const SizedBox(height: 10),
                  _buildFoodLogList(context, ref, state),
                  const SizedBox(height: 25),

                  _sectionHeader("AI HEALTH INSIGHTS"),
                  const SizedBox(height: 10),
                  _buildDynamicInsights(state),
                  const SizedBox(height: 25),
                  _sectionHeader("HEALTHY SUGGESTIONS"),
                  const SizedBox(height: 10),
                  _buildSuggestionCard(randomSuggestion),
                  const SizedBox(height: 40),
                  _buildActionRow(context, ref),
                ],
              ),
            ),
            if (state.isScanning) _buildScanningOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHydrationPanel(FoodTrackerState state) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(25),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               const Text("Hydration", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 16)),
               Icon(LucideIcons.droplets, color: Colors.cyanAccent.withOpacity(0.5), size: 20),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    Text("${state.waterCount} / 8", style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                    const Text("Glasses Today", style: TextStyle(color: Colors.white54, fontSize: 12)),
                 ],
               ),
               ElevatedButton(
                 onPressed: () => _logEntry(context, ref, true),
                 style: ElevatedButton.styleFrom(
                   backgroundColor: Colors.cyanAccent.withOpacity(0.2),
                   foregroundColor: Colors.cyanAccent,
                   shape: const CircleBorder(),
                   padding: const EdgeInsets.all(12),
                 ),
                 child: const Icon(LucideIcons.plus, size: 24),
               )
            ],
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: (state.waterCount / 8).clamp(0.0, 1.0),
            backgroundColor: Colors.white10,
            color: Colors.cyanAccent,
            minHeight: 6,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ),
    );
  }

  Widget _buildFoodLogList(BuildContext context, WidgetRef ref, FoodTrackerState state) {
    if (state.foods.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
        child: const Center(child: Text("No food logged today.", style: TextStyle(color: Colors.white54))),
      );
    }

    return Column(
      children: state.foods.map((food) {
        return Dismissible(
          key: Key('food_${food.id}'),
          direction: DismissibleDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(15)),
            child: const Icon(LucideIcons.trash2, color: Colors.white),
          ),
          onDismissed: (_) {
            if (food.id != null) {
              ref.read(foodTrackerProvider.notifier).deleteFood(food.id!);
            }
          },
          child: GestureDetector(
            onTap: () => _showEditFoodDialog(context, ref, food),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
              child: Row(
                children: [
                  const Icon(LucideIcons.utensils, color: Colors.orangeAccent, size: 20),
                  const SizedBox(width: 15),
                  Expanded(child: Text(food.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  Text("${food.calories} kcal", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showEditFoodDialog(BuildContext context, WidgetRef ref, FoodEntry food) {
    if (food.id == null) return;
    final nameCtrl = TextEditingController(text: food.name);
    final calCtrl = TextEditingController(text: food.calories.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B1E),
        title: const Text("Edit Food", style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Name", labelStyle: TextStyle(color: Colors.white54))),
            const SizedBox(height: 15),
            TextField(controller: calCtrl, keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: "Calories", labelStyle: TextStyle(color: Colors.white54))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
            onPressed: () {
              final newName = nameCtrl.text.trim();
              final newCal = int.tryParse(calCtrl.text) ?? food.calories;
              if (newName.isNotEmpty && newCal > 0) {
                ref.read(foodTrackerProvider.notifier).updateFood(food.id!, newName, newCal);
                Navigator.pop(ctx);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  // --- CONFIG & MODALS ---

  Widget _buildConfigMenu(BuildContext context, WidgetRef ref, FoodTrackerState state) {
    return PopupMenuButton<String>(
      icon: const Icon(LucideIcons.settings, color: Colors.white70),
      color: const Color(0xFF161B1E),
      onSelected: (value) {
        if (value == 'target') _openTargetSheet(context, ref, state);
        if (value == 'allergy') _openAllergySheet(context, ref, state);
        if (value == 'reset') _showResetDialog(context, ref);
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(value: 'target', child: ListTile(leading: Icon(LucideIcons.target, color: Colors.cyanAccent), title: Text("Daily Goal", style: TextStyle(color: Colors.white)))),
        const PopupMenuItem(value: 'allergy', child: ListTile(leading: Icon(LucideIcons.shieldAlert, color: Colors.redAccent), title: Text("Allergies", style: TextStyle(color: Colors.white)))),
        const PopupMenuItem(value: 'reset', child: ListTile(leading: Icon(LucideIcons.refreshCcw, color: Colors.orangeAccent), title: Text("Reset Data", style: TextStyle(color: Colors.white)))),
      ],
    );
  }

  void _openTargetSheet(BuildContext context, WidgetRef ref, FoodTrackerState s) {
    final formKey = GlobalKey<FormState>();
    final c = TextEditingController(text: s.calorieTarget.toString());

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B1E),
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("SET DAILY TARGET", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextFormField(
                controller: c,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: "Calories (kcal)", labelStyle: TextStyle(color: Colors.white54)),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Please set your daily calorie goal";
                  final n = int.tryParse(value);
                  if (n == null) return "Calories must be a number";
                  if (n < 800) return "Daily intake too low to be healthy";
                  if (n > 6000) return "Daily intake too high";
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    ref.read(foodTrackerProvider.notifier).setTarget(int.parse(c.text));
                    Navigator.pop(context);
                  }
                },
                child: const Text("SAVE TARGET"),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _logEntry(BuildContext context, WidgetRef ref, bool isDrink) {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final calCtrl = TextEditingController();
    DrinkType drinkType = DrinkType.water;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161B1E),
      builder: (ctx) => StatefulBuilder(
        builder: (c, setST) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(isDrink ? "LOG DRINK" : "LOG FOOD", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                if (isDrink) ...[
                  DropdownButton<DrinkType>(
                    dropdownColor: const Color(0xFF161B1E),
                    value: drinkType,
                    items: DrinkType.values.map((e) => DropdownMenuItem(value: e, child: Text(e.name, style: const TextStyle(color: Colors.white)))).toList(),
                    onChanged: (v) => setST(() {
                      drinkType = v!;
                      if (drinkType == DrinkType.water) calCtrl.text = "0";
                    }),
                  ),
                ],
                TextFormField(
                  controller: nameCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(hintText: isDrink ? "Drink Name" : "Food Name", hintStyle: const TextStyle(color: Colors.white24)),
                  validator: (value) {
                    final trimmed = value?.trim() ?? "";
                    if (trimmed.isEmpty) return "Please enter a valid name";
                    if (trimmed.length < 2) return "Name too short";
                    if (RegExp(r'^[0-9]+$').hasMatch(trimmed)) return "Enter a valid name (not just numbers)";
                    return null;
                  },
                ),
                if (drinkType != DrinkType.water)
                  TextFormField(
                    controller: calCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(hintText: "Calories", hintStyle: TextStyle(color: Colors.white24)),
                    validator: (value) {
                      if (value == null || value.isEmpty) return "Enter calorie amount";
                      final n = int.tryParse(value);
                      if (n == null) return "Must be a whole number";
                      if (n <= 0) return "Calories must be greater than zero";
                      if (n > 2000) return "Unrealistic for a single item";
                      return null;
                    },
                  ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      final name = nameCtrl.text.trim();
                      final cal = int.tryParse(calCtrl.text) ?? 0;
                      Navigator.pop(ctx);

                      final riskMessage = await ref.read(foodTrackerProvider.notifier).checkAllergyRisk(name);
                      if (riskMessage != null) {
                        _showAllergenWarning(context, riskMessage, () {
                          isDrink ? ref.read(foodTrackerProvider.notifier).addDrink(name, cal, drinkType) : ref.read(foodTrackerProvider.notifier).addFood(name, cal);
                        });
                      } else {
                        isDrink ? ref.read(foodTrackerProvider.notifier).addDrink(name, cal, drinkType) : ref.read(foodTrackerProvider.notifier).addFood(name, cal);
                      }
                    }
                  },
                  child: const Text("ANALYZE & ADD"),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- REUSABLE UI ---

  Widget _buildDynamicInsights(FoodTrackerState state) {
    List<Widget> messages = [];
    final calPercent = state.totalCalories / state.calorieTarget;

    if (calPercent > 1.0) {
      messages.add(_insightItem("Warning: Calorie target exceeded by ${(state.totalCalories - state.calorieTarget)} kcal.", Colors.redAccent, LucideIcons.frown));
    } else if (calPercent > 0.8) {
      messages.add(_insightItem("Approaching limit. Consider lighter snacks for later.", Colors.orangeAccent, LucideIcons.gauge));
    }

    if (state.waterCount < 3) {
      messages.add(_insightItem("Hydration Low: You've logged less than 3 glasses of water.", Colors.blueAccent, LucideIcons.droplets));
    } else {
      messages.add(_insightItem("Hydration Good: Keep maintaining this water intake!", Colors.greenAccent, LucideIcons.smile));
    }
    return Column(children: messages);
  }

  Widget _insightItem(String text, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.05), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(children: [Icon(icon, color: color, size: 18), const SizedBox(width: 12), Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 13)))]),
    ).animate().fadeIn().slideX();
  }

  Widget _buildSuggestionCard(String text) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(20),
      padding: const EdgeInsets.all(16),
      child: Row(children: [const Icon(LucideIcons.lightbulb, color: Colors.amberAccent, size: 24), const SizedBox(width: 15), Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4)))]),
    ).animate().shimmer(duration: 2.seconds);
  }

  Widget _buildProgressCard(FoodTrackerState state) {
    double progress = (state.totalCalories / state.calorieTarget).clamp(0.0, 1.0);
    return GlassContainer(
      borderRadius: BorderRadius.circular(30),
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Today's Progress", style: TextStyle(color: Colors.white38, fontSize: 14)),
              Text("${(progress * 100).toInt()}%", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(value: progress, backgroundColor: Colors.white10, color: progress >= 1.0 ? Colors.redAccent : Colors.cyanAccent, minHeight: 8),
          const SizedBox(height: 15),
          Text("${state.totalCalories} / ${state.calorieTarget} kcal", style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildCalorieChart(FoodTrackerState state) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    // Calculate dynamic MaxY
    double maxCalories = state.calorieTarget.toDouble();
    for (var cal in state.dailyHistory.values) {
      if (cal > maxCalories) maxCalories = cal.toDouble();
    }
    final maxY = maxCalories * 1.2; // Add 20% buffer

    final isOverLimit = state.totalCalories > state.calorieTarget;

    return GlassContainer(
      borderRadius: BorderRadius.circular(25),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("7-Day Trend", style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold)),
              if (isOverLimit)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.redAccent)),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.alertTriangle, color: Colors.redAccent, size: 12),
                      const SizedBox(width: 4),
                      Text("High Intake", style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: 1.seconds, begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 150,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                maxY: maxY,
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final date = today.subtract(Duration(days: 6 - val.toInt()));
                        return Text(DateFormat('E').format(date).substring(0, 1), style: const TextStyle(color: Colors.white38, fontSize: 11));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (index) {
                  final dateKey = DateFormat('yyyy-MM-dd').format(today.subtract(Duration(days: 6 - index)));
                  final calories = state.dailyHistory[dateKey]?.toDouble() ?? 0.0;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: calories,
                        color: calories > state.calorieTarget ? Colors.redAccent : Colors.cyanAccent,
                        width: 14,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        backDrawRodData: BackgroundBarChartRodData(show: true, toY: maxY, color: Colors.white.withOpacity(0.0)), // Use transparent background relative to max
                      )
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, WidgetRef ref) {
    return Row(children: [
      _mainBtn("AI SCAN", LucideIcons.scanLine, Colors.purpleAccent, () => _showScanOptions(context, ref)),
      const SizedBox(width: 10),
      _mainBtn("DESCRIBE", LucideIcons.textCursorInput, Colors.orangeAccent, () => _processText(context, ref)),
    ]);
  }

  Widget _mainBtn(String l, IconData i, Color c, VoidCallback onTap) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(i, size: 18),
        label: Text(l, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)), // Smaller font
        style: ElevatedButton.styleFrom(
            backgroundColor: c.withOpacity(0.1),
            foregroundColor: c,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: c.withOpacity(0.3)))),
      ),
    );
  }

  Widget _sectionHeader(String t) => Text(t, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2));

  void _showScanOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B1E),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("AI CALORIE SCAN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 20),
            _scanOptionTile(ctx, "Take Photo", LucideIcons.camera, () => _processImage(context, ref, ImageSource.camera)),
            _scanOptionTile(ctx, "Choose from Gallery", LucideIcons.image, () => _processImage(context, ref, ImageSource.gallery)),

          ],
        ),
      ),
    );
  }

  Widget _scanOptionTile(BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.purpleAccent.withOpacity(0.2), shape: BoxShape.circle), child: Icon(icon, color: Colors.purpleAccent)),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }

  // --- ERROR HANDLING ---
  void _showErrorDialog(BuildContext context, String message) {
    showElegantErrorDialog(
      context,
      title: "Error",
      message: message,
      buttonText: "OK",
    );
  }

  Future<void> _processImage(BuildContext context, WidgetRef ref, ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source, maxWidth: 800, maxHeight: 800, imageQuality: 85);
      
      if (image != null) {
        try {
           final result = await ref.read(foodTrackerProvider.notifier).analyzeFoodImage(image);
           if (result != null) _showAnalysisResult(context, ref, result);
        } catch (e) {
           _showErrorDialog(context, getFriendlyErrorMessage(e));
        }
      }
    } catch (e) {
      debugPrint("Picker Error: $e");
      _showErrorDialog(context, getFriendlyErrorMessage(e));
    }
  }

  void _processText(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161B1E),
        title: const Text("Describe Meal", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: "e.g. A bowl of chicken curry with rice", hintStyle: TextStyle(color: Colors.white30)),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              if (controller.text.isNotEmpty) {
                 try {
                    final result = await ref.read(foodTrackerProvider.notifier).analyzeFoodText(controller.text);
                    if (result != null) _showAnalysisResult(context, ref, result);
                 } catch (e) {
                    _showErrorDialog(context, getFriendlyErrorMessage(e));
                 }
              }
            }, 
            child: const Text("ANALYZE")
          ),
        ],
      ),
    );
  }

  void _showAnalysisResult(BuildContext context, WidgetRef ref, Map<String, dynamic> result) {
    final nameCtrl = TextEditingController(text: result['food_name']);
    final calCtrl = TextEditingController(text: result['calories'].toString());
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B1E),
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(LucideIcons.sparkles, color: Colors.purpleAccent),
              const SizedBox(width: 10),
              const Text("AI ANALYSIS RESULT", style: TextStyle(color: Colors.purpleAccent, fontWeight: FontWeight.bold)),
            ]),
            const SizedBox(height: 10),
            Text(result['description'] ?? "Food identified.", style: const TextStyle(color: Colors.white70, fontStyle: FontStyle.italic, fontSize: 13)),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Food Name", labelStyle: TextStyle(color: Colors.white54)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: calCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: "Calories", labelStyle: TextStyle(color: Colors.white54)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                   final name = nameCtrl.text;
                   final cal = int.tryParse(calCtrl.text) ?? 0;
                   if (name.isNotEmpty && cal > 0) {
                     // 1. Check for Allergy Risk
                     final riskMessage = await ref.read(foodTrackerProvider.notifier).checkAllergyRisk(name);
                     
                     if (riskMessage != null) {
                        // 2. Show Warning if detected
                        _showAllergenWarning(context, riskMessage, () {
                           // 3. Add on confirmation
                           ref.read(foodTrackerProvider.notifier).addFood(name, cal);
                           Navigator.pop(ctx); 
                        });
                     } else {
                        // 4. Add immediately if safe
                        ref.read(foodTrackerProvider.notifier).addFood(name, cal);
                        Navigator.pop(ctx);
                     }
                   }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purpleAccent, padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text("CONFIRM & ADD"),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _openAllergySheet(BuildContext context, WidgetRef ref, FoodTrackerState s) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161B1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setST) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("SELECT ALLERGENS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: availableAllergens.map((allergy) {
                  final isSelected = ref.watch(foodTrackerProvider).allergies.contains(allergy);
                  return GestureDetector(
                    onTap: () {
                      ref.read(foodTrackerProvider.notifier).toggleAllergy(allergy);
                      setST(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.red.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSelected ? Colors.redAccent : Colors.transparent),
                      ),
                      child: Text(allergy, style: TextStyle(color: isSelected ? Colors.redAccent : Colors.white70)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 30),
              SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent), onPressed: () => Navigator.pop(context), child: const Text("SAVE OPTIONS"))),
            ],
          ),
        ),
      ),
    );
  }

  void _showAllergenWarning(BuildContext context, String message, VoidCallback onConfirm) {
    showElegantErrorDialog(
      context,
      title: "Allergy Alert",
      message: message,
      buttonText: "PROCEED ANYWAY",
      icon: LucideIcons.alertTriangle,
      iconColor: Colors.redAccent,
      onPressed: onConfirm,
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showElegantErrorDialog(
      context,
      title: "Reset Data",
      message: "Are you sure you want to delete all food logs? This action cannot be undone.",
      buttonText: "YES, RESET",
      icon: LucideIcons.trash2,
      iconColor: Colors.redAccent,
      onPressed: () => ref.read(foodTrackerProvider.notifier).reset(),
    );
  }

  Widget _buildScanningOverlay() => Container(color: Colors.black87, child: const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)));
}