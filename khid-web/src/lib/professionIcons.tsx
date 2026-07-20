// Map backend profession category → a lucide icon + accent colour, so the web
// marketing grid renders nicely without the app's Material icon set.
import {
  Droplets,
  Zap,
  Hammer,
  Sparkles,
  Truck,
  Wrench,
  type LucideIcon,
} from 'lucide-react';

interface CatStyle {
  Icon: LucideIcon;
  className: string; // text colour class
  bg: string; // background tint class
}

const MAP: Record<string, CatStyle> = {
  water: { Icon: Droplets, className: 'text-indigo', bg: 'bg-indigo/12' },
  energy: { Icon: Zap, className: 'text-warning', bg: 'bg-warning/12' },
  building: { Icon: Hammer, className: 'text-violet', bg: 'bg-violet/12' },
  service: { Icon: Sparkles, className: 'text-emerald', bg: 'bg-emerald/12' },
  transport: { Icon: Truck, className: 'text-pink', bg: 'bg-pink/12' },
};

export function categoryStyle(categoryKey: string): CatStyle {
  return MAP[categoryKey] ?? { Icon: Wrench, className: 'text-primary', bg: 'bg-primary/12' };
}
