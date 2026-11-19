# Scrypath brand

Version 1.0, November 14, 2026. This is the complete text of the brand book (`scrypath-brand-book.html`), page by page, for people and AI assistants. The same rules as structured data are in `brand.json`; colors, type and motion values in `tokens.json`; every file is explained in `assets/README.md`.

**Read this first.** Scrypath is an Elixir library that adds full-text search to your Ecto schemas and shows which updates are waiting and where an update stopped.

1. Write Scrypath in sentences and headings. Write `scrypath` for the logo, package, commands and file names, and `Scrypath` for the Elixir module. Never start a sentence with `scrypath` or write “scry/path”.
2. The logo is the word scrypath with one slash between the y and the p. The slash is Plum on light and Orchid on dark, and the letters are Ink on light and Pale Ink on dark. Put no shape behind the logo or the symbol (the avatar’s square is the one exception), add no cursor (only the logo animation shows one while it plays) and no tagline. The symbol is s/.
3. Write every sync status as a word. Add its icon and color if you like, but never use them in place of the word.

Light is the default theme. Dark is a complete second theme with its own colors and its own logo drawing. Every text and background pair has a fixed name and a computed contrast ratio in both themes; the pairs are listed on the Color pages.

## Brand at a glance

What Scrypath is. An Elixir library that adds full-text search to your Ecto schemas and shows which updates are waiting and where an update stopped.

### three rules

1. Write Scrypath in sentences and headings. Write `scrypath` for the logo, package, commands and file names, and `Scrypath` for the Elixir module. Never start a sentence with `scrypath` or write “scry/path”.
2. The logo is the word scrypath with one slash; the slash is Plum on light and Orchid on dark. Put no shape behind the logo or symbol, except the avatar’s square, and no cursor except in the logo animation (see Logo). Set the tagline and descriptor beside the logo, never inside it (see Messaging).
3. Write every sync status as a word. Add its icon and color if you like, but never use them in place of the word.

### color

**Page** #F8F4F2 **Panel** #FFFFFF **Ink** #1E1220 **Plum** #7B2D6B **Hairline** #E0D5D1

Failed Retrying Pending Clear

### type

Bricolage Grotesque for the name and headlines, Hanken Grotesk for reading and tables, and Sometype Mono for names, commands and code.

### voice

Every message in the operator UI says what happened, which schema or index it concerns and what to do next.

## The idea

**Why the name has a slash**

The name is one word, `scrypath`, but the logo has a slash inside it: `scry/path`. A slash separates the parts of a file path, and Elixir developers also see it in function names such as `search/3`.

When your app saves a record to its database, you tell Scrypath to sync it, and Scrypath sends the update to Meilisearch, the search engine. Meilisearch indexes the update in the background, so a search may not find a record right after it was saved. This delay is called eventual consistency.

Scrypath shows how far each schema’s updates have gone on a progress line: solid up to the step an update has reached, dashed after it. Every page of this book has the same line down its left side.

## Positioning and values

**An Elixir library that adds full-text search to your Ecto schemas and shows which updates are waiting and where an update stopped.**

### who it is for

- Elixir developers Add search to an existing Ecto schema and choose how updates are sent.
- Whoever keeps search running Use the operator UI, Scrypath’s optional screens, to see which Ecto schemas have an out-of-date search index and where updates are stuck.
- Maintainers and contributors Keep every Scrypath page, from README to operator UI, looking like one project.

**Honest**

Scrypath never reports a record as searchable while Meilisearch is still indexing it.

**Plain**

The operator UI says “record loading”, not “hydration”, and names the exact schema, index or update involved.

**Exact**

Screen text is “1 update to MyApp.Blog.Post failed at 14:31 UTC”, not “something failed recently”.

**Calm**

A Pending update is normal and is shown in muted colors. Retrying is amber. Only a Failed update is shown in an error color, with the next action beside it.

**Native**

Setup is plain Elixir. You list the searchable fields in your Ecto schema with `use Scrypath` and tell Scrypath to sync after each save. Mix tasks show which updates are waiting and which have failed.

## Messaging

### elevator pitch

**Scrypath adds full-text search to Elixir apps. Declare the searchable fields on your Ecto schema and tell Scrypath to sync after each save. An Oban background job then sends the update to Meilisearch. When an update gets stuck, you see where it stopped and how to fix it.**

### key messages

**Declared on the schema.**

You list the searchable fields with `use Scrypath` in your Ecto schema. Scrypath sends nothing to Meilisearch until your code tells it to sync a record.

**Sync you can see.**

In Oban mode, a background job from Oban, the Elixir job library, sends each update to Meilisearch. `mix scrypath.status` and the Search health screen show which updates are waiting or failed.

**When a record is searchable.**

Meilisearch is eventually consistent, so a record can take a moment to show up in search after you save it. Scrypath never says a record is searchable before Meilisearch has indexed it.

### tagline

**Search indexing that feels native to Ecto.**

The tagline is in sentence case and ends with a period. Set it beside the logo, never inside it. For a page title or alt text, use the shorter descriptor “Ecto-native search indexing”.

### about scrypath: approved descriptions

One line, for Hex, GitHub and package listings

Full-text search for Elixir apps, declared on your Ecto schemas, with a way to see when the search index is out of date.

Short, for the README opening and talk bios

Scrypath is an open-source Elixir library that adds full-text search to the Ecto schemas you already have. You list the searchable fields on the schema and tell Scrypath to sync after each save. Mix tasks and an optional operator UI show where any update is stuck and how to fix it.

Do not say

Magic, effortless, “it just stays in sync”, real-time (unless you measured it), federated, hydration, playbook, or “AI-powered”. Scrypath is a library you run inside your own app, and it does not promise that a record is searchable the moment it is saved.

## Where the brand shows

**Scrypath’s own pages use the full brand, the operator UI uses part of it, and your users’ search screens use none of it.**

### Scrypath’s own pages

**Where:** README, Hex page, HexDocs, website, social card

**For:** Developers deciding whether to adopt Scrypath.

**What shows:** The logo in both themes, the colors, the progress line, the code colors and the descriptor.

### In the operator ui

**Where:** ScrypathOps: Search health, Failed sync work, Sync and index

**For:** Whoever keeps search running: developers and platform engineers.

**What shows:** The logo in the top bar, status icons beside their words, a progress line across each row, names and times in Sometype Mono, and a Plum button only for a screen’s single main action.

### In other people’s writing

**Where:** Blog posts, talks, other READMEs

**For:** People writing about Scrypath.

**What shows:** Writers may use the logo unchanged, under the rules in this book, with nothing added to it.

The search screens your app’s users use carry your app’s own name, logo and colors. You may credit Scrypath in plain text if you choose.

## Logo: on light

**The logo, one word and one slash.**

The logo is the word scrypath with a slash between the y and the p. The slash is Plum on light and Orchid on dark. Do not move the slash, repeat it, redraw the letters or add a shape, a gradient or a cursor.

- The logo is a vector drawing, not typed text, so it needs no font.
- It sits directly on the page, with nothing around it.
- It has one slash, never repeated.

There are two exceptions. The logo animation shows a cursor while it plays and ends without one. The avatar sits on a plain square, because a profile picture is cropped to a square. The slanted bar is a separate element: it is the bullet in this book’s lists and each step marker on the progress line down the left of every page.

**The one-color logo.** The slash is the same color as the letters: Ink on a light background, Pale Ink on a dark one. Use it for stamps, print and any single-color job.

**The symbol** is the s and its slash. Use it for avatars, app icons and stickers. Use the logo when the name needs to show.

**Drawn for small sizes.** The favicon is the symbol s/, drawn for exactly 16 and 32 px, so its edges fall on whole pixels. The symbol is not drawn below 16 px.

**Light is the default theme.** The light drawing has Ink letters and a Plum slash. The dark theme has its own drawing; do not invert one into the other.

## Logo: on dark

**The logo, one word and one slash.**

The logo is the word scrypath with a slash between the y and the p. The slash is Plum on light and Orchid on dark. Do not move the slash, repeat it, redraw the letters or add a shape, a gradient or a cursor.

