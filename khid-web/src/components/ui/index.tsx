// Reusable, theme-aware UI primitives for the whole app.
import { forwardRef, type ButtonHTMLAttributes, type InputHTMLAttributes, type ReactNode, type SelectHTMLAttributes } from 'react';
import { Loader2 } from 'lucide-react';
import { cn } from '../../lib/cn';

// ── Button ──────────────────────────────────────────────────────────────────
type Variant = 'primary' | 'ghost' | 'outline' | 'danger' | 'soft';
type Size = 'sm' | 'md' | 'lg';

const btnBase =
  'inline-flex items-center justify-center gap-2 rounded-xl font-semibold transition-all duration-200 focus:outline-none focus-visible:ring-2 focus-visible:ring-primary/60 disabled:opacity-50 disabled:pointer-events-none whitespace-nowrap';

const btnVariants: Record<Variant, string> = {
  primary:
    'bg-primary text-white shadow-glow hover:brightness-110 active:scale-[0.98]',
  soft: 'bg-primary/10 text-primary hover:bg-primary/20',
  ghost: 'text-content-secondary hover:text-content hover:bg-surface-variant',
  outline: 'border border-border text-content hover:bg-surface-variant',
  danger: 'bg-danger/10 text-danger hover:bg-danger/20',
};

const btnSizes: Record<Size, string> = {
  sm: 'h-9 px-3.5 text-sm',
  md: 'h-11 px-5 text-sm',
  lg: 'h-12 px-7 text-base',
};

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: Variant;
  size?: Size;
  loading?: boolean;
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(function Button(
  { className, variant = 'primary', size = 'md', loading, children, disabled, ...rest },
  ref,
) {
  return (
    <button
      ref={ref}
      className={cn(btnBase, btnVariants[variant], btnSizes[size], className)}
      disabled={disabled || loading}
      {...rest}
    >
      {loading && <Loader2 className="h-4 w-4 animate-spin" />}
      {children}
    </button>
  );
});

// ── Card ────────────────────────────────────────────────────────────────────
export function Card({ className, children }: { className?: string; children: ReactNode }) {
  return <div className={cn('card p-5 shadow-card', className)}>{children}</div>;
}

// ── Badge ───────────────────────────────────────────────────────────────────
type Tone = 'primary' | 'success' | 'warning' | 'danger' | 'neutral' | 'violet';
const tones: Record<Tone, string> = {
  primary: 'bg-primary/12 text-primary',
  success: 'bg-success/15 text-success',
  warning: 'bg-warning/15 text-warning',
  danger: 'bg-danger/15 text-danger',
  neutral: 'bg-surface-variant text-content-secondary',
  violet: 'bg-violet/15 text-violet',
};
export function Badge({ tone = 'neutral', children }: { tone?: Tone; children: ReactNode }) {
  return (
    <span
      className={cn(
        'inline-flex items-center gap-1 rounded-full px-2.5 py-0.5 text-xs font-semibold',
        tones[tone],
      )}
    >
      {children}
    </span>
  );
}

// ── Input / Select ──────────────────────────────────────────────────────────
const fieldBase =
  'w-full rounded-xl border border-border bg-surface px-4 text-sm text-content placeholder:text-content-tertiary focus:outline-none focus:ring-2 focus:ring-primary/50 focus:border-primary/50 transition';

export const Input = forwardRef<HTMLInputElement, InputHTMLAttributes<HTMLInputElement>>(
  function Input({ className, ...rest }, ref) {
    return <input ref={ref} className={cn(fieldBase, 'h-11', className)} {...rest} />;
  },
);

export const Select = forwardRef<HTMLSelectElement, SelectHTMLAttributes<HTMLSelectElement>>(
  function Select({ className, children, ...rest }, ref) {
    return (
      <select ref={ref} className={cn(fieldBase, 'h-11 cursor-pointer pe-8', className)} {...rest}>
        {children}
      </select>
    );
  },
);

export function Field({ label, children }: { label: string; children: ReactNode }) {
  return (
    <label className="flex flex-col gap-1.5">
      <span className="text-xs font-semibold text-content-secondary">{label}</span>
      {children}
    </label>
  );
}

// ── Spinner / states ─────────────────────────────────────────────────────────
export function Spinner({ className }: { className?: string }) {
  return <Loader2 className={cn('h-5 w-5 animate-spin text-primary', className)} />;
}

/** Shimmering placeholder block — reserves space while data loads (CLS ≈ 0). */
export function Skeleton({ className }: { className?: string }) {
  return (
    <div
      aria-hidden="true"
      className={cn(
        'animate-shimmer rounded-lg bg-surface-variant',
        'bg-[linear-gradient(90deg,transparent,rgb(var(--border)/0.6),transparent)] bg-[length:200%_100%]',
        className,
      )}
    />
  );
}

export function Centered({ children }: { children: ReactNode }) {
  return <div className="flex min-h-[40vh] items-center justify-center">{children}</div>;
}
