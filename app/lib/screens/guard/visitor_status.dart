import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../../models/visitor_request.dart';
import '../../services/firestore_service.dart';
import '../../widgets/visitor_card.dart';
import '../../widgets/empty_state.dart';

class VisitorStatusScreen extends ConsumerStatefulWidget {
  const VisitorStatusScreen({super.key});

  @override
  ConsumerState<VisitorStatusScreen> createState() => _VisitorStatusScreenState();
}

class _VisitorStatusScreenState extends ConsumerState<VisitorStatusScreen> {
  String _searchQuery = '';
  String _statusFilter = 'all'; // all, pending, approved, rejected

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter by Status'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                title: const Text('All'),
                leading: Radio<String>(
                  value: 'all',
                  // ignore: deprecated_member_use
                  groupValue: _statusFilter,
                  // ignore: deprecated_member_use
                  onChanged: (String? value) {
                    setState(() {
                      _statusFilter = value!;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: const Text('Pending'),
                leading: Radio<String>(
                  value: 'pending',
                  // ignore: deprecated_member_use
                  groupValue: _statusFilter,
                  // ignore: deprecated_member_use
                  onChanged: (String? value) {
                    setState(() {
                      _statusFilter = value!;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: const Text('Approved'),
                leading: Radio<String>(
                  value: 'approved',
                  // ignore: deprecated_member_use
                  groupValue: _statusFilter,
                  // ignore: deprecated_member_use
                  onChanged: (String? value) {
                    setState(() {
                      _statusFilter = value!;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: const Text('Rejected'),
                leading: Radio<String>(
                  value: 'rejected',
                  // ignore: deprecated_member_use
                  groupValue: _statusFilter,
                  // ignore: deprecated_member_use
                  onChanged: (String? value) {
                    setState(() {
                      _statusFilter = value!;
                    });
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  late Stream<List<VisitorRequest>> _logsStream;

  @override
  void initState() {
    super.initState();
    _logsStream = ref.read(firestoreServiceProvider).getTodayVisitorLogs();
  }

  Future<void> _refreshLogs() async {
    setState(() {
      _logsStream = ref.read(firestoreServiceProvider).getTodayVisitorLogs();
    });
    // Wait a bit to show refresh spinner
    await Future.delayed(const Duration(milliseconds: 500)); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // backgroundColor: Use default dark background
      body: RefreshIndicator(
        onRefresh: _refreshLogs,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text('Today\'s Log'),
              // Default dark theme
              elevation: 0,
              floating: true,
              pinned: true,
              actions: [
                IconButton(
                  onPressed: () => _showFilterDialog(),
                  icon: Icon(
                    Icons.filter_list,
                    color: _statusFilter != 'all' ? Colors.indigoAccent : Colors.white70,
                  ),
                ),
              ],
            ),
            
            // 🔍 Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by visitor name...',
                    prefixIcon: Icon(Icons.search),
                    filled: true,
                    // Default theme fill color
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                ),
              ),
            ),
            
            StreamBuilder<List<VisitorRequest>>(
              stream: _logsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // 🌟 Shimmer Loading
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey[800]!,
                          highlightColor: Colors.grey[700]!,
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      childCount: 5,
                    ),
                  );
                }
                
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red))),
                  );
                }

                var logs = snapshot.data ?? [];

                // 🔍 Apply Filters
                logs = logs.where((log) {
                  final matchesSearch = log.visitorName.toLowerCase().contains(_searchQuery) || 
                                       log.flatNumber.toLowerCase().contains(_searchQuery);
                  final matchesStatus = _statusFilter == 'all' || log.status == _statusFilter;
                  
                  // 🕒 Date Filter: TODAY ONLY
                  final now = DateTime.now();
                  final startOfDay = DateTime(now.year, now.month, now.day);
                  final isToday = log.createdAt.isAfter(startOfDay); 
                  
                  return matchesSearch && matchesStatus && isToday;
                }).toList();

                if (logs.isEmpty) {
                  return SliverFillRemaining(
                    child: EmptyState(
                      icon: _searchQuery.isEmpty && _statusFilter == 'all' ? Icons.people_outline : Icons.search_off,
                      title: _searchQuery.isEmpty && _statusFilter == 'all' ? 'No Visitors Today' : 'No Results Found',
                      message: _searchQuery.isEmpty && _statusFilter == 'all' ? 'Visitor logs will appear here' : 'Try adjusting your filters',
                    ),
                  );
                }

                return AnimationLimiter(
                  child: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final log = logs[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 8.0, left: 16, right: 16),
                                 child: VisitorCard(
                                  request: log,
                                  showActions: true,
                                  // Guards can ONLY mark exit, not approve/deny
                                  onExit: () async {

                                      // 1. Optimistic Update (Immediate UI Feedback)
                                      setState(() {
                                        log.status = 'exited';
                                      });
                                      
                                      // 2. Perform Async Operation
                                      await ref.read(firestoreServiceProvider).updateVisitorStatus(log.id, 'exited');
                                      
                                      // 3. Refresh Stream (Keep in Sync)
                                      ref.invalidate(firestoreServiceProvider);
                                  },

                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: logs.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
