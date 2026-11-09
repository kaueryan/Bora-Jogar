// Substitui os dados PUBLICOS apenas quando fornecidos; caso contrário,
// usa a URL e chave publishable que já estão no www/config.js.
const fs = require('node:fs');
const path = require('node:path');
const file = path.join(__dirname, '..', 'www', 'config.js');
const data = fs.readFileSync(file,'utf8');
const match = data.match(/window\.BORA_CONFIG\s*=\s*(\{[\s\S]*?\})\s*;/);
if(!match) throw Error('www/config.js inválido ou ausente');
const existing = JSON.parse(match[1]);
const url = (process.env.SUPABASE_URL || existing.supabaseUrl || '').trim();
const key = (process.env.SUPABASE_PUBLISHABLE_KEY || existing.supabaseAnonKey || '').trim();
if(!/^https:\/\/[a-z0-9-]+\.supabase\.co$/i.test(url)) throw Error('URL Supabase inválida');
if(!key || !(key.startsWith('sb_publishable_') || key.startsWith('eyJ')) || key.startsWith('sb_secret_')) throw Error('Chave do app deve ser pública (publishable/anon)');
fs.writeFileSync(file, '// Valores públicos para o app. Nunca coloque chave secreta.\nwindow.BORA_CONFIG = '+JSON.stringify({supabaseUrl:url,supabaseAnonKey:key},null,2)+';\n','utf8');
console.log('OK: dados públicos do Supabase configurados para os aplicativos.');
