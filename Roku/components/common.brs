' ===================================================================
'  Shared helpers – included by every component
' ===================================================================

' ---------- values ----------
function toStr(v as dynamic) as string
  t = type(v)
  if t = "Invalid" or t = "roInvalid" or t = "<uninitialized>" then return ""
  if t = "roString" or t = "String" then return v
  if t = "roInt" or t = "roInteger" or t = "Integer" or t = "roLongInteger" or t = "LongInteger" then return v.ToStr()
  if t = "roFloat" or t = "Float" or t = "roDouble" or t = "Double" then
    if Abs(v) < 2000000000 then
      n = Int(v)
      if n = v then return n.ToStr()
    end if
    return Str(v).Trim()
  end if
  if t = "roBoolean" or t = "Boolean" then
    if v then return "true"
    return "false"
  end if
  return ""
end function

function num(v as dynamic) as dynamic
  t = type(v)
  if t = "roString" or t = "String" then return Val(v)
  if t = "roInt" or t = "roInteger" or t = "Integer" or t = "roFloat" or t = "Float" or t = "roDouble" or t = "Double" or t = "roLongInteger" or t = "LongInteger" then return v
  return 0
end function

function gv(o as dynamic, k as string) as dynamic
  if o = invalid then return invalid
  if GetInterface(o, "ifAssociativeArray") = invalid then return invalid
  return o[k]
end function

function isTrue(v as dynamic) as boolean
  s = toStr(v)
  return s = "true" or s = "1"
end function

function pad2(n as integer) as string
  if n < 10 then return "0" + n.ToStr()
  return n.ToStr()
end function

function nowSec() as integer
  d = CreateObject("roDateTime")
  return d.AsSeconds()
end function

' local time text for an epoch (or now) – follows the Roku's 12h/24h setting
function hm(secs = -1 as integer) as string
  d = CreateObject("roDateTime")
  if secs >= 0 then d.FromSeconds(secs)
  d.ToLocalTime()
  h = d.GetHours()
  mi = d.GetMinutes()
  if m.clk24 = invalid then m.clk24 = (CreateObject("roDeviceInfo").GetClockFormat() = "24h")
  if m.clk24 then return pad2(h) + ":" + pad2(mi)
  ap = "AM"
  if h >= 12 then ap = "PM"
  h = h mod 12
  if h = 0 then h = 12
  return pad2(h) + ":" + pad2(mi) + " " + ap
end function

' 5400 -> "1h 30m"
function dur(sec as dynamic) as string
  s = Int(num(sec))
  if s <= 0 then return ""
  h = Int(s / 3600)
  mi = Int((s mod 3600) / 60)
  if h > 0 then
    if mi > 0 then return h.ToStr() + "h " + mi.ToStr() + "m"
    return h.ToStr() + "h"
  end if
  if mi < 1 then mi = 1
  return mi.ToStr() + "m"
end function

' 3723 -> "1:02:03"
function clockStr(sec as dynamic) as string
  s = Int(num(sec))
  if s < 0 then s = 0
  h = Int(s / 3600)
  mi = Int((s mod 3600) / 60)
  ss = s mod 60
  if h > 0 then return h.ToStr() + ":" + pad2(mi) + ":" + pad2(ss)
  return mi.ToStr() + ":" + pad2(ss)
end function

function ticksSec(t as dynamic) as integer
  if t = invalid then return 0
  return Int(num(t) / 10000000)
end function

function enc(s as dynamic) as string
  b = CreateObject("roByteArray")
  b.FromAsciiString(toStr(s))
  out = ""
  for each x in b
    if (x >= 48 and x <= 57) or (x >= 65 and x <= 90) or (x >= 97 and x <= 122) or x = 45 or x = 46 or x = 95 or x = 126 then
      out = out + Chr(x)
    else
      h = UCase(StrI(x, 16))
      if Len(h) < 2 then h = "0" + h
      out = out + "%" + h
    end if
  end for
  return out
end function

