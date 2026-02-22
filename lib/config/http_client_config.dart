import 'dart:io';

class HttpClientConfig {
  static void init(String? proxyHost, int? proxyPort) {
    if (proxyHost != null &&
        proxyHost.isNotEmpty &&
        proxyPort != null &&
        proxyPort != 0) {
      HttpOverrides.global = _ProxyHttpOverrides(proxyHost, proxyPort);
    }
  }
}

class _ProxyHttpOverrides extends HttpOverrides {
  final String? _host;
  final int? _port;

  _ProxyHttpOverrides(this._host, this._port);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);

    if (_host != null && _port != null) {
      client.findProxy = (uri) {
        return 'PROXY $_host:$_port;';
      };
      client.badCertificateCallback = (cert, host, port) => true;
    }

    return client;
  }
}
