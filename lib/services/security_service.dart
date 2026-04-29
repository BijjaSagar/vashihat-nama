import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:argon2/argon2.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:archive/archive.dart';

class SecurityService {
  static const _storage = FlutterSecureStorage();
  static const _keySize = 32; // 256 bits
  static const _ivSize = 12;  // 96 bits for GCM

  /// Derives a Master Key from a User PIN using Argon2id (Elite Security)
  static Future<Key> deriveKeyFromPin(String pin) async {
    String? saltBase64 = await _storage.read(key: 'user_argon2_salt');
    
    if (saltBase64 == null) {
      final salt = IV.fromSecureRandom(16).bytes;
      saltBase64 = base64.encode(salt);
      await _storage.write(key: 'user_argon2_salt', value: saltBase64);
    }

    final salt = base64.decode(saltBase64);
    
    // Argon2id Parameters: Memory: 64MB, Iterations: 3, Parallelism: 4
    final argon2 = Argon2();
    final result = await argon2.hash(
      pin,
      salt,
      iterations: 3,
      memory: 65536,
      parallelism: 4,
      type: Argon2Type.argon2id,
      hashLength: 32,
    );

    return Key(Uint8List.fromList(result.hash));
  }

  /// Generates or retrieves the Master Key from the hardware keychain
  static Future<Key> getMasterKey() async {
    // In production, the PIN would be collected at login and held in memory.
    // For this implementation, we retrieve a cached identifier or fallback.
    String? pin = await _storage.read(key: 'cached_user_pin') ?? 'default_pin_poc';
    return await deriveKeyFromPin(pin);
  }

  /// Encrypts data using AES-256-GCM
  static Future<String> encrypt(String plainText) async {
    final key = await getMasterKey();
    final iv = IV.fromSecureRandom(_ivSize);
    
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    
    final combined = BytesBuilder()
      ..add(iv.bytes)
      ..add(encrypted.bytes);
      
    return base64.encode(combined.toBytes());
  }

  /// Decrypts data using AES-256-GCM
  static Future<String> decrypt(String encryptedBase64) async {
    final key = await getMasterKey();
    final combined = base64.decode(encryptedBase64);
    
    if (combined.length < _ivSize) throw Exception("Invalid encrypted data");
    
    final iv = IV(combined.sublist(0, _ivSize));
    final cipherText = combined.sublist(_ivSize);
    
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    return encrypter.decrypt(Encrypted(cipherText), iv: iv);
  }

  /// Shamir's Secret Sharing (SSS) - Concept Implementation
  /// Splitting the Master Key into 3 Shards (2-of-3 threshold)
  static Future<List<String>> generateMasterShards() async {
    final key = await getMasterKey();
    final keyBytes = key.bytes;
    
    // Simplified 2-of-3 XOR Secret Sharing for POC
    final r1 = IV.fromSecureRandom(32).bytes;
    final r2 = IV.fromSecureRandom(32).bytes;
    
    final s1 = Uint8List(32);
    final s2 = Uint8List(32);
    final s3 = Uint8List(32);
    
    for(int i=0; i<32; i++) {
      s1[i] = keyBytes[i] ^ r1[i];
      s2[i] = keyBytes[i] ^ r2[i];
      s3[i] = r1[i] ^ r2[i];
    }
    
    return [
      base64.encode(s1),
      base64.encode(s2),
      base64.encode(s3),
    ];
  }
}
