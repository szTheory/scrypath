// Static design evidence only. Reads one local comp document, blocks requests,
// starts no Phoenix server, and writes captures/evidence beside this script.
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../../..');
const {chromium} = require(path.join(root, 'examples/scrypath_ecommerce/node_modules/playwright'));
const html = fs.readFileSync(path.join(__dirname, '176-comps.html'), 'utf8');

(async () => {
  const browser = await chromium.launch({headless: true});
  const results = [];
  try {
    const page = await browser.newPage({viewport: {width: 1440, height: 1100}, reducedMotion: 'reduce'});
    await page.route('**/*', route => route.abort());
    await page.setContent(html, {waitUntil: 'load'});
    for (const screen of ['search', 'playbooks']) {
      for (const mode of ['light', 'dark']) {
        for (const width of [1440, 390]) {
          await page.setViewportSize({width, height: 1100});
          await page.evaluate(({screen, mode}) => {
            document.documentElement.dataset.mode = mode;
            document.querySelector('#search-screen').hidden = screen !== 'search';
            document.querySelector('#playbooks-screen').hidden = screen !== 'playbooks';
            document.querySelector('#delete-dialog').close();
          }, {screen, mode});
          const name = `176-${screen}-${mode}-${width}.png`;
          await page.screenshot({path: path.join(__dirname, name), fullPage: true});
          const metrics = await page.evaluate(() => ({
            viewport: innerWidth,
            documentWidth: document.documentElement.scrollWidth,
            pageHeight: document.documentElement.scrollHeight,
            visibleSections: [...document.querySelectorAll('.screen:not([hidden]) .section')].length,
            focusTargets: [...document.querySelectorAll('.screen:not([hidden]) button,.screen:not([hidden]) input,.screen:not([hidden]) select,.screen:not([hidden]) textarea')].map(node => ({label: node.getAttribute('aria-label') || node.labels?.[0]?.textContent?.trim() || node.textContent.trim(), height: Math.round((node.type === 'checkbox' || node.type === 'radio') && node.closest('label') ? node.closest('label').getBoundingClientRect().height : node.getBoundingClientRect().height)})),
            fullFilenamesWrap: [...document.querySelectorAll('.file-name')].every(node => getComputedStyle(node).overflowWrap === 'anywhere'),
            openManageCount: document.querySelectorAll('#playbooks-screen details.manage[open]').length,
            activeScreen: document.querySelector('.screen:not([hidden])')?.id
          }));
          if (metrics.documentWidth > width) throw new Error(`${name}: horizontal overflow ${metrics.documentWidth}px > ${width}px`);
          if (metrics.activeScreen !== `${screen}-screen`) throw new Error(`${name}: wrong page composed`);
          if (metrics.focusTargets.some(target => target.height < 40)) throw new Error(`${name}: control target below 40px`);
          if (screen === 'playbooks' && (!metrics.fullFilenamesWrap || metrics.openManageCount !== 0)) throw new Error(`${name}: filename wrapping or closed Manage default failed`);
          results.push({screen, mode, width, file: name, ...metrics});
        }
      }
    }
    for (const mode of ['light', 'dark']) {
      for (const width of [1440, 390]) {
        await page.setViewportSize({width, height: 1100});
        await page.evaluate(mode => {
          document.documentElement.dataset.mode = mode;
          document.querySelector('#search-screen').hidden = true;
          document.querySelector('#playbooks-screen').hidden = false;
          document.querySelector('#playbooks-screen details.manage').open = true;
        }, mode);
        const file = `176-playbooks-manage-open-${mode}-${width}.png`;
        await page.screenshot({path: path.join(__dirname, file), fullPage: true});
        const metrics = await page.evaluate(() => ({
          viewport: innerWidth,
          documentWidth: document.documentElement.scrollWidth,
          openManageCount: document.querySelectorAll('#playbooks-screen details.manage[open]').length,
          actionsVisible: [...document.querySelectorAll('#playbooks-screen details.manage .details-body button')].every(button => button.getBoundingClientRect().width > 0),
          longFilenameVisible: [...document.querySelectorAll('#playbooks-screen .file-name')].every(node => node.getBoundingClientRect().height > 0)
        }));
        if (metrics.documentWidth > width || metrics.openManageCount !== 1 || !metrics.actionsVisible || !metrics.longFilenameVisible) throw new Error(`${file}: Manage disclosure rendering failed: ${JSON.stringify(metrics)}`);
        results.push({screen: 'manage-open', mode, width, file, ...metrics});
      }
    }
    for (const mode of ['light', 'dark']) {
      for (const width of [1440, 390]) {
        await page.setViewportSize({width, height: 1100});
        await page.evaluate(mode => {
          document.documentElement.dataset.mode = mode;
          document.querySelector('#search-screen').hidden = true;
          document.querySelector('#playbooks-screen').hidden = false;
          document.querySelector('#delete-dialog').close();
          document.querySelector('#delete-dialog').showModal();
          document.querySelector('#confirm-name').focus();
        }, mode);
        const file = `176-playbooks-delete-dialog-invalid-${mode}-${width}.png`;
        await page.screenshot({path: path.join(__dirname, file), fullPage: false});
        const metrics = await page.evaluate(() => ({
          viewport: innerWidth,
          dialogVisible: document.querySelector('#delete-dialog').matches(':modal'),
          focusedControl: document.activeElement?.id,
          errorVisible: getComputedStyle(document.querySelector('#confirm-error')).display !== 'none',
          dialogWidth: Math.round(document.querySelector('#delete-dialog').getBoundingClientRect().width),
          dialogWithinViewport: document.querySelector('#delete-dialog').getBoundingClientRect().left >= 0 && document.querySelector('#delete-dialog').getBoundingClientRect().right <= innerWidth
        }));
        if (!metrics.dialogVisible || metrics.focusedControl !== 'confirm-name' || !metrics.errorVisible || !metrics.dialogWithinViewport) throw new Error(`${file}: invalid modal state/focus failed: ${JSON.stringify(metrics)}`);
        results.push({screen: 'delete-dialog-invalid-confirmation', mode, width, file, ...metrics});
      }
    }
    for (const mode of ['light', 'dark']) {
      for (const width of [1440, 390]) {
        await page.setViewportSize({width, height: 1100});
        await page.evaluate(mode => {
          document.documentElement.dataset.mode = mode;
          document.querySelector('#search-screen').hidden = true;
          document.querySelector('#playbooks-screen').hidden = false;
          document.querySelector('#delete-dialog').close();
          document.querySelector('#confirm-name').value = '';
          document.querySelector('#confirm-error').hidden = true;
          document.querySelector('#dialog-state-caption').textContent = 'Initial dialog state · focus starts on Cancel · focus stays inside until close.';
          document.querySelector('#delete-dialog').showModal();
          document.querySelector('#cancel-delete').focus();
        }, mode);
        const file = `176-playbooks-delete-dialog-initial-${mode}-${width}.png`;
        await page.screenshot({path: path.join(__dirname, file), fullPage: false});
        const metrics = await page.evaluate(() => ({
          viewport: innerWidth,
          dialogVisible: document.querySelector('#delete-dialog').matches(':modal'),
          focusedControl: document.activeElement?.id,
          dialogWidth: Math.round(document.querySelector('#delete-dialog').getBoundingClientRect().width),
          dialogWithinViewport: document.querySelector('#delete-dialog').getBoundingClientRect().left >= 0 && document.querySelector('#delete-dialog').getBoundingClientRect().right <= innerWidth
        }));
        if (!metrics.dialogVisible || metrics.focusedControl !== 'cancel-delete' || !metrics.dialogWithinViewport) throw new Error(`${file}: initial modal focus failed: ${JSON.stringify(metrics)}`);
        results.push({screen: 'delete-dialog-initial', mode, width, file, ...metrics});
      }
    }
    const evidence = {kind: 'static-design-comp-only', capturedAt: new Date().toISOString(), renderer: 'Playwright Chromium; in-memory HTML; all network requests aborted', checks: ['horizontal overflow', '40px minimum representative form/button targets', 'full filename wrapping', 'Manage closed by default and visible actions when expanded', 'delete dialog viewport geometry', 'initial delete dialog focuses Cancel', 'invalid confirmation retains value/error and focuses filename'], results};
    fs.writeFileSync(path.join(__dirname, '176-comp-evidence.json'), JSON.stringify(evidence, null, 2) + '\n');
    console.log(JSON.stringify({captures: results.length, horizontalOverflow: 0, undersizedRepresentativeTargets: 0, dialogGeometryOrFocusFailures: 0, deleteFocusStates: 'initial Cancel and invalid filename', manageDisclosureChecks: 'closed by default; open state rendered', scope: 'static comps only'}));
  } finally {
    await browser.close();
  }
})().catch(error => { console.error(error.stack || error.message); process.exitCode = 1; });
