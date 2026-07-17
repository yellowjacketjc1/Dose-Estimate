import 'package:http/http.dart' as http;

Future<String> loadQaFile(String fileName) async {
  // Only allow simple file names — no path separators or traversal.
  if (!RegExp(r'^[A-Za-z0-9._\- ]+$').hasMatch(fileName) ||
      fileName.contains('..')) {
    throw ArgumentError('Invalid QA file name: $fileName');
  }
  final uri = Uri.base.resolve('/qa/${Uri.encodeComponent(fileName)}');
  final response = await http.get(uri);
  if (response.statusCode != 200) {
    throw Exception('HTTP ${response.statusCode} fetching $uri');
  }
  return response.body;
}
