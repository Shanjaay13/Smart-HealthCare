import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:my_sejahtera_ng/features/food_tracker/providers/food_tracker_provider.dart';
import 'package:my_sejahtera_ng/core/utils/ui_utils.dart';
import 'package:my_sejahtera_ng/core/theme/app_theme.dart';

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
    "🥣 Fiber Focus: Add chia seeds or flaxseeds to your breakfast for better digestion.",
  ];

  static const List<String> availableAllergens = [
    'Peanut',
    'Milk & Dairy',
    'Sesame',
    'Wheat & Gluten',
    'Shellfish',
    'Fish',
    'Chicken',
    'Lamb',
    'Beef',
    'Soy',
    'Egg',
    'Tree Nuts',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.autoShowHydration) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Scroll to hydration panel
        if (_hydrationKey.currentContext != null) {
          Scrollable.ensureVisible(
            _hydrationKey.currentContext!,
            duration: 800.ms,
            curve: Curves.easeInOut,
          );
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                backgroundColor: Colors.white,
                elevation: 0,
                pinned: true,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                  title: Text(
                    "Nutrition",
                    style: GoogleFonts.outfit(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 32,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: _buildConfigMenu(context, ref, state),
                  ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 140),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildStunningMacroRings(state),
                    const SizedBox(height: 32),
                    Container(
                      key: _hydrationKey,
                      child: _buildGlassHydration(state),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      "TODAY'S LOG",
                      style: GoogleFonts.outfit(
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStunningTimeline(context, ref, state),
                    const SizedBox(height: 32),
                    _buildCalorieChart(state),
                    const SizedBox(height: 48),
                    Text(
                      "AI HEALTH INSIGHTS",
                      style: GoogleFonts.outfit(
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDynamicInsights(state),
                    const SizedBox(height: 32),
                    Text(
                      "HEALTHY SUGGESTIONS",
                      style: GoogleFonts.outfit(
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildSuggestionCard(randomSuggestion),
                  ]),
                ),
              ),
            ],
          ),

          // Immersive Floating Action Dock
          Positioned(
            bottom: 30,
            left: 30,
            right: 30,
            child: _buildImmersiveDock(context, ref),
          ),

          if (state.isScanning) _buildScanningOverlay(),
        ],
      ),
    );
  }

  Widget _buildStunningMacroRings(FoodTrackerState state) {
    double progress = (state.totalCalories / state.calorieTarget).clamp(
      0.0,
      1.0,
    );
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: CircularProgressIndicator(
                      value: 1.0,
                      color: AppTheme.bgLight,
                      strokeWidth: 18,
                    ),
                  ),
                  ShaderMask(
                    shaderCallback: (rect) => const SweepGradient(
                      startAngle: -1.5707963268, // -pi/2
                      endAngle: 4.7123889804, // 3*pi/2
                      colors: [Color(0xFF8B5CF6), Color(0xFF0EA5E9), Color(0xFF10B981)],
                      stops: [0.0, 0.5, 1.0],
                    ).createShader(rect),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: CircularProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 18,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${state.totalCalories}",
                        style: GoogleFonts.outfit(
                          color: AppTheme.textDark,
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        progress >= 1.0 ? "OVER LIMIT" : "KCAL CONSUMED",
                        style: GoogleFonts.outfit(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 36),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.target,
                          color: AppTheme.primaryBlue,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "TARGET",
                        style: GoogleFonts.outfit(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${state.calorieTarget} kcal",
                    style: GoogleFonts.outfit(
                      color: AppTheme.textDark,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.grey.withOpacity(0.2),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(
                        "REMAINING",
                        style: GoogleFonts.outfit(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          LucideIcons.flame,
                          color: Color(0xFFF59E0B),
                          size: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${max(0, state.calorieTarget - state.totalCalories)} kcal",
                    style: GoogleFonts.outfit(
                      color: AppTheme.textDark,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, curve: Curves.easeOutQuad);
  }

  Widget _buildGlassHydration(FoodTrackerState state) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(36),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Color(0xFF0EA5E9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.droplets,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Hydration",
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF0284C7),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        "${state.waterCount} / 8 Glasses",
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF0284C7).withOpacity(0.7),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => ref
                        .read(foodTrackerProvider.notifier)
                        .removeDrink(),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0EA5E9).withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.minus,
                        color: Color(0xFF0EA5E9),
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => _logEntry(context, ref, true),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0EA5E9).withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.plus,
                        color: Color(0xFF0EA5E9),
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(8, (index) {
              bool filled = index < state.waterCount;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: 32,
                height: 48,
                decoration: BoxDecoration(
                  color: filled
                      ? const Color(0xFF0EA5E9)
                      : Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: filled
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0EA5E9).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : [],
                ),
                child: filled
                    ? const Icon(
                        LucideIcons.droplet,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStunningTimeline(
    BuildContext context,
    WidgetRef ref,
    FoodTrackerState state,
  ) {
    final allEntries = [...state.foods, ...state.drinks];
    // Sort logic placeholder if they have timestamps, but for now we'll just show them
    
    if (allEntries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppTheme.bgLight,
          borderRadius: BorderRadius.circular(32),
        ),
        child: const Center(
          child: Text(
            "No meals or drinks logged yet.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ),
      );
    }
    return Column(
      children: allEntries.map((entry) {
        final isDrink = entry.type != null;
        final iconStr = isDrink ? "💧" : "🍲";

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.bgLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(iconStr, style: const TextStyle(fontSize: 24)),
                  ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                     if (!isDrink) {
                        _showEditFoodDialog(context, ref, entry);
                     }
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        style: GoogleFonts.outfit(
                          color: AppTheme.textDark,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.flame,
                            size: 14,
                            color: Color(0xFFF59E0B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "${entry.calories} kcal",
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFD97706),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.trash2,
                    color: AppTheme.error,
                    size: 18,
                  ),
                ),
                onTap: () {
                  if (entry.id != null) {
                    if (isDrink) {
                       ref.read(foodTrackerProvider.notifier).deleteDrink(entry.id!);
                    } else {
                       ref.read(foodTrackerProvider.notifier).deleteFood(entry.id!);
                    }
                  }
                },
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  void _showEditFoodDialog(
    BuildContext context,
    WidgetRef ref,
    FoodEntry food,
  ) {
    if (food.id == null) return;
    final nameCtrl = TextEditingController(text: food.name);
    final calCtrl = TextEditingController(text: food.calories.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Edit Food",
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: AppTheme.textDark),
              decoration: InputDecoration(
                labelText: "Name",
                labelStyle: const TextStyle(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.bgLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: calCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textDark),
              decoration: InputDecoration(
                labelText: "Calories",
                labelStyle: const TextStyle(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.bgLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Cancel",
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final newName = nameCtrl.text.trim();
              final newCal = int.tryParse(calCtrl.text) ?? food.calories;
              if (newName.isNotEmpty && newCal > 0) {
                ref
                    .read(foodTrackerProvider.notifier)
                    .updateFood(food.id!, newName, newCal);
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

  Widget _buildConfigMenu(
    BuildContext context,
    WidgetRef ref,
    FoodTrackerState state,
  ) {
    return PopupMenuButton<String>(
      icon: const Icon(LucideIcons.settings, color: AppTheme.textDark),
      color: AppTheme.surfaceWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (value) {
        if (value == 'target') _openTargetSheet(context, ref, state);
        if (value == 'allergy') _openAllergySheet(context, ref, state);
        if (value == 'reset') _showResetDialog(context, ref);
      },
      itemBuilder: (ctx) => [
        const PopupMenuItem(
          value: 'target',
          child: ListTile(
            leading: Icon(LucideIcons.target, color: AppTheme.primaryBlue),
            title: Text(
              "Daily Goal",
              style: TextStyle(
                color: AppTheme.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const PopupMenuItem(
          value: 'allergy',
          child: ListTile(
            leading: Icon(LucideIcons.shieldAlert, color: AppTheme.error),
            title: Text(
              "Allergies",
              style: TextStyle(
                color: AppTheme.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const PopupMenuItem(
          value: 'reset',
          child: ListTile(
            leading: Icon(LucideIcons.refreshCcw, color: Color(0xFFF59E0B)),
            title: Text(
              "Reset Data",
              style: TextStyle(
                color: AppTheme.textDark,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openTargetSheet(
    BuildContext context,
    WidgetRef ref,
    FoodTrackerState s,
  ) {
    final formKey = GlobalKey<FormState>();
    final c = TextEditingController(text: s.calorieTarget.toString());

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceWhite,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Set Daily Goal",
                style: TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: c,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textDark),
                decoration: InputDecoration(
                  labelText: "Calories (kcal)",
                  labelStyle: const TextStyle(color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.bgLight,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return "Please set your daily calorie goal";
                  final n = int.tryParse(value);
                  if (n == null) return "Calories must be a number";
                  if (n < 800) return "Daily intake too low to be healthy";
                  if (n > 6000) return "Daily intake too high";
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      ref
                          .read(foodTrackerProvider.notifier)
                          .setTarget(int.parse(c.text));
                      Navigator.pop(context);
                    }
                  },
                  child: const Text(
                    "SAVE TARGET",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
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
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (c, setST) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 30,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDrink ? "Log Drink" : "Log Food",
                  style: const TextStyle(
                    color: AppTheme.textDark,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                if (isDrink) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.bgLight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<DrinkType>(
                        dropdownColor: AppTheme.surfaceWhite,
                        value: drinkType,
                        items: DrinkType.values
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text(
                                  e.name,
                                  style: const TextStyle(
                                    color: AppTheme.textDark,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setST(() {
                          drinkType = v!;
                          if (drinkType == DrinkType.water) calCtrl.text = "0";
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: nameCtrl,
                  style: const TextStyle(color: AppTheme.textDark),
                  decoration: InputDecoration(
                    hintText: isDrink
                        ? "Drink Name (e.g. Mocha)"
                        : "Food Name (e.g. Salad)",
                    hintStyle: const TextStyle(color: AppTheme.textMuted),
                    filled: true,
                    fillColor: AppTheme.bgLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    final trimmed = value?.trim() ?? "";
                    if (trimmed.isEmpty) return "Please enter a valid name";
                    if (trimmed.length < 2) return "Name too short";
                    if (RegExp(r'^[0-9]+$').hasMatch(trimmed))
                      return "Enter a valid name (not just numbers)";
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                if (drinkType != DrinkType.water)
                  TextFormField(
                    controller: calCtrl,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: AppTheme.textDark),
                    decoration: InputDecoration(
                      hintText: "Calories (kcal)",
                      hintStyle: const TextStyle(color: AppTheme.textMuted),
                      filled: true,
                      fillColor: AppTheme.bgLight,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return "Enter calorie amount";
                      final n = int.tryParse(value);
                      if (n == null) return "Must be a whole number";
                      if (n <= 0) return "Calories must be greater than zero";
                      if (n > 2000) return "Unrealistic for a single item";
                      return null;
                    },
                  ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final name = nameCtrl.text.trim();
                        final cal = int.tryParse(calCtrl.text) ?? 0;
                        Navigator.pop(ctx);

                        final riskMessage = await ref
                            .read(foodTrackerProvider.notifier)
                            .checkAllergyRisk(name);
                        if (riskMessage != null) {
                          _showAllergenWarning(context, riskMessage, () {
                            isDrink
                                ? ref
                                      .read(foodTrackerProvider.notifier)
                                      .addDrink(name, cal, drinkType)
                                : ref
                                      .read(foodTrackerProvider.notifier)
                                      .addFood(name, cal);
                          });
                        } else {
                          isDrink
                              ? ref
                                    .read(foodTrackerProvider.notifier)
                                    .addDrink(name, cal, drinkType)
                              : ref
                                    .read(foodTrackerProvider.notifier)
                                    .addFood(name, cal);
                        }
                      }
                    },
                    child: const Text(
                      "SAVE ENTRY",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
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
      messages.add(
        _insightItem(
          "Warning: Calorie target exceeded by ${(state.totalCalories - state.calorieTarget)} kcal.",
          AppTheme.error,
          LucideIcons.frown,
        ),
      );
    } else if (calPercent > 0.8) {
      messages.add(
        _insightItem(
          "Approaching limit. Consider lighter snacks for later.",
          const Color(0xFFF59E0B),
          LucideIcons.gauge,
        ),
      );
    }

    if (state.waterCount < 3) {
      messages.add(
        _insightItem(
          "Hydration Low: You've logged less than 3 glasses of water.",
          AppTheme.primaryBlue,
          LucideIcons.droplets,
        ),
      );
    } else {
      messages.add(
        _insightItem(
          "Hydration Good: Keep maintaining this water intake!",
          AppTheme.success,
          LucideIcons.smile,
        ),
      );
    }
    return Column(children: messages);
  }

  Widget _insightItem(String text, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.textDark,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildSuggestionCard(String text) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.lightbulb,
              color: Color(0xFFF59E0B),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppTheme.textDark,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms);
  }

  Widget _buildProgressCard(FoodTrackerState state) {
    double progress = (state.totalCalories / state.calorieTarget).clamp(
      0.0,
      1.0,
    );
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Daily Intake",
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "${(progress * 100).toInt()}%",
                  style: const TextStyle(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.bgLight,
            color: progress >= 1.0 ? AppTheme.error : AppTheme.primaryBlue,
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${state.totalCalories}",
                style: const TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                " / ${state.calorieTarget} kcal",
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
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
    final maxY = maxCalories * 1.2;

    final isOverLimit = state.totalCalories > state.calorieTarget;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "7-Day Trend",
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isOverLimit)
                Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.error.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.alertTriangle,
                            color: AppTheme.error,
                            size: 12,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            "High Intake",
                            style: TextStyle(
                              color: AppTheme.error,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      duration: 1.seconds,
                      begin: const Offset(1, 1),
                      end: const Offset(1.05, 1.05),
                    ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                maxY: maxY,
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        final date = today.subtract(
                          Duration(days: 6 - val.toInt()),
                        );
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('E').format(date).substring(0, 1),
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (index) {
                  final dateKey = DateFormat(
                    'yyyy-MM-dd',
                  ).format(today.subtract(Duration(days: 6 - index)));
                  final calories =
                      state.dailyHistory[dateKey]?.toDouble() ?? 0.0;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: calories,
                        color: calories > state.calorieTarget
                            ? AppTheme.error
                            : AppTheme.primaryBlue,
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: AppTheme.bgLight,
                        ),
                      ),
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

  Widget _buildImmersiveDock(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _showScanOptions(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.camera,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "AI Scan",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => _showImmersiveTextLog(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      LucideIcons.sparkles,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Describe",
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showScanOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "AI Calorie Scan",
              style: TextStyle(
                color: AppTheme.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 24),
            _scanOptionTile(
              ctx,
              "Take Photo",
              LucideIcons.camera,
              () => _processImage(context, ref, ImageSource.camera),
            ),
            const SizedBox(height: 12),
            _scanOptionTile(
              ctx,
              "Choose from Gallery",
              LucideIcons.image,
              () => _processImage(context, ref, ImageSource.gallery),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _scanOptionTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF8B5CF6).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(LucideIcons.camera, color: Color(0xFF8B5CF6)),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textDark,
          fontWeight: FontWeight.bold,
        ),
      ),
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

  Future<void> _processImage(
    BuildContext context,
    WidgetRef ref,
    ImageSource source,
  ) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (image != null) {
        try {
          final result = await ref
              .read(foodTrackerProvider.notifier)
              .analyzeFoodImage(image);
          if (result != null && context.mounted)
            _showAnalysisResult(context, ref, result);
        } catch (e) {
          if (context.mounted)
            _showErrorDialog(context, getFriendlyErrorMessage(e));
        }
      }
    } catch (e) {
      debugPrint("Picker Error: $e");
      if (context.mounted)
        _showErrorDialog(context, getFriendlyErrorMessage(e));
    }
  }

  void _showImmersiveTextLog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        padding: EdgeInsets.fromLTRB(
          32,
          40,
          32,
          MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.bot,
                      color: Color(0xFF8B5CF6),
                      size: 24,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(LucideIcons.x, color: AppTheme.textDark),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                "What did you\neat today?",
                style: GoogleFonts.outfit(
                  color: AppTheme.textDark,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Tell me naturally. I'll figure out the calories & nutrients.",
                style: GoogleFonts.outfit(
                  color: AppTheme.textMuted,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                constraints: const BoxConstraints(minHeight: 120, maxHeight: 200),
                child: TextField(
                  controller: controller,
                  maxLines: null,
                  autofocus: true,
                  style: GoogleFonts.outfit(
                    color: AppTheme.textDark,
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        "e.g. A large bowl of tonkotsu ramen with extra egg...",
                    hintStyle: GoogleFonts.outfit(
                      color: Colors.grey.shade300,
                      fontSize: 24,
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (controller.text.isNotEmpty) {
                    Navigator.pop(ctx);
                    try {
                      final result = await ref
                          .read(foodTrackerProvider.notifier)
                          .analyzeFoodText(controller.text);
                      if (result != null && context.mounted)
                        _showAnalysisResult(context, ref, result);
                    } catch (e) {
                      if (context.mounted)
                        _showErrorDialog(context, getFriendlyErrorMessage(e));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 10,
                  shadowColor: const Color(0xFF0F172A).withOpacity(0.3),
                ),
                child: Text(
                  "Analyze Meal",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  void _showAnalysisResult(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> result,
  ) {
    final nameCtrl = TextEditingController(text: result['food_name']);
    final calCtrl = TextEditingController(text: result['calories'].toString());

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 32,
          right: 32,
          top: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.sparkles,
                    color: Color(0xFF8B5CF6),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "AI Analysis Result",
                  style: TextStyle(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgLight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                result['description'] ?? "Food identified.",
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontStyle: FontStyle.italic,
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: AppTheme.textDark),
              decoration: InputDecoration(
                labelText: "Food Name",
                labelStyle: const TextStyle(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.bgLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: calCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textDark),
              decoration: InputDecoration(
                labelText: "Calories",
                labelStyle: const TextStyle(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.bgLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text;
                  final cal = int.tryParse(calCtrl.text) ?? 0;
                  if (name.isNotEmpty && cal > 0) {
                    final riskMessage = await ref
                        .read(foodTrackerProvider.notifier)
                        .checkAllergyRisk(name);

                    if (riskMessage != null && ctx.mounted) {
                      _showAllergenWarning(ctx, riskMessage, () {
                        ref
                            .read(foodTrackerProvider.notifier)
                            .addFood(name, cal);
                        Navigator.pop(ctx);
                      });
                    } else if (ctx.mounted) {
                      ref.read(foodTrackerProvider.notifier).addFood(name, cal);
                      Navigator.pop(ctx);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  "CONFIRM & ADD",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _openAllergySheet(
    BuildContext context,
    WidgetRef ref,
    FoodTrackerState s,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceWhite,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setST) => SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.only(
              left: 32,
              right: 32,
              top: 32,
              bottom: MediaQuery.of(context).padding.bottom + 32,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Select Allergens",
                style: TextStyle(
                  color: AppTheme.textDark,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "We will warn you if AI detects these in scanned food.",
                style: TextStyle(color: AppTheme.textMuted),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: availableAllergens.map((allergy) {
                  final isSelected = ref
                      .watch(foodTrackerProvider)
                      .allergies
                      .contains(allergy);
                  return GestureDetector(
                    onTap: () {
                      ref
                          .read(foodTrackerProvider.notifier)
                          .toggleAllergy(allergy);
                      setST(() {});
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.error.withOpacity(0.1)
                            : AppTheme.bgLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.error.withOpacity(0.5)
                              : Colors.transparent,
                        ),
                      ),
                      child: Text(
                        allergy,
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.error
                              : AppTheme.textDark,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "SAVE ALLERGENS",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
      ),
    );
  }

  void _showAllergenWarning(
    BuildContext context,
    String message,
    VoidCallback onConfirm,
  ) {
    showElegantErrorDialog(
      context,
      title: "Allergy Alert",
      message: message,
      buttonText: "PROCEED ANYWAY",
      icon: LucideIcons.alertTriangle,
      iconColor: AppTheme.error,
      onPressed: onConfirm,
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          "Reset Data",
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: const Text(
          "Are you sure you want to delete all food logs for today? This cannot be undone.",
          style: TextStyle(color: AppTheme.textMuted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "Cancel",
              style: TextStyle(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              ref.read(foodTrackerProvider.notifier).resetToday();
              Navigator.pop(ctx);
            },
            child: const Text("Reset"),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.scanLine, size: 60, color: Color(0xFF8B5CF6))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  duration: 800.ms,
                  begin: const Offset(1, 1),
                  end: const Offset(1.2, 1.2),
                ),
            const SizedBox(height: 24),
            const Text(
              "AI is analyzing food...",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Checking ingredients and measuring calories",
              style: TextStyle(color: Colors.white54),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}
