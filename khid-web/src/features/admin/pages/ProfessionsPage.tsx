import { useState } from 'react';
import { useTranslation } from 'react-i18next';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Plus, Pencil, Trash2 } from 'lucide-react';
import { adminApi } from '../api';
import { Button, Badge, Field, Input, Select } from '../../../components/ui';
import { Modal } from '../../../components/ui/Modal';
import { useToast } from '../../../components/ui/toast';
import { PageHeader, TableCard, Th, Td, LoadingRows, EmptyState } from '../components/shared';
import { categoryStyle } from '../../../lib/professionIcons';
import { useTheme } from '../../../lib/theme';
import type { Profession } from '../../../lib/types';
import type { ApiError } from '../../../lib/api';

const CATEGORIES = ['water', 'energy', 'building', 'service', 'transport'];

const EMPTY: Profession = {
  key: '',
  iconName: 'build_outlined',
  categoryKey: 'service',
  isActive: true,
  sortOrder: 0,
  labels: { fr: '', ar: '', en: '' },
  categoryLabels: { fr: '', ar: '', en: '' },
};

export function ProfessionsPage() {
  const { t } = useTranslation();
  const { lang } = useTheme();
  const toast = useToast();
  const qc = useQueryClient();

  const [editing, setEditing] = useState<Profession | null>(null);
  const [isNew, setIsNew] = useState(false);

  const { data, isLoading } = useQuery({ queryKey: ['admin-professions'], queryFn: adminApi.professions });

  const invalidate = () => void qc.invalidateQueries({ queryKey: ['admin-professions'] });
  const onErr = (e: unknown) => toast((e as ApiError)?.message ?? t('common.error'), 'error');

  const saveMut = useMutation({
    mutationFn: (p: Profession) =>
      isNew
        ? adminApi.createProfession(stripId(p))
        : adminApi.updateProfession(p.key, stripId(p)),
    onSuccess: () => {
      invalidate();
      setEditing(null);
      toast(t('common.save'), 'success');
    },
    onError: onErr,
  });
  const toggleMut = useMutation({
    mutationFn: (p: Profession) => adminApi.updateProfession(p.key, { isActive: !p.isActive }),
    onSuccess: invalidate,
    onError: onErr,
  });
  const delMut = useMutation({
    mutationFn: (key: string) => adminApi.deleteProfession(key),
    onSuccess: invalidate,
    onError: onErr,
  });

  const openNew = () => {
    setIsNew(true);
    setEditing({ ...EMPTY, labels: { ...EMPTY.labels }, categoryLabels: { ...EMPTY.categoryLabels } });
  };
  const openEdit = (p: Profession) => {
    setIsNew(false);
    setEditing({ ...p, labels: { ...p.labels }, categoryLabels: { ...p.categoryLabels } });
  };

  return (
    <div>
      <PageHeader
        title={t('admin.professions.title')}
        action={
          <Button onClick={openNew}>
            <Plus className="h-4 w-4" />
            {t('admin.professions.add')}
          </Button>
        }
      />

      {isLoading ? (
        <LoadingRows />
      ) : !data || data.length === 0 ? (
        <EmptyState />
      ) : (
        <TableCard>
          <thead>
            <tr>
              <Th>{t('admin.professions.label')}</Th>
              <Th>{t('admin.professions.key')}</Th>
              <Th>{t('admin.professions.category')}</Th>
              <Th>{t('admin.professions.order')}</Th>
              <Th>{t('admin.users.status')}</Th>
              <Th className="text-end">{t('admin.users.actions')}</Th>
            </tr>
          </thead>
          <tbody>
            {data.map((p: Profession) => {
              const { Icon, className, bg } = categoryStyle(p.categoryKey);
              return (
                <tr key={p.key} className="transition hover:bg-surface-variant/50">
                  <Td>
                    <div className="flex items-center gap-3">
                      <div className={`grid h-9 w-9 place-items-center rounded-lg ${bg}`}>
                        <Icon className={`h-4 w-4 ${className}`} />
                      </div>
                      <span className="font-semibold text-content">
                        {p.labels[lang as 'fr' | 'ar' | 'en'] || p.labels.fr}
                      </span>
                    </div>
                  </Td>
                  <Td>
                    <code className="rounded bg-surface-variant px-1.5 py-0.5 text-xs text-content-secondary">
                      {p.key}
                    </code>
                  </Td>
                  <Td>
                    <Badge tone="neutral">{p.categoryKey}</Badge>
                  </Td>
                  <Td>
                    <span className="text-sm text-content">{p.sortOrder}</span>
                  </Td>
                  <Td>
                    <button onClick={() => toggleMut.mutate(p)}>
                      {p.isActive ? (
                        <Badge tone="success">{t('admin.professions.active')}</Badge>
                      ) : (
                        <Badge tone="neutral">{t('admin.professions.inactive')}</Badge>
                      )}
                    </button>
                  </Td>
                  <Td className="text-end">
                    <div className="flex justify-end gap-2">
                      <Button size="sm" variant="ghost" onClick={() => openEdit(p)}>
                        <Pencil className="h-4 w-4" />
                      </Button>
                      <Button
                        size="sm"
                        variant="danger"
                        onClick={() => {
                          if (confirm(t('admin.professions.delete_confirm'))) delMut.mutate(p.key);
                        }}
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  </Td>
                </tr>
              );
            })}
          </tbody>
        </TableCard>
      )}

      <Modal
        open={!!editing}
        onClose={() => setEditing(null)}
        title={isNew ? t('admin.professions.add') : t('admin.professions.title')}
        footer={
          <>
            <Button variant="outline" onClick={() => setEditing(null)}>
              {t('admin.professions.cancel')}
            </Button>
            <Button loading={saveMut.isPending} onClick={() => editing && saveMut.mutate(editing)}>
              {isNew ? t('admin.professions.create') : t('admin.professions.save')}
            </Button>
          </>
        }
      >
        {editing && (
          <ProfessionForm value={editing} isNew={isNew} onChange={setEditing} />
        )}
      </Modal>
    </div>
  );
}

