// Build-time prerender entry (scripts/prerender.mjs). Renders the public
// marketing routes to static HTML so crawlers and social scrapers get real
// content; the normal client bundle then hydrates-by-replacement on load.
// Admin routes are intentionally NOT prerendered (auth-gated, noindex).
import { StrictMode } from 'react';
import { renderToString } from 'react-dom/server';
import { StaticRouter } from 'react-router-dom/server';
import { QueryClientProvider } from '@tanstack/react-query';
import { MotionConfig } from 'framer-motion';
import './i18n';
import { queryClient } from './lib/queryClient';
import { ThemeProvider } from './lib/theme';
import { AuthProvider } from './lib/auth';
import { ToastProvider } from './components/ui/toast';
import App from './App';

export function render(url: string): string {
  return renderToString(
    <StrictMode>
      <QueryClientProvider client={queryClient}>
        <ThemeProvider>
          <AuthProvider>
            <ToastProvider>
              <MotionConfig reducedMotion="user">
                <StaticRouter location={url}>
                  <App />
                </StaticRouter>
              </MotionConfig>
            </ToastProvider>
          </AuthProvider>
        </ThemeProvider>
      </QueryClientProvider>
    </StrictMode>,
  );
}
