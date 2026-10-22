# Knight Warriors Club — Deploy Package v2 (Netlify + GitHub)

This folder is the complete, ready-to-publish website (v2: automatic
tournaments, tables, records and news). Push the **contents of this folder**
to the GitHub repository `knight-warriors-club` (they sit at the repo root),
then connect that repo to Netlify. It replaces the v1 package file-for-file;
the old `data/tournament.json` and `data/leaderboard.json` are gone — delete
them from the repo if they are still there.

## Contents

| Path | What it is |
|---|---|
| `index.html` | The whole website (single page). Design images are **external files** under `assets/` (nothing heavy is inlined), and each view loads only its own images: the first load fetches just the page, the shared shell art (logo, corner knights) and the Home background; Community and Gallery photos sit in `data-src` and are only requested when that view is first opened; tournament pages pull the arena + champion assets only when a tournament page opens (then they stay cached). Everything tournament-related is computed in the visitor's browser — there is no build step and no server. Over HTTP the content is driven by `data/*.json` (see below); the same demo data is also baked into the page as a fallback. |
| `data/tournaments.json` | `{ "tournaments": [ {id, name, game, status, startDate, endDate, intro, participants[], champion, championPhoto, championCutout} ] }`. `status` is `upcoming` \| `running` \| `finished`. Ships with the finished **eFootball Demo Cup (DEMO)** included — the owner chose to keep the demo, so the site launches with a complete worked example. Delete that entry (and its matches) if it should ever go. |
| `data/matches.json` | `{ "matches": [ {tournamentId, date, player1, player2, goals1, goals2, played} ] }`. `played: false` = fixture, `played: true` = result. Goals may be `null` until played. Ships with the demo cup's six played matches. |
| `assets/background-tournament-arena.webp` | The owner's gladiator-arena picture (1920 px wide, right-sized WebP) — the fixed background of every tournament page, referenced from `index.html` by relative path and loaded only when a tournament page opens. (Replaces the old `background-tournament-arena.gif` — delete that file from the repo.) |
| `assets/` (everything else) | All design imagery as plain files, mirroring the site's own layout: per-view backgrounds (`background-*.jpg`), banners (`banner-*.jpg`), section art (`sections/`), committee photos (`committee/`, `styled/`), the shell art (`logo.jpg`, `knight-left.webp`, `knight-right.webp`, `moon-swords.webp`, `pattern.jpg`) and `intro-document.jpg`. All right-sized to how they are displayed — same pictures, much smaller files (total site imagery ≈ 5.3 MB, down from ≈ 19.4 MB). |
| `assets/champion-demo-photo.webp` | The demo champion's photo (a generated illustration standing in for a real champion photo upload), referenced by the demo tournament's `championPhoto`. |
| `assets/champion-demo-cutout.png` | The demo champion's transparent cut-out (champion holding a trophy overhead, ≈ 291 KB), referenced by the tournament's optional `championCutout` field — on a finished tournament's page it stands at the bottom-right of the header band, over the arena background (tournaments without the field keep a plain header). |
| `data/announcements.json` | Manual news cards: `{ "announcements": [ {date, title, body, link, linkText} ] }` (`link`/`linkText` optional). |
| `data/members.json` | The 68 general member names (JSON array of strings) for the Community page search/list. |
| `admin/index.html` | Decap CMS loader page — served at `/admin`. |
| `admin/config.yml` | Decap CMS configuration (git-gateway backend, repo `tapranto/knight-warriors-club`, branch `main`). |
| `assets/uploads/` | Created automatically by the CMS when images (e.g. champion photos) are uploaded. |

## How v2 works

**One entry drives everything.** A match result is entered once — in the
admin **Matches** collection, or by editing `data/matches.json` — and the
site derives the rest in the browser:

- **Tournament table** — Played / W / D / L / GF / GA / GD / Points
  (win 3, draw 1, loss 0), sorted by Points → Goal Difference → Goals For.
  The top three rows carry the 1st–3rd rank badges.
- **Records** — Top Scorer, Most Wins, Most Goals Against, Best Defence,
  Best Goal Difference, Most Matches Played, Biggest Win, Most Draws,
  Most Goals in One Match, Best Points-Per-Match, Most Losses,
  Highest-Scoring Match. Records appear once a match produces a holder.
