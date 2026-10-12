import http from 'node:http';
import { randomBytes, scryptSync, timingSafeEqual } from 'node:crypto';

const email = process.env.DEMO_EMAIL;
const password = process.env.DEMO_PASSWORD;
if (!email || !password || password.length < 12) {
  throw new Error('Set DEMO_EMAIL and DEMO_PASSWORD (at least 12 characters) in backend/.env');
}
const salt = randomBytes(16);
const passwordHash = scryptSync(password, salt, 64);
const sessions = new Map();
const ttl = 60 * 60 * 1000;
let attempts = 0;
setInterval(() => { attempts = 0; }, 60_000).unref();
setInterval(() => {
  for (const [id, expiry] of sessions) if (expiry <= Date.now()) sessions.delete(id);
}, 60_000).unref();
const cookie = (id, maxAge) => `session=${id}; HttpOnly; SameSite=Strict; Path=/; Max-Age=${maxAge}${process.env.COOKIE_SECURE === 'true' ? '; Secure' : ''}`;
const server = http.createServer(async (req, res) => {
  const path = req.url.split('?')[0];
  const started = Date.now();
  res.on('finish', () => console.log(JSON.stringify({service:'backend', method:req.method, path: ['/api/health','/api/login','/api/me','/api/logout'].includes(path) ? path : 'unknown', status:res.statusCode, durationMs:Date.now()-started})));
  const send = (status, body, headers={}) => {
    res.writeHead(status, {'Content-Type':'application/json', 'Cache-Control':'no-store', 'X-Content-Type-Options':'nosniff', ...headers});
    res.end(JSON.stringify(body));
  };
  const id = /(?:^|;\s*)session=([a-f0-9]{64})(?:;|$)/.exec(req.headers.cookie || '')?.[1];
  if (req.method === 'GET' && path === '/api/health') return send(200, {status:'ok', service:'backend'});
  if (req.method === 'GET' && path === '/api/me') {
    if (!id || (sessions.get(id) || 0) <= Date.now()) return send(401, {message:'Please sign in.'});
    return send(200, {user:{name:'Tanzeel', email}});
  }
  if (req.method === 'POST') {
    if (req.headers.origin !== (process.env.APP_ORIGIN || 'http://localhost:3000')) return send(403, {message:'Origin not allowed.'});
    if (path === '/api/logout') {
      sessions.delete(id);
      return send(200, {message:'Signed out.'}, {'Set-Cookie':cookie('',0)});
    }
    if (path === '/api/login') {
      if (++attempts > 20) return send(429, {message:'Too many attempts. Try again in one minute.'}, {'Retry-After':'60'});
      if (!req.headers['content-type']?.startsWith('application/json')) return send(415, {message:'JSON required.'});
      let body = '';
      try {
        for await (const chunk of req) {
          body += chunk;
          if (Buffer.byteLength(body) > 4096) { send(413, {message:'Request too large.'}); return; }
        }
        const input = JSON.parse(body);
        if (!input || typeof input.email !== 'string' || typeof input.password !== 'string') return send(400,{message:'Email and password are required.'});
        const matches = timingSafeEqual(scryptSync(input.password,salt,64), passwordHash);
        if (input.email !== email || !matches) return send(401,{message:'Incorrect email or password.'});
        if (id) sessions.delete(id);
        const token = randomBytes(32).toString('hex');
        sessions.set(token,Date.now()+ttl);
        return send(200,{user:{name:'Tanzeel',email}}, {'Set-Cookie':cookie(token,ttl/1000)});
      } catch { return send(400,{message:'Invalid request.'}); }
    }
  }
  send(404,{message:'Not found.'});
});
server.requestTimeout = 15_000;
server.listen(Number(process.env.PORT || 5000), process.env.HOST || '127.0.0.1', () => console.log(JSON.stringify({service:'backend',event:'started',port:Number(process.env.PORT || 5000)})));
