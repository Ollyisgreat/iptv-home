sub init()
  m.cards = CreateObject("roSGNode", "Row")
  m.top.appendChild(m.cards)
  m.strip = CreateObject("roSGNode", "Row")
  m.strip.gap = 22
  m.top.appendChild(m.strip)
  m.msg = lbl(m.top, 110, 340, "", 28, "r", thm().muted, 1700)
  m.cards.observeField("selected", "onCard")
  m.strip.observeField("selected", "onTile")
  m.strip.observeField("optionsKey", "onTileMenu")
  m.cardData = []
  m.tiles = []
  m.loaded = false
  m.live = m.global.live
  m.live.observeField("state", "onLive")
end sub

function blur(p as dynamic) as dynamic
  m.cards.callFunc("blurRow", {})
  m.strip.callFunc("blurRow", {})
  return invalid
end function

function reset(p as dynamic) as dynamic
  m.loaded = false
  return invalid
end function

function activate(p as dynamic) as dynamic
  layout()
  renderStrip()
  if not m.loaded or isTrue(gv(p, "force")) then
    load()
  else if m.cardData.count() > 0 then
    c0 = m.cardData[0]
    if not isTrue(c0.demo) then scene().callFunc("ambient", {uri: c0.wide[0]})
  end if
  return invalid
end function

function onReturn(p as dynamic) as dynamic
  renderStrip()
  load()
  return invalid
end function

function takeFocus(p as dynamic) as dynamic
  if m.cards.callFunc("takeFocus", {}) = true then return true
  return m.strip.callFunc("takeFocus", {})
end function

' compact layout when the live TV strip is showing (same as the web version)
sub layout()
  m.withLive = ipOn()
  if m.withLive then
    m.cards.translation = [0, 264]
    m.strip.translation = [0, 664]
    m.strip.visible = true
  else
    m.cards.translation = [0, 320]
    m.strip.visible = false
  end if
end sub

' ---------- Jellyfin cards ----------
sub load()
  m.loaded = true
  if not jfOn() then
    m.cardData = [{demo: true}]
    showCards()
    return
  end if
  a = acct()
  f = "&Fields=Overview,Genres,ProductionYear,ChildCount,RunTimeTicks,ParentBackdropItemId&ImageTypeLimit=1&EnableImageTypes=Primary,Backdrop,Thumb,Logo"
  m.res = {}
  m.want = 4
  jf("resume", "/Users/" + a.uid + "/Items/Resume?Limit=8&IncludeItemTypes=Movie,Episode&MediaTypes=Video" + f)
  jf("nextup", "/Shows/NextUp?UserId=" + a.uid + "&Limit=8" + f)
  jf("random", "/Users/" + a.uid + "/Items?IncludeItemTypes=Movie,Series&Recursive=true&SortBy=Random&Filters=IsUnplayed&Limit=12" + f)
  jf("latest", "/Users/" + a.uid + "/Items/Latest?IncludeItemTypes=Movie,Series&Limit=10" + f)
end sub

sub onApi(e as object)
  if not apiFresh(e) then return
  r = e.getData()
  k = r.kind
  if Left(k, 4) = "epg_" then
    i = Val(Mid(k, 5))
    l = epgList(r.data)
    if l.count() > 0 then m.strip.callFunc("setItem", {i: i, meta: l[0].t, pct: epgPct(l[0])})
    nextEpg()
    return
  end if
  d = r.data
  if type(d) = "roAssociativeArray" then d = d.Items
  if type(d) <> "roArray" then d = []
  m.res[k] = {ok: r.ok, items: d, code: r.code}
  m.want = m.want - 1
  if m.want > 0 then return
  seen = {}
  out = []
  failed = 0
  auth = false
  for each kk in ["resume", "nextup", "random", "latest"]
    x = m.res[kk]
    if not x.ok then
      failed = failed + 1
      if x.code = 401 then auth = true
    end if
    for each it in x.items
      typ = toStr(it.Type)
      key = toStr(it.Id)
      if typ = "Episode" then key = "s" + toStr(it.SeriesId)
      if typ = "Series" then key = "s" + toStr(it.Id)
      if seen[key] = invalid and out.count() < 24 then
        seen[key] = true
        out.push(jfCard(it))
      end if
    end for
  end for
  if failed = 4 then
    if auth then
      m.cardData = [{demo: true, title: "Jellyfin sign-in expired", subtxt: "Press OK to open Settings"}]
    else
      m.cardData = [{demo: true, title: "Can't reach Jellyfin", subtxt: "Press OK to open Settings"}]
    end if
    scene().callFunc("counts", {conn: "err"})
  else
    m.cardData = out
    scene().callFunc("counts", {conn: "ok"})
  end if
  showCards()
end sub

sub showCards()
  hero = [830, 370]
  post = [248, 370]
  ts = 28
  ms = 21
  tmt = 20
  if m.withLive then
    hero = [652, 290]
    post = [194, 290]
    ts = 25
    ms = 19
    tmt = 16
  end if
  items = []
  for i = 0 to m.cardData.count() - 1
    c = m.cardData[i]
    if isTrue(c.demo) then
      t = toStr(c.title)
      if t = "" then t = "Connect Jellyfin"
      s = toStr(c.subtxt)
      if s = "" then s = "Press OK to add your server in Settings"
      items.push({ui: "card", w: hero[0], h: hero[1], title: t, meta: s, ph: t, img: "", tsize: ts, msize: ms, tmt: tmt})
    else if i = 0 then
      items.push({ui: "card", w: hero[0], h: hero[1], title: c.title, meta: c.meta, img: c.wide, logo: c.logo, pct: c.pct, tsize: ts, msize: ms, tmt: tmt})
    else
      items.push({ui: "card", w: post[0], h: post[1], title: c.title, meta: c.meta, img: c.tall, pct: c.pct, tsize: ts, msize: ms, tmt: tmt})
    end if
  end for
  had = m.cards.hasFocus()
  m.cards.index = m.cards.focused
  m.cards.items = items
  if had then m.cards.callFunc("takeFocus", {})
  m.msg.text = ""
  amb = ""
  if m.cardData.count() > 0 then
    c0 = m.cardData[0]
    if not isTrue(c0.demo) then amb = c0.wide[0]
  end if
  if m.top.visible then scene().callFunc("ambient", {uri: amb})
