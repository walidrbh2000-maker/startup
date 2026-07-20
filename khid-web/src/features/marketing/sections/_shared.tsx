import { motion } from 'framer-motion';
import { type ReactNode } from 'react';
import { cn } from '../../../lib/cn';
import { IS_SERVER } from '../../../lib/env';

/** Fade-and-rise on scroll into view. Renders a plain, visible div when
 *  prerendering so crawlers never see opacity:0 content. */
export function Reveal({
  children,
  delay = 0,
  className,
}: {
  children: ReactNode;
  delay?: number;
  className?: string;
}) {
  if (IS_SERVER) return <div className={className}>{children}</div>;
  return (
    <motion.div
      className={className}
      initial={{ opacity: 0, y: 24 }}
      whileInView={{ opacity: 1, y: 0 }}
      viewport={{ once: true, margin: '-80px' }}
      transition={{ duration: 0.55, delay, ease: [0.22, 1, 0.36, 1] }}
    >
      {children}
    </motion.div>
  );
}

export function SectionHeading({
  kicker,
  title,
  subtitle,
  center = true,
}: {
  kicker: string;
  title: string;
  subtitle?: string;
  center?: boolean;
}) {
  return (
    <div className={cn('max-w-2xl', center && 'mx-auto text-center')}>
      <Reveal>
        <span className="inline-flex items-center rounded-full bg-primary/10 px-3 py-1 text-xs font-bold uppercase tracking-wide text-primary">
          {kicker}
        </span>
      </Reveal>
      <Reveal delay={0.05}>
        <h2 className="mt-4 font-display text-3xl font-extrabold leading-tight text-content sm:text-4xl">
          {title}
        </h2>
      </Reveal>
      {subtitle && (
        <Reveal delay={0.1}>
          <p className="mt-3 text-base text-content-secondary sm:text-lg">{subtitle}</p>
        </Reveal>
      )}
    </div>
  );
}

export function Section({
  id,
  children,
  className,
}: {
  id?: string;
  children: ReactNode;
  className?: string;
}) {
  return (
    <section id={id} className={cn('py-20 sm:py-28', className)}>
      <div className="container-x">{children}</div>
    </section>
  );
}
