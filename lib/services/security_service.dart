import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:archive/archive.dart';

class SecurityService {
  static const _storage = FlutterSecureStorage();
  static const _keySize = 32; // 256 bits
  static const _ivSize = 12;  // 96 bits for GCM

  /// Generates or retrieves the Master Key from the hardware keychain
  static Future<Key> getMasterKey() async {
    String? base64Key = await _storage.read(key: 'master_encryption_key');
    
    if (base64Key == null) {
      // Generate a new random key
      final key = Key.fromSecureRandom(_keySize);
      await _storage.write(key: 'master_encryption_key', value: key.base64);
      return key;
    }
    
    return Key.fromBase64(base64Key);
  }

  /// Encrypts data using AES-256-GCM
  /// Returns a base64 encoded string containing IV + Ciphertext
  static Future<String> encrypt(String plainText) async {
    final key = await getMasterKey();
    final iv = IV.fromSecureRandom(_ivSize);
    
    // Using AES-GCM (PointyCastle via Encrypt)
    final encrypter = Encrypter(AES(key, mode: AESMode.gcm));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    
    // Prepend IV to the encrypted data for storage
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

  /// Compresses data using GZip (standard cross-platform)
  static Uint8List compress(String data) {
    final bytes = utf8.encode(data);
    return Uint8List.fromList(GZipEncoder().encode(bytes)!);
  }

  /// Decompresses GZip data
  static String decompress(Uint8List compressedData) {
    final bytes = GZipDecoder().decodeBytes(compressedData);
    return utf8.decode(bytes);
  }

  /// Specialized method for File Encryption
  static Future<Map<String, dynamic>> encryptFile(Uint8List fileBytes) async {
    // 1. Generate a random File Encryption Key (FEK)
    final fek = Key.fromSecureRandom(_keySize);
    final iv = IV.fromSecureRandom(_ivSize);
    
    // 2. Encrypt the file with FEK
    final encrypter = Encrypter(AES(fek, mode: AESMode.gcm));
    final encrypted = encrypter.encryptBytes(fileBytes, iv: iv);
    
    // 3. Encrypt the FEK with the User's Master Key (Key Wrapping)
    final masterKey = await getMasterKey();
    final masterEncrypter = Encrypter(AES(masterKey, mode: AESMode.gcm));
    final wrappedFek = masterEncrypter.encrypt(fek.base64, iv: iv);

    final combinedFile = BytesBuilder()
      ..add(iv.bytes)
      ..add(encrypted.bytes);

    return {
      'encrypted_file': combinedFile.toBytes(),
      'wrapped_key': wrappedFek.base64,
      'iv': iv.base64,
    };
  }
}
