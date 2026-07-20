import { useTranslation } from 'react-i18next';
import { cn } from '../../lib/cn';

/** Khidmeti wordmark: gradient "K" glyph tile + brand name. */
export function Logo({ className, mono = false }: { className?: string; mono?: boolean }) {
  const { t } = useTranslation();
  return (
    <span className={cn('inline-flex items-center gap-2.5', className)}>
      <span className="grid h-9 w-9 place-items-center rounded-xl bg-gradient-to-br from-primary to-violet text-lg font-black text-white shadow-glow">
        خ
      </span>
      <span
        className={cn(
          'font-display text-lg font-extrabold tracking-tight',
          mono ? 'text-white' : 'text-content',
        )}
      >
        {t('brand')}
      </span>
    </span>
  );
}
