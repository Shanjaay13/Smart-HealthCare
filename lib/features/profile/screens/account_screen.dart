import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_sejahtera_ng/core/providers/user_provider.dart';
import 'package:my_sejahtera_ng/core/theme/app_theme.dart';
import 'package:my_sejahtera_ng/core/widgets/glass_container.dart';
import 'package:my_sejahtera_ng/features/auth/screens/login_screen.dart';
import 'package:my_sejahtera_ng/features/gamification/screens/rewards_screen.dart';
import 'package:my_sejahtera_ng/features/profile/screens/emergency_sos_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22, shadows: [Shadow(color: Colors.black45, blurRadius: 5)])),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryBlue, const Color(0xFF0284C7)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: user == null
                ? const Center(child: Text("No User Logged In", style: TextStyle(color: Colors.white)))
                : Column(
                    children: [
                      const SizedBox(height: 20),
                      // Avatar & Name
                      const CircleAvatar(
                        radius: 50,
                        backgroundColor: AppTheme.accentTeal,
                        child: const Icon(LucideIcons.user, size: 50, color: AppTheme.primaryBlue),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        user.fullName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          textAlign: TextAlign.center,
                      ),
                      Text(
                        "MySJ ID: ${user.username}",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Rewards Entry Point
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const RewardsScreen()));
                        },
                        child: GlassContainer(
                          borderRadius: BorderRadius.circular(16),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  color: Colors.amber,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(LucideIcons.crown, color: Colors.black, size: 20),
                              ),
                              const SizedBox(width: 16),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Rewards & Customization", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text("Themes, Frames, Icons", style: TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                              const Spacer(),
                              const Icon(LucideIcons.chevronRight, color: Colors.white54),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // NEW: Emergency SOS
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const EmergencySOSScreen()));
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.redAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.redAccent),
                            boxShadow: [
                              BoxShadow(color: Colors.redAccent.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)
                            ]
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(LucideIcons.siren, color: Colors.redAccent),
                              SizedBox(width: 12),
                              Text(
                                "EMERGENCY MEDICAL CARD",
                                style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  letterSpacing: 1.2
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: 2.seconds, begin: const Offset(1.0, 1.0), end: const Offset(1.02, 1.02)),
                      
                      const SizedBox(height: 30),

                      // MySJ ID Card
                      GlassContainer(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Text(
                              "MySJ ID",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 15),
                            Container(
                              height: 200,
                              width: 200,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Center(
                                child: Icon(LucideIcons.qrCode, size: 150, color: Colors.black),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Scan to verify",
                              style: TextStyle(color: Colors.white60, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Details List
                      GlassContainer(
                        width: double.infinity,
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _buildProfileItem("Full Name", user.fullName),
                            _buildDivider(),
                            _buildProfileItem("IC / Passport", user.icNumber),
                            _buildDivider(),
                            _buildProfileItem("Phone", user.phone, onEdit: () => _showEditPhoneDialog(context, ref, user.phone)),
                            _buildDivider(),
                            _buildProfileItem("Status", "Verified Account", isVerified: true),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            ref.read(userProvider.notifier).logout();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                              (Route<dynamic> route) => false,
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white30),
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Log Out"),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _showDeleteConfirmDialog(context, ref),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.redAccent),
                            foregroundColor: Colors.redAccent,
                          ),
                          child: const Text("Delete Account"),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(String label, String value, {bool isVerified = false, VoidCallback? onEdit}) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                if (isVerified) ...[
                  const SizedBox(width: 5),
                  const Icon(LucideIcons.checkCircle, size: 16, color: AppTheme.accentTeal),
                ],
                if (onEdit != null) ...[
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: onEdit,
                    child: const Icon(LucideIcons.edit3, size: 16, color: Colors.blueAccent),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, color: Colors.white10);
  }

  void _showEditPhoneDialog(BuildContext context, WidgetRef ref, String currentPhone) {
    final controller = TextEditingController(text: currentPhone);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Edit Phone Number", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Enter new phone number",
            hintStyle: TextStyle(color: Colors.white38),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white38)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.blueAccent)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newPhone = controller.text.trim();
              if (newPhone.isNotEmpty) {
                 try {
                   await ref.read(userProvider.notifier).updateContactInfo(newPhone);
                   if (context.mounted) Navigator.pop(context);
                 } catch (e) {
                   // Handle error
                 }
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
  void _showDeleteConfirmDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Delete Account", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
               Navigator.pop(context); // Close dialog
               // Show loading indicator or handle it in UI
               try {
                 await ref.read(userProvider.notifier).deleteAccount();
                 if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (Route<dynamic> route) => false,
                    );
                 }
               } catch (e) {
                  if (context.mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete account: $e")));
                  }
               }
            },
            child: const Text("Delete permanently"),
          ),
        ],
      ),
    );
  }
}
