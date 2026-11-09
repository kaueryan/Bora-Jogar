// Verificacao estatica do beta Bora Jogar sem precisar de navegador/SDK.
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');
const base = path.resolve(__dirname, '..');
const html = fs.readFileSync(path.join(base, 'www/index.html'), 'utf8');
const sql = fs.readFileSync(path.join(base, 'database/schema.sql'), 'utf8');
const cfg = JSON.parse(fs.readFileSync(path.join(base, 'capacitor.config.json'), 'utf8'));
const scripts = [...html.matchAll(/<script(?:\s[^>]*)?>([\s\S]*?)<\/script>/g)].map(m => m[1]).filter(s => s.trim());
for (const s of scripts) new vm.Script(s, { filename: 'www/index.html inline' });
for (const id of ['mode-map', 'mode-list', 'map', 'event-list', 'event-form', 'profile-form','auth-gate','auth-signup','auth-login','authenticated-content','sign-out']) {
  if (!html.includes(`id="${id}"`)) throw new Error(`Falta elemento: ${id}`);
}
for (const city of ['Praia Grande','Santos','São Vicente','Mongaguá']) {
  if (!html.includes(city) || !sql.includes(city)) throw new Error(`Cidade ausente: ${city}`);
}
for (const tbl of ['public.games','public.registrations','public.profiles']) {
  if (!sql.includes(tbl)) throw new Error(`Tabela ausente: ${tbl}`);
}
if (html.includes('signInAnonymously()')) throw new Error('Login anônimo ainda presente no app');
for (const authFunction of ['signUp(', 'signInWithPassword(', 'email_confirmed_at']) {
  if (!html.includes(authFunction)) throw new Error(`Fluxo de conta ausente: ${authFunction}`);
}
if (cfg.webDir !== 'www' || !cfg.appId || !cfg.appName) throw new Error('Capacitor mal configurado');
console.log('OK: JS, login com e-mail, confirmação, perfis, RLS, cidades e Capacitor');
