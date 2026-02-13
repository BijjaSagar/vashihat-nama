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
    // Production URL (Vercel) - Latest Deployment with ALL Fixes (Nominee, File Upload)
    return 'https://backend-mu75xq7uj-sagar-bijjas-projects.vercel.app/api';
    
    // Uncomment for local development
    // if (Platform.isAndroid) {
    //   return 'http://10.0.2.2:3000/api';
    // } else {
    //   return 'http://localhost:3000/api'; 
    // }
  }
  final Dio _dio = Dio();

  // --- 1. User Registration ---
  Future<Map<String, dynamic>> registerUser(String mobileNumber, String publicKey, String encryptedPrivateKey, String name, String email) async {
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
    
    return jsonDecode(response.body);
  }

  // --- OTP Methods ---

  Future<Map<String, dynamic>> sendOtp(String mobile, String purpose) async {
    final url = Uri.parse('$baseUrl/send_otp');
    print('ApiService: Sending OTP to $url');
    print('ApiService: Body: {"mobile": "$mobile", "purpose": "$purpose"}');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'mobile': mobile,
        'purpose': purpose,
      }),
    );

    print('ApiService: Response Code: ${response.statusCode}');
    print('ApiService: Response Body: ${response.body}');

    if (response.statusCode != 200) {
       throw Exception('Server Error: ${response.statusCode} - ${response.body}');
    }

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
        'relationship': relation,
        'email': contact,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add nominee');
    }
  }

  // ============================================
  // VAULT ITEMS API METHODS
  // ============================================

  // 1. Create Vault Item
  Future<Map<String, dynamic>> createVaultItem({
    required int userId,
    required int folderId,
    required String itemType, // 'note', 'password', 'credit_card', 'file'
    required String title,
    required String encryptedData, // JSON string
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/vault_items'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'folder_id': folderId,
        'item_type': itemType,
        'title': title,
        'encrypted_data': encryptedData,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create vault item: ${response.body}');
    }

    return jsonDecode(response.body);
  }

  // 2. Get Vault Items
  Future<List<dynamic>> getVaultItems({
    required int userId,
    int? folderId,
    String? itemType,
  }) async {
    String url = '$baseUrl/vault_items?user_id=$userId';
    
    if (folderId != null) {
      url += '&folder_id=$folderId';
    }
    
    if (itemType != null) {
      url += '&item_type=$itemType';
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['items'] ?? [];
    } else {
      return [];
    }
  }

  // 3. Get Single Vault Item
  Future<Map<String, dynamic>> getVaultItem({
    required int itemId,
    required int userId,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/vault_items/$itemId?user_id=$userId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['item'];
    } else {
      throw Exception('Failed to load vault item');
    }
  }

  // 4. Update Vault Item
  Future<Map<String, dynamic>> updateVaultItem({
    required int itemId,
    required int userId,
    required String title,
    required String encryptedData,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/vault_items/$itemId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'title': title,
        'encrypted_data': encryptedData,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update vault item: ${response.body}');
    }

    return jsonDecode(response.body);
  }

  // 5. Delete Vault Item
  Future<void> deleteVaultItem({
    required int itemId,
    required int userId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/vault_items/$itemId?user_id=$userId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete vault item');
    }
  }

  // 6. Get Vault Stats
  Future<Map<String, dynamic>> getVaultStats({required int userId}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/vault_items/stats/count?user_id=$userId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['stats'];
    } else {
      return {'note': 0, 'password': 0, 'credit_card': 0, 'file': 0};
    }
  }
  // ============================================
  // SMART ALERT API METHODS
  // ============================================

  // 10. Create Smart Alert
  Future<void> createSmartAlert({
    required int userId,
    int? fileId,
    required String docType,
    String? docNumber,
    DateTime? expiryDate,
    DateTime? renewalDate,
    String? issuingAuthority,
    String? notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/smart_docs'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'file_id': fileId,
        'doc_type': docType,
        'doc_number': docNumber,
        'expiry_date': expiryDate?.toIso8601String(),
        'renewal_date': renewalDate?.toIso8601String(),
        'issuing_authority': issuingAuthority,
        'notes': notes,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to create smart alert: ${response.body}');
    }
  }

  // 11. Get Smart Alerts
  Future<List<dynamic>> getSmartAlerts(int userId, {bool upcomingOnly = false}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/smart_docs?user_id=$userId&upcoming_only=$upcomingOnly'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['alerts'] ?? [];
    } else {
      return [];
    }
  }

  // 12. Delete Smart Alert
  Future<void> deleteSmartAlert(int alertId, int userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/smart_docs/$alertId?user_id=$userId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete alert');
    }
  }
  // ============================================
  // HEARTBEAT API METHODS
  // ============================================

  // 13. Get Heartbeat Status
  Future<Map<String, dynamic>> getHeartbeatStatus(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/heartbeat/status?user_id=$userId'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status'];
    } else {
      throw Exception('Failed to get status');
    }
  }

  // 14. Check In (I'm Safe)
  Future<void> checkIn(int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/heartbeat/checkin'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId, 'method': 'manual'}),
    );
    if (response.statusCode != 200) {
      throw Exception('Check-in failed');
    }
  }

  // 15. Update Heartbeat Settings
  Future<void> updateHeartbeatSettings(int userId, bool active, int frequencyDays) async {
    final response = await http.post(
      Uri.parse('$baseUrl/heartbeat/settings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'active': active,
        'frequency_days': frequencyDays,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update settings');
    }
  }
  // ============================================
  // SECURITY SCORE API METHODS
  // ============================================

  // 16. Get Security Score
  Future<Map<String, dynamic>> getSecurityScore(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/security/score?user_id=$userId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get security score');
    }
  }
}

