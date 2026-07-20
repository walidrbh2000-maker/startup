import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import { QueryClientProvider } from '@tanstack/react-query';
import { MotionConfig } from 'framer-motion';
import './i18n';
import './index.css';
import { queryClient } from './lib/queryClient';
import { ThemeProvider } from './lib/theme';
import { AuthProvider } from './lib/auth';
import { ToastProvider } from './components/ui/toast';
import App from './App';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>
      <ThemeProvider>
        <AuthProvider>
          <ToastProvider>
            <MotionConfig reducedMotion="user">
              <BrowserRouter>
                <App />
              </BrowserRouter>
            </MotionConfig>
          </ToastProvider>
        </AuthProvider>
      </ThemeProvider>
    </QueryClientProvider>
  </StrictMode>,
);
