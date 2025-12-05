import 'package:flutter/material.dart';
import '../guard/visitor_status.dart';

// Reusing VisitorStatusScreen logic since it fetches all logs
class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const VisitorStatusScreen(); 
  }
}