function b64(s as dynamic) as string
  t = toStr(s)
  if t = "" then return ""
  b = CreateObject("roByteArray")
  b.FromBase64String(t)
  return b.ToAsciiString()
end function

function initials(s as string) as string
  w = s.Trim()
  r = CreateObject("roRegex", "^[A-Za-z]{2,3}\s*[:|]\s*", "")
  w = r.Replace(w, "")
  if Len(w) = 0 then return "TV"
  return UCase(Left(w, 2))
end function

' ---------- theme ----------
function thm() as object
  if m.pal <> invalid then return m.pal
  if m.global.theme = "light" then
    m.pal = {light: true, bg1: "0xE7E9EEFF", bg2: "0xF7F8FAFF", text: "0x1D1D1FFF", muted: "0x6E6E73FF", glass: "0xFFFFFF8C", glassB: "0xFFFFFFD9", glassS: "0xFFFFFFD1", card: "0xD9DCE2FF", pill: "0xFFFFFFFF", pillText: "0x1D1D1FFF", ring: "0xFFFFFFFF", accent: "0x0A84FFFF", gbg: "0xEEF0F4FF", gpanel: "0x0000000B", input: "0xFFFFFFFF", overlay: "0xE6E8EEF0", ok: "0x30B754FF", err: "0xFF453AFF", stage: "pkg:/images/stage_light.png", shade: "pkg:/images/shade_light.png", focusMuted: "0x666666FF", lgbg: "0x7F7F7F21", bar: "0x7F7F7F40"}
  else
    m.pal = palDark()
  end if
  return m.pal
end function

function palDark() as object
  return {light: false, bg1: "0x07080BFF", bg2: "0x1A1D24FF", text: "0xF5F5F7FF", muted: "0x9A9AA1FF", glass: "0xFFFFFF14", glassB: "0xFFFFFF1F", glassS: "0x282A32EB", card: "0x22252CFF", pill: "0xF5F5F7FF", pillText: "0x111111FF", ring: "0xFFFFFFFF", accent: "0x0A84FFFF", gbg: "0x0B0C10FF", gpanel: "0xFFFFFF0D", input: "0x2A2D35FF", overlay: "0x050609F0", ok: "0x30D158FF", err: "0xFF453AFF", stage: "pkg:/images/stage_dark.png", shade: "pkg:/images/shade_dark.png", focusMuted: "0x555555FF", lgbg: "0x7F7F7F21", bar: "0x7F7F7F40"}
end function

' always-dark palette for the full-screen players
function thmD() as object
  d = palDark()
  d.muted = "0xA1A1A8FF"
  d.gpanel = "0xFFFFFF14"
  d.lgbg = "0xFFFFFF1A"
  d.bar = "0xFFFFFF40"
  return d
end function

' ---------- fonts ----------
function fnt(w as string, size as integer) as object
  if m.fontCache = invalid then m.fontCache = {}
  k = w + size.ToStr()
  f = m.fontCache[k]
  if f = invalid then
    f = CreateObject("roSGNode", "Font")
    if w = "b" then
      f.uri = "pkg:/fonts/Inter-Bold.otf"
    else if w = "s" then
      f.uri = "pkg:/fonts/Inter-SemiBold.otf"
    else
      f.uri = "pkg:/fonts/Inter-Regular.otf"
    end if
    f.size = size
    m.fontCache[k] = f
  end if
  return f
end function

' ---------- node builders ----------
function grp(parent as dynamic, x = 0 as dynamic, y = 0 as dynamic) as object
  g = CreateObject("roSGNode", "Group")
  g.translation = [x, y]
  if parent <> invalid then parent.appendChild(g)
  return g
end function

function lbl(parent as dynamic, x as dynamic, y as dynamic, text as dynamic, size as integer, weight as string, color as string, w = 0 as dynamic, h = 0 as dynamic) as object
  l = CreateObject("roSGNode", "Label")
  l.translation = [x, y]
  l.font = fnt(weight, size)
  l.color = color
  if w > 0 then l.width = w
  if h > 0 then l.height = h
  l.text = toStr(text)
  if parent <> invalid then parent.appendChild(l)
  return l
