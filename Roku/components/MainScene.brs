sub init()
  c = loadCfg()
  th = toStr(c.theme)
  if th <> "light" then th = "dark"
  v = CreateObject("roSGNode", "Video")
  v.width = 1920
  v.height = 1080
  v.enableUI = false
  v.visible = false
  v.notificationInterval = 1
  live = CreateObject("roSGNode", "LiveData")
  vbg = CreateObject("roSGNode", "Rectangle")
  vbg.color = "0x000000FF"
  vbg.visible = false
  m.global.addFields({cfg: c, devId: CreateObject("roDeviceInfo").GetChannelClientId(), theme: th, alt: {}, imgv: "", vid: v, live: live, playingId: "", guideCat: "", vbg: vbg, epgCache: {}})
  m.top.backgroundURI = ""
  m.stack = []
  m.curTab = "explore"
  m.ui = invalid
  m.top.appendChild(vbg)
  m.top.appendChild(v)
  ' the header (tabs + buttons) takes focus through this node; its keys bubble up to the scene
  m.hdrF = CreateObject("roSGNode", "Group")
  m.hdrF.focusable = true
  m.top.appendChild(m.hdrF)
  m.layer = grp(m.top)
  m.toastG = grp(m.top)
  m.toastT = mkTimer(2.6, "hideToast")
  m.tabT = mkTimer(0.35, "pendingTab")
  m.clockT = mkTimer(10, "tick", true)
  m.clockT.control = "start"
  m.global.observeField("theme", "onTheme")
  m.exitAt = -100000
  m.conn = ""
  m.cnt = invalid
  build()
  live.callFunc("load", {})
  if not jfOn() then autoSignIn()
end sub

' the built-in Jellyfin account (signed in automatically on first launch)
function DEF_JF() as object
  return {server: "https://ollyisgreat.eros.bysh.me/jellyfin", user: "ollyisgreat", pw: "12345"}
end function

function loadCfg() as object
  sec = CreateObject("roRegistrySection", "tvhome")
  c = invalid
  if sec.Exists("cfg") then c = ParseJson(sec.Read("cfg"))
  if c = invalid then c = {}
  d = {jfServer: DEF_JF().server, jfUser: DEF_JF().user, jfToken: "", jfUid: "", ipServer: "http://cf.2connectcdn.live", ipUser: "753d956d2244", ipPass: "8942b01377", ipFmt: "m3u8", favs: [], recents: [], theme: "dark"}
  for each k in d
    if c[k] = invalid then c[k] = d[k]
  end for
  ' not signed in yet: use the built-in accounts
  if toStr(c.jfToken) = "" then
    c.jfServer = d.jfServer
    c.jfUser = d.jfUser
  end if
  if toStr(c.ipServer) = "" or toStr(c.ipUser) = "" then
    c.ipServer = d.ipServer
    c.ipUser = d.ipUser
    c.ipPass = d.ipPass
  end if
  return c
end function

' ---------- build the home screen (rebuilt when the theme changes) ----------
sub build()
  m.pal = invalid
  p = thm()
  m.top.backgroundColor = p.bg1
  if m.ui <> invalid then m.top.removeChild(m.ui)
  m.ui = CreateObject("roSGNode", "Group")
  m.top.insertChild(m.ui, 0)
  bgp = pic(m.ui, 0, 0, 1920, 1080, "scaleToFill")
  bgp.uri = p.stage
  m.amb = pic(m.ui, -80, -80, 2080, 1240, "scaleToFill")
  m.amb.loadWidth = 48
  m.amb.loadHeight = 27
  m.amb.opacity = 0
  m.pages = {}
  m.pageG = grp(m.ui)
  for each k in ["explore", "movies", "shows"]
    if k = "explore" then
      pg = CreateObject("roSGNode", "ExplorePage")
    else
      pg = CreateObject("roSGNode", "LibPage")
      pg.section = k
    end if
    pg.visible = false
    m.pageG.appendChild(pg)
    m.pages[k] = pg
  end for
  buildHeader()
  m.hz = "tabs"
  m.hi = 0
  showPage(m.curTab, false)
  focusHeader("tabs", tabIndex(m.curTab))
end sub

