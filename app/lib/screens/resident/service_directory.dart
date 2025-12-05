import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/extras.dart';
import '../../services/firestore_service.dart';

class ServiceDirectoryScreen extends ConsumerWidget {
  const ServiceDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service Directory')),
      body: StreamBuilder<List<ServiceProvider>>(
        stream: ref.watch(firestoreServiceProvider).getServiceProviders(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final providers = snapshot.data!;

          if (providers.isEmpty) {
            return const Center(child: Text('No providers listed yet'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: providers.length,
            itemBuilder: (context, index) {
              final provider = providers[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.indigo.shade50,
                    child: Icon(_getCategoryIcon(provider.category), color: Colors.indigo),
                  ),
                  title: Row(
                    children: [
                      Text(provider.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      if (provider.isVerified) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.verified, size: 16, color: Colors.blue),
                      ],
                    ],
                  ),
                  subtitle: Text(provider.category, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  trailing: IconButton(
                    onPressed: () => launchUrl(Uri.parse('tel:${provider.phone}')),
                    icon: const CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Icon(Icons.call, color: Colors.white),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final c = category.toLowerCase();
    if (c.contains('plumb')) return Icons.plumbing;
    if (c.contains('electric')) return Icons.electric_bolt;
    if (c.contains('clean')) return Icons.cleaning_services;
    if (c.contains('carpenter')) return Icons.carpenter;
    return Icons.handyman;
  }
}
