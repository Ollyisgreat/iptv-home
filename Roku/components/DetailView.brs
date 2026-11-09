sub init()
  p = thm()
  rect(m.top, 0, 0, 1920, 1080, p.bg1)
  m.bd = pic(m.top, 0, 0, 1920, 1080, "scaleToZoom")
  m.bd.loadWidth = 1280
  m.bd.loadHeight = 720
  m.bd.opacity = 0
  m.bd.observeField("loadStatus", "onBd")
  sh = pic(m.top, 0, 0, 1920, 1080, "scaleToFill")
  sh.uri = p.shade
  m.body = grp(m.top, 110, 0)
  m.logo = pic(m.body, 0, 110, 620, 210, "scaleToFit")
  m.logo.observeField("loadStatus", "onLogo")
  m.title = lbl(m.body, 0, 110, "", 78, "b", p.text, 1060, 210)
  m.title.wrap = true
  m.title.maxLines = 2
  m.title.vertAlign = "bottom"
  m.title.visible = false
  m.meta = grp(m.body, 0, 0)
  m.tag = lbl(m.body, 0, 0, "", 27, "s", p.text, 1060)
  m.ov = lbl(m.body, 0, 0, "", 24, "r", p.muted, 1000)
  m.ov.wrap = true
  m.ov.lineSpacing = 10
  m.btns = CreateObject("roSGNode", "Row")
  m.btns.padL = 110
  m.btns.gap = 18
  m.top.appendChild(m.btns)
  m.seasons = CreateObject("roSGNode", "Row")
  m.seasons.padL = 110
  m.seasons.gap = 12
  m.seasons.translation = [0, 620]
  m.top.appendChild(m.seasons)
  m.eps = CreateObject("roSGNode", "Row")
  m.eps.zoom = 1.06
  m.eps.translation = [0, 696]
  m.top.appendChild(m.eps)
  m.load = lbl(m.top, 110, 140, "Loading…", 30, "r", p.muted)
  m.btns.observeField("selected", "onBtn")
  m.eps.observeField("selected", "onEp")
  m.eps.observeField("focused", "onEpFocus")
  m.seasons.observeField("focused", "onSeasonFocus")
  m.seasons.observeField("selected", "onSeasonPick")
  m.seasonT = mkTimer(0.3, "loadFocusedSeason")
  m.series = invalid
  m.item = invalid
  m.zone = "btns"
  m.pending = 0
  m.metaY = 300
end sub

function open(p as object) as dynamic
  it = p.item
  typ = toStr(it.Type)
  m.top.setFocus(true)
  if typ = "Series" then
    m.sid = toStr(it.Id)
    m.targetId = ""
  else if typ = "Episode" then
    m.sid = toStr(it.SeriesId)
    m.targetId = toStr(it.Id)
  else if typ = "Season" then
    m.sid = toStr(it.SeriesId)
    m.targetId = ""
    m.wantSeason = toStr(it.Id)
  else
    m.sid = ""
    m.movieId = toStr(it.Id)
  end if
  m.focusAct = "play"
  refresh()
  return invalid
end function

function onReturn(p as dynamic) as dynamic
  refresh()
  return invalid
end function

sub refresh()
  a = acct()
  if m.sid <> "" then
    m.pending = 2
    jf("series", "/Users/" + a.uid + "/Items/" + m.sid)
    jf("seasons", "/Shows/" + m.sid + "/Seasons?UserId=" + a.uid)
    if m.targetId <> "" then
      m.pending = 3
      jf("target", "/Users/" + a.uid + "/Items/" + m.targetId)
    else
      m.pending = 3
      jf("nextup", "/Shows/NextUp?UserId=" + a.uid + "&SeriesId=" + m.sid + "&Limit=1&Fields=Overview&EnableResumable=true")
    end if
  else
    jf("movie", "/Users/" + a.uid + "/Items/" + m.movieId)
  end if
end sub

