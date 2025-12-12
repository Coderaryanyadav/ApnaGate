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
  DateTime? _selectedDay = DateTime.now(); // Initialize to Today

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.staffName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        color: Colors.white, // ✅ WHITE BACKGROUND
        child: SafeArea(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: ref.read(firestoreServiceProvider).getLogsForStaff(widget.staffId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Colors.black));
              }

              final allLogs = snapshot.data ?? [];

              // Process logs into a Set of "Present Days"
              final Set<String> presentDates = {};
              for (var log in allLogs) {
                 if (log['action'] == 'entry' && log['timestamp'] != null) {
                    final dt = DateTime.parse(log['timestamp']).toLocal();
                    final key = DateFormat('yyyy-MM-dd').format(dt);
                    presentDates.add(key);
                 }
              }

              // Filter Logs for Viewer
              final filteredLogs = _selectedDay == null 
                  ? allLogs 
                  : allLogs.where((log) {
                      if (log['timestamp'] == null) return false;
                      final dt = DateTime.parse(log['timestamp']).toLocal();
                      return isSameDay(dt, _selectedDay);
                    }).toList();

              return Column(
                children: [
                  // Calendar Card
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      // border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
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
                      onFormatChanged: (format) => setState(() => _calendarFormat = format),
                      onPageChanged: (focusedDay) => _focusedDay = focusedDay,
                      
                      // Styles
                      headerStyle: const HeaderStyle(
                        titleCentered: true,
                        formatButtonVisible: false,
                        titleTextStyle: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.bold),
                        leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black54),
                        rightChevronIcon: Icon(Icons.chevron_right, color: Colors.black54),
                      ),
                      calendarStyle: const CalendarStyle(
                        defaultTextStyle: TextStyle(color: Colors.black87),
                        weekendTextStyle: TextStyle(color: Colors.black54),
                        outsideTextStyle: TextStyle(color: Colors.black12),
                        todayDecoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: TextStyle(color: Colors.white),
                        selectedDecoration: BoxDecoration(
                          color: Colors.black,
                          shape: BoxShape.circle,
                        ),
                        selectedTextStyle: TextStyle(color: Colors.white),
                      ),
                      
                      // Builders
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (context, day, focusedDay) {
                           final key = DateFormat('yyyy-MM-dd').format(day);
                           if (presentDates.contains(key)) {
                              return Center(
                                child: Container(
                                   width: 35, height: 35,
                                   decoration: BoxDecoration(
                                     color: Colors.green.withValues(alpha: 0.1),
                                     shape: BoxShape.circle,
                                     border: Border.all(color: Colors.green),
                                   ),
                                   alignment: Alignment.center,
                                   child: Text('${day.day}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                                ),
                              );
                           }
                           return null;
                        },
                      ),
                    ),
                  ),

                  // Divider / Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Row(
                      children: [
                        Text(
                          _selectedDay == null 
                            ? 'All History' 
                            : 'Activity for ${DateFormat('dd MMM').format(_selectedDay!)}', 
                          style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1),
                        ),
                        const Expanded(child: Divider(color: Colors.black12, indent: 16)),
                      ],
                    ),
                  ),

                  // LOGS LIST
                  Expanded(
                    child: filteredLogs.isEmpty 
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.history_toggle_off, size: 48, color: Colors.black12),
                              const SizedBox(height: 12),
                              Text('No records found', style: TextStyle(color: Colors.black26)),
                            ],
                          ),
                        )
                      : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        physics: const BouncingScrollPhysics(),
                        itemCount: filteredLogs.length,
                        itemBuilder: (context, index) {
                          final log = filteredLogs[index];
                          final isEntry = log['action'] == 'entry';
                          final dt = DateTime.parse(log['timestamp']).toLocal();
                          
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
                              boxShadow: [
                                 BoxShadow(
                                   color: Colors.black.withValues(alpha: 0.03),
                                   blurRadius: 5,
                                   offset: const Offset(0, 2),
                                 )
                              ]
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isEntry 
                                      ? const Color(0xFF00C853).withValues(alpha: 0.1) 
                                      : const Color(0xFFD32F2F).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isEntry ? Icons.login_rounded : Icons.logout_rounded,
                                  color: isEntry ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                isEntry ? 'Check In' : 'Check Out',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              subtitle: Text(
                                DateFormat('MMM dd • hh:mm a').format(dt),
                                style: TextStyle(color: Colors.black54, fontSize: 13),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  DateFormat('hh:mm').format(dt),
                                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
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
        ),
      ),
    );
  }
}
