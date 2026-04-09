class AppConfig {
  static const String apiBaseUrl = String.fromEnvironment(
    'APP_API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static const String agentBaseUrl = String.fromEnvironment(
    'APP_AGENT_BASE_URL',
    defaultValue: '',
  );

  static const String agentChatPath = String.fromEnvironment(
    'APP_AGENT_CHAT_PATH',
    defaultValue: '/chat/stream',
  );

  static const String demoPatientId = String.fromEnvironment(
    'APP_DEMO_PATIENT_ID',
    defaultValue: 'PT0001',
  );

  static const bool enableFirebase = bool.fromEnvironment(
    'APP_ENABLE_FIREBASE',
    defaultValue: false,
  );

  static const String firestoreDatabaseId = String.fromEnvironment(
    'APP_FIRESTORE_DATABASE_ID',
    defaultValue: '(default)',
  );
}