sub buildHeader()
  p = thm()
  m.hdr = grp(m.ui)
  lbl(m.hdr, 110, 52, "For you", 78, "s", p.text)
  m.tabs = []
  defs = [{id: "explore", t: "Explore"}, {id: "movies", t: "Movies"}, {id: "shows", t: "Shows"}, {id: "guide", t: "IPTV Guide", icon: "tv", outline: true}, {id: "search", t: "Search movies", icon: "search"}]
  for each d in defs
    g = grp(m.hdr, 0, 172)
    t = {id: d.id, g: g, outline: isTrue(d.outline)}
    if t.outline then
      t.ob = rbox(g, 0, 0, 10, 58, 29, p.glass)
      t.oe = edge(g, "thin29", 0, 0, 10, 58, p.glassB)
    end if
    t.bg = rbox(g, 0, 0, 10, 58, 29, p.pill)
    t.bg.visible = false
    x = 22
    if d.icon <> invalid then
      t.ic = icon(g, d.icon, 22, 15, 28, p.muted)
      x = 60
    end if
    t.l = lbl(g, x, 10, d.t, 31, "r", p.muted)
    t.lx = x
    m.tabs.push(t)
  end for
  m.tools = []
  names = ["refresh", "settings"]
  for i = 0 to names.count() - 1
    g = grp(m.hdr, 1648 + i * 90, 62)
    o = {id: names[i], g: g}
    o.bg = rbox(g, 0, 0, 72, 72, 32, p.glass)
    o.ed = edge(g, "thin36", 0, 0, 72, 72, p.glassB)
    o.ic = icon(g, names[i], 21, 21, 30, p.text)
    g.scaleRotateCenter = [36, 36]
    m.tools.push(o)
  end for
  m.stats = grp(m.hdr, 0, 156)
  layoutTabs()
  tick()
end sub

sub layoutTabs()
  p = thm()
  x = 90
  for each t in m.tabs
    vis = true
    if t.id = "search" then vis = (m.curTab = "movies" or m.curTab = "shows")
    t.g.visible = vis
    if vis then
      if t.id = "guide" then x = x + 18
      if t.id = "search" then
        x = x + 6
        if m.curTab = "movies" then t.l.text = "Search movies" else t.l.text = "Search shows"
      end if
      active = (t.id = m.curTab)
      if active then t.l.font = fnt("s", 31) else t.l.font = fnt("r", 31)
      w = t.lx + textW(t.l) + 22
      t.w = w
      t.bg.width = w
      if t.outline then
        t.ob.width = w
        t.oe.width = w
      end if
      t.g.translation = [x, 172]
      t.g.scaleRotateCenter = [w / 2, 29]
      x = x + w + 14
    end if
  end for
  paintHeader()
end sub

sub paintHeader()
  p = thm()
  focusedHdr = m.hdrF.hasFocus()
  for i = 0 to m.tabs.count() - 1
    t = m.tabs[i]
    f = focusedHdr and m.hz = "tabs" and m.hi = i
    t.bg.visible = f
    if f then
      t.l.color = p.pillText
      tween(t.g, "scale", [1.06, 1.06], 0.18)
    else
      if t.id = m.curTab then t.l.color = p.text else t.l.color = p.muted
      tween(t.g, "scale", [1.0, 1.0], 0.18)
    end if
    if t.ic <> invalid then t.ic.blendColor = t.l.color
  end for
  for i = 0 to m.tools.count() - 1
    o = m.tools[i]
    f = focusedHdr and m.hz = "tools" and m.hi = i
    if f then
      o.bg.blendColor = p.pill
      o.ic.blendColor = p.pillText
      tween(o.g, "scale", [1.14, 1.14], 0.18)
    else
      o.bg.blendColor = p.glass
      o.ic.blendColor = p.text
      tween(o.g, "scale", [1.0, 1.0], 0.18)
    end if
  end for
end sub

' film count · show count · ● user · clock (right-aligned under the buttons)
sub tick()
  if m.stats = invalid then return
  p = thm()
  m.stats.removeChildrenIndex(m.stats.getChildCount(), 0)
  items = []
  if m.cnt <> invalid then
    items.push({ic: "film", t: toStr(m.cnt.MovieCount)})
    items.push({ic: "monitor", t: toStr(m.cnt.SeriesCount)})
  end if
  a = acct()
  if a.token <> "" then
    col = "0x8E8E93FF"
    if m.conn = "ok" then col = "0x30D158FF"
    if m.conn = "err" then col = "0xFF453AFF"
    items.push({dot: col, t: a.user})
  end if
  items.push({t: hm()})
  x = 1810
  for i = items.count() - 1 to 0 step -1
    it = items[i]
    l = lbl(m.stats, 0, 0, it.t, 22, "r", p.muted)
    w = textW(l)
    x = x - w
    l.translation = [x, 0]
    if it.ic <> invalid then
      x = x - 28
      icon(m.stats, it.ic, x, 3, 20, p.muted)
    else if it.dot <> invalid then
      x = x - 18
      icon(m.stats, "dot", x, 9, 10, it.dot)
    end if
    x = x - 26
  end for
end sub

function counts(p as dynamic) as dynamic
  if p <> invalid then
    if p.conn <> invalid then m.conn = p.conn
  end if
  if jfOn() then jf("counts", "/Items/Counts?UserId=" + acct().uid)
  tick()
  return invalid
end function

