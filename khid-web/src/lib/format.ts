// Small formatting helpers shared across the admin tables.

export function formatDate(iso: string | null | undefined, lang = 'fr'): string {
  if (!iso) return '—';
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return '—';
  const locale = lang === 'ar' ? 'ar-DZ' : lang === 'en' ? 'en-GB' : 'fr-DZ';
  return new Intl.DateTimeFormat(locale, { dateStyle: 'medium' }).format(d);
}

export function formatPrice(value: number | null | undefined): string {
  if (value === null || value === undefined) return '—';
  return `${value.toLocaleString('fr-DZ')} DA`;
}

export function initials(name: string): string {
  return name
    .trim()
    .split(/\s+/)
    .slice(0, 2)
    .map((p) => p[0]?.toUpperCase() ?? '')
    .join('');
}
