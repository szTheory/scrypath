import { spawn } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const serveScript = fileURLToPath(new URL('../serve.mjs', import.meta.url));
const STARTUP_LINE = /^Serving .* on (http:\/\/127\.0\.0\.1:(\d+))(\/\S*)?$/;
const REQUEST_LINE = /^([A-Z]+) (\S+) (\d{3})$/;

// Starts serve.mjs on an ephemeral port (--port 0) and resolves once its startup line names the real
// port, so no caller depends on a fixed port or touches the network.
//
//   dir   directory to serve (the server reads files per request, so it may still be empty)
//   base  URL prefix the directory is served under (default /)
//   log   collect `<METHOD> <pathname> <status>` request lines into `requests` (default true)
//
// Resolves with { origin, baseUrl, requests, flush, stop }. Rejects with the child's stderr when the
// child exits before it is ready.
export function startServer({ dir, base = '/', log = true, timeoutMs = 10000 } = {}) {
  const normalisedBase = `${base.startsWith('/') ? '' : '/'}${base}${base.endsWith('/') ? '' : '/'}`;
  const args = [serveScript, '--port', '0', '--base', normalisedBase, '--parent-pipe'];
  if (dir) {
    args.push('--dir', path.resolve(dir));
  }
  if (log) {
    args.push('--log');
  }

  const child = spawn(process.execPath, args, { stdio: ['pipe', 'pipe', 'pipe'] });
  const requests = [];
  let stdoutBuffer = '';
  let stderrText = '';
  let exited = false;
  let ready = false;
  let origin = '';

  child.stderr.on('data', chunk => {
    stderrText += String(chunk);
  });

  const exit = new Promise(resolve => {
    child.on('exit', code => {
      exited = true;
      resolve(code);
    });
  });

  const handle = {
    get origin() {
      return origin;
    },
    get baseUrl() {
      return `${origin}${normalisedBase}`;
    },
    requests,
    // Resolves once every request line the server wrote before now has been read. The barrier is a
    // request to the origin root, which is outside any base other than / and so never counts as a
    // missing asset.
    async flush() {
      const marker = `/__flush_${Date.now()}_${Math.random().toString(36).slice(2)}`;
      await fetch(`${origin}${marker}`).catch(() => {});
      const deadline = Date.now() + 5000;
      while (!requests.some(request => request.path === marker) && Date.now() < deadline) {
        await new Promise(resolve => setTimeout(resolve, 10));
      }
    },
    async stop() {
      if (exited) {
        return;
      }
      child.stdin.destroy();
      child.kill('SIGTERM');
      const killer = setTimeout(() => child.kill('SIGKILL'), 3000);
      await exit;
      clearTimeout(killer);
    }
  };

  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      child.kill('SIGKILL');
      reject(new Error(`Preview server did not start within ${timeoutMs} ms\n${stderrText}`));
    }, timeoutMs);

    child.stdout.on('data', chunk => {
      stdoutBuffer += String(chunk);
      let newline;
      while ((newline = stdoutBuffer.indexOf('\n')) >= 0) {
        const line = stdoutBuffer.slice(0, newline).trim();
        stdoutBuffer = stdoutBuffer.slice(newline + 1);
        if (!ready) {
          const match = STARTUP_LINE.exec(line);
          if (match) {
            ready = true;
            origin = match[1];
            clearTimeout(timer);
            resolve(handle);
          }
          continue;
        }
        const request = REQUEST_LINE.exec(line);
        if (request) {
          requests.push({ method: request[1], path: request[2], status: Number(request[3]), line });
        }
      }
    });

    exit.then(code => {
      if (!ready) {
        clearTimeout(timer);
        reject(new Error(`Preview server exited with code ${code} before it was ready\n${stderrText}`));
      }
    });
  });
}
