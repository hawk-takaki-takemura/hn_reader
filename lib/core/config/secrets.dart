class Secrets {
  Secrets._();

  // Claude API Key
  // dart-define で注入: --dart-define=CLAUDE_API_KEY=xxx
  static const String claudeApiKey =
      String.fromEnvironment('CLAUDE_API_KEY', defaultValue: '');
}
