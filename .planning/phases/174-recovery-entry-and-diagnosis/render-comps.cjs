// Bounded design-only renderer, adapted from Phase 173's owned static renderer.
// Loads generated HTML in memory, blocks network access, and writes only phase captures/evidence.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const root = path.resolve(__dirname, '../../..');
const repositoryPath = process.env.SCRYPATH_PLAYWRIGHT_MODULE;
const playwrightPaths = [
  ...(repositoryPath ? [repositoryPath] : []),
  path.join(root, 'examples/scrypath_ecommerce/node_modules/playwright'),
  '/Users/jon/projects/scrypath/examples/scrypath_ecommerce/node_modules/playwright'
];
const playwrightPath = playwrightPaths.find(candidate => fs.existsSync(candidate));
if (!playwrightPath) throw new Error(`Could not find installed Playwright at: ${playwrightPaths.join(', ')}`);
const {chromium} = require(playwrightPath);
let html = fs.readFileSync(path.join(__dirname, '174-comps.html'), 'utf8');
for (const name of ['scrypath-wordmark.svg', 'scrypath-wordmark-inverse.svg']) {
  const svg = fs.readFileSync(path.join(root, 'scrypath_ops/priv/static/images', name));
  html = html.replaceAll(`../../../scrypath_ops/priv/static/images/${name}`, `data:image/svg+xml;base64,${svg.toString('base64')}`);
}
(async () => {
  const browser = await chromium.launch({headless:true});
  const results = [];
  try {
    const page = await browser.newPage({viewport:{width:1440,height:1000}, reducedMotion:'reduce'});
    await page.route('**/*', route => route.abort());
    await page.setContent(html, {waitUntil:'load'});
    for (const screen of ['control-room','search-health','failed-work']) {
      for (const mode of ['light','dark']) {
        for (const width of [1440,1280,1279,390]) {
          await page.setViewportSize({width,height:1000});
          await page.evaluate(({screen,mode}) => {document.documentElement.dataset.screen=screen;document.documentElement.dataset.mode=mode;}, {screen,mode});
          const filename=`174-${screen}-${mode}-${width}.png`;
          await page.screenshot({path:path.join(__dirname,filename),fullPage:true});
          const metrics=await page.evaluate(() => ({
            width:innerWidth,scrollWidth:document.documentElement.scrollWidth,
            activeScreens:[...document.querySelectorAll('section[data-screen]')].filter(e=>getComputedStyle(e).display!=='none').length,
            railVisible:getComputedStyle(document.querySelector('.rail')).display!=='none',
            title:document.querySelector(`[data-screen="${document.documentElement.dataset.screen}"] h1`)?.textContent,
            controls:[...document.querySelectorAll('.button, .theme button, select')].filter(e=>e.getBoundingClientRect().height>0).map(e=>({text:e.textContent.trim(),height:Math.round(e.getBoundingClientRect().height)})),
            identifiers:[...document.querySelectorAll('code')].filter(e=>e.getBoundingClientRect().height>0).map(e=>e.textContent.trim()).filter(Boolean)
          }));
          if(metrics.scrollWidth>width||metrics.activeScreens!==1||!metrics.title) throw new Error(`Static comp geometry failed: ${JSON.stringify({screen,mode,width,metrics})}`);
          results.push({screen,mode,width,filename,...metrics});
        }
      }
    }
    fs.writeFileSync(path.join(__dirname,'174-comp-evidence.json'),JSON.stringify({kind:'static-design-comp-only',capturedAt:new Date().toISOString(),source:'174-comps.html',sourceSha256:crypto.createHash('sha256').update(fs.readFileSync(path.join(__dirname,'174-comps.html'))).digest('hex'),method:'adapted Phase 173 Playwright renderer; no application server or network',results},null,2)+'\n');
    console.log(JSON.stringify({captures:results.length,overflow:results.filter(r=>r.scrollWidth>r.width).length,screens:[...new Set(results.map(r=>r.screen))],modes:['light','dark'],widths:[1440,1280,1279,390],scope:'static comps only'}));
  } finally {await browser.close();}
})().catch(e=>{console.error(e.message);process.exitCode=1;});
