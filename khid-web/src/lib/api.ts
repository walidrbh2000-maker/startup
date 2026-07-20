// Axios client for the Khidmeti API.
//   • baseURL from VITE_API_BASE_URL (defaults to the dev proxy '/api').
//   • Request interceptor attaches the current Firebase ID token.
//   • Response interceptor unwraps the { success, data, timestamp } envelope
//     produced by the backend ResponseInterceptor, so callers get `data`.
import axios, { AxiosError, type AxiosInstance } from 'axios';
import { getLoadedAuth } from './firebase';

export interface ApiError {
  status: number;
  message: string;
}

const baseURL = import.meta.env.VITE_API_BASE_URL || '/api';

export const api: AxiosInstance = axios.create({ baseURL, timeout: 20000 });

api.interceptors.request.use(async (config) => {
  try {
    // Only attaches a token if the admin area already lazy-loaded Firebase.
    const user = getLoadedAuth()?.currentUser;
    if (user) {
      const token = await user.getIdToken();
      config.headers.set('Authorization', `Bearer ${token}`);
    }
  } catch {
    // No auth available (public endpoints like /professions still work).
  }
  return config;
});

api.interceptors.response.use(
  (res) => {
    // Unwrap the standard envelope when present.
    const body = res.data;
    if (body && typeof body === 'object' && 'success' in body && 'data' in body) {
      res.data = (body as { data: unknown }).data;
    }
    return res;
  },
  (error: AxiosError<{ message?: string | string[] }>) => {
    const status = error.response?.status ?? 0;
    const raw = error.response?.data?.message;
    const message = Array.isArray(raw) ? raw.join(', ') : raw || error.message || 'Network error';
    return Promise.reject({ status, message } satisfies ApiError);
  },
);

/** Thin typed GET/POST/PATCH/DELETE helpers returning the unwrapped data. */
export const http = {
  get: <T>(url: string, params?: Record<string, unknown>) =>
    api.get<T>(url, { params }).then((r) => r.data),
  post: <T>(url: string, body?: unknown) => api.post<T>(url, body).then((r) => r.data),
  patch: <T>(url: string, body?: unknown) => api.patch<T>(url, body).then((r) => r.data),
  del: <T>(url: string) => api.delete<T>(url).then((r) => r.data),
};
