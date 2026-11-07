import { readFileSync, existsSync } from 'node:fs';
import { resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import assert from 'node:assert/strict';
const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const site = resolve(root, 'site');
const html = readFileSync(resolve(site,'index.html'),'utf8');
const css = readFileSync(resolve(site,'assets/styles.css'),'utf8');
const js = readFileSync(resolve(site,'assets/app.js'),'utf8');
const local = [];
for (const id of ['main','overview','projects','lab','architecture','verification','about']) {
  assert.match(html, new RegExp('id="' + id + '"'), 'Missing ' + id + ' section');
}
assert.match(html, /<html lang="en">/);
assert.match(html, /href="#main"[^>]*>Skip to main content/);
assert.match(html, /<nav aria-label="Primary navigation">/);
assert.match(html, /<main id="main">/);
assert.match(html, /<footer class="site-footer">/);
assert.match(html, /<meta name="robots" content="noindex, nofollow">/);
assert.match(html, /connect-src 'none'/);
assert.match(html, /<label for="prefix">/);
assert.match(html, /role="alert"/);
assert.match(html, /role="status"/);
assert.match(css, /:focus-visible/);
assert.match(css, /prefers-reduced-motion:reduce/);
assert.match(css, /max-width:640px/);
assert.match(js, /\.textContent/);
assert.doesNotMatch(js, /\b(?:fetch|XMLHttpRequest|WebSocket|localStorage|sessionStorage)\b/);
for (const [,attr,url] of html.matchAll(/\b(src|href)="([^"]+)"/g)) {
  if (/^(https?:|mailto:|tel:)/.test(url)) continue;
  assert(!url.startsWith('/'), 'Root-relative path: ' + url);
  if (url.startsWith('#')) {
    assert(html.includes('id="' + url.slice(1) + '"'), 'Missing fragment ' + url);
  } else {
    const path = resolve(site,url.split(/[?#]/)[0]);
    assert(path.startsWith(site + '/'), 'Unsafe relative path ' + url);
    assert(existsSync(path), 'Missing local asset ' + url);
    local.push(url);
  }
}
for (const [,url] of js.matchAll(/from\s+['"]([^'"]+)['"]/g)) {
  assert(url.startsWith('.'), 'Nonlocal import ' + url);
  assert(existsSync(resolve(site,'assets',url)), 'Missing module ' + url);
}
console.log('Static checks passed: ' + local.length + ' local assets, navigation, privacy hooks, accessibility selectors, module path.');
