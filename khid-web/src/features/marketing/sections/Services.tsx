import { useTranslation } from 'react-i18next';
import { useQuery } from '@tanstack/react-query';
import { http } from '../../../lib/api';
import type { ProfessionDto } from '../../../lib/types';
import { categoryStyle } from '../../../lib/professionIcons';
import { Section, SectionHeading, Reveal } from './_shared';
import { Spinner } from '../../../components/ui';
import { useTheme } from '../../../lib/theme';

export function Services() {
  const { t } = useTranslation();
  const { lang } = useTheme();

  const { data, isLoading, isError } = useQuery({
    queryKey: ['professions', lang],
    queryFn: () => http.get<ProfessionDto[]>('/professions', { lang }),
    staleTime: 1000 * 60 * 30,
  });

  const items = (data ?? []).slice(0, 12);

  return (
    <Section id="services">
      <SectionHeading kicker={t('services.kicker')} title={t('services.title')} subtitle={t('services.subtitle')} />

      <div className="mt-14">
        {isLoading && (
          <div className="flex justify-center py-10">
            <Spinner />
          </div>
        )}
        {isError && <p className="text-center text-content-secondary">{t('services.error')}</p>}

        <div className="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">
          {items.map((p, i) => {
            const { Icon, className, bg } = categoryStyle(p.categoryKey);
            return (
              <Reveal key={p.key} delay={(i % 4) * 0.05}>
                <div className="group card flex h-full flex-col items-start gap-3 p-5 transition-all duration-300 hover:-translate-y-1 hover:border-primary/40 hover:shadow-glow">
                  <div className={`grid h-12 w-12 place-items-center rounded-xl ${bg} transition group-hover:scale-110`}>
                    <Icon className={`h-6 w-6 ${className}`} />
                  </div>
                  <div>
                    <div className="font-bold text-content">{p.label}</div>
                    <div className="text-xs text-content-secondary">{p.categoryLabel}</div>
                  </div>
                </div>
              </Reveal>
            );
          })}
        </div>

        {!isLoading && !isError && (
          <p className="mt-8 text-center text-sm font-semibold text-primary">{t('services.cta')}</p>
        )}
      </div>
    </Section>
  );
}
