import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/visitor_request.dart';
import '../../services/firestore_service.dart';
import '../../widgets/visitor_card.dart';

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
              RadioListTile<String>(
                title: const Text('All'),
                value: 'all',
                groupValue: _statusFilter,
                onChanged: (String? value) {
                  setState(() {
                    _statusFilter = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('Pending'),
                value: 'pending',
                groupValue: _statusFilter,
                onChanged: (String? value) {
                  setState(() {
                    _statusFilter = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('Approved'),
                value: 'approved',
                groupValue: _statusFilter,
                onChanged: (String? value) {
                  setState(() {
                    _statusFilter = value!;
                  });
                  Navigator.pop(context);
                },
              ),
              RadioListTile<String>(
                title: const Text('Rejected'),
                value: 'rejected',
                groupValue: _statusFilter,
                onChanged: (String? value) {
                  setState(() {
                    _statusFilter = value!;
                  });
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final logsStream = ref.watch(firestoreServiceProvider).getTodayVisitorLogs();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: RefreshIndicator(
        onRefresh: () async {
          // Refresh stream by invalidating provider
          ref.invalidate(firestoreServiceProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text('Today\'s Log', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              elevation: 0,
              floating: true,
              pinned: true,
              iconTheme: const IconThemeData(color: Colors.black),
              actions: [
                IconButton(
                  onPressed: () => _showFilterDialog(),
                  icon: Icon(
                    Icons.filter_list,
                    color: _statusFilter != 'all' ? Colors.indigo : Colors.grey,
                  ),
                ),
              ],
            ),
            
            // 🔍 Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by visitor name...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                ),
              ),
            ),
            
            StreamBuilder<List<VisitorRequest>>(
              stream: logsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // 🌟 Shimmer Loading
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white,
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
                    child: Center(child: Text('Error: ${snapshot.error}')),
                  );
                }

                var logs = snapshot.data ?? [];

                // 🔍 Apply Filters
                logs = logs.where((log) {
                  final matchesSearch = log.visitorName.toLowerCase().contains(_searchQuery);
                  final matchesStatus = _statusFilter == 'all' || log.status == _statusFilter;
                  return matchesSearch && matchesStatus;
                }).toList();

                if (logs.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 60, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty && _statusFilter == 'all' ? 'No visitors yet today' : 'No results found',
                            style: TextStyle(color: Colors.grey[500], fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  );
                }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final log = logs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: VisitorCard(request: log),
                    );
                  },
                  childCount: logs.length,
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
