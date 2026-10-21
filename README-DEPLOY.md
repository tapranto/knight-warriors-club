# Knight Warriors Club — Deploy Package (Netlify + GitHub)

This folder is the complete, ready-to-publish website. Push the **contents of
this folder** to the GitHub repository `knight-warriors-club` (they sit at the
repo root), then connect that repo to Netlify.

## Contents

| Path | What it is |
|---|---|
| `index.html` | The whole website (single page, all images inlined). Design, backgrounds, committee, rules, gallery and forms are exactly as exported; the frequently-changing content loads at runtime from `data/*.json`. |
| `data/announcements.json` | Announcements shown on the Events page. Root object: `{ "announcements": [ {date, title, body, link, linkText} ] }` (`link`/`linkText` optional). |
| `data/tournament.json` | Home-page “Running Tournament” block: `{ status: "coming-soon" \| "live", name, latestResults: [strings], nextMatch }`. |
| `data/leaderboard.json` | Per-game standings: `{ "PUBG": [{rank, player, points}], "eFootball": [], "Clash of Clans": [], "Call of Duty": [] }`. An empty list shows the “season rankings coming soon” message. |
| `data/members.json` | The 68 general member names (JSON array of strings) for the Community page search/list. |
| `admin/index.html` | Decap CMS loader page — served at `/admin`. |
| `admin/config.yml` | Decap CMS configuration (git-gateway backend). |
| `assets/uploads/` | Created automatically by the CMS when images are uploaded (media folder). |

## Netlify site settings

- **Publish directory:** the repository root (`.`) — this folder *is* the root.
- **Build command:** *(none — leave empty).* The site is plain static files;
  there is nothing to build.
- Framework preset: “Other” / no framework.

## Admin panel (`/admin`) — one-time setup

1. In `admin/config.yml`, replace the placeholder `__GITHUB_USERNAME__` with
   the GitHub username that owns the repo (backend repo is
   `__GITHUB_USERNAME__/knight-warriors-club`, branch `main`).
2. In the Netlify dashboard for the site: **Site settings → Identity →
   Enable Identity.**
3. Then **Identity → Services → Enable Git Gateway.**
4. Invite yourself (and any committee editors) under **Identity → Invite
   users**. Editors log in at `https://<your-site>/admin`, edit announcements,
   the tournament block, leaderboard or members, and hit Publish — Decap
   commits the changed JSON to GitHub and Netlify redeploys automatically.

The CMS collections edit exactly the four `data/*.json` files above, so
content changes never touch the page code.

## Join form

The application form carries Netlify Forms attributes
(`name="join-application"`, `data-netlify="true"`), including the new
**Facebook ID link** and **Email** fields. Once the site is live on Netlify,
each successful “Prepare My Application” also posts the application to Netlify
Forms in the background (see **Forms** in the Netlify dashboard), while the
visitor still gets the same copyable application summary as before. Off-Netlify
(e.g. a local preview) the background post simply fails silently and only the
summary is produced.

## Local preview

```bash
cd deploy
python3 -m http.server 8000
# open http://localhost:8000
```

(Opening `index.html` as a file:// URL works for the static content, but the
browser blocks the `data/*.json` fetches — the page then falls back to the
baked-in copies of the same content.)