end sub

sub nextEpg()
  if m.epgQ.count() = 0 then return
  i = m.epgQ.Shift()
  t = m.tiles[i]
  m.epgN = m.epgN + 1
  api("epg_" + i.ToStr(), xBase() + "&action=get_short_epg&stream_id=" + toStr(t.s.id) + "&limit=2", {timeout: 12000})
end sub

sub onCard()
  c = m.cardData[m.cards.selected]
  if c = invalid then return
  if isTrue(c.demo) then
    scene().callFunc("push", {view: "SettingsView"})
  else
    openItem(c.item)
  end if
end sub

' ---------- live TV strip: recently watched · favourites · IPTV Guide ----------
sub onLive()
  if m.top.visible then renderStrip()
end sub

sub renderStrip()
  wasLive = m.withLive
  layout()
  if wasLive <> m.withLive and m.cardData.count() > 0 then showCards()
  if not m.withLive then
    m.strip.items = []
    return
  end if
  m.tiles = []
  items = []
  rec = liveRecents()
  fav = liveFavs()
  groups = [{name: "Recently watched", list: rec, kind: "r"}, {name: "Favourites", list: fav, kind: "f"}]
  for each g in groups
    n = 0
    for each s in g.list
      if n < 12 then
        it = {ui: "live", title: toStr(s.n), logo: toStr(s.i), meta: "", pct: 0}
        if n = 0 then
          it.group = g.name
          if items.count() > 0 then it.gapBefore = 46
        end if
        items.push(it)
        m.tiles.push({kind: g.kind, s: s, list: g.list})
        n = n + 1
      end if
    end for
  end for
  go = {ui: "go", title: "IPTV Guide"}
  if items.count() > 0 then
    go.subtxt = "All categories & channels"
    go.gapBefore = 46
    go.group = " "
  else
    go.subtxt = "Channels you watch and favourite appear here"
    go.group = "Live TV"
  end if
  items.push(go)
  m.tiles.push({kind: "go"})
  had = m.strip.hasFocus()
  m.strip.index = m.strip.focused
  m.strip.items = items
  if had then m.strip.callFunc("takeFocus", {})
  m.epgQ = []
  for i = 0 to m.tiles.count() - 1
    if m.tiles[i].kind <> "go" then m.epgQ.push(i)
  end for
  m.epgN = 0
  for k = 1 to 3
    nextEpg()
  end for
end sub

sub onTile()
  t = m.tiles[m.strip.selected]
  if t = invalid then return
  if t.kind = "go" then
    scene().callFunc("push", {view: "GuideView"})
    return
  end if
  playTile(t)
end sub

sub playTile(t as object)
  list = m.live.callFunc("list", {cat: "@" + iif(t.kind = "f", "fav", "recent")})
  idx = 0
  for i = 0 to list.count() - 1
    if list[i].id = toStr(t.s.id) then idx = i
  end for
  ctx = "Recently watched"
  if t.kind = "f" then ctx = "Favourites"
  scene().callFunc("push", {view: "LivePlayer", list: list, index: idx, ctx: ctx})
end sub

function iif(c as boolean, a as dynamic, b as dynamic) as dynamic
  if c then return a
  return b
end function

sub onTileMenu()
  t = m.tiles[m.strip.optionsKey]
  if t = invalid then return
  if t.kind = "go" then return
  m.menuTile = t
  items = [{label: "Watch"}]
  if isFav(t.s.id) then items.push({label: "Remove from favourites"}) else items.push({label: "Add to favourites"})
  if t.kind = "r" then items.push({label: "Remove from recently watched"})
  items.push({label: "Open IPTV Guide"})
  m.menuItems = items
  mn = scene().callFunc("push", {view: "SideMenu", title: toStr(t.s.n), items: items})
  mn.observeField("chosen", "onTileChoice")
end sub

sub onTileChoice(e as object)
  i = e.getData()
  if i < 0 then return
  l = m.menuItems[i].label
  t = m.menuTile
  if l = "Watch" then
    playTile(t)
  else if l = "Open IPTV Guide" then
    scene().callFunc("push", {view: "GuideView"})
  else if l = "Remove from recently watched" then
    removeRecent(t.s.id)
    renderStrip()
  else
    toggleFav(t.s)
    renderStrip()
  end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
  if not press then return false
  if key = "down" and m.cards.hasFocus() then
    if m.strip.visible then
      if m.strip.callFunc("takeFocus", {}) = true then m.cards.callFunc("blurRow", {})
    end if
    return true
  else if key = "up" and m.strip.hasFocus() then
    m.strip.callFunc("blurRow", {})
    if m.cards.callFunc("takeFocus", {}) <> true then return false
    return true
  else if key = "down" then
    return true
  end if
  return false
end function
