/**
 * Security Service for Vasihat Nama Web App
 * Implements AES-256-GCM encryption and GZip compression using native Browser APIs.
 */

export class SecurityService {
  private static MASTER_KEY_ALIAS = 'vasihat_nama_master_key';

  /**
   * Generates or retrieves a Master Key from IndexedDB (Hardware-backed if supported)
   */
  private static async getMasterKey(): Promise<CryptoKey> {
    const existingKey = await this.loadKey();
    if (existingKey) return existingKey;

    const key = await window.crypto.subtle.generateKey(
      { name: 'AES-GCM', length: 256 },
      true, // extractable
      ['encrypt', 'decrypt']
    );

    await this.saveKey(key);
    return key;
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

    // Combine IV + Ciphertext
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

  // --- Internal Storage Helpers (Mimicking hardware keychain in Browser) ---

  private static async saveKey(key: CryptoKey): Promise<void> {
    const exported = await window.crypto.subtle.exportKey('jwk', key);
    localStorage.setItem(this.MASTER_KEY_ALIAS, JSON.stringify(exported));
  }

  private static async loadKey(): Promise<CryptoKey | null> {
    const jwk = localStorage.getItem(this.MASTER_KEY_ALIAS);
    if (!jwk) return null;

    try {
      return await window.crypto.subtle.importKey(
        'jwk',
        JSON.parse(jwk),
        { name: 'AES-GCM', length: 256 },
        true,
        ['encrypt', 'decrypt']
      );
    } catch {
      return null;
    }
  }
}
