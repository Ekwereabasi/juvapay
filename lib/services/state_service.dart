// state_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/location_models.dart';

class StateService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Fetch all states
  Future<List<StateModel>> getStates() async {
    try {
      final response = await _supabase.from('states').select().order('name');

      return (response as List).map((e) => StateModel.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching states: $e');
      return [];
    }
  }

  // Fetch LGAs by state ID
  Future<List<LgaModel>> getLgasByState(int stateId) async {
    try {
      final response = await _supabase
          .from('lgas')
          .select()
          .eq('state_id', stateId)
          .order('name');

      return (response as List).map((e) => LgaModel.fromJson(e)).toList();
    } catch (e) {
      print('Error fetching LGAs: $e');
      return [];
    }
  }

  // Get state by ID
  Future<StateModel?> getStateById(int id) async {
    try {
      final response =
          await _supabase.from('states').select().eq('id', id).maybeSingle();

      if (response != null) {
        return StateModel.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error fetching state: $e');
      return null;
    }
  }

  // Get LGA by ID
  Future<LgaModel?> getLgaById(int id) async {
    try {
      final response =
          await _supabase.from('lgas').select().eq('id', id).maybeSingle();

      if (response != null) {
        return LgaModel.fromJson(response);
      }
      return null;
    } catch (e) {
      print('Error fetching LGA: $e');
      return null;
    }
  }
}
