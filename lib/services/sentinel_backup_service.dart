import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as enc;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class SentinelBackupService {
  static final SentinelBackupService _instance = SentinelBackupService._internal();
  factory SentinelBackupService() => _instance;
  SentinelBackupService._internal();

  final _secureStorage = const FlutterSecureStorage();
  final String _cacheFileName = 'sentinel_vault.cache';

  /// Generates or retrieves a unique local encryption key for the device
  Future<String> _getOrCreateKey() async {
    String? key = await _secureStorage.read(key: 'sentinel_local_key');
    if (key == null) {
      key = enc.Key.fromSecureRandom(32).base64;
      await _secureStorage.write(key: 'sentinel_local_key', value: key);
    }
    return key;
  }

  /// Encrypts and saves the vault data to a local file
  Future<void> saveVaultToLocalCache(List<dynamic> vaultItems) async {
    try {
      final keyStr = await _getOrCreateKey();
      final key = enc.Key.fromBase64(keyStr);
      final iv = enc.IV.fromLength(16);
      final encrypter = enc.Encrypter(enc.AES(key));

      final jsonData = jsonEncode(vaultItems);
      final encrypted = encrypter.encrypt(jsonData, iv: iv);

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_cacheFileName');
      
      // Store IV + Encrypted Data
      final storageData = {
        'iv': iv.base64,
        'data': encrypted.base64,
        'timestamp': DateTime.now().toIso8601String(),
        'checksum': sha256.convert(utf8.encode(jsonData)).toString(),
      };

      await file.writeAsString(jsonEncode(storageData));
      debugPrint("SENTINEL: Vault cached locally and encrypted.");
    } catch (e) {
      debugPrint("SENTINEL CACHE ERROR: $e");
    }
  }

  /// Retrieves and decrypts the local vault cache
  Future<List<dynamic>?> getLocalVaultCache() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$_cacheFileName');

      if (!await file.exists()) return null;

      final keyStr = await _getOrCreateKey();
      final key = enc.Key.fromBase64(keyStr);
      final storageData = jsonDecode(await file.readAsString());
      
      final iv = enc.IV.fromBase64(storageData['iv']);
      final encrypter = enc.Encrypter(enc.AES(key));
      
      final decrypted = encrypter.decrypt64(storageData['data'], iv: iv);
      return jsonDecode(decrypted);
    } catch (e) {
      debugPrint("SENTINEL RESTORE ERROR: $e");
      return null;
    }
  }

  /// Checks if the server data matches the last known healthy local backup
  Future<Map<String, dynamic>> checkIntegrity(List<dynamic> serverItems) async {
    final localData = await getLocalVaultCache();
    if (localData == null) return {'status': 'SECURE', 'message': 'No local backup found for comparison.'};

    final serverHash = sha256.convert(utf8.encode(jsonEncode(serverItems))).toString();
    
    // Get stored checksum from file
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_cacheFileName');
    final storageData = jsonDecode(await file.readAsString());
    final localHash = storageData['checksum'];

    if (serverHash == localHash) {
      return {
        'status': 'SECURE',
        'message': 'Server integrity verified against local Sentinel backup.',
        'last_sync': storageData['timestamp']
      };
    } else {
      return {
        'status': 'TAMPERED',
        'message': 'CRITICAL: Server data mismatch detected! The data on the server differs from your last secure local backup.',
        'local_backup': localData
      };
    }
  }

  /// Force sync local backup with server
  Future<void> syncWithServer(int userId) async {
    try {
      final vaultData = await ApiService().getVaultItems(userId: userId);
      if (vaultData != null) {
        await saveVaultToLocalCache(vaultData);
      }
    } catch (e) {
      debugPrint("SYNC FAILED: $e");
    }
  }
}
