# TV Home — a custom Fire TV home screen

An Apple TV–style home screen for Fire TV. The top row is filled with recommendations
from your Jellyfin server (continue watching, next up, unwatched picks, recently added),
the row under it shows your IPTV channels (recently watched + favourites), and the bottom
bar is your own app dock, which you can edit from the remote.

Both Jellyfin and IPTV play **inside the app** with a built-in ExoPlayer, the same engine
the official Jellyfin and most IPTV apps use.

## 1. Build the APK (no Android Studio needed)

1. Create a new **private** repo on GitHub and upload everything in this folder
   (including the hidden `.github` folder).
2. Open the repo's **Actions** tab. The "Build APK" workflow runs automatically
   (or press *Run workflow*). It takes ~3 minutes.
3. Open the finished run and download the **TVHome-apk** artifact → `app-debug.apk`.

Prefer Android Studio? Open this folder as a project and press Run / Build APK.

## 2. Install it on the Fire Stick

- Fire Stick: *Settings → My Fire TV → Developer options* → turn on **Apps from Unknown Sources**
  (for the Downloader app) and **ADB debugging** if you want to use adb.
- Easiest: put the APK somewhere with a link (Google Drive direct link, your own server…),
  then open it in the **Downloader** app and install.
- Or from a computer: `adb connect <firestick-ip>` then `adb install -r app-debug.apk`.

"TV Home" then appears in *Your Apps & Channels*. Hold the Home button → Apps,
and move it to the front row so it's one click away.

## 3. Connect Jellyfin

Settings (⚙ top-right) → enter your server (e.g. `http://192.168.1.20:8096`, or
`http://127.0.0.1:8096` if the server runs on the stick itself), username and password → **Connect**.

Under *When I pick a title* choose:
- **Play in TV Home (built-in player)** — the default. Opens a title page (resume / play from start /
  mark watched / favourite, seasons and episodes for shows) and plays it right here.
- **Open the Jellyfin app** — launches Jellyfin for Android TV (`org.jellyfin.androidtv`).
- **Open Jellyfin web inside TV Home** — opens that title's page in Jellyfin's web player,
  right inside this app. Back returns to the home screen.

### The built-in Jellyfin player

- **Direct play** whenever the Fire TV can decode the file (it checks the stick's own decoders:
  H.264, HEVC, VP9, AV1, Dolby Digital/DD+ …); otherwise Jellyfin converts it (HLS). If direct play
  fails part-way, it switches to a converted stream automatically.
- **Saves where you are.** Progress is reported to Jellyfin every 10 seconds, on pause, on seek and when
  you stop, so *Continue Watching* / *Next Up* stay in sync with your other devices. A copy is also kept
  on the stick in case the server can't be reached.
- Audio + subtitle picker (your choice is remembered per series), *Skip intro* (Jellyfin 10.10 media
  segments), *Up next* with a 10-second countdown, picture fit/zoom, playback speed.

| Remote | While watching |
|---|---|
| OK / ▶❚❚ | Pause / play (OK also brings up the controls) |
| ◀ ▶ (or ⏪ ⏩) | Skip back/forward — hold to scrub faster, it jumps when you let go |
| ▼ in the controls | Buttons: audio, subtitles, next episode, more |
| ≡ Menu | Options |
| Back | Hide controls, then exit (your place is saved) |

Tip: press ▶❚❚ on a home-screen card to start it straight away.

### Wrestling tab

A big showcase up top (the next WWE Premium Live Event with a countdown, or whatever you're focused on, with its
match card), then rows: **This week** (latest Raw, SmackDown, NXT, Dynamite, Collision), **WWE Premium Live Events**,
**AEW** (with an *Open MyAEW* tile), **On your Jellyfin** (if you have a library with "wrestling", "WWE", "AEW"… in
its name) and **Wrestling channels** from your IPTV. WWE opens in Netflix, AEW opens the MyAEW app.
**Search wrestling** in the tab bar searches all of it. Show info comes from TMDB (the same key as Netflix).

### Netflix on Explore

Explore mixes in what's **trending** and **new on Netflix** (UK by default), each with a red N in the corner;
Jellyfin titles get the Jellyfin logo. OK (or ▶❚❚) on a Netflix card opens that exact title in the Netflix app.
Titles come from TMDB and the Netflix link from Watchmode (both free API keys, already filled in under
Settings → *Netflix on Explore*, where you can also hide the Netflix titles or change country; *Check Netflix* tests both keys).
It can't show your own Netflix Continue Watching or My List — Netflix doesn't share those with other apps.

### Movies and Shows tabs

Move onto **Movies** or **Shows** and the page switches to that library: *Continue watching* along the
top (in-progress films, or the next episode of each show), then every title A–Z underneath. Scroll down
as far as you like and more loads in. **Search movies / Search shows** sits at the end of the tab bar;
results narrow with every letter. **Back** from either tab returns to Explore.