end function

function rbox(parent as dynamic, x as dynamic, y as dynamic, w as dynamic, h as dynamic, r as integer, color as string) as object
  p = CreateObject("roSGNode", "Poster")
  p.uri = "pkg:/images/r" + r.ToStr() + ".9.png"
  p.translation = [x, y]
  p.width = w
  p.height = h
  p.blendColor = color
  if parent <> invalid then parent.appendChild(p)
  return p
end function

' outline drawn with a 9-patch ("ring22", "thin36" ...)
function edge(parent as dynamic, name as string, x as dynamic, y as dynamic, w as dynamic, h as dynamic, color as string) as object
  p = CreateObject("roSGNode", "Poster")
  p.uri = "pkg:/images/" + name + ".9.png"
  p.translation = [x, y]
  p.width = w
  p.height = h
  p.blendColor = color
  if parent <> invalid then parent.appendChild(p)
  return p
end function

function rect(parent as dynamic, x as dynamic, y as dynamic, w as dynamic, h as dynamic, color as string) as object
  r = CreateObject("roSGNode", "Rectangle")
  r.translation = [x, y]
  r.width = w
  r.height = h
  r.color = color
  if parent <> invalid then parent.appendChild(r)
  return r
end function

function icon(parent as dynamic, name as string, x as dynamic, y as dynamic, size as integer, color as string) as object
  p = CreateObject("roSGNode", "Poster")
  p.uri = "pkg:/images/i_" + name + ".png"
  p.translation = [x, y]
  p.width = size
  p.height = size
  p.blendColor = color
  if parent <> invalid then parent.appendChild(p)
  return p
end function

function pic(parent as dynamic, x as dynamic, y as dynamic, w as dynamic, h as dynamic, mode = "scaleToZoom" as string) as object
  p = CreateObject("roSGNode", "Poster")
  p.translation = [x, y]
  p.width = w
  p.height = h
  p.loadDisplayMode = mode
  if parent <> invalid then parent.appendChild(p)
  return p
end function

' artwork with rounded corners (uses a pre-made mask for that exact size)
function mpic(parent as dynamic, x as dynamic, y as dynamic, w as integer, h as integer) as object
  g = CreateObject("roSGNode", "MaskGroup")
  g.maskUri = "pkg:/images/m_" + w.ToStr() + "x" + h.ToStr() + ".png"
  g.maskSize = [w, h]
  g.translation = [x, y]
  p = CreateObject("roSGNode", "Poster")
  p.width = w
  p.height = h
  p.loadWidth = w
  p.loadHeight = h
  p.loadDisplayMode = "scaleToZoom"
  g.appendChild(p)
  if parent <> invalid then parent.appendChild(g)
  return p
end function

function textW(l as object) as integer
  r = l.boundingRect()
  return Int(r.width)
end function

function mkTimer(d as float, cb as string, rpt = false as boolean) as object
  t = CreateObject("roSGNode", "Timer")
  t.duration = d
  t.repeat = rpt
  t.observeField("fire", cb)
  m.top.appendChild(t)
  return t
end function

sub restart(t as object)
  t.control = "stop"
  t.control = "start"
end sub

