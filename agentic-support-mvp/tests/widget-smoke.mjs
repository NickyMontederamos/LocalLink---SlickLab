import fs from 'node:fs';
const path=new URL('../widget/src/agentic-support-widget.js',import.meta.url);
const source=fs.readFileSync(path,'utf8');
const required=[
  "customElements.define('agentic-support'",
  "attachShadow({mode:'open'})",
  "role=\"dialog\"",
  "role=\"status\"",
  "Idempotency-Key",
  "/handoffs",
  "api-base",
  "X-Tenant-Key"
];
const missing=required.filter(x=>!source.includes(x));
if(missing.length){console.error('Missing widget contracts:',missing);process.exit(1);}
if(source.includes('sk-')||source.includes('password=')){console.error('Potential secret detected');process.exit(1);}
console.log('Widget smoke checks passed:',required.length);