sub onApi(e as object)
  if not apiFresh(e) then return
  r = e.getData()
  k = r.kind
  d = r.data
  if k = "movie" then
    if not r.ok or d = invalid then
      m.load.text = "Couldn't load this from Jellyfin."
      return
    end if
    m.item = d
    m.series = invalid
    showMovie()
  else if k = "series" then
    m.series = d
    m.pending = m.pending - 1
  else if k = "seasons" then
    m.seasonList = []
    if d <> invalid then
      if d.Items <> invalid then m.seasonList = d.Items
    end if
    m.pending = m.pending - 1
  else if k = "target" then
    m.target = d
    m.pending = m.pending - 1
  else if k = "nextup" then
    m.target = invalid
    l = gv(d, "Items")
    if l <> invalid then
      if l.count() > 0 then m.target = l[0]
    end if
    m.pending = m.pending - 1
  else if k = "eps" then
    m.epList = []
    l = gv(d, "Items")
    if l <> invalid then m.epList = l
    showEps()
  else if k = "flag" then
    if r.ok then
      notify(m.flagMsg)
      refresh()
    else
      notify("Couldn't update Jellyfin")
    end if
  end if
  if (k = "series" or k = "seasons" or k = "target" or k = "nextup") and m.pending = 0 then
    if m.series = invalid then
      m.load.text = "Couldn't load this from Jellyfin."
      return
    end if
    m.item = m.series
    showSeries()
  end if
end sub

' ---------- header (logo or title, meta, tagline, overview) ----------
sub header(it as object, isSeries as boolean)
  p = thm()
  m.load.visible = false
  maxH = 210
  if isSeries then maxH = 150
  logoId = toStr(it.Id)
  if toStr(it.Type) = "Episode" then logoId = toStr(it.SeriesId)
  m.title.text = toStr(it.Name)
  if isSeries then m.title.font = fnt("b", 64) else m.title.font = fnt("b", 78)
  m.title.height = maxH
  m.maxH = maxH
  u = jfImg(logoId, "Logo", 700)
  if m.logo.uri <> u then
    m.logo.visible = false
    m.title.visible = false
    m.logo.uri = u
  end if
  bid = ""
  bt = gv(it, "BackdropImageTags")
  if bt <> invalid then
    if bt.count() > 0 then bid = toStr(it.Id)
  end if
  if bid = "" then bid = toStr(it.ParentBackdropItemId)
  if bid = "" then bid = toStr(it.SeriesId)
  if bid <> "" then
    nu = jfImg(bid, "Backdrop", 1920)
    if m.bd.uri <> nu then
      m.bd.opacity = 0
      m.bd.uri = nu
    end if
  end if
  m.metaY = 110 + maxH + 22
  buildMeta(it, m.metaY)
  tl = gv(it, "Taglines")
  tag = ""
  if tl <> invalid then
    if tl.count() > 0 then tag = toStr(tl[0])
  end if
  if isSeries then m.ov.maxLines = 3 else m.ov.maxLines = 4
  m.tag.text = tag
  m.ov.text = toStr(it.Overview)
  m.ovText = m.ov.text
  m.tagText = tag
  relayout()
end sub

' tagline, overview and buttons flow down the page like the web version
sub relayout()
  y = m.metaY + 44
  if m.tag.text <> "" then
    m.tag.translation = [0, y + 4]
    y = y + 42
  end if
  m.ov.translation = [0, y + 8]
  oh = 0
  if m.ov.text <> "" then oh = m.ov.boundingRect().height
  m.btns.translation = [0, y + 8 + oh + 34]
end sub

sub onBd()
  if m.bd.loadStatus = "ready" then tween(m.bd, "opacity", 1.0, 0.6)
end sub

sub onLogo()
  st = m.logo.loadStatus
  if st = "ready" then
    bw = m.logo.bitmapWidth
    bh = m.logo.bitmapHeight
    if bw > 0 and bh > 0 then
      s = 620 / bw
      if m.maxH / bh < s then s = m.maxH / bh
      w = Int(bw * s)
      h = Int(bh * s)
      m.logo.width = w
      m.logo.height = h
      m.logo.translation = [0, 110 + m.maxH - h]
    end if
    m.logo.visible = true
    m.title.visible = false
  else if st = "failed" then
    m.logo.visible = false
    m.title.visible = true
  end if
end sub

