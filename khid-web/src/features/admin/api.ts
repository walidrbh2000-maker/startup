// Typed wrappers over the /admin/* endpoints (backend AdminController).
import { http } from '../../lib/api';
import type {
  AdminStats,
  AdminUser,
  Paginated,
  Profession,
  Role,
  ServiceRequest,
  WorkerBid,
} from '../../lib/types';

export type ListParams = Record<string, string | number | boolean | undefined>;

export const adminApi = {
  stats: () => http.get<AdminStats>('/admin/stats'),

  // users
  users: (params: ListParams) => http.get<Paginated<AdminUser>>('/admin/users', params),
  updateUser: (id: string, body: Partial<AdminUser>) => http.patch<AdminUser>(`/admin/users/${id}`, body),
  setRole: (id: string, role: Role) => http.patch<AdminUser>(`/admin/users/${id}/role`, { role }),
  setBan: (id: string, isBanned: boolean) => http.patch<AdminUser>(`/admin/users/${id}/ban`, { isBanned }),
  deleteUser: (id: string) => http.del<{ deleted: true }>(`/admin/users/${id}`),

  // workers
  workers: (params: ListParams) => http.get<Paginated<AdminUser>>('/admin/workers', params),
  setVerified: (id: string, isVerified: boolean) =>
    http.patch<AdminUser>(`/admin/workers/${id}/verify`, { isVerified }),
  setOnline: (id: string, isOnline: boolean) =>
    http.patch<AdminUser>(`/admin/workers/${id}/status`, { isOnline }),

  // verifications
  setVerification: (id: string, status: 'approved' | 'rejected', note?: string) =>
    http.patch<AdminUser>(`/admin/users/${id}/verification`, { status, note }),

  // requests
  requests: (params: ListParams) => http.get<Paginated<ServiceRequest>>('/admin/service-requests', params),
  cancelRequest: (id: string) => http.post<ServiceRequest>(`/admin/service-requests/${id}/cancel`),

  // bids
  bids: (params: ListParams) => http.get<Paginated<WorkerBid>>('/admin/bids', params),

  // professions
  professions: () => http.get<Profession[]>('/admin/professions'),
  createProfession: (body: Omit<Profession, '_id'>) => http.post<Profession>('/admin/professions', body),
  updateProfession: (key: string, body: Partial<Profession>) =>
    http.patch<Profession>(`/admin/professions/${key}`, body),
  deleteProfession: (key: string) => http.del<{ deleted: true }>(`/admin/professions/${key}`),

  // broadcast
  broadcast: (body: { title: string; body: string; audience: string; wilayaCode?: number }) =>
    http.post<{ recipients: number }>('/admin/broadcast', body),
};