- The logo is a vector drawing, not typed text, so it needs no font.
- It sits directly on the page, with nothing around it.
- It has one slash, never repeated.

There are two exceptions. The logo animation shows a cursor while it plays and ends without one. The avatar sits on a plain square, because a profile picture is cropped to a square. The slanted bar is a separate element: it is the bullet in this book’s lists and each step marker on the progress line down the left of every page.

**The one-color logo.** The slash is the same color as the letters: Ink on a light background, Pale Ink on a dark one. Use it for stamps, print and any single-color job.

**The symbol** is the s and its slash. Use it for avatars, app icons and stickers. Use the logo when the name needs to show.

**Drawn for small sizes.** The favicon is the symbol s/, drawn for exactly 16 and 32 px, so its edges fall on whole pixels. The symbol is not drawn below 16 px.

**Dark has its own drawing.** The dark drawing has Pale Ink letters, with slightly thinner strokes than the light drawing (weight 670 instead of 700), and an Orchid slash, so the slash is easy to see on Night.

## Logo: construction

**Logo measurements.**

T is the thickness of the h’s stem. Every other distance in the logo is a multiple or a fraction of T.

Scroll the drawing sideways to see every measurement.

### the slash

The slash is one T thick (146.5 font units, measured horizontally) and leans 14.46 degrees, the same angle as the typeface’s own slash at these settings. It starts at the height of the top of the h and ends at the bottom of the p. Its four corners are sharp.

### spacing

Spacing is measured, then adjusted by eye. Across the height of a lowercase x, the average space between letters is 0.85 T for every pair, and no two parts come closer than 0.42 T. At their closest points the slash is 0.63 T from the y and 0.43 T from the p. By eye, the r and y were moved 0.12 T closer, and the slash 0.10 T further from the y.

### the letters

Bricolage Grotesque Bold at optical size 96 and width 90. The typeface has ink traps, small notches where strokes meet: in the r, the y, twice in the p, the a and the h. In the font these notches are deep enough to look like hairline cracks at display size, so each one is cut to half its depth. That is the one drawn detail; no letter is otherwise redrawn.

### the dark drawing

The dark drawing uses weight 670 instead of 700, with the spacing measured again, because pale letters on a dark background look heavier than they are.

### clear space

Clear space is 2 T on every side, measured from the outermost edge of the logo.

### the symbol

The symbol s/ is the name’s first letter and its slash, the way the substitute command starts in sed and vim. The slash is shortened to the height of the s. It always includes the s; a lone slash is never the logo.

## Logo: symbol and favicon

**The symbol, drawn for 16 and 32 px.**

The symbol alone is the s and the slash, for avatars, app icons and stickers. The favicon is the symbol s/, drawn for exactly 16 and 32 px, so its edges fall on whole pixels. The symbol is not drawn below 16 px.

At 16 px: x-height 10 px, baseline on row 13, slash 3 px wide in 3 one-pixel steps, at least 1 px between the s and the slash. At 32 px: x-height 20 px, baseline on row 26, slash 6 px wide in 5 steps, and 2 px between the s and the slash. The slash is drawn to line up with whole pixels, so it stays sharp at 16 and 32 px. Only Chrome’s rendering was looked at; other browsers may draw favicons differently. `favicon.svg` follows the device’s light or dark setting: in dark mode its slash is Orchid.

The favicon in a browser tab at 16 px, on a light tab and a dark tab.

## Logo: clear space and minimum size

Keep clear space on every side equal to 2 T, twice the thickness of the h’s stem, measured from the outermost edge of the logo. Keep it empty: no other logo, no text and no page edge inside it.

### on screenshots and photographs

- Set the logo on a plain, low-detail area at least as wide as the logo plus its clear space.
- Use the light drawing on a light background and the dark drawing on a dark background. If a photograph makes both hard to read, move the logo to a plainer part of the image.
- Do not put a screenshot of the operator UI behind the logo; show the screenshot beside it.

### minimum size

|   | Screen | Print |
| --- | --- | --- |
| **Logo** | 112 px wide | 25 mm wide |
| **The symbol, drawn for 16 px** | 16 px wide | Not specified |

On screen, the logo is never narrower than 112 px (24 px tall) and the favicon drawing of the symbol never narrower than 16 px. Below 24 px tall, use the symbol. In print, the logo is never narrower than 25 mm.

### color

The slash is never green, blue or red, and it is never recolored to match your app. Meilisearch, the engine Scrypath is built on, uses a mark of three slanted bars in a pink gradient. This logo has one flat Plum slash with sharp-cornered ends, and the symbol always includes a letter. Do not use repeated slashes, stripes or gradients as a brand pattern. Other brands also put a slash inside their names. This logo differs in its drawing, its color and the word around the slash.

## Logo: misuse

✕ Don’t stretch, squeeze or rotate the logo.

✕ Don’t use colors other than the ones on the logo pages. For a one-color job, use the one-color logo.

✕ Don’t put a tile, badge or any other shape behind the logo.

✕ Don’t add the tagline, the descriptor or any other text to the logo.

✕ Don’t move the slash, repeat it, or add a cursor after the word.

✕ Don’t pair a drawing with the wrong background: the dark drawing on light, or the light drawing on dark.

## Color: light

**Page**

#F8F4F2 RGB 248 244 242

The default background of the book, docs and operator UI.

**Panel**

#FFFFFF RGB 255 255 255

Tables, form fields, the detail panel and the README card.

**Ink**

#1E1220 RGB 30 18 32

Text, and the letters in the logo on light.

**Plum**

#7B2D6B RGB 123 45 107

The logo’s slash, links, the focus ring, the main button (at most one per screen) and the marker for the current page on this book’s progress line.

**Hairline**

#E0D5D1 RGB 224 213 209

Dividing lines between rows and sections. An input or a button has a Control Edge border.

**Muted Ink**

#5E5360

Secondary text on Page and Panel.

**Sunken Page**

#F0E9E6

The background of code blocks and table heads, on light.

**Selected Page**

#EBDFE7

The background of the selected row, on light. Darker than Page, so the selected row is easy to see.

**Control Edge**

#8A7A8E

The border of an input or a button on light (3.7:1 on Page). Dark uses #8F7F94.

## Color: dark

**Night**

#160E19 RGB 22 14 25

The dark background of the terminal, docs and operator UI.

**Night Panel**

#201624 RGB 32 22 36

Tables, form fields and the detail panel on Night.

**Pale Ink**

#F4EDF3 RGB 244 237 243

Text, and the letters in the logo on dark.

**Orchid**

#D58BC4 RGB 213 139 196

The logo’s slash on dark, links, the focus ring, the main button (at most one per screen) and the marker for the current page on this book’s progress line.

**Night Hairline**

#3A2A3E RGB 58 42 62

Dividing lines on dark.

**Muted Pale**

#BBAAC0

Secondary text on Night and Night Panel.

**Control Edge**

#8F7F94

Borders of inputs and buttons on Night.

**Night Sunken**

#110A14

The background of code blocks and table heads on dark.

**Selected Night**

#2B2130

The background of the selected row on dark. Lighter than Night, with a 2 px Orchid line along its left edge.

## Color: sync statuses

**Four statuses, each a word, a status icon and a color.**

Write every sync status as a word. Add its icon and color if you like, but never use them in place of the word.

**The symbol** is the s and the slash from the logo.

**The status icon** is the logo’s slash, shortened to a small bar and set beside the status word.

### in grayscale

The status icon is 16 px tall in a Search health row; the pictures here show it larger. The status icon was not tried below 14 px. Each status has its own shape, so the four can be told apart without color: filled for Clear, hollow for Pending, filled from the bottom for Retrying and notched for Failed. Only Failed uses an error color.

## Color: contrast pairs

**Text, links and the main button.**

