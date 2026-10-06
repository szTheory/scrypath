// Owned design-only renderer. Reads the generated mockup and two known logo assets.
// Runs no application server, contacts no network, and never opens a file:// URL.
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../../..');
const {chromium} = require(path.join(root, 'examples/scrypath_ecommerce/node_modules/playwright'));
let html = fs.readFileSync(path.join(__dirname, '173-comps.html'), 'utf8');
for (const name of ['scrypath-wordmark.svg', 'scrypath-wordmark-inverse.svg']) {
  const svg = fs.readFileSync(path.join(root, 'scrypath_ops/priv/static/images', name));
  html = html.replaceAll(`../../../scrypath_ops/priv/static/images/${name}`, `data:image/svg+xml;base64,${svg.toString('base64')}`);
}
function rgb(value) { return value.match(/[\d.]+/g).slice(0, 3).map(Number); }
function luminance(value) {
  return rgb(value).map(v => {v /= 255; return v <= .04045 ? v / 12.92 : ((v + .055) / 1.055) ** 2.4;}).reduce((s,v,i) => s + v * [.2126,.7152,.0722][i], 0);
}
function ratio(a,b) {const x=luminance(a),y=luminance(b);return Number(((Math.max(x,y)+.05)/(Math.min(x,y)+.05)).toFixed(2));}
(async () => {
  const browser = await chromium.launch({headless:true});
  const results = [];
  try {
    const page = await browser.newPage({viewport:{width:1440,height:1100}, reducedMotion:'reduce'});
    await page.route('**/*', route => route.abort());
    await page.setContent(html, {waitUntil:'load'});
    for (const candidate of ['warm','cool']) for (const mode of ['light','dark']) {
      for (const width of [1440,390, ...(candidate === 'warm' ? [1279,1280] : [])]) {
        await page.setViewportSize({width,height:1100});
        await page.evaluate(({candidate,mode}) => {document.documentElement.dataset.candidate=candidate;document.documentElement.dataset.mode=mode;}, {candidate,mode});
        await page.screenshot({path:path.join(__dirname, `173-${candidate}-${mode}-${width}.png`),fullPage:true});
        const metrics = await page.evaluate(() => {
          const s = sel => getComputedStyle(document.querySelector(sel));
          const primary=s('.schema'), selected=s('.nav-item.active'), summary=s('.verdict');
          return {
            viewport:innerWidth, scrollWidth:document.documentElement.scrollWidth,
            selectedPreferences:document.querySelectorAll('.theme button[aria-pressed="true"]').length,
            selectedPreference:document.querySelector('.theme button[aria-pressed="true"]').textContent,
            backgroundImage:getComputedStyle(document.body).backgroundImage,
            railVisible:getComputedStyle(document.querySelector('.sidebar')).display !== 'none',
            brokenImages:[...document.images].filter(i => !i.complete || i.naturalWidth === 0).length,
            colors:{text:primary.color,muted:s('.secondary').color,accent:s('.copy').color,warning:s('.state-label').color,error:s('.state-error').color,surface:primary.backgroundColor,selectedText:selected.color,selectedFill:selected.backgroundColor,summaryFill:summary.backgroundColor},
            themeTargets:[...document.querySelectorAll('.theme button')].map(b => ({width:b.getBoundingClientRect().width,height:b.getBoundingClientRect().height}))
          };
        });
        const c = metrics.colors;
        metrics.contrast={text:ratio(c.text,c.surface),muted:ratio(c.muted,c.surface),accent:ratio(c.accent,c.surface),warning:ratio(c.warning,c.surface),error:ratio(c.error,c.surface),selected:ratio(c.selectedText,c.selectedFill)};
        results.push({candidate,mode,width,...metrics});
        if (metrics.scrollWidth > width || metrics.selectedPreferences !== 1 || metrics.selectedPreference !== 'System' || metrics.brokenImages || Object.values(metrics.contrast).some(r=>r<4.5)) throw new Error(`Mockup check failed: ${JSON.stringify(results.at(-1))}`);
      }
    }
    fs.writeFileSync(path.join(__dirname, '173-comp-evidence.json'),JSON.stringify({kind:'static-design-comp-only',capturedAt:new Date().toISOString(),results},null,2)+'\n');
    console.log(JSON.stringify({captures:results.length,overflow:0,aaFailures:0,brokenImages:0,scope:'generated static comps only'}));
  } finally {await browser.close();}
})().catch(e => {console.error(e.message);process.exitCode=1;});
