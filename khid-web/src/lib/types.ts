// Shared API types mirroring the backend schemas (khid-back).

export type Role = 'client' | 'worker' | 'admin';

export interface Paginated<T> {
  items: T[];
  total: number;
  page: number;
  limit: number;
  pages: number;
}

export interface AdminUser {
  _id: string;
  name: string;
  email: string;
  phoneNumber: string;
  role: Role;
  isBanned?: boolean;
  isVerified?: boolean;
  profileImageUrl: string | null;
  language: string;
  wilayaCode: number | null;
  profession: string | null;
  isOnline: boolean;
  averageRating: number;
  ratingCount: number;
  jobsCompleted: number;
  responseRate: number;
  lastUpdated: string;
  lastActiveAt: string | null;
  verificationStatus?: string;
  verificationDocs?: string[];
  verificationNote?: string;
}

export type ServiceStatus =
  | 'open'
  | 'awaitingSelection'
  | 'bidSelected'
  | 'inProgress'
  | 'completed'
  | 'cancelled'
  | 'expired'
  | 'pending'
  | 'accepted'
  | 'declined';

export interface ServiceRequest {
  _id: string;
  userId: string;
  userName: string;
  userPhone: string;
  serviceType: string;
  title: string;
  description: string;
  status: ServiceStatus;
  priority: string;
  scheduledDate: string;
  userAddress: string;
  bidCount: number;
  budgetMin: number | null;
  budgetMax: number | null;
  workerId: string | null;
  workerName: string | null;
  agreedPrice: number | null;
  finalPrice: number | null;
  clientRating: number | null;
  wilayaCode: number | null;
  createdAt: string;
  completedAt: string | null;
}

export type BidStatus = 'pending' | 'accepted' | 'declined' | 'withdrawn' | 'expired';

export interface WorkerBid {
  _id: string;
  serviceRequestId: string;
  workerId: string;
  workerName: string;
  workerAverageRating: number;
  workerJobsCompleted: number;
  proposedPrice: number;
  estimatedMinutes: number;
  message: string | null;
  status: BidStatus;
  createdAt: string;
}

export interface LocalizedLabel {
  fr: string;
  ar: string;
  en: string;
}

export interface Profession {
  _id?: string;
  key: string;
  iconName: string;
  categoryKey: string;
  isActive: boolean;
  sortOrder: number;
  labels: LocalizedLabel;
  categoryLabels: LocalizedLabel;
}

/** Public professions endpoint (GET /professions?lang=) returns flattened DTOs. */
export interface ProfessionDto {
  key: string;
  iconName: string;
  categoryKey: string;
  label: string;
  categoryLabel: string;
  sortOrder: number;
}

export interface AdminStats {
  users: { total: number; clients: number; workers: number; banned: number };
  workers: { total: number; online: number; verified: number };
  requests: { total: number; byStatus: Record<string, number> };
  bids: { total: number };
  charts: {
    requestsPerDay: { date: string; count: number }[];
    topProfessions: { profession: string; count: number }[];
  };
}
