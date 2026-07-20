import type { Config } from 'tailwindcss';

/**
 * Khidmeti "Midnight Indigo" — colours ported 1:1 from
 * khid-app/lib/utils/app_theme.dart so web and mobile read as one product.
 *
 * Theme-aware tokens (bg / surface / text / border / semantic) are driven by
 * CSS variables defined in index.css and flip with [data-theme]. Brand tokens
 * (primary / worker / icon accents) are fixed across themes.
 *
 * Variables hold raw "R G B" triplets so Tailwind's `<alpha-value>` slot works:
 *   text-primary/40, bg-surface/60, etc.
 */
const withVar = (name: string) => `rgb(var(${name}) / <alpha-value>)`;

export default {
  darkMode: ['selector', '[data-theme="dark"]'],
  content: ['./index.html', './src/**/*.{ts,tsx}'],
  theme: {
    extend: {
      colors: {
        // ── Theme-aware surfaces & text ──
        bg: withVar('--bg'),
        'bg-deep': withVar('--bg-deep'),
        surface: withVar('--surface'),
        'surface-variant': withVar('--surface-variant'),
        border: withVar('--border'),
        content: {
          DEFAULT: withVar('--text'),
          secondary: withVar('--text-secondary'),
          tertiary: withVar('--text-tertiary'),
        },
        // ── Brand (fixed) ──
        primary: {
          DEFAULT: withVar('--primary'),
          soft: withVar('--primary-soft'),
        },
        worker: withVar('--worker'),
        // ── Semantic (theme-aware) ──
        success: withVar('--success'),
        warning: withVar('--warning'),
        danger: withVar('--danger'),
        // ── Icon accents (fixed) ──
        indigo: withVar('--accent-indigo'),
        violet: withVar('--accent-violet'),
        emerald: withVar('--accent-emerald'),
        pink: withVar('--accent-pink'),
      },
      fontFamily: {
        sans: ['Inter', 'system-ui', 'Segoe UI', 'Tahoma', 'Arial', 'sans-serif'],
        display: ['"Plus Jakarta Sans"', 'Inter', 'system-ui', 'sans-serif'],
        arabic: ['"Noto Kufi Arabic"', '"Cairo"', 'Tahoma', 'system-ui', 'sans-serif'],
      },
      borderRadius: {
        xl: '1rem',
        '2xl': '1.25rem',
        '3xl': '1.75rem',
      },
      boxShadow: {
        glow: '0 0 0 1px rgb(var(--primary) / 0.25), 0 20px 60px -20px rgb(var(--primary) / 0.55)',
        card: '0 12px 40px -18px rgb(0 0 0 / 0.5)',
      },
      backgroundImage: {
        'grid-fade':
          'radial-gradient(circle at center, rgb(var(--primary) / 0.10) 0, transparent 70%)',
      },
      keyframes: {
        float: {
          '0%,100%': { transform: 'translateY(0)' },
          '50%': { transform: 'translateY(-12px)' },
        },
        'fade-up': {
          '0%': { opacity: '0', transform: 'translateY(16px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        shimmer: {
          '0%': { backgroundPosition: '-200% 0' },
          '100%': { backgroundPosition: '200% 0' },
        },
      },
      animation: {
        float: 'float 6s ease-in-out infinite',
        'fade-up': 'fade-up 0.6s ease-out both',
        shimmer: 'shimmer 1.6s linear infinite',
      },
    },
  },
  plugins: [],
} satisfies Config;
