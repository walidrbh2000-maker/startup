import { useTranslation } from 'react-i18next';
import { Link } from 'react-router-dom';
import { Logo } from '../../../components/layout/Logo';

export function Footer() {
  const { t } = useTranslation();
  const year = new Date().getFullYear();

  const cols = [
    {
      title: t('footer.product'),
      links: [
        { label: t('nav.services'), href: '#services' },
        { label: t('nav.how'), href: '#how' },
        { label: t('nav.download'), href: '#download' },
      ],
    },
    {
      title: t('footer.company'),
      links: [
        { label: t('nav.workers'), href: '#workers' },
        { label: t('footer.contact'), href: 'mailto:contact@khidmeti.com' },
      ],
    },
  ];

  return (
    <footer className="border-t border-border bg-bg-deep/50">
      <div className="container-x py-14">
        <div className="grid gap-10 md:grid-cols-2 lg:grid-cols-4">
          <div className="max-w-xs">
            <Logo />
            <p className="mt-4 text-sm text-content-secondary">{t('footer.tagline')}</p>
          </div>
          {cols.map((c) => (
            <div key={c.title}>
              <h4 className="text-sm font-bold text-content">{c.title}</h4>
              <ul className="mt-4 space-y-2.5">
                {c.links.map((l) => (
                  <li key={l.label}>
                    <a
                      href={l.href}
                      className="text-sm text-content-secondary transition hover:text-primary"
                    >
                      {l.label}
                    </a>
                  </li>
                ))}
              </ul>
            </div>
          ))}
          <div>
            <h4 className="text-sm font-bold text-content">{t('footer.legal')}</h4>
            <ul className="mt-4 space-y-2.5">
              <li>
                <Link
                  to="/legal/privacy"
                  className="text-sm text-content-secondary transition hover:text-primary"
                >
                  {t('footer.privacy')}
                </Link>
              </li>
              <li>
                <Link
                  to="/legal/terms"
                  className="text-sm text-content-secondary transition hover:text-primary"
                >
                  {t('footer.terms')}
                </Link>
              </li>
            </ul>
          </div>
        </div>

        <div className="mt-12 flex flex-col items-center justify-between gap-4 border-t border-border pt-6 sm:flex-row">
          <p className="text-xs text-content-secondary">
            © {year} {t('brand')}. {t('footer.rights')}
          </p>
          <Link
            to="/admin"
            className="text-xs font-semibold text-content-secondary transition hover:text-primary"
          >
            {t('nav.admin')}
          </Link>
        </div>
      </div>
    </footer>
  );
}
