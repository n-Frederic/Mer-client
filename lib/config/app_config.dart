class AppConfig {

  static const String _baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:8080/api',
    // defaultValue:'http://10.61.237.155:8080/api'
    // defaultValue: 'http://127.0.0.1:8080/api'
  );
  //创建一个 getter，方便其他 service 调用
  static String get baseUrl {
    // 你可以在这里做一些检查，比如 URL 是否为空
    if (_baseUrl.isEmpty) {
      throw Exception('BASE_URL is not set in --dart-define');
    }
    return _baseUrl;
  }
}