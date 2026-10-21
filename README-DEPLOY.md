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
| `index.html` | The whole website (single page, design images inlined). Design, per-view backgrounds, committee, rules, gallery and the join form are unchanged from v1. Everything tournament-related is computed in the visitor's browser from `data/*.json` — there is no build step and no server. One exception: the tournament pages' arena background is an external file (see `assets/` below). |
| `data/tournaments.json` | `{ "tournaments": [ {id, name, game, status, startDate, endDate, intro, participants[], champion, championPhoto} ] }`. `status` is `upcoming` \| `running` \| `finished`. Ships with the finished **eFootball Demo Cup (DEMO)** included — the owner chose to keep the demo, so the site launches with a complete worked example. Delete that entry (and its matches) if it should ever go. |
| `data/matches.json` | `{ "matches": [ {tournamentId, date, player1, player2, goals1, goals2, played} ] }`. `played: false` = fixture, `played: true` = result. Goals may be `null` until played. Ships with the demo cup's six played matches. |
| `assets/background-tournament-arena.gif` | The owner's gladiator-arena picture (1920×1080) — the fixed background of every tournament page, referenced from `index.html` by relative path (not inlined, to keep the HTML lean). |
| `assets/champion-demo-photo.webp` | The demo champion's photo (a generated illustration standing in for a real champion photo upload), referenced by the demo tournament's `championPhoto`. |
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
  Players level on all three share the position number; 🥇🥈🥉 mark 1st–3rd.
- **Records** — Top Scorer, Most Wins, Most Goals Against, Best Defence,
  Best Goal Difference, Most Matches Played, Biggest Win, Most Draws,
  Most Goals in One Match, Best Points-Per-Match, Most Losses,
  Highest-Scoring Match. Records with no holder yet (e.g. no wins yet) are
  hidden until a match produces one.
- **News** — every played match becomes a headline
  ("A beat B 3–1", or "A drew 2–2 with B") tagged with its tournament, and
  every finished tournament with a champion becomes a
  "🏆 CHAMPION — &lt;name&gt; wins &lt;tournament&gt;" headline. Both merge
  with the manual News cards into one feed (News section; latest 3 on Home).
  Use real dates (e.g. `2026-11-03`) on matches/tournaments/news so the
  feed can sort newest-first; undated items sink to the bottom.
- **Placement by status** — `running` → Home tournament band (name + next
  fixture) and the Events **Running** banner; `upcoming` → Events
  **Upcoming** banner; `finished` → Events **Tournament History** banner
  (name + champion). Everywhere a tournament appears, its **name** is the
  click target (underlined, with an arrow) and opens the tournament's own
  page: Overview · Fixture · Results · Table · Records · Participants.
  Every tournament page uses the gladiator-arena picture
  (`assets/background-tournament-arena.gif`) as its fixed background.
  A finished tournament's Overview layers the champion's photo **above
  that arena background**, with a CHAMPION name panel in front.
- **Leaderboard (tournament-first)** — picking a game tab lists **that
  game's tournaments by name** (tappable rows showing each tournament's
  status); picking a tournament then shows **that tournament's standings
  table only** — computed from its own matches in `data/matches.json`,
  with the same points/sorting/medals as the tournament page's Table,
  the tournament name as the heading, and a "← All tournaments" button
  back to the list. There is **no merged or all-time table** anywhere.
  A game with no tournaments yet shows the "season rankings coming
  soon" state (currently PUBG, Clash of Clans and Call of Duty).

Tournament pages are linkable: `https://<your-site>/#tournament/<id>`.

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

(Opening `index.html` as a file:// URL works for the static content, but
the browser blocks the `data/*.json` fetches — the page then falls back to
the baked-in copies: “Tournament: Coming Soon”, the two manual news cards,
and the coming-soon leaderboard state.)
