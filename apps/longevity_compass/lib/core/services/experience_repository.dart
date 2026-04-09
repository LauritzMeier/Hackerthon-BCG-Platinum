import '../config/app_config.dart';
import '../models/experience_models.dart';
import 'api_client.dart';

class ExperienceRepository {
  ExperienceRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  Future<List<PatientListItem>> fetchPatients() async {
    final response = await _apiClient.getMap('/patients?limit=50');
    final items = response['items'];
    if (items is! List) {
      return <PatientListItem>[];
    }

    return items
        .whereType<Map<String, dynamic>>()
        .map(PatientListItem.fromJson)
        .toList(growable: false);
  }

  Future<ExperienceSnapshot> fetchExperience(String patientId) async {
    final response = await _apiClient.getMap('/patients/$patientId/experience');
    return ExperienceSnapshot.fromJson(response);
  }

  Future<CoachReply> sendCoachMessage(String patientId, String message) async {
    final response = await _apiClient.postJson(
      '/patients/$patientId/coach/reply',
      {'message': message},
    );
    return CoachReply.fromJson(response);
  }

  String get defaultPatientId => AppConfig.demoPatientId;

  void dispose() {
    _apiClient.dispose();
  }
}
