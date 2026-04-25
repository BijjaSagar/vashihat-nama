export const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'https://vashihat-nama-main.vercel.app/api';

export class ApiService {
  static getAuthToken(): string | null {
    if (typeof window !== 'undefined') {
      return localStorage.getItem('authToken');
    }
    return null;
  }

  static getUserId(): string | null {
    if (typeof window !== 'undefined') {
      return localStorage.getItem('userId');
    }
    return null;
  }

  static logout() {
    if (typeof window !== 'undefined') {
      localStorage.removeItem('authToken');
      localStorage.removeItem('userId');
      localStorage.removeItem('userMobile');
      window.location.href = '/';
    }
  }

  static async request(endpoint: string, options: RequestInit = {}) {
    const url = `${API_BASE_URL}${endpoint}`;
    const token = this.getAuthToken();
    
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      ...((options.headers as Record<string, string>) || {}),
    };

    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    const response = await fetch(url, {
      ...options,
      headers,
    });

    if (response.status === 401) {
      this.logout();
      throw new Error('Session expired. Please log in again.');
    }

    if (!response.ok) {
      let errorMessage = 'An error occurred';
      try {
        const errorData = await response.json();
        errorMessage = errorData.error || errorData.message || errorMessage;
      } catch (e) {
        errorMessage = await response.text();
      }
      throw new Error(errorMessage);
    }

    return response.json();
  }
}
