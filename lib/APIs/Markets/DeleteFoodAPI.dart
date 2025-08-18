import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> deleteFood(int foodId) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  final uri = Uri.parse('http://10.0.2.2:4000/api/food/delete/$foodId');
  final response = await http.delete(
    uri,
    headers: token != null ? {'Authorization': 'Bearer $token'} : {},
  );

  if (response.statusCode == 200) {
    return true;
  } else {
    print('❌ Failed to delete food: ${response.statusCode}, ${response.body}');
    return false;
  }
}