| Role | Where it is used | Light | Dark | Minimum |
| --- | --- | --- | --- | --- |
| **Body text** | README, docs, the operator UI and this book. | Aa 16.53:1 | Aa 16.43:1 | 4.5:1 |
| **Descriptor and secondary text** | The descriptor next to the logo, and the metadata under a title. | Aa 6.67:1 | Aa 8.66:1 | 4.5:1 |
| **Caption and table metadata** | Captions, times and column heads. | Aa 7.29:1 | Aa 8.01:1 | 4.5:1 |
| **Copy inside an application** | Text on a panel in the operator UI or the README. | Aa 18.06:1 | Aa 15.19:1 | 4.5:1 |
| **Link and current navigation item** | Links, and the current item in the top navigation. | Aa 8.64:1 | Aa 6.92:1 | 4.5:1 |
| **Focus ring on the page** | A 2 px ring around the control in focus, against the page. | 7.91:1 | 7.49:1 | 3:1 |
| **Logo slash** | The logo’s slash against the page, as a shape: Plum on light, Orchid on dark. | 7.91:1 | 7.49:1 | 3:1 |
| **Main button** | The label on the main button against its fill (Plum on light, Orchid on dark); at most one per screen. | Aa 8.64:1 | Aa 7.49:1 | 4.5:1 |

### about these ratios

Ratios are WCAG 2.2 contrast, computed from the hex values. A pair passing here is not a claim about any product built with it. Plum on Page is 7.9:1 (8.6:1 on Panel), so the slash passes the 3:1 minimum for shapes and Plum also passes as link text. Orchid on Night is 7.5:1. The Failed orange-red and the Retrying amber are 29 degrees apart in hue on light (CIELAB hue angle), and the book’s automated check fails if that gap falls under 25. A person can also tell them apart by the icon’s shape and the word. Color is never the only way to tell the four statuses apart.

## Color: contrast pairs, continued

**The selected row and the four statuses.**

| Role | Where it is used | Light | Dark | Minimum |
| --- | --- | --- | --- | --- |
| **Notes on the selected row** | Index names and notes on the selected row. | Aa 5.64:1 | Aa 7.06:1 | 4.5:1 |
| **Status word, selected row** | The word Failed on the selected row. | Aa 4.81:1 | Aa 7.40:1 | 4.5:1 |
| **Status word: Failed** | The word “Failed”. | Aa 6.22:1 | Aa 8.39:1 | 4.5:1 |
| **Status word: Retrying** | The word “Retrying”. | Aa 5.93:1 | Aa 8.98:1 | 4.5:1 |
| **Status word: Pending** | The word “Pending”, in Muted Ink. | Aa 6.86:1 | Aa 6.70:1 | 4.5:1 |
| **Status word: Clear** | The word “Clear”. | Aa 6.52:1 | Aa 9.08:1 | 4.5:1 |

### reading a pair

Each ratio is computed from the two hex values on the Color pages. Text needs 4.5:1 at any size. A control or a graphic needs 3:1.

### never

- **Plum** as text on Night (use Orchid)
- **Hairline** as the only edge of a control (use Control Edge)
- **a status color** as the sole sign of a status
- **Failed orange-red** as anything other than a failure

## Type

Bricolage Grotesque

SemiBold (600), Bold (700) and ExtraBold (800), at optical size 96 and width 90, the same settings as the logo. Headlines on dark backgrounds use weight 670, as the dark logo does, in addition to those three.

For the logo, headlines and covers, never for body text.

Queued, then searchable.

The y, a and t have distinctive shapes at large sizes, so the name is recognizable at a glance. Bricolage Grotesque is an open-source font whose letter width and shape can be adjusted for large sizes.

Hanken Grotesk

Weights 400, 600 and 700.

Reading text, tables, labels and the operator interface.

Meilisearch is still indexing 4 updates. They are not searchable yet.

A plain sans-serif with open letter shapes and tabular (equal-width) numerals, so a dense table of counts stays legible.

Sometype Mono

Regular (400) and Medium (500).

Anything copied or compared: schema and index names, commands, Mix task output, times and code.

mix scrypath.status MyApp.Blog.Post

Sometype Mono’s zero has a slash (turn on the slashed-zero font feature), and 1, l and I look different from each other, so a module name or an id can be read aloud and copied correctly.

All three families are SIL Open Font License 1.1, from Google Fonts. Each family’s license text ships in assets/fonts. Hanken Grotesk and Sometype Mono have no up and down arrow characters (U+2191 and U+2193): write “up” and “down”, or draw the arrow.

## Type: the hierarchy

Display Covers, decks and social cards. One line, two at most. Bricolage Grotesque, 700, 56/1.05, -0.02em Queued, then searchable.

Heading Titles of pages and sections in docs and the operator UI. Bricolage Grotesque, 700, 28/1.2, -0.01em Which index is out of date?

Body README, guides and paragraphs in the operator UI. 62 to 72 characters a line. Hanken Grotesk, 400, 16/1.55, 0 In Oban mode, `Scrypath.sync_record/3` returns once the job is queued. The record is searchable when Meilisearch has indexed it.

Dense text Counts and notes in each Search health row. Always with tabular numerals. Hanken Grotesk, 400, 13/1.4, 0 2 updates pending, 3 retrying, 1 failed

Label Table heads and small captions. Set in sentence case, never in capitals. Hanken Grotesk, 600, 12/1.2, 0.01em Failed sync work

Code Schema and index names, commands, task output and times. Clicking a schema name, index name or command copies it. Sometype Mono, 400, 13/1.5, 0 mix scrypath.status MyApp.Blog.Post

## Type: in a dense row

Counts are set in 13 px Hanken Grotesk with tabular numerals, and names and times in Sometype Mono. The counts line up by digit, and each status is a word with its status icon.

### rules for dense rows

- Numbers that stack in a column use tabular numerals (`font-variant-numeric: tabular-nums`) so the digits line up.
- Every schema name, index name, command and time is set in Sometype Mono with the slashed zero on, so it can be compared by eye. None of them is ever set in Hanken Grotesk.
- Show the time zone with every time: `14:02 UTC`. A bare time is a defect, because the queue and Meilisearch can run in different zones.
- Clicking a name or command copies it and shows a brief “Copied to clipboard” note; the text does not move.
- Headlines are in sentence case. Nothing is set below 12 px or lighter than weight 400.
- Characters in code are never joined into one symbol (`font-variant-ligatures: none`), so a pipe operator or an arrow appears as the characters that were typed.

## Voice: the tone dial

**Every message in the operator UI says what happened, which schema or index it concerns and what to do next.**

- The operator UI and Mix task output: liveliness 0 on a scale from 0 (plain) to 4 (lively). Meilisearch is still indexing 4 updates. They are not searchable yet.
- Guides and README: liveliness 1 on a scale from 0 (plain) to 4 (lively). After you save a record, tell Scrypath to sync it with Scrypath.sync_record/3, then read what it returns.
- Release notes: liveliness 1 on a scale from 0 (plain) to 4 (lively). Failed sync work now shows why each update failed.
- Talks and social posts: liveliness 2 on a scale from 0 (plain) to 4 (lively). Full-text search for Elixir that tells you when your index is out of date.

Scrypath’s writing is plain in every channel. A talk or a post can be a little more lively than the guides. The operator UI and Mix task output are never lively, because people open them when the search index is out of date or an update has failed.

## Voice: this not that

- Say: “Meilisearch is still indexing 4 updates. They are not searchable yet.” Not: “Indexing in progress. Hang tight!”
- Say: “One delete for MyApp.Blog.Post 4417 failed at 14:31 UTC because Meilisearch did not respond in time.” Not: “Something went wrong while syncing.”
- Say: “Scrypath.sync_record/3 returned :accepted, so the update is not indexed yet. The record is searchable once indexing finishes.” Not: “Your documents are synced!”
- Say: “Two updates are waiting for their next attempt. Nothing for you to do yet.” Not: “All good! We are on it.”
- Say: “This schema syncs in `:oban` mode.” Not: “Search that just stays in sync.”
- Say: “Retry failed work for MyApp.Blog.Post.” Not: “Fix it”
- Say: “There are 2 pending updates in the Oban queue.” Not: “Everything looks fine upstream.”

### write for the people reading

