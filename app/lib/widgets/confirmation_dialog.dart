import 'package:flutter/material.dart';

/// Reusable Confirmation Dialog
/// Shows before destructive actions
class ConfirmationDialog {
  static Future<bool> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color confirmColor = Colors.red,
    IconData? icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: confirmColor, size: 28),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              cancelText,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  /// Quick delete confirmation
  static Future<bool> confirmDelete({
    required BuildContext context,
    required String itemName,
  }) {
    return show(
      context: context,
      title: 'Delete $itemName?',
      message: 'This action cannot be undone. Are you sure you want to delete this $itemName?',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      confirmColor: Colors.red,
      icon: Icons.delete_forever,
    );
  }

  /// Quick SOS confirmation
  static Future<bool> confirmSOS({
    required BuildContext context,
  }) {
    return show(
      context: context,
      title: 'Send SOS Alert?',
      message: 'This will immediately notify all guards and admins. Only use in real emergencies.',
      confirmText: 'Send SOS',
      cancelText: 'Cancel',
      confirmColor: Colors.red,
      icon: Icons.warning_amber_rounded,
    );
  }
}
