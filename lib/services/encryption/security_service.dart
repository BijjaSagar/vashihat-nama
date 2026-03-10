import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/export.dart' as pc;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

class SecurityService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // --- Constants ---
  static const _privateKeyStorageKey = 'user_private_key';
  static const _publicKeyStorageKey = 'user_public_key';
  static const _masterKeyCheck = 'master_key_check_hash';

  // --- 1. Key Generation (Onboarding) ---

  /// Generates a new RSA Key Pair (2048-bit) for the user.
  /// This happens once during sign-up.
  Future<pc.AsymmetricKeyPair<pc.RSAPublicKey, pc.RSAPrivateKey>> generateUserKeyPair() async {
    final keyGen = pc.RSAKeyGenerator()
      ..init(pc.ParametersWithRandom(
        pc.RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
        _getSecureRandom(),
      ));

    final pair = keyGen.generateKeyPair();
    // In a real app, store these keys securely or send Public Key to server
    return pc.AsymmetricKeyPair<pc.RSAPublicKey, pc.RSAPrivateKey>(
      pair.publicKey as pc.RSAPublicKey, 
      pair.privateKey as pc.RSAPrivateKey
    );
  }

  // --- 2. Master Password Handling ---

  /// Encrypts the Private Key using the User's Master Password (AES).
  /// Returns the encrypted private key string to send to the server.
  String encryptPrivateKeyWithPassword(pc.RSAPrivateKey privateKey, String masterPassword) {
    // 1. Derive a 32-byte AES key from the password
    final key = encrypt.Key(_deriveKeyFromPassword(masterPassword)); 
    final iv = encrypt.IV.fromLength(16); // Generate random IV
    
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    
    // Convert Private Key components to a JSON string
    final privateKeyString = jsonEncode({
      'modulus': privateKey.modulus.toString(),
      'exponent': privateKey.privateExponent.toString(),
      'p': privateKey.p.toString(),
      'q': privateKey.q.toString(),
    });

    final encrypted = encrypter.encrypt(privateKeyString, iv: iv);
    return '${iv.base64}:${encrypted.base64}'; // Return IV:Text format
  }

  // --- 3. Document Encryption (AES) ---

  /// Generates a random AES-256 key for file encryption.
  String generateFileKey() {
    final key = encrypt.Key.fromSecureRandom(32);
    return key.base64;
  }

  /// Encrypts file bytes using a specific AES Key.
  Uint8List encryptFile(Uint8List fileBytes, String base64Key) {
    final key = encrypt.Key.fromBase64(base64Key);
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    
    final encrypted = encrypter.encryptBytes(fileBytes, iv: iv);
    
    // Combine IV + Encrypted Data
    final combined = BytesBuilder();
    combined.add(iv.bytes);
    combined.add(encrypted.bytes);
    return combined.toBytes();
  }
  
  /// Decrypts file bytes using a specific AES Key.
  Uint8List decryptFile(Uint8List encryptedBytes, String base64Key) {
    try {
      final key = encrypt.Key.fromBase64(base64Key);
      
      // Extract IV (first 16 bytes)
      final iv = encrypt.IV(encryptedBytes.sublist(0, 16));
      final cipherText = encryptedBytes.sublist(16);
      
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final decrypted = encrypter.decryptBytes(encrypt.Encrypted(cipherText), iv: iv);
      
      return Uint8List.fromList(decrypted);
    } catch (e) {
      throw Exception("Decryption failed: $e");
    }
  }

  // --- Utilities ---

  pc.SecureRandom _getSecureRandom() {
    final secureRandom = pc.FortunaRandom();
    final random = Random.secure();
    final seeds = List<int>.generate(32, (_) => random.nextInt(255));
    secureRandom.seed(pc.KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }

  Uint8List _deriveKeyFromPassword(String password) {
    // In a real app, use PBKDF2 with salt.
    // Here we wrap it in SHA256 to get exactly 32 bytes.
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return Uint8List.fromList(digest.bytes); 
  }
}
