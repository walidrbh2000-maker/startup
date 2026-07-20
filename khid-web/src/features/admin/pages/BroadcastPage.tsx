import { useState, type FormEvent } from 'react';
import { useTranslation } from 'react-i18next';
import { useMutation } from '@tanstack/react-query';
import { Send, Users, UserRound, HardHat, MapPin } from 'lucide-react';
import { adminApi } from '../api';
import { Button, Card, Field, Input } from '../../../components/ui';
import { useToast } from '../../../components/ui/toast';
import { PageHeader } from '../components/shared';
import { cn } from '../../../lib/cn';
import type { ApiError } from '../../../lib/api';

type Audience = 'all' | 'clients' | 'workers' | 'wilaya';

export function BroadcastPage() {
  const { t } = useTranslation();
  const toast = useToast();

  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [audience, setAudience] = useState<Audience>('all');
  const [wilaya, setWilaya] = useState('');

  const mut = useMutation({
    mutationFn: () =>
      adminApi.broadcast({
        title: title.trim(),
        body: body.trim(),
        audience,
        wilayaCode: audience === 'wilaya' ? Number(wilaya) : undefined,
      }),
    onSuccess: (res) => {
      toast(t('admin.broadcast.sent', { count: res.recipients }), 'success');
      setTitle('');
      setBody('');
    },
    onError: (e: unknown) => toast((e as ApiError)?.message ?? t('common.error'), 'error'),
  });

  const audiences: { key: Audience; label: string; Icon: typeof Users }[] = [
    { key: 'all', label: t('admin.broadcast.aud_all'), Icon: Users },
    { key: 'clients', label: t('admin.broadcast.aud_clients'), Icon: UserRound },
    { key: 'workers', label: t('admin.broadcast.aud_workers'), Icon: HardHat },
    { key: 'wilaya', label: t('admin.broadcast.aud_wilaya'), Icon: MapPin },
  ];

  const onSubmit = (e: FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !body.trim()) return;
    mut.mutate();
  };

  return (
    <div>
      <PageHeader title={t('admin.broadcast.title')} subtitle={t('admin.broadcast.subtitle')} />

      <div className="grid gap-6 lg:grid-cols-5">
        <Card className="lg:col-span-3">
          <form onSubmit={onSubmit} className="space-y-5">
            <Field label={t('admin.broadcast.notif_title')}>
              <Input value={title} onChange={(e) => setTitle(e.target.value)} maxLength={120} required />
            </Field>
            <Field label={t('admin.broadcast.notif_body')}>
              <textarea
                value={body}
                onChange={(e) => setBody(e.target.value)}
                maxLength={500}
                required
                rows={4}
                className="w-full rounded-xl border border-border bg-surface px-4 py-3 text-sm text-content placeholder:text-content-tertiary focus:border-primary/50 focus:outline-none focus:ring-2 focus:ring-primary/50"
              />
            </Field>

            <div>
              <span className="mb-2 block text-xs font-semibold text-content-secondary">
                {t('admin.broadcast.audience')}
              </span>
              <div className="grid grid-cols-2 gap-2.5 sm:grid-cols-4">
                {audiences.map((a) => (
                  <button
                    key={a.key}
                    type="button"
                    onClick={() => setAudience(a.key)}
                    className={cn(
                      'flex flex-col items-center gap-2 rounded-xl border p-3 text-xs font-semibold transition',
                      audience === a.key
                        ? 'border-primary bg-primary/10 text-primary'
                        : 'border-border text-content-secondary hover:bg-surface-variant',
                    )}
                  >
                    <a.Icon className="h-5 w-5" />
                    {a.label}
                  </button>
                ))}
              </div>
            </div>

            {audience === 'wilaya' && (
              <Field label={t('admin.broadcast.wilaya')}>
                <Input
                  type="number"
                  value={wilaya}
                  onChange={(e) => setWilaya(e.target.value)}
                  placeholder="31"
                  required
                />
              </Field>
            )}

            <Button type="submit" size="lg" loading={mut.isPending} className="w-full sm:w-auto">
              <Send className="h-4 w-4" />
              {mut.isPending ? t('admin.broadcast.sending') : t('admin.broadcast.send')}
            </Button>
          </form>
        </Card>

        {/* live preview */}
        <div className="lg:col-span-2">
          <span className="mb-2 block text-xs font-semibold text-content-secondary">Preview</span>
          <div className="card border-s-4 border-primary p-4">
            <div className="flex items-start gap-3">
              <div className="grid h-10 w-10 shrink-0 place-items-center rounded-xl bg-gradient-to-br from-primary to-violet text-sm font-black text-white">
                خ
              </div>
              <div className="min-w-0">
                <div className="font-bold text-content">{title || t('admin.broadcast.notif_title')}</div>
                <div className="mt-0.5 text-sm text-content-secondary">
                  {body || t('admin.broadcast.notif_body')}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