With the Home button remapped to TV Home (Button Mapper etc.), pressing Home always closes whatever is
open (saving your place in anything you're watching) and lands on Explore.

The screensaver can't kick in while something is playing, including while it buffers or changes
channel. It can come on again once you pause.

### Football scores

Press the ⚽ button next to Settings. While watching, choose *⚽ Live scores* from the ≡ options menu: the picture shrinks to the left so you can keep watching, with the scores and leagues in a panel on the right (Back returns to full screen). Pick a
league, then press OK on a game to follow it. That's it: a small card pops up in the top-right corner
for a few seconds when someone scores and at full time, wherever you are in the app. *My games* shows
live scores for everything you follow. You can also switch on kick-off alerts there.

Scores come from ESPN's free public scoreboard feed (no account needed). It's only checked every 30
seconds while a followed game is live, and not at all otherwise. ESPN doesn't officially support this
feed, so it could stop working one day.

### Type theme

Settings → Appearance → **Type** turns the home screen into one big typographic list: your TV Home sections
(For You, Movies, Shows, Wrestling, Live TV, TV Guide, Football), then **the apps on your app bar**, then
+ Add app and Settings. The selected item is solid with its brand colour beside it; OK sweeps the colour
across and opens it. Hold OK on an app to edit, move or remove it. ≡ opens the TV guide, Back always returns
to the list. Everything else uses the Dark colours.

## 4. Connect IPTV (Xtream Codes)

Settings → *IPTV (Xtream Codes)* → server address (e.g. `http://provider.com:8080`), username, password →
**Connect**. You can also paste the full M3U link your provider gave you
(`http://…/get.php?username=…&password=…`) into the server box and leave the rest blank.

- **Stream format:** MPEG-TS works with almost every provider. Try HLS if channels won't start.
- **User agent:** leave blank unless your provider says otherwise.
- The channel list is cached on the stick and refreshed every few hours (*Reload channels* forces it).

### IPTV Guide

Open it from **IPTV Guide** in the tab bar, the tile at the end of the live row, or the Guide button on remotes that have one.

- **Left:** Search, ★ Favourites, Recently watched, All channels, then every category with its channel count.
  Moving over a category shows its channels.
- **Middle:** the channels, each with what's on now and a progress bar.
- **Right:** a live preview window, then the channel's schedule. Programmes with ⟲ can be watched again
  (catch-up) if your provider supports it.
- **OK** on a channel previews it; **OK again** goes full screen. **Hold OK** (or ≡) to ★ favourite.
- **Search** has an on-screen keyboard: every letter you add narrows the list of channels *and* the
  matching categories straight away (picking a category jumps to it). The TV keyboard / voice typing
  works too if you select the text box.

### TV guide (≡ on the home screen)

A Sky-style grid of British channels in Sky's order: 101 BBC One, 102 BBC Two, 103 ITV1… Sky Cinema, Sky Sports,
TNT, news and kids, each matched to your IPTV streams by name (UK, HD and non-"+1" versions preferred; channels you
have no stream for are hidden). ◀ ▶ moves through time, ▲ ▼ through channels, tabs for Entertainment / Movies /
Sports / News / Kids. OK lists every stream found for that channel, best first, and remembers the one you pick;
while watching, ▲ ▼ flips through the guide's channels in order, and BACK returns to the guide.

### ⚽ Football today (in the guide)

Under Favourites / Recently watched: today's Premier League, Championship, League One, League Two and National
League games (from ESPN), each with the IPTV channels that seem to be showing it, matched by channel name
(e.g. "EFL 03 | Leeds v Burnley") and by the sports channels' TV listings around kick-off ("Live: Man Utd v Spurs").
Common nicknames (Man Utd, Spurs, Wolves, QPR…) are understood. OK previews, OK again goes full screen.

### Watching live TV

| Remote | |
|---|---|
| ▲ ▼ (or CH+/CH−) | Previous / next channel |
| OK | Show what's on; OK again opens the channel list |
| ◀ | Channel list — ◀ again for categories |
| ▶ or ≡ | Options: favourite, audio, subtitles, picture, open guide, reconnect |
| Back | Hide the info, then leave (back to the guide if you came from it) |

The stream reconnects by itself if the provider drops it.

## 5. Editing the home bar

| Do this | Result |
|---|---|
| Select the **+** tile (or the grid icon top-right) | Add a tile: pick the app it opens from your installed apps, name it, and paste a **logo image URL** |
| Highlight a tile and **hold OK** (or press the ≡ Menu button) | Edit that tile — change app, logo, colour, fit |
| In the editor, **◀ Move / Move ▶** | Tile wiggles; use ◀ ▶ to slide it, OK to drop |
| **Remove** | Takes it off the bar |

Logo images: any PNG/JPG/SVG URL works. *Fill tile* stretches the image across the whole
tile (good for cover-style art); *Fit logo* centres it on the tile colour you pick
(good for transparent logos). Leave the URL blank to use the app's own TV banner.

## Remote controls

Arrows move · OK selects · hold OK / ≡ edits a dock tile (or opens options for a live channel tile) · Back closes dialogs.

## Good to know

- Fire OS doesn't let third-party apps replace the Amazon home screen, so the Home button still
  goes to Amazon's. Apps such as *Button Mapper* or a launcher-redirect tool can remap it to open TV Home.
- Your dock, settings, IPTV favourites and recently watched channels are saved on the device.
- The UI is a single file — `app/src/main/assets/index.html` — so tweaking the look is just HTML/CSS.
  Open it in a desktop browser to preview it (arrows + Enter work, M = menu, Esc = back).
  Video playback itself is native (`VideoPlayer.kt`); in a desktop browser it falls back to an HTML5
  `<video>` for MP4 files only.
