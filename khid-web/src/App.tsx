import { lazy, Suspense } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { Landing } from './features/marketing/Landing';
import { LegalPage } from './features/marketing/LegalPage';
import { Centered, Spinner } from './components/ui';

// The admin area (Firebase, Recharts, tables, forms) is code-split so the public
// marketing site loads without shipping any of that weight.
const AdminLogin = lazy(() => import('./features/admin/auth/AdminLogin').then((m) => ({ default: m.AdminLogin })));
const RequireAdmin = lazy(() => import('./features/admin/auth/RequireAdmin').then((m) => ({ default: m.RequireAdmin })));
const AdminLayout = lazy(() => import('./features/admin/AdminLayout').then((m) => ({ default: m.AdminLayout })));
const Dashboard = lazy(() => import('./features/admin/pages/Dashboard').then((m) => ({ default: m.Dashboard })));
const UsersPage = lazy(() => import('./features/admin/pages/UsersPage').then((m) => ({ default: m.UsersPage })));
const WorkersPage = lazy(() => import('./features/admin/pages/WorkersPage').then((m) => ({ default: m.WorkersPage })));
const VerificationsPage = lazy(() => import('./features/admin/pages/VerificationsPage').then((m) => ({ default: m.VerificationsPage })));
const RequestsPage = lazy(() => import('./features/admin/pages/RequestsPage').then((m) => ({ default: m.RequestsPage })));
const BidsPage = lazy(() => import('./features/admin/pages/BidsPage').then((m) => ({ default: m.BidsPage })));
const ProfessionsPage = lazy(() => import('./features/admin/pages/ProfessionsPage').then((m) => ({ default: m.ProfessionsPage })));
const BroadcastPage = lazy(() => import('./features/admin/pages/BroadcastPage').then((m) => ({ default: m.BroadcastPage })));

function AdminFallback() {
  return (
    <div className="min-h-screen bg-bg">
      <Centered>
        <Spinner />
      </Centered>
    </div>
  );
}

export default function App() {
  return (
    <Routes>
      {/* Public marketing site */}
      <Route path="/" element={<Landing />} />
      <Route path="/legal/:doc" element={<LegalPage />} />

      {/* Admin (lazy-loaded) */}
      <Route
        path="/admin/login"
        element={
          <Suspense fallback={<AdminFallback />}>
            <AdminLogin />
          </Suspense>
        }
      />
      <Route
        path="/admin"
        element={
          <Suspense fallback={<AdminFallback />}>
            <RequireAdmin>
              <AdminLayout />
            </RequireAdmin>
          </Suspense>
        }
      >
        <Route index element={<Dashboard />} />
        <Route path="users" element={<UsersPage />} />
        <Route path="workers" element={<WorkersPage />} />
        <Route path="verifications" element={<VerificationsPage />} />
        <Route path="requests" element={<RequestsPage />} />
        <Route path="bids" element={<BidsPage />} />
        <Route path="professions" element={<ProfessionsPage />} />
        <Route path="broadcast" element={<BroadcastPage />} />
      </Route>

      <Route path="*" element={<Navigate to="/" replace />} />
    </Routes>
  );
}