sub autoSignIn()
  c = m.global.cfg
  d = DEF_JF()
  if c.jfServer <> d.server or c.jfUser <> d.user then return
  body = FormatJson({"Username": d.user, "Pw": d.pw})
  api("autoauth", d.server + "/Users/AuthenticateByName", {method: "POST", body: body, headers: jfHeaders(""), timeout: 20000})
end sub

sub onApi(e as object)
  if not apiFresh(e) then return
  r = e.getData()
  if r.kind = "autoauth" then
    tok = toStr(gv(r.data, "AccessToken"))
    if r.ok and tok <> "" then
      c = m.global.cfg
      c.jfToken = tok
      c.jfUid = toStr(gv(gv(r.data, "User"), "Id"))
      setCfg(c)
      jfSwitched({})
    else
      toast({text: "Couldn't sign in to Jellyfin (" + toStr(r.code) + ") — check Settings"})
    end if
    return
  end if
  if r.kind = "counts" then
    if r.ok then
      m.cnt = r.data
      m.conn = "ok"
    else
      m.conn = "err"
    end if
    tick()
  end if
end sub

' ---------- pages ----------
function tabIndex(id as string) as integer
  for i = 0 to m.tabs.count() - 1
    if m.tabs[i].id = id then return i
  end for
  return 0
end function

sub showPage(id as string, force as boolean)
  m.curTab = id
  for each k in m.pages
    m.pages[k].visible = (k = id)
  end for
  if id <> "explore" then ambient({uri: ""})
  headerDown({down: false})
  layoutTabs()
  m.pages[id].callFunc("activate", {force: force})
  if m.cnt = invalid then counts({})
end sub

function openTab(p as dynamic) as dynamic
  showPage(p.id, false)
  focusHeader("tabs", tabIndex(p.id))
  return invalid
end function

sub pendingTab()
  if not m.hdrF.hasFocus() or m.hz <> "tabs" then return
  t = m.tabs[m.hi]
  if t.id = "explore" or t.id = "movies" or t.id = "shows" then
    if t.id <> m.curTab then showPage(t.id, false)
  end if
end sub

sub focusHeader(z as string, i as integer)
  pg = m.pages[m.curTab]
  if pg <> invalid then pg.callFunc("blur", {})
  m.hz = z
  m.hi = i
  m.hdrF.setFocus(true)
  paintHeader()
  if z = "tabs" then restart(m.tabT)
end sub

function headerDown(p as dynamic) as dynamic
  if m.hdr = invalid then return invalid
  if isTrue(p.down) then
    tween(m.hdr, "opacity", 0.0, 0.25)
    tween(m.hdr, "translation", [0, -40], 0.25)
  else
    tween(m.hdr, "opacity", 1.0, 0.25)
    tween(m.hdr, "translation", [0, 0], 0.25)
  end if
  return invalid
end function

function ambient(p as dynamic) as dynamic
  if m.amb = invalid then return invalid
  u = toStr(p.uri)
  if u = "" or thm().light then
    tween(m.amb, "opacity", 0.0, 0.6)
  else
    if m.amb.uri <> u then m.amb.uri = u
    tween(m.amb, "opacity", 0.35, 0.8)
  end if
  return invalid
end function

' the account changed (secret toggle / new sign-in): drop everything loaded and reload
function jfSwitched(p as dynamic) as dynamic
  m.cnt = invalid
  for each k in m.pages
    m.pages[k].callFunc("reset", {})
  end for
  m.pages[m.curTab].callFunc("activate", {force: true})
  counts({})
  return invalid
end function

sub hardRefresh()
  if not jfOn() then
    toast({text: "Sign in to Jellyfin in Settings first"})
    return
  end if
  jf("refresh", "/Library/Refresh", {method: "POST", keep: true})
  ns = nowSec()
  m.global.imgv = "&v=" + ns.ToStr()
  toast({text: "Refreshing Jellyfin metadata…"})
  jfSwitched({})
  live = m.global.live
  if ipOn() then live.callFunc("load", {force: true})
end sub

sub onTheme()
  build()
  for each e in m.stack
    e.node.callFunc("onReturn", {theme: true})
  end for
end sub

' ---------- overlays ----------
function push(p as object) as dynamic
  v = CreateObject("roSGNode", p.view)
  if v = invalid then return invalid
  ' players draw over the video, so hide whatever is underneath them
  full = (p.view = "VodPlayer" or p.view = "LivePlayer")
  if full then
    for each e in m.stack
      e.node.visible = false
    end for
    m.ui.visible = false
  end if
  m.stack.push({node: v, focus: focusedNode(), full: full})
  m.layer.appendChild(v)
  v.callFunc("open", p)
  return v
end function

