import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import { IS_SERVER } from '../lib/env';
import ar from './locales/ar.json';
import fr from './locales/fr.json';
import en from './locales/en.json';

export const LANGS = ['ar', 'fr', 'en'] as const;
export type Lang = (typeof LANGS)[number];

export const RTL_LANGS: Lang[] = ['ar'];

function readStored(): Lang | null {
  if (IS_SERVER) return null;
  try {
    const v = localStorage.getItem('khid-lang') as Lang | null;
    return v && LANGS.includes(v) ? v : null;
  } catch {
    return null;
  }
}

const initial: Lang = readStored() ?? 'ar';

void i18n.use(initReactI18next).init({
  resources: {
    ar: { translation: ar },
    fr: { translation: fr },
    en: { translation: en },
  },
  lng: initial,
  fallbackLng: 'fr',
  interpolation: { escapeValue: false },
});

/** Apply lang + direction to <html>, persist choice. No-ops document/storage on the server. */
export function applyLang(lang: Lang): void {
  void i18n.changeLanguage(lang);
  if (IS_SERVER) return;
  const dir = RTL_LANGS.includes(lang) ? 'rtl' : 'ltr';
  document.documentElement.setAttribute('lang', lang);
  document.documentElement.setAttribute('dir', dir);
  try {
    localStorage.setItem('khid-lang', lang);
  } catch {
    /* ignore */
  }
}

// Apply once on load.
applyLang(initial);

export default i18n;
