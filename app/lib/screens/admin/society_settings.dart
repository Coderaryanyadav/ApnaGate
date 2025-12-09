import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/society_config_service.dart';
import '../../utils/haptic_helper.dart';

class SocietySettingsScreen extends ConsumerStatefulWidget {
  const SocietySettingsScreen({super.key});

  @override
  ConsumerState<SocietySettingsScreen> createState() => _SocietySettingsScreenState();
}

class _SocietySettingsScreenState extends ConsumerState<SocietySettingsScreen> {
  final TextEditingController _wingController = TextEditingController();
  final TextEditingController _floorsController = TextEditingController();
  final TextEditingController _flatsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final config = ref.read(societyConfigProvider);
    _floorsController.text = config.totalFloors.toString();
    _flatsController.text = config.flatsPerFloor.toString();
  }

  void _addWing() {
    if (_wingController.text.isNotEmpty) {
      final currentWings = List<String>.from(ref.read(societyConfigProvider).wings);
      final newWing = _wingController.text.toUpperCase().trim();
      
      if (!currentWings.contains(newWing)) {
        currentWings.add(newWing);
        currentWings.sort();
        ref.read(societyConfigProvider.notifier).updateConfig(wings: currentWings);
        _wingController.clear();
        HapticHelper.mediumImpact();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wing already exists')));
      }
    }
  }

  void _removeWing(String wing) {
    final currentWings = List<String>.from(ref.read(societyConfigProvider).wings);
    currentWings.remove(wing);
    ref.read(societyConfigProvider.notifier).updateConfig(wings: currentWings);
    HapticHelper.mediumImpact();
  }

  void _saveStructure() {
    final floors = int.tryParse(_floorsController.text);
    final flats = int.tryParse(_flatsController.text);

    if (floors != null && flats != null) {
      ref.read(societyConfigProvider.notifier).updateConfig(
        floors: floors,
        flatsPerFloor: flats,
      );
      HapticHelper.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✅ Structure Updated!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(societyConfigProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Society Settings'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🏢 building Structure
            _buildSectionHeader('🏢 Building Structure'),
            Card(
              color: Theme.of(context).cardTheme.color,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _floorsController,
                            decoration: const InputDecoration(labelText: 'Total Floors', prefixIcon: Icon(Icons.apartment)),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _flatsController,
                            decoration: const InputDecoration(labelText: 'Flats per Floor', prefixIcon: Icon(Icons.grid_view)),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveStructure,
                        icon: const Icon(Icons.save),
                        label: const Text('Save Structure'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            
            // 🏙️ Wings Configuration
            _buildSectionHeader('🏙️ Manage Wings'),
            Card(
              color: Theme.of(context).cardTheme.color,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _wingController,
                            decoration: const InputDecoration(
                              labelText: 'Add New Wing (e.g., C)', 
                              hintText: 'Enter Wing Name',
                              prefixIcon: Icon(Icons.add_location_alt)
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: _addWing, 
                          icon: const Icon(Icons.add_circle, size: 32, color: Colors.indigoAccent),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: config.wings.map((wing) {
                        return Chip(
                          label: Text('Wing $wing', style: const TextStyle(fontWeight: FontWeight.bold)),
                          backgroundColor: Colors.indigo.withValues(alpha: 0.2),
                          deleteIcon: const Icon(Icons.cancel, size: 18),
                          onDeleted: () => _removeWing(wing),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white70),
      ),
    );
  }
}