- **Write for the person on call.** Name the schema and say what happened before showing the error’s technical name.
- **Point to the safe next action.** Every failure message says what you can do next and whether Scrypath will retry the update automatically.
- **Write the time zone with every time.** Write “14:02 UTC”, never a bare “14:02”.
- **One word per status.** Failed, Retrying, Pending and Clear mean different things, and no word is used for more than one of them.

## Voice: how to write the name

Write Scrypath in sentences and headings. Write `scrypath` for the logo, package, commands and file names, and `Scrypath` for the Elixir module. Never start a sentence with `scrypath` or write “scry/path”.

### describing the library

Call it “a full-text search library for Elixir”. Call the optional screens “the operator UI”, or ScrypathOps where the screens themselves show that name. Say “your app” for the Elixir app that uses Scrypath.

### not like this

- ~~scry/path, Scry Path~~: one word; the slash belongs to the logo only
- ~~SCRYPATH, ScryPath~~: one capital only (except ScrypathOps)
- ~~Scrypath.io, Scrypath Search~~: no suffix (except ScrypathOps)
- ~~the Scrypath platform, Scrypath Cloud~~: Scrypath is a library, not a service
- ~~scrypt~~: a different thing, the password-hashing function

| Written as | Where | Example |
| --- | --- | --- |
| **Scrypath** | Sentences, headings, release notes | Scrypath queued 4 updates for MyApp.Blog.Post. |
| **scrypath** | The logo, the package, commands, file names | mix scrypath.status |
| **Scrypath** | Elixir module names | use Scrypath, fields: [:title] |
| **ScrypathOps** | The operator UI, where the screens show that name | ScrypathOps: Search health |

## Voice: key terms

**The words this book uses.**

| Term | What it means here | Instead of |
| --- | --- | --- |
| **Schema** | The Ecto schema that declares what is searchable. Screens show its full module name in Sometype Mono. | ~~model~~, ~~resource~~, ~~entity~~ |
| **Update** | A change Scrypath sends to Meilisearch: a new or edited record, a delete, or a batch of records in a backfill. | ~~write~~, ~~indexing job~~, ~~task (Meilisearch has its own tasks)~~ |
| **Failed sync work** | The operator UI screen that lists updates that failed, each with its reason and what you can do next. | ~~errors~~, ~~dead jobs~~ |
| **Search health** | The operator UI screen that shows, for each schema, whether its search index is up to date and what is waiting. | ~~dashboard~~, ~~status page~~ |
| **Queued** | Waiting to be indexed: in the Oban queue, or sent and waiting in Meilisearch. Not searchable yet. In code, `Scrypath.sync_record/3` returns `:accepted`. | ~~synced~~, ~~done~~, ~~indexed~~ |
| **Searchable** | A new search reflects the update: a record that was added or edited is found, and a record that was deleted is gone. | ~~live~~, ~~fresh~~ |
| **Sync mode** | How Scrypath sends an update to Meilisearch. Inline: Scrypath waits for Meilisearch to index it, up to a time limit. Oban: a background job sends it. Manual: Scrypath sends it and you check afterward whether it was indexed. Written `:inline`, `:oban`, `:manual` in code. | ~~strategy~~, ~~adapter~~ |
| **Index** | The part of Meilisearch that holds a schema’s records for searching. Shown by its full name, in Sometype Mono. | ~~collection~~, ~~table~~ |

## Voice: key terms, continued

| Term | What it means here | Instead of |
| --- | --- | --- |
| **Backfill** | Re-sending existing records to an index, for example after adding Scrypath to a table that already holds records. | ~~reload~~, ~~resync~~ |
| **Managed reindex** | Building a new index and switching search over to it, when settings or mappings changed and the live index can no longer be trusted. | ~~rebuild~~, ~~migration~~ |
| **Drift** | A schema’s search index and its database table no longer match. Scrypath’s guides use this word; screens say which schemas have an out-of-date index. | ~~out of sync~~, ~~stale~~ |
| **Reconcile** | Comparing the index with the database and reporting the difference. | ~~verify~~, ~~audit~~ |
| **Saved search** | A search definition that can be run again. It keeps the query, not the results. | ~~playbook (API and file format only)~~, ~~saved check~~ |
| **Per-schema results** | The results of one search, listed separately for each selected schema. There is no combined relevance score. | ~~federated results~~, ~~merged results~~ |
| **Record loading** | After a search returns, your app loads the matching Ecto records itself; Meilisearch does not. | ~~hydration (in screens)~~ |
| **Your app** | The Elixir app that uses Scrypath, often a Phoenix app. | ~~host~~, ~~consumer~~ |

This list covers only the words this book uses. The product glossary is the source for screen copy; “hydrate” and “playbook” stay where the glossary uses them, in code and guides. In prose, write “queued” and “searchable”; in code the values are `:accepted` and `:completed`.

## Graphic elements

**Two graphic elements: the progress line and the slanted bar.**

Scrypath has two graphic elements, both built on the logo’s slash. They are not buttons, tabs or inputs; the product has its own buttons, tabs and inputs.

- **The slanted bar.** The slanted bar is the logo’s slash, shortened to a small bar. As a status icon it has four shapes: filled for Clear, hollow for Pending, filled from the bottom for Retrying and notched for Failed. It is also the marker at each step of the progress line and the bullet in this book’s lists. Draw every slanted bar as a single sharp-cornered bar that leans 14.46 degrees. Never repeat it as a stripe or pattern.
- **The progress line.** A line with one slanted bar, called a step marker, at each step. On a Search health row the steps are Queue, Meilisearch and Last succeeded; in this book they are the pages, down the left side, solid up to the current page and dashed after it. A solid line between two steps means updates have reached the later step; a dashed line means they have not. A step marker is filled once updates have reached it and hollow until then. Every progress line ends in a marker. On a Search health row, a step with waiting updates has a marker in the row’s status color and a count.

A status icon never appears without its word. Outside this book’s list bullets, the slanted bar appears only beside a status word or on a progress line. Never use the progress line as a loading animation or for anything that is not a series of steps in order.

## Graphic elements: the progress line

**How to read the progress line.**

Each row on the Search health screen has a progress line with three steps: `Queue`, `Meilisearch` and `Last succeeded`. A solid line means updates have reached the later step; a dashed line means they have not. A step marker is filled once updates have reached it and hollow until then. Each step that holds updates has a marker in the row’s status color.

The pictures on this page show three rows: one waiting for a retry in the Oban queue, one waiting in Meilisearch in inline mode, and one with nothing waiting in a schema that uses manual mode. A row that does not use a step shows a short note in words saying so.

## Imagery: the path

**Show the path an update takes.**

Scrypath’s pictures show the product at work, using the names Scrypath itself uses. They show the Search health screen, Mix task output, the five steps from a saved record to a search result (saved, queued, sent, indexed, searchable), and a schema declaration. They need no stock photography and no search-box icons.

### never

- Crystal balls, eyes and tarot
- Magnifying glasses over a database
- A cloud with an arrow to a search box
- Glowing neural-network nodes
- Rocket ships and lightning bolts
- Stock people at laptops
- Neon “AI search” gradients
- Result lists with perfect matches

**A terminal drawing.** Output from mix scrypath.status, set in Sometype Mono on Night.

**A row from the Search health screen.** A status word, its icon and the three steps of one schema, with sample data and a time zone.

A crystal ball does not show the steps and suggests guessing. A cloud with an arrow does not show them either. A glowing network has nothing a developer can check. With a drawing of the five steps or Mix task output, a developer can compare the picture with what Scrypath does.

Every product picture here is a drawing of a proposed layout filled with sample data; none is a screenshot of the product.

## Imagery: diagrams

**Diagrams show each step.**

### this

One failing delete, step by step, with the status Scrypath shows at each step. The step that needs a person is marked; the lines after it are dashed.

### not this

✕ A cloud, an arrow and a magnifying glass. This drawing could be any search product, shows none of the steps, and contains nothing a developer can check.

### diagram rules

- One idea per drawing.
- Label every part with the name Scrypath uses, such as Failed.
- Draw lines the same color as the text, with one status color at most.
- No icons inside boxes.
- Show the time zone with every time.
- Caption what the drawing shows and whether its data is sample data.

