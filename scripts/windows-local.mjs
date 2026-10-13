// Offline integration sandbox: synthetic frames, no chain or real Doom gameplay.
import {createServer as httpServer} from 'node:http';
import {readFile} from 'node:fs/promises';
import {dirname, resolve, sep} from 'node:path';
import {fileURLToPath} from 'node:url';
import {createRelayer, createServer} from '../stunts/doom-relayer/server.mjs';

const webRoot = resolve(dirname(fileURLToPath(import.meta.url)), '../web');
const relayer = createRelayer({mode: 'mock'});
const relayServer = createServer(relayer);
const mime = {'.html': 'text/html', '.js': 'text/javascript', '.css': 'text/css', '.json': 'application/json'};
const pageServer = httpServer(async (req, res) => {
  try {
    let path = decodeURIComponent(new URL(req.url, 'http://localhost').pathname);
    if (path.endsWith('/')) path += 'index.html';
    const target = resolve(webRoot, '.' + path);
    if (!target.startsWith(webRoot + sep)) { res.writeHead(403); res.end(); return; }
    const bytes = await readFile(target);
    const extension = target.slice(target.lastIndexOf('.'));
    res.writeHead(200, {'Content-Type': mime[extension] ?? 'application/octet-stream', 'Cache-Control': 'no-store'});
    res.end(bytes);
  } catch { res.writeHead(404); res.end('Not found'); }
});
relayServer.listen(18787, '127.0.0.1');
pageServer.listen(18080, '127.0.0.1', () => {
  console.log('OFFLINE MOCK: synthetic frames, no blockchain or real gameplay');
  console.log('http://127.0.0.1:18080/doom-play/?relayer=http://127.0.0.1:18787');
});
for (const server of [relayServer, pageServer]) server.on('error', error => { console.error(error.message); process.exit(1); });
for (const signal of ['SIGINT', 'SIGTERM']) process.on(signal, () => {
  relayServer.close(); pageServer.close(); process.exit(0);
});