sub buildMeta(it as object, y as integer)
  p = thm()
  m.meta.removeChildrenIndex(m.meta.getChildCount(), 0)
  m.meta.translation = [0, y]
  parts = []
  if toStr(it.ProductionYear) <> "" then parts.push({t: toStr(it.ProductionYear)})
  if toStr(it.OfficialRating) <> "" then parts.push({chip: toStr(it.OfficialRating)})
  typ = toStr(it.Type)
  if typ <> "Series" and it.RunTimeTicks <> invalid then parts.push({t: dur(ticksSec(it.RunTimeTicks))})
  if typ = "Series" then
    st = seasonsText(it)
    if st <> "" then parts.push({t: st})
  end if
  cr = num(it.CommunityRating)
  if cr > 0 then parts.push({star: true, t: oneDp(cr)})
  g = gv(it, "Genres")
  if g <> invalid then
    gs = []
    for each x in g
      if gs.count() < 3 then gs.push(toStr(x))
    end for
    if gs.count() > 0 then parts.push({t: gs.Join(", ")})
  end if
  ms = gv(it, "MediaStreams")
  hasSub = false
  if ms <> invalid then
    for each s in ms
      if toStr(s.Type) = "Video" and parts.count() < 20 then
        w = num(s.Width)
        h = num(s.Height)
        res = ""
        if w >= 3200 or h >= 2000 then
          res = "4K"
        else if w >= 1800 or h >= 1000 then
          res = "HD"
        end if
        if res <> "" then parts.push({chip: res})
        vr = toStr(s.VideoRange)
        if vr <> "" and vr <> "SDR" then
          vrt = toStr(s.VideoRangeType)
          if vrt = "" then vrt = vr
          parts.push({chip: vrt})
        end if
      end if
      if toStr(s.Type) = "Subtitle" then hasSub = true
    end for
  end if
  if hasSub then parts.push({chip: "CC"})
  if typ = "Movie" and it.RunTimeTicks <> invalid then
    remain = ticksSec(it.RunTimeTicks) - ticksSec(gv(gv(it, "UserData"), "PlaybackPositionTicks"))
    parts.push({t: "Ends at " + hm(nowSec() + remain)})
  end if
  x = 0
  for each pt in parts
    if pt.chip <> invalid then
      l = lbl(m.meta, x + 12, 4, pt.chip, 18, "b", p.muted)
      w = textW(l) + 24
      edge(m.meta, "thin7", x, 1, w, 30, p.muted)
      x = x + w + 28
    else
      lx = x
      if isTrue(pt.star) then
        icon(m.meta, "star", x, 4, 22, p.muted)
        lx = x + 28
      end if
      l = lbl(m.meta, lx, 0, pt.t, 24, "r", p.muted)
      x = lx + textW(l) + 28
    end if
  end for
end sub

function oneDp(v as float) as string
  n = Int(v * 10 + 0.5)
  a = Int(n / 10)
  b = n mod 10
  return a.ToStr() + "." + b.ToStr()
end function

function fmtLeft(it as object, at as integer) as string
  rt = ticksSec(it.RunTimeTicks)
  if rt > at then return dur(rt - at) + " left"
  return clockStr(at)
end function

' ---------- movie ----------
sub showMovie()
  it = m.item
  header(it, false)
  m.seasons.visible = false
  m.eps.visible = false
  ps = ticksSec(gv(gv(it, "UserData"), "PlaybackPositionTicks"))
  b = []
  m.acts = []
  if ps > 0 then
    b.push({ui: "btn", title: "Resume · " + fmtLeft(it, ps), icon: "play", primary: true})
    m.acts.push("play")
    b.push({ui: "btn", title: "From start", icon: "restart"})
    m.acts.push("restart")
  else
    b.push({ui: "btn", title: "Play", icon: "play", primary: true})
    m.acts.push("play")
  end if
  addFlagBtns(b, it)
  setBtns(b)
end sub

sub addFlagBtns(b as object, it as object)
  ud = gv(it, "UserData")
  if isTrue(gv(ud, "Played")) then
    b.push({ui: "btn", title: "Watched", icon: "check"})
  else
    b.push({ui: "btn", title: "Mark watched"})
  end if
  m.acts.push("played")
  if isTrue(gv(ud, "IsFavorite")) then
    b.push({ui: "btn", title: "Favourite", icon: "heartf"})
  else
    b.push({ui: "btn", title: "Favourite", icon: "heart"})
  end if
  m.acts.push("fav")
