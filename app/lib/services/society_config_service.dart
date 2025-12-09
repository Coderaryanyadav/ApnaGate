import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

final societyConfigProvider = StateNotifierProvider<SocietyConfigNotifier, SocietyConfig>((ref) {
  return SocietyConfigNotifier();
});

class SocietyConfig {
  final List<String> wings;
  final int totalFloors;
  final int flatsPerFloor;

  SocietyConfig({
    required this.wings,
    required this.totalFloors,
    required this.flatsPerFloor,
  });

  // Default Fallback
  factory SocietyConfig.defaults() {
    return SocietyConfig(
      wings: ['A', 'B'],
      totalFloors: 12,
      flatsPerFloor: 4,
    );
  }
}

class SocietyConfigNotifier extends StateNotifier<SocietyConfig> {
  SocietyConfigNotifier() : super(SocietyConfig.defaults()) {
    loadConfig();
  }

  Future<void> loadConfig() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase.from('society_config').select(); // List of rows
      
      final data = response as List<dynamic>;
      
      if (data.isEmpty) return; // Keep defaults

      List<String> wings = ['A', 'B'];
      int floors = 12;
      int flats = 4;

      for (var row in data) {
        if (row['key'] == 'wings') wings = List<String>.from(row['value']);
        if (row['key'] == 'floors') floors = row['value'] as int;
        if (row['key'] == 'flats_per_floor') flats = row['value'] as int;
      }

      state = SocietyConfig(
        wings: wings,
        totalFloors: floors,
        flatsPerFloor: flats,
      );
    } catch (e) {
      // Fallback or Table doesn't exist yet
      debugPrint('Config Load Error: $e');
    }
  }

  Future<void> updateConfig({List<String>? wings, int? floors, int? flatsPerFloor}) async {
    final supabase = Supabase.instance.client;
    
    // Optimistic Update
    state = SocietyConfig(
      wings: wings ?? state.wings,
      totalFloors: floors ?? state.totalFloors,
      flatsPerFloor: flatsPerFloor ?? state.flatsPerFloor,
    );

    try {
      if (wings != null) {
        await supabase.from('society_config').upsert({'key': 'wings', 'value': wings});
      }
      if (floors != null) {
        await supabase.from('society_config').upsert({'key': 'floors', 'value': floors});
      }
      if (flatsPerFloor != null) {
        await supabase.from('society_config').upsert({'key': 'flats_per_floor', 'value': flatsPerFloor});
      }
    } catch (e) {
      debugPrint('Config Update Error: $e');
      await loadConfig(); // Revert on failure
    }
  }
}
