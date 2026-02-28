import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:my_sejahtera_ng/core/widgets/glass_container.dart';
import 'package:google_fonts/google_fonts.dart';

void showElegantErrorDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? buttonText,
  VoidCallback? onPressed,
  IconData icon = LucideIcons.alertCircle,
  Color iconColor = Colors.redAccent,
}) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassContainer(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 40),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  onPressed?.call();
                },
                child: Text(
                  buttonText ?? "OK",
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
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

void showElegantSuccessDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? buttonText,
  VoidCallback? onPressed,
}) {
  showElegantErrorDialog(
    context,
    title: title,
    message: message,
    buttonText: buttonText ?? "Great!",
    onPressed: onPressed,
    icon: LucideIcons.checkCircle,
    iconColor: Colors.greenAccent,
  );
}

String getFriendlyErrorMessage(Object error) {
  final String raw = error.toString();
  
  if (raw.contains("AuthWeakPasswordException")) {
    return "Your password is too weak. Please use at least 6 characters.";
  }
  if (raw.contains("User already registered") || raw.contains("already exists")) {
    return "An account with this email already exists. Please login instead.";
  }
  if (raw.contains("Invalid login credentials")) {
    return "Incorrect email or password. Please try again.";
  }
  if (raw.contains("SocketException") || raw.contains("ClientException")) {
    return "Network error. Please check your internet connection.";
  }
  
  // Extract message from "Exception: message" or "AuthException(message: ...)"
  if (raw.contains("message:")) {
    final start = raw.indexOf("message:") + 8;
    final end = raw.indexOf(",", start);
    if (end != -1) {
      return raw.substring(start, end).trim();
    }
    // Fallback if no comma
    final endBracket = raw.indexOf(")", start);
    if (endBracket != -1) {
       return raw.substring(start, endBracket).trim();
    }
  }

  // Fallback cleanup
  var clean = raw.replaceAll("Exception:", "").replaceAll("AuthException:", "").trim();
  if (clean.startsWith("Error:")) clean = clean.substring(6).trim();
  
  return clean.isNotEmpty ? clean : "Something went wrong. Please try again.";
}