function pop(p as dynamic) as dynamic
  if m.stack.count() = 0 then return invalid
  e = m.stack.pop()
  m.layer.removeChild(e.node)
  if e.full then
    for each x in m.stack
      x.node.visible = true
    end for
    m.ui.visible = true
  end if
  if m.stack.count() > 0 then
    top = m.stack.peek()
    if e.focus <> invalid then e.focus.setFocus(true) else top.node.setFocus(true)
    top.node.callFunc("onReturn", {})
  else
    if e.focus <> invalid then
      e.focus.setFocus(true)
    else
      m.hdrF.setFocus(true)
    end if
    if m.hdrF.hasFocus() then paintHeader()
    m.pages[m.curTab].callFunc("onReturn", {})
  end if
  return invalid
end function

function focusedNode() as object
  n = m.top
  while true
    f = n.focusedChild
    if f = invalid then exit while
    if f.isSameNode(n) then exit while
    n = f
  end while
  return n
end function

function toast(p as dynamic) as dynamic
  pal = thm()
  m.top.removeChild(m.toastG)
  m.toastG = grp(m.top)
  l = lbl(m.toastG, 34, 18, toStr(p.text), 25, "r", pal.text)
  w = textW(l) + 68
  b = rbox(invalid, 0, 0, w, 66, 32, pal.glassS)
  m.toastG.insertChild(b, 0)
  ed = edge(m.toastG, "thin32", 0, 0, w, 66, pal.glassB)
  ed.opacity = 0.9
  m.toastG.removeChild(l)
  m.toastG.appendChild(l)
  m.toastG.translation = [(1920 - w) / 2, 30]
  m.toastG.opacity = 0
  tween(m.toastG, "opacity", 1.0, 0.3)
  tween(m.toastG, "translation", [(1920 - w) / 2, 60], 0.3)
  restart(m.toastT)
  return invalid
end function

sub hideToast()
  tween(m.toastG, "opacity", 0.0, 0.3)
end sub

' ---------- keys (header + routing) ----------
function onKeyEvent(key as string, press as boolean) as boolean
  if not press then return false
  if m.stack.count() > 0 then return true
  if not m.hdrF.hasFocus() then
    ' a page let this key through
    if key = "up" or key = "back" then
      focusHeader("tabs", tabIndex(m.curTab))
      return true
    end if
    return true
  end if
  if key = "left" then
    if m.hz = "tabs" then
      i = m.hi - 1
      while i >= 0
        if m.tabs[i].g.visible then exit while
        i = i - 1
      end while
      if i >= 0 then focusHeader("tabs", i)
    else
      if m.hi > 0 then
        focusHeader("tools", m.hi - 1)
      else
        focusHeader("tabs", lastTab())
      end if
    end if
  else if key = "right" then
    if m.hz = "tabs" then
      i = m.hi + 1
      while i < m.tabs.count()
        if m.tabs[i].g.visible then exit while
        i = i + 1
      end while
      if i < m.tabs.count() then focusHeader("tabs", i) else focusHeader("tools", 0)
    else if m.hi < m.tools.count() - 1 then
      focusHeader("tools", m.hi + 1)
    end if
  else if key = "up" then
    if m.hz = "tabs" then focusHeader("tools", m.tools.count() - 1)
  else if key = "down" then
    if m.hz = "tools" then
      focusHeader("tabs", tabIndex(m.curTab))
    else
      t = m.tabs[m.hi]
      if t.id = "explore" or t.id = "movies" or t.id = "shows" then
        if t.id <> m.curTab then showPage(t.id, false)
        downIntoPage()
      else
        downIntoPage()
      end if
    end if
  else if key = "OK" then
    if m.hz = "tools" then
      if m.tools[m.hi].id = "settings" then push({view: "SettingsView"}) else hardRefresh()
    else
      t = m.tabs[m.hi]
      if t.id = "guide" then
        push({view: "GuideView"})
      else if t.id = "search" then
        push({view: "SearchView", mode: m.curTab})
      else
        if t.id <> m.curTab then showPage(t.id, false)
        downIntoPage()
      end if
    end if
  else if key = "back" then
    if m.curTab <> "explore" then
      showPage("explore", false)
      focusHeader("tabs", 0)
    else if m.hz <> "tabs" or m.hi <> 0 then
      focusHeader("tabs", 0)
    else
      now = msNow()
      if now - m.exitAt < 2500 then return false
      m.exitAt = now
      toast({text: "Press Back again to exit"})
    end if
  else if key = "options" then
    push({view: "SettingsView"})
  end if
  return true
end function

function lastTab() as integer
  for i = m.tabs.count() - 1 to 0 step -1
    if m.tabs[i].g.visible then return i
  end for
  return 0
end function

sub downIntoPage()
  pg = m.pages[m.curTab]
  if pg.callFunc("takeFocus", {}) = true then paintHeader()
end sub
