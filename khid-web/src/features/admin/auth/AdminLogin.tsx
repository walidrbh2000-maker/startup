import { useEffect, useState, type FormEvent } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useTranslation } from 'react-i18next';
import { ArrowLeft, ShieldCheck } from 'lucide-react';
import { useAuth } from '../../../lib/auth';
import { Button, Field, Input } from '../../../components/ui';
import { Logo } from '../../../components/layout/Logo';
import { Controls } from '../../../components/layout/Controls';

export function AdminLogin() {
  const { t } = useTranslation();
  const navigate = useNavigate();
  const { signIn, configured, ensureInit } = useAuth();

  // Warm up the lazy Firebase chunk while the user types their credentials.
  useEffect(() => ensureInit(), [ensureInit]);

  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  async function onSubmit(e: FormEvent) {
    e.preventDefault();
    if (!configured) {
      setError(t('admin.login.not_configured'));
      return;
    }
    setError(null);
    setLoading(true);
    try {
      await signIn(email.trim(), password);
      navigate('/admin', { replace: true });
    } catch {
      setError(t('admin.login.invalid'));
    } finally {
      setLoading(false);
    }
  }

  return (
    <div className="relative flex min-h-screen items-center justify-center overflow-hidden bg-bg px-4">
      <div className="pointer-events-none absolute inset-0 -z-10">
        <div className="absolute -top-24 start-1/3 h-96 w-96 rounded-full bg-primary/20 blur-[120px]" />
        <div className="absolute bottom-0 end-1/4 h-80 w-80 rounded-full bg-violet/15 blur-[120px]" />
      </div>

      <div className="absolute end-4 top-4">
        <Controls />
      </div>

      <div className="w-full max-w-md">
        <div className="mb-8 flex justify-center">
          <Logo />
        </div>
        <div className="card p-8 shadow-card">
          <div className="mb-6 flex items-center gap-3">
            <div className="grid h-11 w-11 place-items-center rounded-xl bg-primary/12 text-primary">
              <ShieldCheck className="h-6 w-6" />
            </div>
            <div>
              <h1 className="font-display text-xl font-extrabold text-content">{t('admin.login.title')}</h1>
              <p className="text-sm text-content-secondary">{t('admin.login.subtitle')}</p>
            </div>
          </div>

          <form onSubmit={onSubmit} className="space-y-4">
            <Field label={t('admin.login.email')}>
              <Input
                type="email"
                autoComplete="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                placeholder="admin@khidmeti.com"
              />
            </Field>
            <Field label={t('admin.login.password')}>
              <Input
                type="password"
                autoComplete="current-password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                placeholder="••••••••"
              />
            </Field>

            {error && (
              <p className="rounded-lg bg-danger/10 px-3 py-2 text-sm font-medium text-danger">{error}</p>
            )}

            <Button type="submit" size="lg" loading={loading} className="w-full">
              {loading ? t('admin.login.submitting') : t('admin.login.submit')}
            </Button>
          </form>
        </div>

        <div className="mt-6 text-center">
          <Link
            to="/"
            className="inline-flex items-center gap-1.5 text-sm font-semibold text-content-secondary transition hover:text-primary"
          >
            <ArrowLeft className="h-4 w-4 rtl:rotate-180" />
            {t('admin.login.back')}
          </Link>
        </div>
      </div>
    </div>
  );
}