## Imagery: code colors

**Code in three hues.**

| Role | Light | Dark | Used for |
| --- | --- | --- | --- |
| **Text** | #1E1220 | #F4EDF3 | Names, functions, modules and punctuation. |
| **Comment** | #6B5F6E | #A89BAD | Comments, in a neutral gray-plum. |
| **Keyword** | #7B2D6B | #D58BC4 | Keywords such as use, def and fn, in plum. |
| **String** | #2748A8 | #93A9F5 | Strings, in ultramarine. |
| **Atom** | #006A7A | #6FD0DC | Atoms, keys and numbers, in a deep teal. |

- Code uses three hues, plum, ultramarine and teal, and two neutrals. It has no green, amber or red. The book’s check confirms, each time the book is made, that no code color is the same as a status color, and none is within 30 CIELAB units of Clear, Retrying or Failed.
- Syntax colors belong in code blocks. Inline code in a sentence is plain Sometype Mono on a lightly tinted background, with no syntax colors.
- ExDoc and HexDocs apply their own code colors, so these colors apply there only through the stylesheet in assets/docs, which was written for ExDoc’s class names. That stylesheet has not been tried in an ExDoc build yet.
- GitHub applies its own colors to code in a README, and Scrypath does not control them.
- Show code that runs on the current release, never pseudo-code.

defmodule MyApp.Blog.Post do ⏎ use Ecto.Schema ⏎ ⏎ use Scrypath, ⏎ fields: [:title, :body], ⏎ filterable: [:status], ⏎ sortable: [:inserted_at] ⏎ end

defmodule MyApp.Blog.Post do ⏎ use Ecto.Schema ⏎ ⏎ use Scrypath, ⏎ fields: [:title, :body], ⏎ filterable: [:status], ⏎ sortable: [:inserted_at] ⏎ end

## Applications: Search health

Light theme. A drawing of the proposed layout with sample data, not a screenshot of the product.

### What the search health screen is for

Use Search health to see which Ecto schemas have an out-of-date index, where their updates are waiting, and what to do next. Updates for several schemas can fail or wait together. A row shows the status of its most urgent update (Failed, Retrying, then Pending). Rows are sorted by status (Failed, Retrying, Pending, Clear), then by schema name.

### The first row and row actions

The first row is selected when Search health opens. The selected row also shows one sentence about its most urgent update, such as which update failed and when. Every row action, such as Retry failed work, is the same underlined text, so it looks the same on every row that has it.

### What a row shows

Search health shows one row for each Ecto schema. Each row has a progress line with three steps: Queue, Meilisearch and Last succeeded. A step that holds Pending, Retrying or Failed updates has a marker in the row’s status color and a count; a step with nothing waiting has no count. A solid line means updates have reached the later step; a dashed line means they have not. A marker is filled once updates have reached it and hollow until then.

### No cards or charts

Lines separate the rows. Search health has no cards or charts. Schema names and times are in Sometype Mono, and every time shows its time zone.

## Applications: Search health dark

Dark theme. A drawing of the proposed layout with sample data, not a screenshot of the product.

### Same layout on a dark background

The rows and progress lines are the same; only the colors change. Each status word is at least 4.5:1 on Night Panel (see the contrast pairs page).

### The selected row

On the dark background the selected row is lighter than Night Panel, never darker, with a 2 px Orchid line along its left edge.

### Status colors on dark

Failed is an orange-red, lightened for the dark theme. Retrying is amber and Pending a muted gray-plum, so waiting never looks like a fault.

## Applications: the terminal

`mix scrypath.status` in a terminal. The labels are what the task prints; the values are sample data. The prompt is Orchid.

### The labels the task prints

Backend failed, Queue pending, Queue retrying and Queue failed are the lines the task prints, copied from the task’s source code. The values here are sample data. A screenshot in the docs should show these labels unchanged.

### Terminal font and background

Sometype Mono at 13 px on the dark background, with the slashed zero. The terminal in the docs is dark in both themes.

### Error color in the terminal

Only a line that reports a failure uses an error color.

### Four mix tasks

`mix scrypath.status`, `mix scrypath.failed`, `mix scrypath.retry` and `mix scrypath.reconcile` let you do from the command line what you can see and do on the Search health screen.

## Applications: README, Hex and HexDocs

The README header: the logo, the approved short description, the version, license and Elixir requirement from `mix.exs` and Hex (the version is the one Hex listed in November 2026), and a schema declaration. A drawing of the proposed layout with sample data, not a screenshot of the product.

The Hex package header. Scrypath sets the wording; Hex supplies the page and its frame.

A HexDocs guide page. ExDoc supplies the navigation; the stylesheet in assets/docs sets the type and code colors (not yet tried in an ExDoc build).

## Applications: the website

The website’s first screen. A drawing of the proposed layout with sample data, not a screenshot of the product.

### Headline and button

The headline is the tagline. The one Plum button, “Read the golden path”, opens the README’s first guide.

### Show the command

The picture shows a Mix command and the output it prints, instead of a generic illustration.

### No version badge here

The version belongs in the README and on Hex, where the version is published with the package, so the page has no badge that can go out of date.

## Applications: link preview

The link preview image (shown here at half size) is dark across its whole area, because it appears with no page behind it. The book also shows it in link cards on a light and a dark page. A drawing of the proposed layout with sample data, not a screenshot of the product.

### What the image contains

The logo, the sentence “Queued, then searchable.” and a progress line with filled markers up to Meilisearch, followed by a hollow marker labeled Searchable, all on a Night background. The sentence is set in Bricolage Grotesque and is placed next to the logo, never inside it.

### What it leaves out

No screenshot, no magnifying glass, no gradient: the logo and the progress line are the only graphics.

### File and size

The PNG is 1280 by 640 px, the size GitHub’s social preview requires. Hex, a blog or a chat app may crop it differently.

### Margins

Logo and sentence start 40 px from the left and top edges of the full-size image.

## Applications: stickers and shirts

Six stickers: the logo and the symbol, each with a white border and with a border in Night, plus two text stickers. The laptop and shirts are stand-ins; only the printed art is the brand’s.

### Die-cut stickers are cut along the logo’s outline

The sticker is cut to the shape of the logo, with a border about 3 mm wide: white for the light logo, Night for the dark one. The border is part of the cut. The slash stays Plum, or Orchid on Night. The logo is never placed on a tile.

### Text stickers have a solid color background

A sticker with a sentence or a command can be Plum or Night, set in Bricolage Grotesque or Sometype Mono, with no logo on it.

### Shirts

On a shirt in Night use the dark logo, and on a shirt in Page the light one. On a Plum shirt, use the one-color logo in Pale Ink, because an Orchid slash would be hard to see. For a left-chest print use the symbol, about 30 mm wide; the full logo is never under 25 mm wide.

## Applications: light, dark and system

**Light by default. Dark when chosen, or when System follows a dark device.**

### light, the default

Search health rows use the Panel color on a Page background, with Ink text and Plum links. Row actions, such as Retry failed work, are underlined Ink text and look the same on every row. Each pair of text and background colors has a computed contrast ratio.

### dark

Search health rows use Night Panel on a Night background, with Pale Ink text and Orchid links, and the actions on rows are underlined Pale Ink text. The status colors are lighter tones of the same hues, and the logo’s slash is Orchid so that it is easy to see on Night.

### system

With System chosen, the book follows the device’s light or dark setting. The theme picker offers Light, Dark and System and remembers the choice. Docs and website follow the same rule, and the favicon follows the device’s light or dark setting.

## Applications: sync modes

**Where the call returns in each sync mode.**

Which step an update has reached when `Scrypath.sync_record/3` returns depends on the mode. In Oban mode the call returns once the update is queued as a job. In manual mode it returns once Meilisearch has received the update. In inline mode it returns once the update is indexed, or when the wait times out. Say which of the five steps an update has reached, never “synced”.

| Mode | Saved | Queued | Sent | Indexed | Searchable |
| --- | --- | --- | --- | --- | --- |
| `:inline` |  |  | :accepted | :completed | once indexed |
| `:oban` |  | :accepted |  |  | once indexed |
| `:manual` |  |  | :accepted |  | once indexed |

