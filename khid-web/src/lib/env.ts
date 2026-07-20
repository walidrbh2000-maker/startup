/**
 * True while rendering on the server (build-time prerender via renderToString).
 * Used to skip browser APIs and to render motion elements in their final,
 * visible state so crawlers see real content instead of opacity:0 nodes.
 */
export const IS_SERVER = typeof document === 'undefined';