function stripId(p: Profession): Omit<Profession, '_id'> {
  const { _id, ...rest } = p;
  void _id;
  return rest;
}

function ProfessionForm({
  value,
  isNew,
  onChange,
}: {
  value: Profession;
  isNew: boolean;
  onChange: (p: Profession) => void;
}) {
  const { t } = useTranslation();
  const set = (patch: Partial<Profession>) => onChange({ ...value, ...patch });
  const setLabel = (lng: 'fr' | 'ar' | 'en', v: string) =>
    onChange({ ...value, labels: { ...value.labels, [lng]: v } });
  const setCat = (lng: 'fr' | 'ar' | 'en', v: string) =>
    onChange({ ...value, categoryLabels: { ...value.categoryLabels, [lng]: v } });

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-2 gap-3">
        <Field label={t('admin.professions.key')}>
          <Input
            value={value.key}
            disabled={!isNew}
            onChange={(e) => set({ key: e.target.value.trim() })}
            placeholder="plumber"
          />
        </Field>
        <Field label={t('admin.professions.category')}>
          <Select value={value.categoryKey} onChange={(e) => set({ categoryKey: e.target.value })}>
            {CATEGORIES.map((c) => (
              <option key={c} value={c}>
                {c}
              </option>
            ))}
          </Select>
        </Field>
        <Field label={t('admin.professions.icon')}>
          <Input value={value.iconName} onChange={(e) => set({ iconName: e.target.value })} />
        </Field>
        <Field label={t('admin.professions.order')}>
          <Input
            type="number"
            value={value.sortOrder}
            onChange={(e) => set({ sortOrder: Number(e.target.value) })}
          />
        </Field>
      </div>

      <div className="grid grid-cols-3 gap-3">
        <Field label={t('admin.professions.label_fr')}>
          <Input value={value.labels.fr} onChange={(e) => setLabel('fr', e.target.value)} />
        </Field>
        <Field label={t('admin.professions.label_ar')}>
          <Input value={value.labels.ar} onChange={(e) => setLabel('ar', e.target.value)} dir="rtl" />
        </Field>
        <Field label={t('admin.professions.label_en')}>
          <Input value={value.labels.en} onChange={(e) => setLabel('en', e.target.value)} />
        </Field>
      </div>

      <div className="grid grid-cols-3 gap-3">
        <Field label={t('admin.professions.cat_label_fr')}>
          <Input value={value.categoryLabels.fr} onChange={(e) => setCat('fr', e.target.value)} />
        </Field>
        <Field label={t('admin.professions.cat_label_ar')}>
          <Input value={value.categoryLabels.ar} onChange={(e) => setCat('ar', e.target.value)} dir="rtl" />
        </Field>
        <Field label={t('admin.professions.cat_label_en')}>
          <Input value={value.categoryLabels.en} onChange={(e) => setCat('en', e.target.value)} />
        </Field>
      </div>

      <label className="flex items-center gap-2.5">
        <input
          type="checkbox"
          checked={value.isActive}
          onChange={(e) => set({ isActive: e.target.checked })}
          className="h-4 w-4 accent-primary"
        />
        <span className="text-sm font-medium text-content">{t('admin.professions.active')}</span>
      </label>
    </div>
  );
}
