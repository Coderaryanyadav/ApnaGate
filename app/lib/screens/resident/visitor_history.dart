import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/visitor_request.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/visitor_card.dart';
import '../../widgets/loading_widgets.dart';

class VisitorHistoryScreen extends ConsumerStatefulWidget {
  const VisitorHistoryScreen({super.key});

  @override
  ConsumerState<VisitorHistoryScreen> createState() => _VisitorHistoryScreenState();
}

class _VisitorHistoryScreenState extends ConsumerState<VisitorHistoryScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.week;
  
  Map<DateTime, List<VisitorRequest>> _events = {};

  // Group visitors by day
  Map<DateTime, List<VisitorRequest>> _groupVisitorsByDay(List<VisitorRequest> visitors) {
    final Map<DateTime, List<VisitorRequest>> data = {};
    for (var visitor in visitors) {
      // Normalize date to UTC midnight for comparison or just local YMD
      final date = DateTime(
        visitor.createdAt.year, 
        visitor.createdAt.month, 
        visitor.createdAt.day
      );
      if (data[date] == null) data[date] = [];
      data[date]!.add(visitor);
    }
    return data;
  }

  List<VisitorRequest> _getVisitorsForDay(DateTime day) {
    final date = DateTime(day.year, day.month, day.day);
    return _events[date] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;
    if (user == null) return const SizedBox.shrink();

    final historyStream = ref.watch(firestoreServiceProvider).getVisitorHistoryForResident(user.id);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Visitor Log'), backgroundColor: Colors.transparent),
      body: StreamBuilder<List<VisitorRequest>>(
        stream: historyStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingList(message: 'Loading logs...');
          }
          
          final allVisitors = snapshot.data ?? [];
          _events = _groupVisitorsByDay(allVisitors);

          final selectedVisitors = _getVisitorsForDay(_selectedDay ?? _focusedDay);

          return Column(
            children: [
              // Calendar
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: TableCalendar(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                     setState(() {
                       _calendarFormat = format;
                     });
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                  },
                  eventLoader: _getVisitorsForDay,
                  calendarStyle: const CalendarStyle(
                    defaultTextStyle: TextStyle(color: Colors.white),
                    weekendTextStyle: TextStyle(color: Colors.white70),
                    outsideTextStyle: TextStyle(color: Colors.white24),
                    todayDecoration: BoxDecoration(
                      color: Colors.indigoAccent,
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: Colors.orangeAccent,
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: BoxDecoration(
                      color: Colors.tealAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonTextStyle: TextStyle(color: Colors.white),
                    titleTextStyle: TextStyle(color: Colors.white, fontSize: 16),
                    leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                    rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
                  ),
                ),
              ),

              const Divider(color: Colors.white12),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.history, color: Colors.orangeAccent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Entries (${selectedVisitors.length})',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              // List
              Expanded(
                child: selectedVisitors.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey[800]),
                          const SizedBox(height: 16),
                          Text(
                            'No visitors on this date',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: selectedVisitors.length,
                      itemBuilder: (context, index) {
                         // Sort reverse chronological
                         selectedVisitors.sort((a,b) => b.createdAt.compareTo(a.createdAt));
                         return VisitorCard(request: selectedVisitors[index]);
                      },
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}
