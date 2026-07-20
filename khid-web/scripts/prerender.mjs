// Prerenders the public marketing routes into static HTML after `vite build`.
//
//   node node_modules/vite/bin/vite.js build                      → dist/ (client)
//   node node_modules/vite/bin/vite.js build --ssr src/entry-server.tsx --outDir dist-ssr
//   node scripts/prerender.mjs                                    → injects HTML
//
// Each route's rendered markup replaces <div id="root"></div> in dist/index.html,
// with per-route <title> + canonical. The client bundle re-renders over it on
// load (createRoot.render replaces the static tree), so behaviour is unchanged —
// crawlers and social scrapers just get real content instead of an empty div.
import { readFile, writeFile, mkdir, rm } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = path.dirname(fileURLToPath(import.meta.url));
const dist = path.join(root, '..', 'dist');
const ssrEntry = path.join(root, '..', 'dist-ssr', 'entry-server.js');

const ORIGIN = 'https://khidmeti.com';

// Public routes only — /admin stays client-rendered behind auth.
const ROUTES = [
  { url: '/', file: 'index.html', title: 'خدمتي · Khidmeti — حرفيّ موثوق في دقائق' },
  {
    url: '/legal/privacy',
    file: 'legal/privacy/index.html',
    title: 'سياسة الخصوصية · Khidmeti',
  },
  {
    url: '/legal/terms',
    file: 'legal/terms/index.html',
    title: 'شروط الاستخدام · Khidmeti',
  },
];

const { render } = await import(ssrEntry);
const template = await readFile(path.join(dist, 'index.html'), 'utf-8');

for (const route of ROUTES) {
  const appHtml = render(route.url);
  let html = template.replace('<div id="root"></div>', `<div id="root">${appHtml}</div>`);
  html = html.replace(/<title>[^<]*<\/title>/, `<title>${route.title}</title>`);
  html = html.replace(
    /<link rel="canonical" href="[^"]*" \/>/,
    `<link rel="canonical" href="${ORIGIN}${route.url === '/' ? '/' : route.url}" />`,
  );

  const outFile = path.join(dist, route.file);
  await mkdir(path.dirname(outFile), { recursive: true });
  await writeFile(outFile, html);
  console.log(`✓ prerendered ${route.url} → dist/${route.file} (${appHtml.length} bytes of markup)`);
}

// The SSR bundle is a build artifact only — not needed for deployment.
await rm(path.join(root, '..', 'dist-ssr'), { recursive: true, force: true });
console.log('✓ cleaned dist-ssr');
