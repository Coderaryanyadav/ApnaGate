import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/service_provider.dart';
import '../../services/firestore_service.dart';

class ServiceDirectoryScreen extends ConsumerWidget {
  const ServiceDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service Directory')),
      body: FutureBuilder<List<ServiceProvider>>(
        future: ref.read(firestoreServiceProvider).getServiceProviders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snapshot.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text('No service providers listed yet.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final sp = list[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.handyman, color: Color(0xFF00E5FF)),
                  title: Text(sp.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(sp.category),
                  trailing: IconButton(
                    icon: const Icon(Icons.phone, color: Colors.greenAccent),
                    onPressed: () {
                      final uri = Uri.parse('tel:${sp.phone}');
                      launchUrl(uri);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
