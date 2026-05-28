import { mkdir, readFile, rm, writeFile, cp } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const websiteDir = fileURLToPath(new URL('..', import.meta.url));
const repoRoot = path.resolve(websiteDir, '..');
const srcDir = path.join(websiteDir, 'src');
const distDir = path.join(websiteDir, 'dist');
const siteUrl = process.env.SCRYPATH_SITE_URL ?? 'https://sztheory.github.io/scrypath/';
const repoUrl = process.env.SCRYPATH_REPO_URL ?? 'https://github.com/szTheory/scrypath';
const buildDate = new Date().toISOString().slice(0, 10);

const mixExs = await readFile(path.join(repoRoot, 'mix.exs'), 'utf8');
const versionMatch = mixExs.match(/@version\s+"([^"]+)"/);

if (!versionMatch) {
  throw new Error('Could not locate @version in mix.exs');
}

const version = versionMatch[1];
const canonicalInstall = '{:scrypath, "~> 0.3"}';

const pages = [
  {
    input: 'index.html',
    output: 'index.html',
    title: 'Scrypath - Search indexing that feels native to Ecto',
    description:
      'Scrypath is an open-source Elixir library for declarative, Ecto-native search indexing and search orchestration for Phoenix and Ecto teams.',
    routePath: ''
  },
  {
    input: 'docs.html',
    output: path.join('docs', 'index.html'),
    title: 'Scrypath docs map - guides for Phoenix and Ecto search',
    description:
      'A compact map to the Scrypath guides, example app, Phoenix request-edge docs, multitenancy, and recovery material.',
    routePath: 'docs/'
  },
  {
    input: 'operators.html',
    output: path.join('operators', 'index.html'),
    title: 'Scrypath operator support - recovery, verification, and drift',
    description:
      'The operator path for verification commands, drift recovery, and observability around Scrypath.',
    routePath: 'operators/'
  },
  {
    input: 'evaluate.html',
    output: path.join('evaluate', 'index.html'),
    title: 'Should I use Scrypath? - evaluation and fit',
    description:
      'A blunt evaluation page for Phoenix and Ecto teams comparing Scrypath to other search approaches.',
    routePath: 'evaluate/'
  }
];

await rm(distDir, { recursive: true, force: true });
await mkdir(distDir, { recursive: true });

for (const page of pages) {
  const basePath = page.routePath === '' ? './' : '../';
  const template = await readFile(path.join(srcDir, 'layout.html'), 'utf8');
  const content = await readFile(path.join(srcDir, 'pages', page.input), 'utf8');
  const renderedContent = replaceTokens(content, {
    BASE_PATH: basePath,
    BUILD_DATE: buildDate,
    CANONICAL_INSTALL: canonicalInstall,
    DESCRIPTION: page.description,
    GITHUB_URL: repoUrl,
    PAGE_PATH: page.routePath,
    PAGE_TITLE: page.title,
    REPO_URL: repoUrl,
    SITE_URL: siteUrl,
    VERSION: version
  });
  const rendered = replaceTokens(template, {
    BASE_PATH: basePath,
    BUILD_DATE: buildDate,
    CANONICAL_INSTALL: canonicalInstall,
    CONTENT: renderedContent,
    DESCRIPTION: page.description,
    GITHUB_URL: repoUrl,
    PAGE_PATH: page.routePath,
    PAGE_TITLE: page.title,
    REPO_URL: repoUrl,
    SITE_URL: siteUrl,
    VERSION: version
  });

  const outputPath = path.join(distDir, page.output);
  await mkdir(path.dirname(outputPath), { recursive: true });
  await writeFile(outputPath, rendered);
}

await cp(path.join(srcDir, 'assets'), path.join(distDir, 'assets'), { recursive: true });

await writeFile(
  path.join(distDir, 'robots.txt'),
  replaceTokens(await readFile(path.join(srcDir, 'robots.txt'), 'utf8'), {
    SITE_URL: siteUrl
  })
);

await writeFile(
  path.join(distDir, 'sitemap.xml'),
  replaceTokens(await readFile(path.join(srcDir, 'sitemap.xml'), 'utf8'), {
    SITE_URL: siteUrl,
    VERSION: version
  })
);

function replaceTokens(input, tokens) {
  return Object.entries(tokens).reduce((output, [key, value]) => {
    return output.split(`{{${key}}}`).join(String(value));
  }, input);
}
