// Auth context — wraps Firebase Auth for the admin area.
// Firebase is loaded lazily: nothing is downloaded until an /admin screen
// mounts and calls ensureInit() (or signIn is invoked). The public marketing
// site therefore ships zero Firebase bytes.
// Admin-role enforcement itself lives server-side (AdminGuard) and is surfaced
// in RequireAdmin by probing GET /admin/stats.
import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from 'react';
import type { User } from 'firebase/auth';
import { loadFirebaseAuth, isFirebaseConfigured } from './firebase';

interface AuthContextValue {
  user: User | null;
  initializing: boolean;
  configured: boolean;
  /** Lazily loads Firebase + subscribes to auth state. Idempotent. */
  ensureInit: () => void;
  signIn: (email: string, password: string) => Promise<void>;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [initializing, setInitializing] = useState(isFirebaseConfigured);
  const started = useRef(false);

  const ensureInit = useCallback(() => {
    if (started.current || !isFirebaseConfigured) {
      if (!isFirebaseConfigured) setInitializing(false);
      return;
    }
    started.current = true;
    void (async () => {
      const auth = await loadFirebaseAuth();
      const { onAuthStateChanged } = await import('firebase/auth');
      onAuthStateChanged(auth, (u) => {
        setUser(u);
        setInitializing(false);
      });
    })();
  }, []);

  const value = useMemo<AuthContextValue>(
    () => ({
      user,
      initializing,
      configured: isFirebaseConfigured,
      ensureInit,
      signIn: async (email, password) => {
        ensureInit();
        const auth = await loadFirebaseAuth();
        const { signInWithEmailAndPassword } = await import('firebase/auth');
        await signInWithEmailAndPassword(auth, email, password);
      },
      signOut: async () => {
        const auth = await loadFirebaseAuth();
        const { signOut: fbSignOut } = await import('firebase/auth');
        await fbSignOut(auth);
      },
    }),
    [user, initializing, ensureInit],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
