import {createServer} from 'node:http';
import {readFile, access} from 'node:fs/promises';
import {resolve, extname} from 'node:path';
const directory = process.argv[2];
const port = Number(process.argv[3] ?? 18081);
if (!directory) throw new Error('Supply a Dwasm browser build directory.');
const root = resolve(directory);
const allowed = new Set(['index.html', 'index.js', 'index.wasm', 'index.data', 'agent_api.js', 'teacher_runner.js']);
for (const name of ['index.html', 'index.js', 'index.wasm', 'index.data']) await access(resolve(root, name));
const types = {'.html':'text/html', '.js':'text/javascript', '.wasm':'application/wasm', '.data':'application/octet-stream'};
const server = createServer(async (req,res) => {
  try {
    const name = new URL(req.url, 'http://localhost').pathname.slice(1) || 'index.html';
    if (!allowed.has(name)) { res.writeHead(404); res.end(); return; }
    let bytes = await readFile(resolve(root,name));
    if (name === 'index.html') {
      let html = bytes.toString();
      html = html.replace('</head>', '<style>html,body{overflow:hidden}canvas.emscripten{max-width:100vw;max-height:calc(100vh - 44px);width:auto;height:auto}#playbar{height:44px;display:flex;align-items:center;justify-content:center;gap:12px;font:14px Arial;color:white;background:#171717}#playbar button{padding:6px 12px;cursor:pointer}</style></head>');
      html = html.replace(/<body[^>]*>/, '$&<div id="playbar"><span>LOCAL PLAY · W/S: move, A/D: strafe, left/right: turn · Ctrl: fire · Space: doors · Esc: menu</span><button onclick="document.documentElement.requestFullscreen();document.getElementById(\'canvas\').focus()">Fullscreen</button></div>');
      bytes = Buffer.from(html);
    }
    res.writeHead(200, {'Content-Type':types[extname(name)], 'Cache-Control':'no-store'}); res.end(bytes);
  } catch {res.writeHead(404);res.end('Not found');}
});
server.on('error',error=>{console.error(error.message);process.exit(1)});
server.listen(port,'127.0.0.1',()=>console.log(`Real local gameplay: http://127.0.0.1:${port}/index.html?-warp&1&1&-skill&3`));
