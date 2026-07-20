// Theme + language controls. Theme flips [data-theme] on <html>; language is
// handled by i18n/applyLang. Both persist to localStorage.
import { createContext, useCallback, useContext, useEffect, useState, type ReactNode } from 'react';
import { useTranslation } from 'react-i18next';
import { applyLang, LANGS, type Lang } from '../i18n';
import { IS_SERVER } from './env';

type Theme = 'light' | 'dark';

interface ThemeContextValue {
  theme: Theme;
  toggleTheme: () => void;
  lang: Lang;
  setLang: (l: Lang) => void;
  cycleLang: () => void;
}

const ThemeContext = createContext<ThemeContextValue | null>(null);

function readTheme(): Theme {
  if (IS_SERVER) return 'light';
  const attr = document.documentElement.getAttribute('data-theme');
  return attr === 'dark' ? 'dark' : 'light';
}

export function ThemeProvider({ children }: { children: ReactNode }) {
  const { i18n } = useTranslation();
  const [theme, setTheme] = useState<Theme>(readTheme);
  const [lang, setLangState] = useState<Lang>((i18n.language as Lang) ?? 'ar');

  useEffect(() => {
    // useEffect never runs during renderToString, but keep the guard explicit.
    if (IS_SERVER) return;
    document.documentElement.setAttribute('data-theme', theme);
    try {
      localStorage.setItem('khid-theme', theme);
    } catch {
      /* ignore */
    }
  }, [theme]);

  const toggleTheme = useCallback(() => setTheme((t) => (t === 'dark' ? 'light' : 'dark')), []);

  const setLang = useCallback((l: Lang) => {
    applyLang(l);
    setLangState(l);
  }, []);

  const cycleLang = useCallback(() => {
    setLangState((cur) => {
      const idx = LANGS.indexOf(cur);
      const next = LANGS[(idx + 1) % LANGS.length];
      applyLang(next);
      return next;
    });
  }, []);

  return (
    <ThemeContext.Provider value={{ theme, toggleTheme, lang, setLang, cycleLang }}>
      {children}
    </ThemeContext.Provider>
  );
}

export function useTheme(): ThemeContextValue {
  const ctx = useContext(ThemeContext);
  if (!ctx) throw new Error('useTheme must be used within ThemeProvider');
  return ctx;
}
