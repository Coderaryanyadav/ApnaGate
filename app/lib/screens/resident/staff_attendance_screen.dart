import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../services/firestore_service.dart';

class StaffAttendanceScreen extends ConsumerStatefulWidget {
  final String staffId;
  final String staffName;

  const StaffAttendanceScreen({
    super.key, 
    required this.staffId,
    required this.staffName,
  });

  @override
  ConsumerState<StaffAttendanceScreen> createState() => _StaffAttendanceScreenState();
}

class _StaffAttendanceScreenState extends ConsumerState<StaffAttendanceScreen> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('${widget.staffName} Attendance'),
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ref.read(firestoreServiceProvider).getLogsForStaff(widget.staffId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final logs = snapshot.data ?? [];

          // Process logs into a Set of "Present Days"
          // We consider a day "Present" if there is at least one 'entry' log
          final Set<String> presentDates = {};
          
          for (var log in logs) {
             if (log['action'] == 'entry' && log['timestamp'] != null) {
                final dt = DateTime.parse(log['timestamp']).toLocal();
                final key = DateFormat('yyyy-MM-dd').format(dt);
                presentDates.add(key);
             }
          }

          return Column(
            children: [
              // Calendar
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TableCalendar(
                  firstDay: DateTime.utc(2024, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
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
                  // Style
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
                  ),
                  headerStyle: const HeaderStyle(
                    titleTextStyle: TextStyle(color: Colors.white, fontSize: 16),
                    formatButtonTextStyle: TextStyle(color: Colors.white),
                    leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                    rightChevronIcon: Icon(Icons.chevron_right, color: Colors.white),
                  ),
                  
                  // Custom Builders for Markers
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, day, events) {
                       final key = DateFormat('yyyy-MM-dd').format(day);
                       if (presentDates.contains(key)) {
                         return Positioned(
                           bottom: 1,
                           child: Container(
                             width: 6, height: 6,
                             decoration: const BoxDecoration(
                               color: Colors.greenAccent,
                               shape: BoxShape.circle,
                             ),
                           ),
                         );
                       }
                       return null;
                    },
                    defaultBuilder: (context, day, focusedDay) {
                       // Logic to color background if present?
                       final key = DateFormat('yyyy-MM-dd').format(day);
                       if (presentDates.contains(key)) {
                          return Center(
                            child: Container(
                              alignment: Alignment.center,
                               width: 35, height: 35,
                               decoration: BoxDecoration(
                                 color: Colors.green.withValues(alpha: 0.2),
                                 shape: BoxShape.circle,
                                 border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.5)),
                               ),
                               child: Text(
                                 '${day.day}',
                                 style: const TextStyle(color: Colors.white),
                               ),
                            ),
                          );
                       }
                       return null; // Use default
                    },
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.history, color: Colors.white54, size: 16),
                    SizedBox(width: 8),
                    Text('Detailed Logs', style: TextStyle(color: Colors.white54, fontSize: 14)),
                  ],
                ),
              ),

              // LOGS LIST
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final isEntry = log['action'] == 'entry';
                    final dt = DateTime.parse(log['timestamp']).toLocal();
                    
                    return Card(
                      color: const Color(0xFF1E1E1E),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Icon(
                          isEntry ? Icons.login : Icons.logout,
                          color: isEntry ? Colors.greenAccent : Colors.redAccent,
                        ),
                        title: Text(
                          isEntry ? 'Entry' : 'Exit',
                          style: TextStyle(
                            color: isEntry ? Colors.greenAccent : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          DateFormat('MMM dd, yyyy - hh:mm a').format(dt),
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ),
                    );
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
