import 'dart:html' as html;

Future<String> loadQaFile(String fileName) {
  return html.HttpRequest.getString('/qa/$fileName');
}