end sub

sub setBtns(b as object)
  idx = 0
  for i = 0 to m.acts.count() - 1
    if m.acts[i] = m.focusAct then idx = i
  end for
  m.btns.index = idx
  m.btns.items = b
  if m.zone = "btns" then m.btns.callFunc("takeFocus", {index: idx})
end sub

' ---------- series ----------
sub showSeries()
  s = m.series
  header(s, true)
  m.seasons.visible = true
  m.eps.visible = true
  ' which season to show
  sea = ""
  if m.wantSeason <> invalid then sea = m.wantSeason
  if sea = "" and m.curSeason <> invalid then sea = m.curSeason
  if sea = "" and m.target <> invalid then sea = toStr(m.target.SeasonId)
  if sea = "" and m.seasonList.count() > 0 then sea = toStr(m.seasonList[0].Id)
  m.wantSeason = invalid
  items = []
  idx = 0
  for i = 0 to m.seasonList.count() - 1
    x = m.seasonList[i]
    if toStr(x.Id) = sea then idx = i
    items.push({ui: "pill", title: toStr(x.Name), sel: toStr(x.Id) = sea})
  end for
  m.seasons.index = idx
  m.seasons.items = items
  seriesBtns()
  if sea <> "" then loadSeason(sea)
end sub

sub seriesBtns()
  t = m.target
  b = []
  m.acts = []
  if t <> invalid then
    lb = "S" + toStr(t.ParentIndexNumber) + ", E" + toStr(t.IndexNumber)
    ps = ticksSec(gv(gv(t, "UserData"), "PlaybackPositionTicks"))
    if ps > 0 then
      b.push({ui: "btn", title: "Resume " + lb, icon: "play", primary: true})
      m.acts.push("play")
      b.push({ui: "btn", title: "From start", icon: "restart"})
      m.acts.push("restart")
    else
      b.push({ui: "btn", title: "Play " + lb, icon: "play", primary: true})
      m.acts.push("play")
    end if
  end if
  addFlagBtns(b, m.series)
  setBtns(b)
end sub

sub loadSeason(id as string)
  m.curSeason = id
  jf("eps", "/Shows/" + m.sid + "/Episodes?UserId=" + acct().uid + "&SeasonId=" + id + "&Fields=Overview")
end sub

sub showEps()
  p = thm()
  if m.target = invalid and m.epList.count() > 0 then
    for each e in m.epList
      if m.target = invalid and not isTrue(gv(gv(e, "UserData"), "Played")) then m.target = e
    end for
    if m.target = invalid then m.target = m.epList[0]
    seriesBtns()
  end if
  items = []
  cur = 0
  for i = 0 to m.epList.count() - 1
    e = m.epList[i]
    isCur = false
    if m.target <> invalid then isCur = (toStr(e.Id) = toStr(m.target.Id))
    if isCur then cur = i
    t = toStr(e.Name)
    if e.IndexNumber <> invalid then t = toStr(e.IndexNumber) + ". " + t
    meta = dur(ticksSec(e.RunTimeTicks))
    pd = toStr(e.PremiereDate)
    if Len(pd) >= 10 then meta = joinDot([meta, niceDate(pd)])
    items.push({ui: "card", w: 400, h: 225, r: 20, title: t, meta: meta, img: [jfImg(e.Id, "Primary", 560)], pct: pctOf(e), played: isTrue(gv(gv(e, "UserData"), "Played")), tsize: 24, tweight: "s", msize: 20, tmt: 16, tmove: 8, dot: isCur})
  end for
  if m.epFocus <> invalid then
    cur = m.epFocus
    m.epFocus = invalid
  end if
  had = m.eps.hasFocus()
  m.eps.index = cur
  m.eps.items = items
  if had then m.eps.callFunc("takeFocus", {index: cur})
end sub

function niceDate(iso as string) as string
  d = CreateObject("roDateTime")
  d.FromISO8601String(Left(iso, 19) + "Z")
  mo = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
  dd = d.GetDayOfMonth()
  mm = d.GetMonth()
  yy = d.GetYear()
  if mm < 1 or mm > 12 then return ""
  return dd.ToStr() + " " + mo[mm - 1] + " " + yy.ToStr()
