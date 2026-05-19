import '../network/api_client.dart';

String? buildMediaUrl(String? path) {
  if (path == null || path.trim().isEmpty) {
    return null;
  }

  final value = path.trim();
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }

  if (value.startsWith('/')) {
    return '${ApiClient.backendOrigin}$value';
  }

  return '${ApiClient.backendOrigin}/$value';
}
