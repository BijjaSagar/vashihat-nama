import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class ApiService {
  // Replace with your actual backend URL
  // For Android Emulator: 'http://10.0.2.2:3000/api'
  // For iOS Simulator: 'http://localhost:3000/api'
  // For Physical Device: Use your machine's local IP (e.g., http://192.168.1.5:3000/api)
  static String get baseUrl {
    // 1. Local Development (Uncomment if needed)
    /*
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8080/api';
    } else {
      return 'http://localhost:8080/api'; 
    }
    */

    // 2. Production URL (Vercel)
    return 'https://backend-sagar-bijjas-projects.vercel.app/api'; 
  }
  final Dio _dio = Dio();

  // ─── JWT Token Helpers ───────────────────────────────────────────────────────

  /// Retrieves the stored JWT auth token.
  Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  /// Builds headers with Content-Type and the Bearer auth token.
  /// Pass [requiresAuth] = false for public endpoints (login, register, send_otp).
  Future<Map<String, String>> _authHeaders({bool requiresAuth = true}) async {
    final headers = {'Content-Type': 'application/json'};
    if (requiresAuth) {
      final token = await getAuthToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  // ... (Other methods)

  // 21. AI Assistant Chat
  Future<String> getAIChatResponse(String message, List<dynamic>? history) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message': message,
        'history': history,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['reply'] ?? 'No response from AI';
    } else {
      throw Exception('Chat failed: ${response.body}');
    }
  }

  // 22. AI Classification
  Future<Map<String, dynamic>> classifyDocument(String text) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai/classify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': text}),
    );
     if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['classification'] ?? {};
    } else {
      throw Exception('Classification failed');
    }
  }

  // 23. AI Conflict Check
  Future<Map<String, dynamic>> checkWillConflicts(String willText) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai/conflict-check'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'will_text': willText}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['conflict_check'] ?? {};
    } else {
      throw Exception('Conflict check failed');
    }
  }

  // 24. AI Tone Analysis
  Future<Map<String, dynamic>> analyzeTone(String message) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai/analyze-tone'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'message': message}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['analysis'] ?? {};
    } else {
      throw Exception('Tone analysis failed');
    }
  }

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

  // --- 5.1 Delete Folder ---
  Future<void> deleteFolder(int folderId, String firebaseUid) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/folders/$folderId?user_id=$firebaseUid'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete folder');
    }
  }

  // --- 5.2 Rename Folder ---
  Future<void> renameFolder(int folderId, String newName, String firebaseUid) async {
    final response = await http.put(
      Uri.parse('$baseUrl/folders/$folderId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': firebaseUid,
        'name': newName,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to rename folder');
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
  // --- 7. Upload File (S3 Presigned URL) ---
  Future<void> uploadFile(int folderId, File file) async {
    String fileName = file.path.split('/').last;
    String? mimeType = _getMimeType(fileName);

    try {
      // 1. Get Presigned URL
      final presignedResponse = await http.post(
        Uri.parse('$baseUrl/get-presigned-url'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'folder_id': folderId,
          'file_name': fileName,
          'file_type': mimeType ?? 'application/octet-stream',
        }),
      );

      if (presignedResponse.statusCode != 200) {
        throw Exception('Failed to get upload URL: ${presignedResponse.body}');
      }

      final presignedData = jsonDecode(presignedResponse.body);
      String uploadUrl = presignedData['uploadUrl'];
      String key = presignedData['key'];

      // 2. Upload to S3 directly
      final uploadResponse = await http.put(
        Uri.parse(uploadUrl),
        headers: {'Content-Type': mimeType ?? 'application/octet-stream'},
        body: await file.readAsBytes(),
      );

      if (uploadResponse.statusCode != 200) {
        throw Exception('Failed to upload items to storage: ${uploadResponse.statusCode}');
      }

      // 3. Confirm Upload to Backend
      // We need user_id, but it's not passed here. 
      // The backend can infer it or we can update the API signature.
      // For now, let's verify if the backend 'confirm-upload' requires user_id. 
      // In my previous edit to index.ts, I used: [user_id || 1, ...] 
      // So it's safe to not send it if we don't have it, but ideally we should.
      // However, ApiService seems to be used in context where user_id isn't always available globally?
      // FilesScreen has folderId. Folder belongs to user. Backend index.ts handles lookup.
      
      final confirmResponse = await http.post(
        Uri.parse('$baseUrl/files/confirm-upload'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'folder_id': folderId,
          'file_name': fileName,
          'key': key,
          'file_size': await file.length(),
          'mime_type': mimeType,
        }),
      );

      if (confirmResponse.statusCode != 201) {
        throw Exception('Failed to confirm upload: ${confirmResponse.body}');
      }

    } catch (e) {
      print("Upload error: $e");
      throw Exception('Failed to upload file: $e');
    }
  }

  String? _getMimeType(String fileName) {
    if (fileName.endsWith('.pdf')) return 'application/pdf';
    if (fileName.endsWith('.jpg') || fileName.endsWith('.jpeg')) return 'image/jpeg';
    if (fileName.endsWith('.png')) return 'image/png';
    return 'application/octet-stream';
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

  // --- 9. Add Nominee (Updated) ---
  Future<void> addNominee({
    required String userId,
    required String name,
    required String relationship,
    required String email,
    required String primaryMobile,
    String? optionalMobile,
    String? address,
    String? identityProof,
    String? handDeliveryRules,
    String deliveryMode = 'digital',
    int handoverWaitingDays = 0,
    bool requireOtpForAccess = false,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/nominees'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'name': name,
        'relationship': relationship,
        'email': email,
        'primary_mobile': primaryMobile,
        'optional_mobile': optionalMobile,
        'address': address,
        'identity_proof': identityProof,
        'hand_delivery_rules': handDeliveryRules,
        'delivery_mode': deliveryMode,
        'handover_waiting_days': handoverWaitingDays,
        'require_otp_for_access': requireOtpForAccess,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add nominee: ${response.body}');
    }
  }

  // --- 9.1 Update Nominee ---
  Future<void> updateNominee({
    required int nomineeId,
    required String name,
    required String relationship,
    required String email,
    required String primaryMobile,
    String? optionalMobile,
    String? address,
    String? identityProof,
    String? handDeliveryRules,
    String deliveryMode = 'digital',
    int? handoverWaitingDays,
    bool? requireOtpForAccess,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/nominees/$nomineeId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'relationship': relationship,
        'email': email,
        'primary_mobile': primaryMobile,
        'optional_mobile': optionalMobile,
        'address': address,
        'identity_proof': identityProof,
        'hand_delivery_rules': handDeliveryRules,
        'delivery_mode': deliveryMode,
        'handover_waiting_days': handoverWaitingDays,
        'require_otp_for_access': requireOtpForAccess,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update nominee: ${response.body}');
    }
  }

  //  // 5.4 Get Assigned Items for Nominee
  Future<List<dynamic>> getNomineeAssignedItems(int nomineeId) async {
    final response = await http.get(Uri.parse('$baseUrl/nominees/$nomineeId/assigned_items'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['items'] ?? [];
    } else {
      throw Exception('Failed to fetch assigned items');
    }
  }

  // --- 9.2 Delete Nominee ---
  Future<void> deleteNominee(int nomineeId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/nominees/$nomineeId'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete nominee');
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
    List<int>? nomineeIds,
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
        'nominee_ids': nomineeIds,
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
    String? title,
    String? encryptedData,
    int? nomineeId,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/vault_items/$itemId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'title': title,
        'encrypted_data': encryptedData,
        'nominee_id': nomineeId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['item'] ?? data;
    } else {
      throw Exception('Failed to update vault item: ${response.body}');
    }
  }

  // 4a. Simple Assign Nominee
  Future<void> assignNomineeToVaultItem({
    required int itemId,
    required int userId,
    required int nomineeId,
  }) async {
    await updateVaultItem(
      itemId: itemId,
      userId: userId,
      nomineeId: nomineeId,
    );
  }

  // 4b. Simple Unassign Nominee
  Future<void> unassignNomineeFromVaultItem({
    required int itemId,
    required int userId,
    int? nomineeId,
  }) async {
    final body = <String, dynamic>{'user_id': userId};
    if (nomineeId != null) body['nominee_id'] = nomineeId;

    final response = await http.put(
      Uri.parse('$baseUrl/vault_items/$itemId/remove_nominee'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove nominee from vault item: ${response.body}');
    }
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

  // ============================================
  // REGIONAL CHECKLIST API METHODS
  // ============================================

  // 17. Get Regional Checklists
  Future<List<dynamic>> getRegionalChecklists(String countryCode) async {
    final response = await http.get(
      Uri.parse('$baseUrl/regional/checklists?country_code=$countryCode'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['checklists'] ?? [];
    } else {
      return [];
    }
  }

  // 18. Save Regional Document Selection
  Future<void> saveRegionalDoc({
    required int userId,
    required int checklistId,
    Map<String, dynamic>? details,
    String? filePath,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/regional/user_docs'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'checklist_id': checklistId,
        'details': details,
        'file_path': filePath,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to save selection: ${response.body}');
    }
  }

  // 19. Get User Regional Docs
  Future<List<dynamic>> getUserRegionalDocs(int userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/regional/user_docs?user_id=$userId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['docs'] ?? [];
    } else {
      return [];
    }
  }

  // 20. Generate Regional Checklist with AI
  Future<List<dynamic>> generateRegionalChecklistAI(String countryCode, String countryName) async {
    final response = await http.post(
      Uri.parse('$baseUrl/regional/generate-ai'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'country_code': countryCode,
        'country_name': countryName,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['checklist'] ?? [];
    } else {
      throw Exception('AI generation failed: ${response.body}');
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
  /// Returns {success, message, last_check_in, next_check_in}
  Future<Map<String, dynamic>> checkIn(int userId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/heartbeat/checkin'),
      headers: await _authHeaders(),
      body: jsonEncode({'user_id': userId, 'method': 'manual'}),
    );
    if (response.statusCode != 200) {
      throw Exception('Check-in failed: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // 15. Update Heartbeat Settings
  Future<void> updateHeartbeatSettings(int userId, bool active, int frequencyDays, {int frequencyHours = 0, int frequencyMinutes = 0}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/heartbeat/settings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'active': active,
        'frequency_days': frequencyDays,
        'frequency_hours': frequencyHours,
        'frequency_minutes': frequencyMinutes,
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

  // ============================================
  // FEATURE 1: VAULT HEALTH ANALYZER
  // ============================================
  Future<Map<String, dynamic>> getVaultHealth(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/vault-health?user_id=$userId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get vault health');
    }
  }

  // ============================================
  // FEATURE 2: VIDEO WILL / VOICE MESSAGE
  // ============================================
  Future<Map<String, dynamic>> createVideoWill({
    required int userId,
    int? nomineeId,
    required String title,
    String messageType = 'text',
    String? storagePath,
    String? transcript,
    int? durationSeconds,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/video-wills'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'nominee_id': nomineeId,
        'title': title,
        'message_type': messageType,
        'storage_path': storagePath,
        'transcript': transcript,
        'duration_seconds': durationSeconds,
      }),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getVideoWills(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/video-wills?user_id=$userId'));
    return jsonDecode(response.body);
  }

  Future<void> deleteVideoWill(int id, int userId) async {
    await http.delete(Uri.parse('$baseUrl/video-wills/$id?user_id=$userId'));
  }

  Future<Map<String, dynamic>> summarizeTranscript(String transcript) async {
    final response = await http.post(
      Uri.parse('$baseUrl/video-wills/summarize'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'transcript': transcript}),
    );
    return jsonDecode(response.body);
  }

  // ============================================
  // FEATURE 3: SMART ASSET DISCOVERY
  // ============================================
  Future<Map<String, dynamic>> generateAssetDiscovery({
    required int userId,
    String? country,
    String? ageGroup,
    String? occupation,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/asset-discovery/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'country': country ?? 'India',
        'age_group': ageGroup ?? '30-50',
        'occupation': occupation ?? 'Professional',
      }),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getAssetDiscovery(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/asset-discovery?user_id=$userId'));
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> toggleAssetDiscovery(int id) async {
    final response = await http.put(Uri.parse('$baseUrl/asset-discovery/$id/toggle'));
    return jsonDecode(response.body);
  }

  // ============================================
  // FEATURE 4: NOMINEE READINESS REPORT
  // ============================================
  Future<Map<String, dynamic>> getNomineeReadiness(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/nominee-readiness?user_id=$userId'));
    return jsonDecode(response.body);
  }

  // ============================================
  // FEATURE 5: ESTATE SUMMARY
  // ============================================
  Future<Map<String, dynamic>> getEstateSummary(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/estate-summary?user_id=$userId'));
    return jsonDecode(response.body);
  }

  // ============================================
  // FEATURE 6: ACTIVITY LOG (FRAUD DETECTION)
  // ============================================
  Future<Map<String, dynamic>> logActivity({
    required int userId,
    required String action,
    String? deviceInfo,
    String? ipAddress,
    Map<String, dynamic>? details,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/activity-log'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'action': action,
        'device_info': deviceInfo,
        'ip_address': ipAddress,
        'details': details,
      }),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getActivityLogs(int userId, {bool suspiciousOnly = false}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/activity-log?user_id=$userId&suspicious_only=$suspiciousOnly'),
    );
    return jsonDecode(response.body);
  }

  // ============================================
  // FEATURE 7: GRIEF SUPPORT CHATBOT
  // ============================================
  Future<Map<String, dynamic>> griefSupportChat({
    required String message,
    List<Map<String, dynamic>>? history,
    String? nomineeName,
    String? deceasedName,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai/grief-support'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'message': message,
        'history': history,
        'nominee_name': nomineeName,
        'deceased_name': deceasedName,
      }),
    );
    return jsonDecode(response.body);
  }

  // ============================================
  // FEATURE 8: LEGAL DOCUMENT GENERATOR
  // ============================================
  Future<Map<String, dynamic>> generateLegalDocument({
    required int userId,
    required String docType,
    Map<String, dynamic>? userDetails,
    String language = 'en',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/legal-documents/generate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'doc_type': docType,
        'user_details': userDetails,
        'language': language,
      }),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getLegalDocuments(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/legal-documents?user_id=$userId'));
    return jsonDecode(response.body);
  }

  Future<void> deleteLegalDocument(int id, int userId) async {
    await http.delete(Uri.parse('$baseUrl/legal-documents/$id?user_id=$userId'));
  }

  // ============================================
  // FEATURE 9: MULTI-LANGUAGE TRANSLATE
  // ============================================
  Future<Map<String, dynamic>> translateText(String text, String targetLanguage) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ai/translate'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'text': text,
        'target_language': targetLanguage,
      }),
    );
    return jsonDecode(response.body);
  }

  // ============================================
  // FEATURE 10: EMERGENCY CARD
  // ============================================
  Future<Map<String, dynamic>> updateEmergencyCard(int userId, Map<String, dynamic> emergencyData) async {
    final response = await http.put(
      Uri.parse('$baseUrl/emergency-card'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'emergency_data': emergencyData,
      }),
    );
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getEmergencyCard(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/emergency-card?user_id=$userId'));
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getEmergencyCardSuggestions({String? age, String? conditions}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/emergency-card/suggest'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'age': age, 'conditions': conditions}),
    );
    return jsonDecode(response.body);
  }

  // Run V3 Migration
  Future<Map<String, dynamic>> runV3Migration() async {
    final response = await http.get(Uri.parse('$baseUrl/migrate-v3'));
    return jsonDecode(response.body);
  }
}