end function

sub onEpFocus()
  if m.zone <> "eps" then return
  e = m.epList[m.eps.focused]
  if e = invalid then return
  m.tag.text = "S" + toStr(e.ParentIndexNumber) + ", E" + toStr(e.IndexNumber) + " · " + toStr(e.Name)
  m.ov.maxLines = 2
  m.ov.text = toStr(e.Overview)
  relayout()
end sub

sub restoreOv()
  m.tag.text = m.tagText
  m.ov.maxLines = 3
  m.ov.text = m.ovText
  relayout()
end sub

sub onSeasonFocus()
  restart(m.seasonT)
end sub

sub loadFocusedSeason()
  if m.zone <> "seasons" then return
  s = m.seasonList[m.seasons.focused]
  if s = invalid then return
  if toStr(s.Id) = m.curSeason then return
  markSeason(m.seasons.focused)
  loadSeason(toStr(s.Id))
end sub

sub onSeasonPick()
  s = m.seasonList[m.seasons.selected]
  if s = invalid then return
  markSeason(m.seasons.selected)
  if toStr(s.Id) <> m.curSeason then loadSeason(toStr(s.Id))
  m.zone = "eps"
  m.seasons.callFunc("blurRow", {})
  m.eps.callFunc("takeFocus", {})
end sub

sub markSeason(i as integer)
  for j = 0 to m.seasonList.count() - 1
    m.seasons.callFunc("setItem", {i: j, sel: (j = i)})
  end for
end sub

' ---------- actions ----------
sub onBtn()
  a = m.acts[m.btns.selected]
  m.focusAct = a
  t = m.item
  if m.series <> invalid then t = m.target
  if a = "play" then
    if t <> invalid then play(t, ticksSec(gv(gv(t, "UserData"), "PlaybackPositionTicks")))
  else if a = "restart" then
    if t <> invalid then play(t, 0)
  else if a = "played" or a = "fav" then
    it = m.item
    ud = gv(it, "UserData")
    path = "/Users/" + acct().uid + "/PlayedItems/" + toStr(it.Id)
    on = not isTrue(gv(ud, "Played"))
    if a = "fav" then
      path = "/Users/" + acct().uid + "/FavoriteItems/" + toStr(it.Id)
      on = not isTrue(gv(ud, "IsFavorite"))
      if on then m.flagMsg = "Added to favourites" else m.flagMsg = "Removed from favourites"
    else
      if on then m.flagMsg = "Marked as watched" else m.flagMsg = "Marked as unwatched"
    end if
    if on then
      jf("flag", path, {method: "POST", body: ""})
    else
      jf("flag", path, {method: "DELETE"})
    end if
  end if
end sub

sub onEp()
  e = m.epList[m.eps.selected]
  if e = invalid then return
  m.epFocus = m.eps.selected
  play(e, ticksSec(gv(gv(e, "UserData"), "PlaybackPositionTicks")))
end sub

sub play(it as object, start as integer)
  scene().callFunc("push", {view: "VodPlayer", item: it, start: start, series: m.series})
end sub

function onKeyEvent(key as string, press as boolean) as boolean
  if not press then return false
  if key = "back" then
    scene().callFunc("pop", {})
    return true
  end if
  isSeries = (m.series <> invalid)
  if key = "down" then
    if m.zone = "btns" and isSeries then
      m.zone = "seasons"
      m.btns.callFunc("blurRow", {})
      m.seasons.callFunc("takeFocus", {})
    else if m.zone = "seasons" then
      if m.eps.callFunc("takeFocus", {}) = true then
        m.zone = "eps"
        m.seasons.callFunc("blurRow", {})
        onEpFocus()
      end if
    end if
    return true
  else if key = "up" then
    if m.zone = "eps" then
      m.zone = "seasons"
      m.eps.callFunc("blurRow", {})
      restoreOv()
      m.seasons.callFunc("takeFocus", {})
    else if m.zone = "seasons" then
      m.zone = "btns"
      m.seasons.callFunc("blurRow", {})
      m.btns.callFunc("takeFocus", {})
    end if
    return true
  end if
  return true
end function
