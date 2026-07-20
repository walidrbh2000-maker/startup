// Minimal toast system — no external dependency.
import { createContext, useCallback, useContext, useState, type ReactNode } from 'react';
import { createPortal } from 'react-dom';
import { motion, AnimatePresence } from 'framer-motion';
import { CheckCircle2, AlertCircle, Info } from 'lucide-react';
import { IS_SERVER } from '../../lib/env';

type ToastKind = 'success' | 'error' | 'info';
interface Toast {
  id: number;
  kind: ToastKind;
  message: string;
}

const ToastContext = createContext<(message: string, kind?: ToastKind) => void>(() => {});

const icons = {
  success: <CheckCircle2 className="h-5 w-5 text-success" />,
  error: <AlertCircle className="h-5 w-5 text-danger" />,
  info: <Info className="h-5 w-5 text-primary" />,
};

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([]);

  const push = useCallback((message: string, kind: ToastKind = 'success') => {
    const id = Date.now() + Math.random();
    setToasts((t) => [...t, { id, kind, message }]);
    setTimeout(() => setToasts((t) => t.filter((x) => x.id !== id)), 3500);
  }, []);

  if (IS_SERVER) {
    // No portal target during prerender; toasts are a client-only concern.
    return <ToastContext.Provider value={push}>{children}</ToastContext.Provider>;
  }

  return (
    <ToastContext.Provider value={push}>
      {children}
      {createPortal(
        <div className="fixed inset-x-0 bottom-4 z-[60] flex flex-col items-center gap-2 px-4">
          <AnimatePresence>
            {toasts.map((tst) => (
              <motion.div
                key={tst.id}
                initial={{ opacity: 0, y: 20, scale: 0.95 }}
                animate={{ opacity: 1, y: 0, scale: 1 }}
                exit={{ opacity: 0, scale: 0.95 }}
                className="glass flex items-center gap-3 rounded-xl border border-border px-4 py-3 text-sm font-medium text-content shadow-card"
              >
                {icons[tst.kind]}
                <span>{tst.message}</span>
              </motion.div>
            ))}
          </AnimatePresence>
        </div>,
        document.body,
      )}
    </ToastContext.Provider>
  );
}

export function useToast() {
  return useContext(ToastContext);
}
