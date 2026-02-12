import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart'; 
import 'dart:io';

class ApiService {
  // Replace with your actual backend URL
  // For Android Emulator: 'http://10.0.2.2:3000/api'
  // For iOS Simulator: 'http://localhost:3000/api'
  // For Physical Device: Use your machine's local IP (e.g., http://192.168.1.5:3000/api)
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api';
    } else {
      return 'http://localhost:3000/api'; // For iOS Simulator and macOS
    }
  }
  final Dio _dio = Dio();

  // --- 1. User Registration ---
  Future<void> registerUser(String mobileNumber, String publicKey, String encryptedPrivateKey, String name, String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/users/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile_number': mobileNumber,
        'public_key': publicKey,
        'encrypted_private_key': encryptedPrivateKey,
        'name': name,
        'email': email,
      }),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to register user: ${response.body}');
    }
  }

  // --- OTP Methods ---

  Future<Map<String, dynamic>> sendOtp(String mobile, String purpose) async {
    final response = await http.post(
      Uri.parse('$baseUrl/send_otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile': mobile,
        'purpose': purpose,
      }),
    );

    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> verifyOtp(String mobile, String otp, String purpose) async {
    final response = await http.post(
      Uri.parse('$baseUrl/verify_otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile': mobile,
        'otp': otp,
        'purpose': purpose,
      }),
    );

    return jsonDecode(response.body);
  }

  // --- 2. Get User Profile ---
  Future<Map<String, dynamic>> getUserProfile(String firebaseUid) async {
    final response = await http.get(Uri.parse('$baseUrl/users/$firebaseUid'));
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user profile');
    }
  }

  // --- 3. Update User Profile ---
  Future<void> updateUserProfile(String firebaseUid, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/users/$firebaseUid'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update profile: ${response.body}');
    }
  }

  // --- 4. Get Folders ---
  Future<List<dynamic>> getFolders(String firebaseUid) async {
    final response = await http.get(Uri.parse('$baseUrl/folders?user_id=$firebaseUid'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return []; // Return empty list on failure or no folders
    }
  }

  // --- 5. Create Folder ---
  Future<void> createFolder(String firebaseUid, String name, String icon) async {
    final response = await http.post(
      Uri.parse('$baseUrl/folders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': firebaseUid,
        'name': name,
        'icon': icon,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create folder');
    }
  }

  // --- 6. Get Files ---
  Future<List<dynamic>> getFiles(int folderId) async {
    final response = await http.get(Uri.parse('$baseUrl/files?folder_id=$folderId'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return [];
    }
  }

  // --- 7. Upload File (Dio) ---
  Future<void> uploadFile(int folderId, File file) async {
    String fileName = file.path.split('/').last;
    FormData formData = FormData.fromMap({
      "folder_id": folderId,
      "file": await MultipartFile.fromFile(file.path, filename: fileName),
    });

    try {
      await _dio.post("$baseUrl/upload", data: formData);
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  // --- 8. Get Nominees ---
  Future<List<dynamic>> getNominees(String firebaseUid) async {
    final response = await http.get(Uri.parse('$baseUrl/nominees?user_id=$firebaseUid'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      return [];
    }
  }

  // --- 9. Add Nominee ---
  Future<void> addNominee(String firebaseUid, String name, String relation, String contact) async {
    final response = await http.post(
      Uri.parse('$baseUrl/nominees'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': firebaseUid,
        'name': name,
        'relation': relation,
        'contact': contact,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add nominee');
    }
  }
}

