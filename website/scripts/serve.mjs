import { createServer } from 'node:http';
import { readFile, stat } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { extname } from 'node:path';

// Preview server that reproduces the production URL shape (GitHub Pages serves the site under
// /scrypath/ and 404s at the origin root).
//
//   --port <n>     port to bind; 0 binds an ephemeral port and the startup line prints the real one
//                  (default 4173)
//   --base <path>  serve the output only under this prefix (default /); every other path, including
//                  /, answers 404
//   --dir <path>   directory to serve (default website/dist)
//   --log          after the startup line, write one `<METHOD> <pathname> <status>` line per request
//   --parent-pipe  exit when stdin closes, so a parent that dies cannot leave this server running
const websiteDir = fileURLToPath(new URL('..', import.meta.url));
const args = process.argv.slice(2);

function value(name) {
  const index = args.indexOf(name);
  if (index < 0) {
    return undefined;
  }
  const next = args[index + 1];
  if (next === undefined || next.startsWith('--')) {
    throw new Error(`${name} needs a value`);
  }
  return next;
}

const portValue = value('--port');
const port = portValue === undefined ? 4173 : Number(portValue);
if (!Number.isInteger(port) || port < 0 || port > 65535) {
  throw new Error(`Invalid --port ${portValue}`);
}

const dirValue = value('--dir');
const distDir = path.resolve(dirValue ?? path.join(websiteDir, 'dist'));
const dirLabel = dirValue ?? 'website/dist';

let base = value('--base') ?? '/';
if (!base.startsWith('/')) {
  base = `/${base}`;
}
if (!base.endsWith('/')) {
  base = `${base}/`;
}

const logRequests = args.includes('--log');

const mimeTypes = {
  '.css': 'text/css; charset=utf-8',
  '.html': 'text/html; charset=utf-8',
  '.ico': 'image/x-icon',
  '.js': 'text/javascript; charset=utf-8',
  '.json': 'application/json; charset=utf-8',
  '.png': 'image/png',
  '.svg': 'image/svg+xml; charset=utf-8',
  '.txt': 'text/plain; charset=utf-8',
  '.woff2': 'font/woff2',
  '.xml': 'application/xml; charset=utf-8'
};

function inside(child, parent) {
  const relative = path.relative(parent, child);
  return relative === '' || (!relative.startsWith('..') && !path.isAbsolute(relative));
}

const server = createServer(async (req, res) => {
  let rawPathname = '/';
  const send = (status, headers, body) => {
    res.writeHead(status, headers);
    res.end(req.method === 'HEAD' ? undefined : body);
    if (logRequests) {
      process.stdout.write(`${req.method} ${rawPathname} ${status}\n`);
    }
  };
  const text = { 'content-type': 'text/plain; charset=utf-8' };

  try {
    if (req.method !== 'GET' && req.method !== 'HEAD') {
      send(405, { ...text, allow: 'GET, HEAD' }, 'Method not allowed');
      return;
    }

    const url = new URL(req.url, 'http://127.0.0.1');
    rawPathname = url.pathname;
    const pathname = decodeURIComponent(url.pathname);

    if (!pathname.startsWith(base)) {
      // /scrypath answers like Pages does for the directory root: a redirect to the slash form.
      if (`${pathname}/` === base) {
        send(301, { ...text, location: base }, '');
      } else {
        send(404, text, 'Not found');
      }
      return;
    }

    let relative = pathname.slice(base.length);
    if (relative === '' || relative.endsWith('/')) {
      relative += 'index.html';
    }

    const filePath = path.resolve(distDir, relative);
    if (!inside(filePath, distDir)) {
      send(403, text, 'Forbidden');
      return;
    }

    const info = await stat(filePath);
    if (info.isDirectory()) {
      // A directory request without the trailing slash redirects to the slash form, as Pages does.
      send(301, { ...text, location: `${pathname}/` }, '');
      return;
    }

    const data = await readFile(filePath);
    send(200, { 'content-type': mimeTypes[extname(filePath)] ?? 'application/octet-stream' }, data);
  } catch (error) {
    if (error instanceof URIError) {
      send(400, text, 'Bad request');
    } else {
      send(404, text, 'Not found');
    }
  }
});

server.on('error', error => {
  process.stderr.write(`Preview server failed: ${error.message}\n`);
  process.exit(1);
});

server.listen(port, '127.0.0.1', () => {
  process.stdout.write(`Serving ${dirLabel} on http://127.0.0.1:${server.address().port}${base}\n`);
});

if (args.includes('--parent-pipe')) {
  process.stdin.resume();
  process.stdin.on('end', () => process.exit(0));
  process.stdin.on('close', () => process.exit(0));
}
