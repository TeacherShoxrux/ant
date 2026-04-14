import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  var res = await http.get(Uri.parse('http://localhost:5297/api/fixdb'));
  print('Result: \${res.body}');
}