The columns are the five steps from a save to a search result. Each :accepted or :completed marks the step where the call returns.

### three sync modes

| Mode | The call returns | Choose it for |
| --- | --- | --- |
| `:inline` | `:completed` once Meilisearch has indexed the update, or `:accepted` if the wait times out first | Trying Scrypath out and following the README’s first guide. The call waits for Meilisearch to index the update. Production apps often use Oban mode instead. |
| `:oban` | `:accepted` once the Oban job is stored. Nothing has reached Meilisearch yet. | Apps whose saves must not wait on search. Jobs are stored, so they survive a restart. |
| `:manual` | `:accepted` as soon as Meilisearch has received the update, without waiting for indexing | Imports, scripts and jobs you write yourself. Scrypath creates no Oban job for the update, so you check afterward whether Meilisearch indexed the update. |

In inline and manual modes an update skips the Oban queue; in all three modes it goes through the steps Saved, Sent, Indexed and Searchable. The modes differ in where the call returns.

## Motion: the logo

**How the logo animation plays.**

The logo animation shows the sentence “Queued, then searchable.” A blinking cursor (an underscore) grows into the slash. The letters appear one after another. A highlight moves across the word, the way a search result is highlighted, and then the word moves down and back up once, after the highlight has crossed it. The animation ends on the finished logo, with nothing else on screen.

The logo never loops and the slash never repeats. The underscore never appears in the logo at rest. Nothing in the product pulses, and counts do not tick up. With reduced motion, the page shows the finished logo with a short fade and no movement.

1. **0 to 300 ms** A cursor blinks, then grows into the slash.
2. **300 to 400 ms** The slash drops in a little taller than its final size and leaning back, then moves to its final size and angle.
3. **440 to 895 ms** The letters appear one after another at uneven gaps, each moving up a little as it appears.
4. **800 to 1080 ms** A plum highlight moves across the word, behind the letters, at the slash’s angle.
5. **1100 to 1320 ms** The word dips down and back once, the slash gets wider once, and a cursor blinks after the h.
6. **1650 ms** The finished logo, identical to the static logo.

The logo animation plays once when the page first comes into view, and again on Replay. Play with sound starts the sound first and begins the animation when the sound is heard, so picture and sound match. With reduced motion the finished logo fades in and nothing moves. The same animation is in `assets/motion` as video, with its sound.

## Motion: the key poses

**Ten frames from 1.65 seconds.**

1. 60 ms The cursor blinks where the slash will be. A very quiet key.
2. 270 ms The cursor grows into the slash. No sound yet.
3. 300 ms The slash appears slightly too tall and leaning back. The one full-volume key and a low wooden note.
4. 360 ms The slash moves upright and stops at the logo’s own angle. The low note is still sounding.
5. 490 ms The letters s and c have appeared. Quiet keys, each a little higher.
6. 640 ms The y has appeared and the p is about to. Typing, at uneven gaps on purpose.
7. 880 ms A plum highlight moves across the word. A soft rising sweep.
8. 1110 ms The word dips down and back once and the slash gets wider once. Two notes that resolve.
9. 1320 ms The cursor blinks once after the h. A low key.
10. 1650 ms The finished logo, identical to the static logo. The notes fade out.

### six animation principles used

- **Anticipation** The cursor blinks first, so the slash does not appear out of nowhere.
- **Squash and stretch** The slash goes 4.5 percent past its final height and leans back 2.3 degrees, then moves to its final size and angle. It is scaled along its own length, so the stretch does not change its angle.
- **Follow-through and overlap** Each letter starts moving before the previous one has stopped. Each letter moves up about 12 percent of the x-height while it fades in, goes 1 percent past its final position, then returns.
- **Uneven timing** The letters appear 45 to 90 ms apart, never at even gaps, because evenly spaced letters look mechanical.
- **One focus at a time** The word is nearly complete before the highlight starts, and the two overlap for under 100 ms. The highlight moves smoothly, never flashing.
- **A clear exit** The cursor fades out and only the logo remains. The finished frame is the static logo.

## Motion: in the product

**In the product, an update moves from one step to the next.**

An update moving along the progress line, 600 ms per step, on a row from the Search health screen. A drawing of the proposed layout with sample data, not a screenshot of the product. A slanted bar travels along the dashed line from one step to the next, and the line behind it is solid. When the last waiting update in the row finishes, the last marker fills and the status word changes to Clear.

### what animates

- **An update moving to the next step.** A slanted bar travels along the dashed line to the next step, and the line behind it is solid. When the bar reaches the last marker, the marker fills. 600 ms.
- **A status change on one row.** The old word fades out as the new one fades in over 160 ms, and the status icon switches shape without moving. Color is never the only change.
- **Selection and focus.** The selected row’s left border and background, and the focus ring, appear within 80 ms.
- **The logo animation.** Once, on first view of a page that shows it, and on a deliberate replay.

### what never animates

- **Anything that repeats.** No pulsing progress lines, no fade that repeats, no spinner while updates wait. Waiting updates show as the word Pending or Retrying and a count.
- **Numbers counting up.** A count jumps straight to its new value.
- **A failed, retrying or pending status that shakes, flashes or bounces.** A failed update shows its word and status icon without movement, and its sound is soft, not an alarm.
- **Layout.** Rows, columns and the page never move while an update is moving. Only the animated element changes position or transparency.
- **The logo at rest.** In print, in the README header, in a favicon and in an avatar the logo is the static drawing.

## Motion: timing and easing

**Six easings, five durations.**

These are the only motion values the product uses. They are stored in `tokens.json` as named values.

| Name in tokens.json | Value | Use |
| --- | --- | --- |
| `motion.duration.instant` | 80 ms | A change the eye must not wait for: hover, press, focus. |
| `motion.duration.quick` | 160 ms | A small change of one element: a status word swapping, a row highlight. |
| `motion.duration.base` | 240 ms | A change of a region: a panel opening. |
| `motion.duration.advance` | 600 ms | An update moving to the next step along the progress line. |
| `motion.duration.sting` | 1650 ms | The whole logo animation, from the first blink to rest. |
| `motion.easing.strike` | cubic-bezier(0.1, 0.9, 0.2, 1) | Fast in, hard stop. For a thing that lands: the slash, a status icon arriving, a key press. |
| `motion.easing.resolve` | cubic-bezier(0.2, 0.8, 0.2, 1) | Quick start, soft landing. For a thing that appears: letters, a new row. |
| `motion.easing.settle` | cubic-bezier(0.3, 0, 0.2, 1) | Slow start, gentle stop. For coming back from an overshoot. |
| `motion.easing.sweep` | cubic-bezier(0.45, 0, 0.25, 1) | Ease in and out. For a highlight or a marker crossing something. |
| `motion.easing.exit` | cubic-bezier(0.4, 0, 1, 1) | Accelerates away. For a thing that leaves. |
| `motion.easing.advance` | cubic-bezier(0.45, 0, 0.2, 1) | Ease in and out, a little slower to arrive. For an update moving from one step to the next. |

### reduced motion

- The logo animation shows the finished logo and fades it in over 160 ms. Nothing moves.
- An update moving along the progress line appears at its new step right away; the status word and the solid line show where the update is now.
- The sound still plays if someone has pressed Play. It never starts by itself.
- The animation follows the device’s reduced-motion setting and no other setting.

### do

- In a video, keep each sound within ten milliseconds after its picture, never before it.
- Keep one element moving at a time, except where the logo timeline shows an overlap.
- Use the six easings and five durations in this book, and no others.
- Hold the finished logo for 1.5 seconds at the end of a video.

### don’t

- Add a second slash or repeat the slash. Meilisearch’s own mark is three slanted bars.
- Animate the slash’s angle at rest. The slash always leans 14.46 degrees.
- Show the cursor in the logo at rest. It exists only in the animation.
- Spin, bounce more than once, scatter the letters or make the highlight a flash.
- Use the logo animation as a loading animation. It plays once.

## Sound: the idea

**What the sounds are made of.**

