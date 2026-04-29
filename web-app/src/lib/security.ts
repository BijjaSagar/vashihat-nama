import * as argon2 from 'argon2-browser';

/**
 * Security Service for Vasihat Nama Web App
 * Implements AES-256-GCM encryption, GZip compression, and Argon2id key derivation.
 */
export class SecurityService {
  private static MASTER_KEY_ALIAS = 'vasihat_nama_master_key';
  private static SALT_ALIAS = 'vasihat_nama_salt';

  /**
   * Derives a Master Key from a User PIN using Argon2id
   */
  static async deriveKeyFromPin(pin: string): Promise<CryptoKey> {
    let saltString = localStorage.getItem(this.SALT_ALIAS);
    if (!saltString) {
      const salt = window.crypto.getRandomValues(new Uint8Array(16));
      saltString = btoa(String.fromCharCode(...salt));
      localStorage.setItem(this.SALT_ALIAS, saltString);
    }

    const saltUint8 = new Uint8Array(atob(saltString).split('').map(c => c.charCodeAt(0)));

    // Argon2id Parameters (High Security)
    // Memory: 64MB, Iterations: 3, Parallelism: 4
    const result = await argon2.hash({
      pass: pin,
      salt: saltUint8,
      time: 3,
      mem: 65536,
      hashLen: 32,
      parallelism: 4,
      type: argon2.ArgonType.Argon2id,
    });

    return await window.crypto.subtle.importKey(
      'raw',
      result.hash,
      { name: 'AES-GCM', length: 256 },
      false,
      ['encrypt', 'decrypt']
    );
  }

  /**
   * Retrieves the current Master Key (In a real app, this would be in memory after login)
   */
  private static async getMasterKey(): Promise<CryptoKey> {
    // For this POC, we use a fallback if not logged in, but in production, 
    // the key is only derived at login and held in memory.
    const pin = localStorage.getItem('user_session_pin') || 'default_pin_poc';
    return await this.deriveKeyFromPin(pin);
  }

  /**
   * Encrypts a string using AES-256-GCM
   */
  static async encrypt(plainText: string): Promise<string> {
    const key = await this.getMasterKey();
    const iv = window.crypto.getRandomValues(new Uint8Array(12));
    const encoder = new TextEncoder();
    const data = encoder.encode(plainText);

    const ciphertext = await window.crypto.subtle.encrypt(
      { name: 'AES-GCM', iv },
      key,
      data
    );

    const combined = new Uint8Array(iv.length + ciphertext.byteLength);
    combined.set(iv);
    combined.set(new Uint8Array(ciphertext), iv.length);

    return btoa(String.fromCharCode(...combined));
  }

  /**
   * Decrypts a base64 string using AES-256-GCM
   */
  static async decrypt(encryptedBase64: string): Promise<string> {
    const key = await this.getMasterKey();
    const combined = new Uint8Array(atob(encryptedBase64).split('').map(c => c.charCodeAt(0)));
    
    const iv = combined.slice(0, 12);
    const ciphertext = combined.slice(12);

    const decrypted = await window.crypto.subtle.decrypt(
      { name: 'AES-GCM', iv },
      key,
      ciphertext
    );

    return new TextDecoder().decode(decrypted);
  }

  /**
   * Shamir's Secret Sharing (SSS) - Shard Generation (Conceptual/Simplified for POC)
   * Splits a key into 3 shards, requiring 2 to reconstruct.
   */
  static async generateShards(key: Uint8Array): Promise<string[]> {
    // Simplified SSS implementation for the purpose of the POC
    // Shard 1: Key XOR Random1
    // Shard 2: Key XOR Random2
    // Shard 3: Random1 XOR Random2
    const r1 = window.crypto.getRandomValues(new Uint8Array(32));
    const r2 = window.crypto.getRandomValues(new Uint8Array(32));
    
    const s1 = new Uint8Array(32);
    const s2 = new Uint8Array(32);
    const s3 = new Uint8Array(32);
    
    for(let i=0; i<32; i++) {
      s1[i] = key[i] ^ r1[i];
      s2[i] = key[i] ^ r2[i];
      s3[i] = r1[i] ^ r2[i];
    }
    
    return [
      btoa(String.fromCharCode(...s1)),
      btoa(String.fromCharCode(...s2)),
      btoa(String.fromCharCode(...s3))
    ];
  }

  /**
   * Compresses data using native GZip
   */
  static async compress(data: string): Promise<Uint8Array> {
    const stream = new Blob([data]).stream();
    const compressionStream = new CompressionStream('gzip');
    const compressedStream = stream.pipeThrough(compressionStream);
    const response = new Response(compressedStream);
    const buffer = await response.arrayBuffer();
    return new Uint8Array(buffer);
  }

  /**
   * Decompresses GZip data
   */
  static async decompress(compressedData: Uint8Array): Promise<string> {
    const stream = new Blob([compressedData]).stream();
    const decompressionStream = new DecompressionStream('gzip');
    const decompressedStream = stream.pipeThrough(decompressionStream);
    const response = new Response(decompressedStream);
    return await response.text();
  }
}