- **News (a separated portal inside the News section)** — every played
  match becomes a headline ("A beat B 3–1", or "A and B drew 2–2"), and
  every finished tournament with a champion becomes a
  "CHAMPION — &lt;name&gt; wins &lt;tournament&gt;" headline, shown first.
  Both merge with the manual News cards into one feed, presented as a
  news portal in the site's dark red/black branding: a **Breaking**
  ticker strip carrying the latest headline, the newest story as a
  **full-width featured highlight** (no sidebar), then a grid of large
  story cards — each with a photo (the champion's photo for champion
  stories, the arena picture for results, club art for announcements), a
  red tag chip (Champion / Result / Club News), the headline and the
  date. Every card — featured, grid, ticker and the latest-3 rows on
  Home — is a **whole-box link**: clicking anywhere on it opens that
  story's own **article page inside News** (`#news/<story-id>`), never
  the tournament page. Articles carry a "← All news" back link, the tag
  and date, a large headline and a hero photo; manual announcements
  show their full text, result articles show the tournament, a match
  card (Player1 G–G Player2), the date and which player currently
  leads that tournament's table, and champion articles show the
  champion, the tournament and the final top three. Only result and
  champion articles end with a small "View the full tournament →"
  footer link.
- **Placement by status** — `running` → Home tournament band (name + next
  fixture) and the Events **Running** banner; `upcoming` → Events
  **Upcoming** banner; `finished` → Events **Tournament History**
  banner, which lists the finished tournaments **one by one in small,
  body-sized lines** (name — at about the size of the "Champion: …"
  text, not the big display heading — with the champion noted), so a
  long history stacks cleanly. Everywhere a tournament appears, its **name** is the
  click target (underlined, with an arrow) and opens the tournament's own
  page: Overview · Fixture · Results · Table · Records · Participants.
  Every tournament page uses the gladiator-arena picture
  (`assets/background-tournament-arena.webp`) as its fixed background.
  A finished tournament's Overview layers the champion's photo **above
  that arena background**, with a CHAMPION name panel in front.
- **Leaderboard (tournament-first)** — picking a game tab lists **that
  game's tournaments by name** (tappable rows showing each tournament's
  status); picking a tournament then shows **that tournament's standings
  table only** — computed from its own matches in `data/matches.json`,
  with the same points and sorting as the tournament page's Table,
  the tournament name as the heading, and a "← All tournaments" button
  back to the list. There is **no merged or all-time table** anywhere.
  A game with no tournaments yet shows the "season rankings coming
  soon" state (currently PUBG, Clash of Clans and Call of Duty).

Tournament pages are linkable: `https://<your-site>/#tournament/<id>`.
News articles are too: `https://<your-site>/#news/<story-id>`.

## Netlify site settings

- **Publish directory:** the repository root (`.`) — this folder *is* the root.
- **Build command:** *(none — leave empty).* Plain static files.
- Framework preset: “Other” / no framework.

## Admin panel (`/admin`) — one-time setup

1. In the Netlify dashboard for the site: **Site settings → Identity →
   Enable Identity.**
2. Then **Identity → Services → Enable Git Gateway.**
3. Invite yourself (and any committee editors) under **Identity → Invite
   users**. Editors log in at `https://<your-site>/admin`, manage **News**,
   **Tournaments**, **Matches** and **Members**, and hit Publish — Decap
   commits the changed JSON to GitHub and Netlify redeploys automatically.

Day-to-day workflow: create the **Tournament** once (name, game, dates,
participants) and set it Running. Add its **Matches** as fixtures
(`played` off). After each match, fill in the score and flip `played` on —
the table, records and news headline update everywhere on the next page
load. When the tournament ends, set the champion (and photo) and flip the
status to Finished.

## Join form

The application form carries Netlify Forms attributes
(`name="join-application"`, `data-netlify="true"`), including the
**Facebook ID link** and **Email** fields. Once live on Netlify, each
successful “Prepare My Application” also posts the application to Netlify
Forms in the background (see **Forms** in the Netlify dashboard), while the
visitor still gets the same copyable application summary as before.
Off-Netlify the background post simply fails silently.

## Local preview

```bash
cd deploy-v2
python3 -m http.server 8000
# open http://localhost:8000
```

(Opening `index.html` as a file:// URL also works: browsers block the
`data/*.json` fetches there, so the page simply renders from the copies
baked into `index.html` — the full site, including the demo tournament
with its table, records and champion page. Edits made through the admin
panel only show when the site is served over HTTP, as it is on Netlify.)

## Loading & performance

The page loads **per view**: the initial download is just `index.html`
(≈ 175 KB) plus the shell art, the Home background and the small
`data/*.json` files (≈ 615 KB total).
Each other view's images are fetched the first time that view is opened
and stay cached afterwards (Community ≈ 955 KB, Gallery ≈ 898 KB, a
tournament page ≈ 834 KB, the rest less). All imagery is right-sized to
its display size, so the whole package is ≈ 5.6 MB — it was ≈ 24 MB when
every image was inlined into the HTML.
