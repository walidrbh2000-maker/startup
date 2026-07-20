// Firebase Web SDK — same project as the mobile app & backend. Only Auth is
// used here (admin email/password sign-in). The ID token minted here is what
// FirebaseAuthGuard verifies on the NestJS side.
//
// The SDK is loaded via dynamic import so the public marketing site never
// downloads Firebase: only the /admin area calls loadFirebaseAuth().
import type { FirebaseApp } from 'firebase/app';
import type { Auth } from 'firebase/auth';

const config = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN,
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID,
  appId: import.meta.env.VITE_FIREBASE_APP_ID,
};

export const isFirebaseConfigured = Boolean(config.apiKey && config.projectId);

let app: FirebaseApp | undefined;
let authInstance: Auth | undefined;

export async function loadFirebaseAuth(): Promise<Auth> {
  if (!authInstance) {
    const [{ initializeApp }, { getAuth }] = await Promise.all([
      import('firebase/app'),
      import('firebase/auth'),
    ]);
    app = initializeApp(config);
    authInstance = getAuth(app);
  }
  return authInstance;
}

/** Synchronous accessor: defined only after loadFirebaseAuth() has resolved. */
export function getLoadedAuth(): Auth | undefined {
  return authInstance;
}
