# scrypath assets: which file to use

Open `index.html` in a browser for previews. Version 1.0, November 14, 2026.

## Logo on a light background

- `logo/scrypath-lockup-light.svg`
- `logo/scrypath-symbol-light.svg`
- `logo/scrypath-lockup-light-2048.png`

## Logo on a dark background

- `logo/scrypath-lockup-dark.svg`
- `logo/scrypath-symbol-dark.svg`
- `logo/scrypath-lockup-dark-2048.png`

## One color: print and single-color jobs

- `logo/scrypath-lockup-one-color-ink.svg`
- `logo/scrypath-lockup-one-color-pale-ink.svg`
- `logo/scrypath-symbol-one-color-ink.svg`
- `logo/scrypath-symbol-one-color-pale-ink.svg`

## Favicon (the symbol, drawn for 16 and 32 px)

- `icon/favicon.svg`
- `icon/favicon.ico`
- `icon/favicon-32-light.png`
- `icon/favicon-16-light.png`

## Avatar (a 512 px square: the one place the symbol sits on a background)

- `avatar/scrypath-avatar-light.svg`
- `avatar/scrypath-avatar-dark.svg`
- `avatar/scrypath-avatar-512-light.png`
- `avatar/scrypath-avatar-512-dark.png`

## README header

- `readme/scrypath-header-light.svg`
- `readme/scrypath-header-dark.svg`
- `readme/header-snippet.html`

## Link preview and social card

- `social/scrypath-social-card-1280x640.png`

## Docs: code colors for ExDoc

- `docs/scrypath-exdoc.css`

## Logo animation (video, light and dark, with sound)

- `motion/scrypath-logo-animation-dark.mp4`
- `motion/scrypath-logo-animation-dark.webm`
- `motion/scrypath-logo-animation-light.mp4`
- `motion/scrypath-logo-animation-light.webm`

## Sounds: raw files for the product and for a sound designer

- `sound/scrypath-sting.wav`
- `sound/scrypath-sting-quiet.wav`
- `sound/scrypath-slash.wav`
- `sound/scrypath-run.wav`
- `sound/scrypath-accepted.wav`
- `sound/scrypath-visible.wav`
- `sound/scrypath-retrying.wav`
- `sound/scrypath-failed.wav`
- `sound/scrypath-done.wav`

## Sounds: listening masters (MP3) for demos and video

- `sound/listening/scrypath-sting.mp3`
- `sound/listening/scrypath-sting-quiet.mp3`
- `sound/listening/scrypath-slash.mp3`
- `sound/listening/scrypath-run.mp3`
- `sound/listening/scrypath-accepted.mp3`
- `sound/listening/scrypath-visible.mp3`
- `sound/listening/scrypath-retrying.mp3`
- `sound/listening/scrypath-failed.mp3`
- `sound/listening/scrypath-done.mp3`

## Fonts

- `fonts/web/fonts.css`
- `fonts/variable/BricolageGrotesque[opsz,wdth,wght].ttf`
- `fonts/variable/HankenGrotesk[wght].ttf`
- `fonts/variable/SometypeMono[wght].ttf`
- `fonts/OFL-BricolageGrotesque.txt`
- `fonts/OFL-HankenGrotesk.txt`
- `fonts/OFL-SometypeMono.txt`

All logo SVGs are flat filled paths (no live text, no strokes, no masks) in exact brand colors, transparent. `light` files are for light backgrounds, `dark` for dark ones; `one-color-ink` (all Ink) and `one-color-pale-ink` (all Pale Ink) are drawn in a single color, not recolored. `lockup` is the word with its slash and `symbol` is the s and the slash alone; the favicon files are the symbol, redrawn so its edges fall on whole pixels, for exactly 16 and 32 px. The avatar is the one file with a square background. `icon/favicon.svg` swaps its letter and slash with the device theme; the ICO holds only the light drawing. `docs/scrypath-exdoc.css` colors code in ExDoc and has not been run in an ExDoc build. Fonts are SIL Open Font License 1.1 (licenses in `fonts/`). The logo animation is in `motion/` (video with sound, light and dark); the sounds are in `sound/` (raw WAV) and `sound/listening/` (MP3 listening masters).