' placeholder colour for artwork that hasn't loaded (like the web version's gradient)
function hueColor(s as string) as string
  h = 0
  b = CreateObject("roByteArray")
  b.FromAsciiString(s)
  for each c in b
    h = (h * 31 + c) mod 360
  end for
  ' hsl(h,55%,32%) -> rgb
  sat = 0.55
  li = 0.32
  cc = (1 - Abs(2 * li - 1)) * sat
  hp = h / 60.0
  hi = Int(hp)
  f2 = (hi mod 2) + (hp - hi)
  x = cc * (1 - Abs(f2 - 1))
  r = 0.0
  g = 0.0
  bl = 0.0
  if hp < 1 then
    r = cc: g = x
  else if hp < 2 then
    r = x: g = cc
  else if hp < 3 then
    g = cc: bl = x
  else if hp < 4 then
    g = x: bl = cc
  else if hp < 5 then
    r = x: bl = cc
  else
    r = cc: bl = x
  end if
  mm = li - cc / 2
  return "0x" + hex2(Int((r + mm) * 255)) + hex2(Int((g + mm) * 255)) + hex2(Int((bl + mm) * 255)) + "FF"
end function

function hex2(n as integer) as string
  if n < 0 then n = 0
  if n > 255 then n = 255
  h = UCase(StrI(n, 16))
  if Len(h) < 2 then h = "0" + h
  return h
end function

' ---------- tiny tween engine (render thread) ----------
function msNow() as integer
  if m.clockTs = invalid then m.clockTs = CreateObject("roTimespan")
  return m.clockTs.TotalMilliseconds()
end function

sub tween(node as object, field as string, target as dynamic, d = 0.22 as float)
  if m.tw = invalid then
    m.tw = []
    m.twT = CreateObject("roSGNode", "Timer")
    m.twT.repeat = true
    m.twT.duration = 0.016
    m.twT.observeField("fire", "twTick")
    m.top.appendChild(m.twT)
  end if
  for i = m.tw.count() - 1 to 0 step -1
    t = m.tw[i]
    if t.n.isSameNode(node) and t.f = field then m.tw.Delete(i)
  end for
  if d <= 0 then
    node.setField(field, target)
    return
  end if
  m.tw.push({n: node, f: field, a: node.getField(field), b: target, t0: msNow(), d: d * 1000})
  if m.tw.count() = 1 then m.twT.control = "start"
end sub

sub twTick()
  now = msNow()
  keep = []
  for each t in m.tw
    p = (now - t.t0) / t.d
    if p >= 1 then p = 1
    e = 1 - (1 - p) * (1 - p) * (1 - p)
    if type(t.b) = "roArray" then
      v = [t.a[0] + (t.b[0] - t.a[0]) * e, t.a[1] + (t.b[1] - t.a[1]) * e]
    else
      v = t.a + (t.b - t.a) * e
    end if
    t.n.setField(t.f, v)
    if p < 1 then keep.push(t)
  end for
  m.tw = keep
  if keep.count() = 0 then m.twT.control = "stop"
end sub

' ---------- settings ----------
function cfg() as object
  return m.global.cfg
end function

sub setCfg(c as object)
  m.global.cfg = c
  sec = CreateObject("roRegistrySection", "tvhome")
  sec.Write("cfg", FormatJson(c))
  sec.Flush()
end sub

sub notify(t as string)
  m.top.getScene().callFunc("toast", {text: t})
end sub

function scene() as object
  return m.top.getScene()
end function

' ---------- network (all requests run in ApiTask threads) ----------
function api(kind as string, url as string, opts = invalid as dynamic) as object
  t = CreateObject("roSGNode", "ApiTask")
  t.kind = kind
  t.url = url
  if opts <> invalid then
    if opts.method <> invalid then t.method = opts.method
    if opts.body <> invalid then t.body = opts.body
    if opts.headers <> invalid then t.headers = opts.headers
    if opts.mode <> invalid then t.mode = opts.mode
    if opts.timeout <> invalid then t.timeout = opts.timeout
    if isTrue(opts.keep) then m.top.getScene().appendChild(t)
  end if
  t.observeField("result", "onApi")
  if m.tasks = invalid then m.tasks = {}
  m.tasks[kind] = t
  t.control = "RUN"
  return t
end function

' true only for the newest request of a kind (older, superseded ones are ignored)
function apiFresh(e as object) as boolean
  r = e.getData()
  if r = invalid then return false
  cur = m.tasks[toStr(r.kind)]
  if cur = invalid then return false
  return cur.isSameNode(e.getRoSGNode())
end function

' ---------- Jellyfin ----------
function acct() as object
  a = m.global.alt
  if a <> invalid then
    if toStr(a.token) <> "" then return a
  end if
  c = m.global.cfg
  return {server: toStr(c.jfServer), user: toStr(c.jfUser), token: toStr(c.jfToken), uid: toStr(c.jfUid)}
end function

function jfOn() as boolean
  a = acct()
  return a.token <> "" and a.server <> ""
end function

function jfHeaders(token = "" as string) as object
  a = "MediaBrowser Client=""TV Home"", Device=""Roku"", DeviceId=""" + m.global.devId + """, Version=""1.0.0"""
  if token <> "" then a = a + ", Token=""" + token + """"
  return {"Authorization": a, "X-Emby-Authorization": a, "Content-Type": "application/json"}
end function

function jf(kind as string, path as string, opts = invalid as dynamic) as object
  a = acct()
  if opts = invalid then opts = {}
  opts.headers = jfHeaders(a.token)
  return api(kind, a.server + path, opts)
end function

function jfImg(id as dynamic, kind as string, w as integer) as string
  if toStr(id) = "" then return ""
  return acct().server + "/Items/" + toStr(id) + "/Images/" + kind + "?maxWidth=" + w.ToStr() + "&quality=90" + m.global.imgv
end function

' Jellyfin item -> what a card needs
function jfCard(it as object) as object
  ep = toStr(it.Type) = "Episode"
  typ = toStr(it.Type)
  genres = gv(it, "Genres")
  genre = ""
  if genres <> invalid then
    if genres.count() > 0 then genre = toStr(genres[0])
  end if
  parts = []
  if ep then
    parts.push(epCode(it))
    parts.push(toStr(it.Name))
  else if typ = "Series" then
    parts = ["Series", genre, seasonsText(it), toStr(it.ProductionYear)]
  else
    parts = ["Movie", genre, toStr(it.ProductionYear), dur(ticksSec(it.RunTimeTicks))]
  end if
  sid = toStr(it.SeriesId)
  if sid = "" then sid = toStr(it.Id)
  bid = toStr(it.ParentBackdropItemId)
  if bid = "" then bid = sid
  c = {id: toStr(it.Id), item: it, meta: joinDot(parts), pct: pctOf(it), played: isTrue(gv(gv(it, "UserData"), "Played"))}
  if ep then
    c.title = toStr(it.SeriesName)
    c.wide = [jfImg(it.Id, "Primary", 1400), jfImg(bid, "Backdrop", 1400)]
    c.tall = [jfImg(sid, "Primary", 500)]
    c.logo = jfImg(sid, "Logo", 700)
  else
    c.title = toStr(it.Name)
    c.wide = [jfImg(it.Id, "Backdrop", 1400), jfImg(it.Id, "Thumb", 1400)]
    c.tall = [jfImg(it.Id, "Primary", 500)]
    c.logo = ""
    if gv(gv(it, "ImageTags"), "Logo") <> invalid then c.logo = jfImg(it.Id, "Logo", 700)
  end if
  if c.title = "" then c.title = toStr(it.Name)
  return c
end function

function epCode(it as object) as string
  s = toStr(it.ParentIndexNumber)
  e = toStr(it.IndexNumber)
  if s = "" then s = "1"
  if e = "" then e = "?"
  return "S" + s + ":E" + e
end function

function seasonsText(it as object) as string
  n = Int(num(it.ChildCount))
  if n <= 0 then return ""
  if n = 1 then return "1 season"
  return n.ToStr() + " seasons"
end function

function pctOf(it as object) as float
  p = gv(gv(it, "UserData"), "PlayedPercentage")
  if p = invalid then return 0
  return num(p)
end function

function joinDot(parts as object) as string
  out = ""
  for each p in parts
    s = toStr(p)
    if s <> "" then
      if out <> "" then out = out + " · "
      out = out + s
    end if
  end for
  return out
end function

' standard way to open any Jellyfin item
sub openItem(it as object)
  typ = toStr(it.Type)
  if typ = "Movie" or typ = "Episode" or typ = "Series" or typ = "Video" or typ = "MusicVideo" or typ = "Season" then
    scene().callFunc("push", {view: "DetailView", item: it})
  else if isTrue(it.IsFolder) then
    scene().callFunc("push", {view: "SearchView", mode: "folder", item: it})
  end if
end sub

' ---------- IPTV (Xtream Codes) ----------
function ipOn() as boolean
  return toStr(m.global.cfg.ipServer) <> "" and toStr(m.global.cfg.ipUser) <> ""
end function

function xBase() as string
  c = m.global.cfg
  return c.ipServer + "/player_api.php?username=" + enc(c.ipUser) + "&password=" + enc(c.ipPass)
end function

function xLiveUrl(id as dynamic) as string
  c = m.global.cfg
  ext = ".m3u8"
  if c.ipFmt = "ts" then ext = ".ts"
  return c.ipServer + "/live/" + enc(c.ipUser) + "/" + enc(c.ipPass) + "/" + toStr(id) + ext
end function

function slimCh(s as object) as object
  return {id: toStr(s.id), n: toStr(s.n), i: toStr(s.i), num: toStr(s.num), c: toStr(s.c)}
end function

function liveRecents() as object
  r = m.global.cfg.recents
  if r = invalid then return []
  return r
end function

function liveFavs() as object
  r = m.global.cfg.favs
  if r = invalid then return []
  return r
end function

function isFav(id as dynamic) as boolean
  k = toStr(id)
  for each f in liveFavs()
    if toStr(f.id) = k then return true
  end for
  return false
end function

sub addRecent(s as object)
  c = m.global.cfg
  k = toStr(s.id)
  out = [slimCh(s)]
  for each r in liveRecents()
    if toStr(r.id) <> k and out.count() < 12 then out.push(r)
  end for
  c.recents = out
  setCfg(c)
end sub

sub removeRecent(id as dynamic)
  c = m.global.cfg
  out = []
  for each r in liveRecents()
    if toStr(r.id) <> toStr(id) then out.push(r)
  end for
  c.recents = out
  setCfg(c)
end sub

function toggleFav(s as object) as boolean
  c = m.global.cfg
  k = toStr(s.id)
  out = []
  was = false
  for each f in liveFavs()
    if toStr(f.id) = k then
      was = true
    else
      out.push(f)
    end if
  end for
  if not was and out.count() < 60 then out.push(slimCh(s))
  c.favs = out
  setCfg(c)
  if was then
    notify("Removed from favourites")
  else
    notify("Added to favourites")
  end if
  return not was
end function

' now/next from get_short_epg -> [{t, d, s, e}]
function epgList(data as dynamic) as object
  out = []
  l = gv(data, "epg_listings")
  if l = invalid then return out
  if type(l) <> "roArray" then return out
  now = nowSec()
  for each p in l
    st = Int(num(p.start_timestamp))
    en = Int(num(p.stop_timestamp))
    if en > now or en = 0 then out.push({t: b64(p.title), d: b64(p.description), s: st, e: en})
  end for
  return out
end function

function epgPct(p as object) as float
  if p = invalid then return 0
  if p.e <= p.s then return 0
  v = (nowSec() - p.s) / (p.e - p.s)
  if v < 0 then v = 0
  if v > 1 then v = 1
  return v
end function

' the shared video node lives in MainScene, behind every overlay
function vid() as object
  return m.global.vid
end function

sub showVid(x as integer, y as integer, w as integer, h as integer)
  v = m.global.vid
  b = m.global.vbg
  v.translation = [x, y]
  v.width = w
  v.height = h
  b.translation = [x, y]
  b.width = w
  b.height = h
  b.visible = true
  v.visible = true
end sub

sub hideVid()
  m.global.vid.visible = false
  m.global.vbg.visible = false
end sub