Every sound is built from a muted key, a plucked wooden bar and a soft glide, in D minor, short and low in volume. Queued is two notes that end unfinished, on E5. Searchable goes from E5 to D5, the home note. Failed is a muted knock and a low note, never an alarm.

The sounds follow the sentence “Queued, then searchable.” Queued ends on a note that sounds unfinished, and Searchable ends on the note that completes it. Played one after the other they make one short phrase, and Done plays the whole phrase.

### queued, then searchable; done plays the two as one phrase

**Queued** Two notes, a fifth apart, ending on a note that sounds unfinished. The update is queued and not searchable yet. Play

**Searchable** The unfinished note drops to the home note over a low fifth. The record can now be found by searching. Play

**Done** The whole path in one phrase, queued, then found, ending on a low, resolved note. A batch or reindex has finished. Play

### the logo sound, full and quiet, and the shortest brand sound

**Logo sound** A muted key as the cursor blinks, then a firmer key and a low wooden note as the slash appears. Soft typing plays as the letters appear, then a rising sweep and two resolving notes. Play

**Logo sound, quiet** The same keys and notes without the typing and the sweep. For a place where the full version would be too busy. Play

**Slash** The shortest brand sound. One firm key and one low wooden note. For a notification or a short clip. Play

### the notes, in d minor

| The low note of the strike and of Done | D4 | 294 Hz |
| --- | --- | --- |
| The fifth: the first note of Queued | A4 | 440 Hz |
| Home: the note Searchable ends on | D5 | 587 Hz |

| The second: Queued’s last note | E5 | 659 Hz |
| --- | --- | --- |
| The first note of Failed | F4 | 349 Hz |
| The top of the highlight sweep | D6 | 1175 Hz |

## Sound: the events

**Nine sounds, each for one event.**

| Sound | When it plays | What you hear | LUFS, WAV and MP3 |
| --- | --- | --- | --- |
| **Logo sound** | The logo animation, for intros in docs, talks and video. | A muted key as the cursor blinks, then a firm key and a low wooden note as the slash appears. Soft typing plays while the letters appear, a rising sweep plays while the highlight moves, and two notes resolve when the word is found. | −21 and −24 |
| **Logo sound, quiet** | The same sound, for places where the full version would be too busy. | The same keys and notes without the typing and the sweep. | −21 and −24 |
| **Slash** | A notification or a short clip. The shortest brand sound. | One firm key and one low wooden note. | −24 and −28 |
| **Run** | Someone starts a backfill or a reindex in the operator UI. | A key and a quiet low note. | −28 and −32 |
| **Queued** | An update is queued, not yet searchable. | Two notes, a fifth apart, ending on a note that sounds unfinished. | −26 and −30 |
| **Searchable** | The record is now searchable. | The unfinished note drops to the home note over a low fifth. | −22 and −26 |
| **Retrying** | An automatic retry. | Two soft keys, the second lower and quieter. | −32 and −36 |
| **Failed** | One or more updates failed. | One muted knock and one low note that drops by a semitone. It sounds like a sigh, not an alarm. | −23 and −27 |
| **Done** | A batch or a reindex finished. | The whole phrase: queued, then found, ending low and settled. | −21 and −25 |

## Sound: where it plays

**Where sound belongs, and where it never does.**

In the logo animation, each sound is tied to one moment: the firm key and low note play when the slash appears, typing while the letters appear, the rising sweep while the highlight moves, the two resolving notes when the word is found, and a low key when the cursor blinks after the h. On the page, the sound starts first and the animation begins when it is heard, so speaker or Bluetooth delay cannot separate them. In the video, a sound may come up to ten milliseconds after its picture, never before it.

### how they were made

These sounds are synthesized from three parts: a muted key, a plucked wooden bar and a soft glide. There are no recordings. Their loudness and timing were measured, and the book’s check measures them again each time the book is made. A sound designer can re-record the same idea with a keyboard and a marimba bar without changing it.

- **In the operator UI.** Sound is off until someone turns it on with a single setting. Sound follows the system volume and mute.
- **In terminals, logs and CI.** Mix tasks, logs and CI output stay silent. Never use the terminal bell.
- **For frequent events.** Queued and Retrying play at most once every two seconds, however many records are involved.
- **For batches.** Done and Failed play once per batch, not per record.
- **For Slash and the logo sound.** Slash is for a notification or a short clip. The logo sound is for intros, talks and video, and plays only after someone presses Play.
- **Never** speed a sound up, layer a second sound on it, or add a sound to an event that has none.

### loudness and files

Each sound comes in two files. The raw WAV is the synthesis, 48 kHz and mono, measured between −21 and −32 LUFS: louder for rare and important sounds, quieter for frequent ones. The listening master is an MP3 at 320 kbps, corrected gently for laptop speakers and headphones. It is 4 LU quieter than its WAV (the two logo sounds are 3 LU quieter, at −24 LUFS) and under a −1 dBTP true-peak ceiling. The sound players in this book, the logo video and the MP3s use the listening masters. The WAVs are for the product and for a sound designer.

## Handoff: accessibility

**Contrast, color, keyboard, motion and zoom.**

These checks apply to the book and to the pairs it specifies. They do not certify a product built with them.

- Contrast Every text pair has a computed WCAG 2.2 ratio on the contrast page, in both themes. The Plum slash passes 3:1 as a graphic on Page and Orchid passes on Night.
- Never color alone Each sync status is written as a word. The four status icons have different shapes, so they can be told apart in grayscale, and the progress line uses solid and dashed lines and filled and hollow markers, so a person who cannot tell hues apart reads the same thing.
- Time zones Every time shows its time zone, so a person in another zone reads the same moment.
- Keyboard and focus The focus ring is the Plum or Orchid 2 px ring (3:1 or better against the page). Schema names, index names and commands that copy when clicked are buttons, and you can reach and use them with the keyboard.
- Reduced motion The logo’s motion has a finished, still version that shows no animation when the device is set to reduced motion, and nothing in the book animates forever.
- Size and zoom Body text is 16 px and nothing is smaller than 12 px. The book reflows to a phone width without horizontal scrolling, except for the logo measurement drawing.

## Handoff: which file to use

| You need | Use (in assets/) |
| --- | --- |
| Logo on a light background | `logo/scrypath-lockup-light.svg` `logo/scrypath-symbol-light.svg` `logo/scrypath-lockup-light-2048.png` |
| Logo on a dark background | `logo/scrypath-lockup-dark.svg` `logo/scrypath-symbol-dark.svg` `logo/scrypath-lockup-dark-2048.png` |
| One color: print and single-color jobs | `logo/scrypath-lockup-one-color-ink.svg` `logo/scrypath-lockup-one-color-pale-ink.svg` `logo/scrypath-symbol-one-color-ink.svg` `logo/scrypath-symbol-one-color-pale-ink.svg` |
| Favicon (the symbol, drawn for 16 and 32 px) | `icon/favicon.svg` `icon/favicon.ico` `icon/favicon-32-light.png` `icon/favicon-16-light.png` |
| Avatar (a 512 px square: the one place the symbol sits on a background) | `avatar/scrypath-avatar-light.svg` `avatar/scrypath-avatar-dark.svg` `avatar/scrypath-avatar-512-light.png` `avatar/scrypath-avatar-512-dark.png` |
| README header | `readme/scrypath-header-light.svg` `readme/scrypath-header-dark.svg` `readme/header-snippet.html` |
| Link preview and social card | `social/scrypath-social-card-1280x640.png` |
| Docs: code colors for ExDoc | `docs/scrypath-exdoc.css` |
| Logo animation (video, light and dark, with sound) | `motion/scrypath-logo-animation-dark.mp4` `motion/scrypath-logo-animation-dark.webm` `motion/scrypath-logo-animation-light.mp4` `motion/scrypath-logo-animation-light.webm` |
| Sounds: raw files for the product and for a sound designer | `sound/` |
| Sounds: listening masters (MP3) for demos and video | `sound/listening/` |
| Fonts | `fonts/web/fonts.css` `fonts/variable/BricolageGrotesque[opsz,wdth,wght].ttf` `fonts/variable/HankenGrotesk[wght].ttf` `fonts/variable/SometypeMono[wght].ttf` `fonts/OFL-BricolageGrotesque.txt` `fonts/OFL-HankenGrotesk.txt` `fonts/OFL-SometypeMono.txt` |

