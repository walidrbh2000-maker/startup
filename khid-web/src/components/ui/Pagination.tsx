import { ChevronLeft, ChevronRight } from 'lucide-react';
import { useTranslation } from 'react-i18next';
import { Button } from './index';

export function Pagination({
  page,
  pages,
  total,
  onPage,
}: {
  page: number;
  pages: number;
  total: number;
  onPage: (p: number) => void;
}) {
  const { t } = useTranslation();
  if (pages <= 1 && total === 0) return null;
  return (
    <div className="flex items-center justify-between gap-3 pt-4 text-sm text-content-secondary">
      <span>
        {total} {t('common.results')}
      </span>
      <div className="flex items-center gap-2">
        <span>{t('common.page', { page, pages })}</span>
        {/* Chevrons stay visually consistent regardless of dir via logical order */}
        <Button
          variant="outline"
          size="sm"
          disabled={page <= 1}
          onClick={() => onPage(page - 1)}
          aria-label={t('common.prev')}
        >
          <ChevronLeft className="h-4 w-4 rtl:hidden" />
          <ChevronRight className="hidden h-4 w-4 rtl:block" />
        </Button>
        <Button
          variant="outline"
          size="sm"
          disabled={page >= pages}
          onClick={() => onPage(page + 1)}
          aria-label={t('common.next')}
        >
          <ChevronRight className="h-4 w-4 rtl:hidden" />
          <ChevronLeft className="hidden h-4 w-4 rtl:block" />
        </Button>
      </div>
    </div>
  );
}
