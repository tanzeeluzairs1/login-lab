import http from 'node:http';
import { readFile } from 'node:fs/promises';
const backend = new URL(process.env.BACKEND_URL || 'http://127.0.0.1:5000');
const assets = {'/':['index.html','text/html'], '/styles.css':['styles.css','text/css'], '/app.js':['app.js','text/javascript']};
http.createServer(async (req,res) => {
  const path = req.url.split('?')[0];
  if (path.startsWith('/api/')) {
    const upstream = http.request({hostname:backend.hostname,port:backend.port || 80,path:req.url,method:req.method,headers:{...req.headers,host:backend.host}}, response => {
      res.writeHead(response.statusCode,response.headers);
      response.pipe(res);
    });
    upstream.setTimeout(10_000, () => upstream.destroy());
    upstream.on('error', () => {
      console.error(JSON.stringify({service:'frontend',event:'backend_unavailable'}));
      if (!res.headersSent) {res.writeHead(502,{'Content-Type':'application/json'});res.end(JSON.stringify({message:'Backend unavailable. Start the backend and try again.'}));}
      else res.destroy();
    });
    req.pipe(upstream);
    return;
  }
  const asset=assets[path];
  if (!asset || !['GET','HEAD'].includes(req.method)) {res.writeHead(404);res.end('Not found');return;}
  try {
    const body = await readFile(new URL(`./public/${asset[0]}`, import.meta.url));
    res.writeHead(200,{'Content-Type':`${asset[1]}; charset=utf-8`,'X-Content-Type-Options':'nosniff','Content-Security-Policy':"default-src 'self'; frame-ancestors 'none'; base-uri 'none'; form-action 'self'",'Cache-Control':'no-store'});
    res.end(req.method === 'HEAD' ? undefined : body);
  } catch {res.writeHead(500);res.end('Unable to load page');}
}).listen(Number(process.env.PORT || 3000),process.env.HOST || '127.0.0.1',() => console.log(JSON.stringify({service:'frontend',event:'started',port:Number(process.env.PORT || 3000)})));