## Handoff: contact and legal

**Questions, approvals and license.**

To ask the maintainers to approve a change to the logo or colors, send these three items.

1. **Where it will appear** Name the page, product or print piece, and who will see it.
2. **Which file you used** Say which logo file and which theme, so a change is easy to spot.
3. **A picture of the use** A screenshot or a mock-up. A rough one is enough.

- Who to ask Ask the Scrypath maintainers, through the project’s issue tracker, about the brand or about using it. Any use that changes the logo or colors needs the maintainers’ approval. Unchanged use under the rules in this book needs none.
- Use by others Hex packages, blogs, newsletters and conference sites may use the logo unchanged to refer to Scrypath. Do not use it to suggest that Scrypath endorses another product, or that Meilisearch is affiliated with Scrypath. Do not alter the logo, or build one from the slash alone, unless the maintainers have approved the change.
- Legal Scrypath is released under the Apache License 2.0. The logo files and this book fall under the same license, unless the repository states a different one. This book claims no registered trademark, and no trademark register was searched. Meilisearch is a separate product. This brand does not use Meilisearch’s logo or colors and does not imply an affiliation.

## Considered and not needed

**Mascot**

A mascot was considered and not proposed. A character would not help a library that people trust for plain wording.

**Patterns and textures**

The progress line and the slanted bar are the only graphic elements. A pattern would make a dense row harder to read, and the status words and the progress line already show where each update is.

**Stock photography**

A photograph cannot show a sync queue. A drawing of the Search health screen or a diagram can.

**A magnifying glass**

Most search products use one. Scrypath’s mark is the slash inside its name.

**A leading slash and a cursor**

The alternative with the slash in front (/scrypath, symbol /s) is kept in the logo files and not chosen: a slash before a word is a common developer motif. Typesense, another search engine, puts a cursor after its name in its logo, so the Scrypath logo has none at rest; one appears only in the logo’s motion.

**Icon set**

The operator UI uses words and the four status icons, and no other icon set. A new icon would need a new word from the product glossary.

**Brand-colored tables**

The progress line and status words show where each update is, so rows stay on Panel or Night Panel, apart from the selected row. Only the status icon, the status word and markers at waiting steps use color.

## Handoff: retired

**What version 1.0 replaces.**

Kept from the earlier book: the name, the slash inside it, the plain voice and the rule to say when an update is still queued and not yet searchable. The tagline changed; see the last row.

| Retired | Now | Why |
| --- | --- | --- |
| The split name scry/path in Familjen Grotesk, with a copper slash that was a plain font character. | The slash is kept as the idea and is now drawn for the logo: Bricolage Grotesque letters and one sharp-cornered Plum slash. | A name split in two reads as two words, and a slash set as a font character had default spacing. |
| The s/p monogram, and the S on a dark square tile. | The symbol s/, set directly on the page. Only the avatar has a square background. | An abbreviation gives a reader no information about the name, and a tile behind the letters hides part of the drawing. |
| Violet `#5B4AD1` as the lead color, and copper `#C17A3E` as the second. | Plum, and Orchid on dark. Violet is close to Meilisearch’s own blue-violet. | Violet measured 15 CIELAB units from the blue-violet Meilisearch uses, and could suggest an affiliation. |
| Inter for the interface and IBM Plex Mono for code. | Hanken Grotesk and Sometype Mono. | Tabular numerals, a slashed zero and a clear 1, l and I are worth more in a dense row than a familiar typeface. |
| The line “Declarative search, observable sync, dependable results.” | The current tagline, which comes from the website (see Messaging). | One plain sentence tells a developer more than three abstract nouns. |

## Handoff: to review

**Decisions in this edition that are open to review**

1. **The slash stays inside the word, as in the earlier logo. The alternative puts it in front.** The earlier mark was a copper slash set between scry and path. That is the one idea of the old logo worth keeping, so this edition keeps it and redraws it at the angle of the typeface’s own slash. The alternative /scrypath, with symbol /s, is the typed-command reading and the more common developer motif; it is kept in the logo files and not chosen.

2. **The name stays one word and the slash is a logo device only.** The earlier logo split the name as scry/path. This edition keeps `scrypath` as one word, so text never says “scry/path”.
3. **The accent is plum, a new hue for this library.** The earlier palette was violet and copper. Violet was close to Meilisearch’s own blue-violet, and plum is at least 33 CIELAB units from the brand color of every search tool measured. Adopting it changes the operator UI’s main and accent colors and the contrast checks, so it is a coordinated change.
4. **Failed is an orange-red, close to Retrying’s amber.** The two are 29 degrees apart on the CIELAB scale, and the check fails under 25. The icon shape and the word also tell them apart. Only Failed uses orange-red.
5. **The tagline comes from the website’s headline.** It is plain and accurate, so it stays. Four other taglines were offered and not chosen.
6. **The symbol is s/, a letter and a slash.** It is nearly square and is drawn separately for 16 and 32 px. On its own it is just an initial, so its meaning (the start of the name, and of the sed substitute command) has to be explained in words. Not yet checked at 16 to 24 px on a phone or laptop screen.
7. **The slash resembles Meilisearch’s mark.** Meilisearch’s own logo is three slanted rounded bars in a pink gradient. This logo is one flat Plum slash with sharp corners, and the symbol always carries a letter. The risk is handled by use rules, not by geometry alone. Orchid on dark is the nearest color, 33 CIELAB units from that pink.
8. **The ink traps are cut back to half depth.** Bricolage Grotesque’s ink traps read as hairline cracks at display size, so each of the six is cut back to half its depth. It is the logo’s one drawn detail, and no type designer has reviewed it yet.

## Handoff: risks and not done

**Risks and things not done**

1. **Pending is a muted gray-plum, not an alert color.** Waiting is normal when updates are sent in the background, so only Failed uses an error color. Retrying is amber because a person may soon need to look.
2. **Scrypath keeps the product glossary’s words on screens.** The product glossary uses the names Search health, Failed sync work, Sync and index, Saved search, Per-schema results and Record loading. This book uses the same names.
3. **The Search health pictures are a proposal.** They show the layout this book proposes, filled with sample data. They are not a screenshot of the current Search health screen. The three steps follow the queue and backend lines that `mix scrypath.status` prints today.
4. **The pictures use MyApp.* names and `.test` addresses.** Sample data uses example app names such as MyApp.Blog.Post and MyApp.Catalog.Product, and addresses that end in .test.
5. **The ExDoc stylesheet is not verified.** It was written from ExDoc’s class names and not run in an ExDoc build.
6. **The logo motion and the sounds are designed and measured, not yet checked by eye and ear.** The picture and the sound line up to within 10 ms, and every sound is on its loudness target. Not yet checked: the animation at normal playback speed, and the sounds on a laptop speaker. The keys sit mostly under 500 Hz and may sound like a click on a small speaker, and eight typed keys in a row may sound like a ratchet. A quiet version of the logo sound is included for that case.
7. **The first five letters of Scrypath are the first five of scrypt, the password-hashing function.** Five Hex packages are named for scrypt, and scrypath.com is a career site, so Scrypath cannot use the .com domain. The Hex packages and the career site are not conflicts in the Elixir space. The name is kept, and not cleared beyond the lookups under Not checked.

**Not checked:** Name clearance is limited: lookups of Hex, npm, PyPI, crates.io, RubyGems, GitHub, the US and UK App Stores and eight domain extensions found no conflict in the Elixir space (scrypath.com is taken by a career site), but no trademark register was searched. Look-alike pass: a slash before a word was compared from memory, not looked up. Not checked yet: the symbol at 16 to 24 px on a phone or laptop screen; the operator UI itself, since the pictures are drawings; the ExDoc stylesheet in an ExDoc build; a screen reader and a keyboard on the pictures; printing; the animation at normal playback speed; and the sounds on a laptop speaker.
