import { Moon, Sun, Languages } from 'lucide-react';
import { useTheme } from '../../lib/theme';
import { cn } from '../../lib/cn';

const LANG_LABEL: Record<string, string> = { ar: 'ع', fr: 'FR', en: 'EN' };

/** Compact language cycler + theme toggle, used in public nav and admin topbar. */
export function Controls({ className }: { className?: string }) {
  const { theme, toggleTheme, lang, cycleLang } = useTheme();
  return (
    <div className={cn('flex items-center gap-1.5', className)}>
      <button
        onClick={cycleLang}
        className="inline-flex h-9 items-center gap-1.5 rounded-lg border border-border bg-surface px-2.5 text-xs font-bold text-content-secondary transition hover:text-content hover:bg-surface-variant"
        aria-label="Change language"
      >
        <Languages className="h-4 w-4" />
        {LANG_LABEL[lang] ?? lang.toUpperCase()}
      </button>
      <button
        onClick={toggleTheme}
        className="inline-flex h-9 w-9 items-center justify-center rounded-lg border border-border bg-surface text-content-secondary transition hover:text-content hover:bg-surface-variant"
        aria-label="Toggle theme"
      >
        {theme === 'dark' ? <Sun className="h-4 w-4" /> : <Moon className="h-4 w-4" />}
      </button>
    </div>
  );
}
