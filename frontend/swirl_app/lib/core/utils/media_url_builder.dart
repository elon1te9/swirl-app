import '../network/api_client.dart';

String? buildMediaUrl(String? path) {
  if (path == null || path.trim().isEmpty) {
    return null;
  }

  final value = path.trim();
  if (value.startsWith('http://') || value.startsWith('https://')) {
    final normalizedUrl = _normalizeLocalDevelopmentUrl(value);
    if (normalizedUrl != null) {
      return normalizedUrl;
    }

    return value;
  }

  if (value.startsWith('/')) {
    return '${ApiClient.backendOrigin}$value';
  }

  return '${ApiClient.backendOrigin}/$value';
}

String? _normalizeLocalDevelopmentUrl(String value) {
  final uri = Uri.tryParse(value);
  if (uri == null ||
      !uri.hasAbsolutePath ||
      !_isLocalDevelopmentHost(uri.host)) {
    return null;
  }

  final backendOrigin = Uri.tryParse(ApiClient.backendOrigin);
  if (backendOrigin == null ||
      !backendOrigin.hasScheme ||
      backendOrigin.host.isEmpty) {
    return null;
  }

  return backendOrigin
      .replace(
        path: uri.path,
        query: uri.hasQuery ? uri.query : null,
        fragment: uri.hasFragment ? uri.fragment : null,
      )
      .toString();
}

bool _isLocalDevelopmentHost(String host) {
  return host == 'localhost' ||
      host == '127.0.0.1' ||
      host == '::1' ||
      host == '10.0.2.2';
}
