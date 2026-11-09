' Settings sheet: Jellyfin, IPTV, appearance. ▲▲▼▼ quietly swaps to the second Jellyfin account.
sub init()
  p = thm()
  m.p = p
  rect(m.top, 0, 0, 1920, 1080, p.overlay)
  sx = 410
  sy = 40
  rbox(m.top, sx, sy, 1100, 1000, 40, p.glassS)
  edge(m.top, "thin40", sx, sy, 1100, 1000, p.glassB)
  m.clip = CreateObject("roSGNode", "Group")
  m.clip.clippingRect = [sx, sy + 30, 1100, 940]
  m.top.appendChild(m.clip)
  m.body = grp(m.clip, sx + 60, sy + 46)
  m.els = []
  m.idx = 0
  m.scroll = 0
  m.seq = []
  c = m.global.cfg
  m.f = {jfServer: toStr(c.jfServer), jfUser: toStr(c.jfUser), jfPass: "", ipServer: toStr(c.ipServer), ipUser: toStr(c.ipUser), ipPass: toStr(c.ipPass)}
  draw()
end sub

function onReturn(p as dynamic) as dynamic
  m.top.setFocus(true)
  return invalid
end function

function open(p as dynamic) as dynamic
  m.top.setFocus(true)
  paint()
  return invalid
end function

' ---------- layout ----------
sub draw()
  p = m.p
  b = m.body
  b.removeChildrenIndex(b.getChildCount(), 0)
  m.els = []
  c = m.global.cfg
  lbl(b, 0, 0, "Settings", 46, "s", p.text)
  h3(b, 74, "Jellyfin")
  fl(b, 0, 112, "Server address")
  inField(b, 0, 142, 980, "jfServer", "https://your-server/jellyfin", 0)
  fl(b, 0, 220, "Username")
  fl(b, 503, 220, "Password")
  inField(b, 0, 250, 477, "jfUser", "", 1)
  inField(b, 503, 250, 477, "jfPass", "", 1)
  btn(b, 0, 342, "Connect", "jfConnect", "primary", 2)
  m.jfStatus = lbl(b, 200, 358, "", 22, "r", p.muted, 780)
  setJfStatus()
  h3(b, 432, "IPTV (Xtream Codes)")
  fl(b, 0, 470, "Server address (or paste your full M3U link)")
  inField(b, 0, 500, 980, "ipServer", "http://provider.example:8080", 3)
  fl(b, 0, 578, "Username")
  fl(b, 503, 578, "Password")
  inField(b, 0, 608, 477, "ipUser", "", 4)
  inField(b, 503, 608, 477, "ipPass", "", 4)
  btn(b, 0, 700, "Connect", "ipConnect", "primary", 5)
  m.ipStatus = lbl(b, 200, 716, "", 22, "r", p.muted, 780)
  setIpStatus("")
  fl(b, 0, 790, "Stream type (try MPEG-TS if channels won't play)")
  btn(b, 0, 820, "HLS (.m3u8)", "fmt:m3u8", iif(c.ipFmt <> "ts", "sel", ""), 6)
  btn(b, 0, 820, "MPEG-TS (.ts)", "fmt:ts", iif(c.ipFmt = "ts", "sel", ""), 6)
  h3(b, 906, "Appearance")
  fl(b, 0, 944, "Theme")
  th = m.global.theme
  btn(b, 0, 974, "Light", "theme:light", iif(th = "light", "sel", ""), 7)
  btn(b, 0, 974, "Dark", "theme:dark", iif(th <> "light", "sel", ""), 7)
  h3(b, 1060, "Live TV")
  btn(b, 0, 1098, "Clear recently watched", "clear", "danger", 8)
  btn(b, 0, 1188, "Done", "done", "primary", 9)
  ' lay buttons that share a row side by side
  for r = 0 to 9
    x = 0
    for each e in m.els
      if e.row = r and e.kind = "btn" then
        e.g.translation = [x, e.y]
        x = x + e.w + 16
      end if
    end for
  end for
  paint()
end sub

function iif(c as boolean, a as dynamic, b as dynamic) as dynamic
  if c then return a
  return b
end function

sub h3(b as object, y as integer, t as string)
  lbl(b, 0, y, UCase(t), 22, "s", m.p.muted)
end sub

sub fl(b as object, x as integer, y as integer, t as string)
  lbl(b, x, y, t, 22, "r", m.p.muted, 980)
end sub

sub inField(b as object, x as integer, y as integer, w as integer, key as string, ph as string, row as integer)
  p = m.p
  g = grp(b, x, y)
  bg = rbox(g, 0, 0, w, 62, 16, p.input)
  ed = edge(g, "thin16", 0, 0, w, 62, p.accent)
  l = lbl(g, 22, 14, "", 27, "r", p.text, w - 44)
  e = {kind: "input", key: key, g: g, ed: ed, l: l, ph: ph, row: row, y: y, h: 62}
  m.els.push(e)
  showVal(e)
end sub

sub showVal(e as object)
  v = toStr(m.f[e.key])
  if e.key = "jfPass" or e.key = "ipPass" then
    if v <> "" then
      e.l.text = "••••••••"
      e.l.color = m.p.text
    else
      if e.key = "ipPass" and toStr(m.global.cfg.ipPass) <> "" then e.l.text = "(saved)" else e.l.text = ""
      e.l.color = m.p.muted
    end if
    return
  end if
  if v = "" then
    e.l.text = e.ph
    e.l.color = m.p.muted
  else
    e.l.text = v
    e.l.color = m.p.text
  end if
end sub

sub btn(b as object, x as integer, y as integer, t as string, act as string, style as string, row as integer)
  p = m.p
  g = grp(b, x, y)
  l = lbl(g, 30, 15, t, 25, "s", p.text)
  w = textW(l) + 60
  bgc = p.glass
  tc = p.text
  if style = "primary" then
    bgc = p.accent
    tc = "0xFFFFFFFF"
  else if style = "sel" then
    bgc = p.text
    tc = p.bg1
  else if style = "danger" then
    tc = "0xFF453AFF"
  end if
  bg = rbox(invalid, 0, 0, w, 60, 29, bgc)
  g.insertChild(bg, 0)
  if style = "" or style = "danger" then
    ed = edge(invalid, "thin29", 0, 0, w, 60, p.glassB)
    g.insertChild(ed, 1)
  end if
  l.color = tc
  g.scaleRotateCenter = [w / 2, 30]
  rg = edge(g, "ring33", -4, -4, w + 8, 68, p.ring)
  rg.opacity = 0
  m.els.push({kind: "btn", act: act, g: g, ring: rg, w: w, row: row, y: y, h: 60})
end sub

sub setJfStatus()
  c = m.global.cfg
  if toStr(c.jfToken) <> "" then
    m.jfStatus.text = "Connected to " + toStr(c.jfServer) + " as " + toStr(c.jfUser)
    m.jfStatus.color = m.p.ok
  else
    m.jfStatus.text = "Not connected"
    m.jfStatus.color = m.p.muted
  end if
end sub

sub setIpStatus(t as string)
  c = m.global.cfg
  if t <> "" then
    m.ipStatus.text = t
    return
  end if
  if toStr(c.ipServer) <> "" then
    m.ipStatus.text = "Saved · " + toStr(c.ipUser) + " @ " + toStr(c.ipServer)
    m.ipStatus.color = m.p.ok
  else
    m.ipStatus.text = "Not connected"
    m.ipStatus.color = m.p.muted
  end if
end sub

' ---------- focus ----------
sub paint()
  for i = 0 to m.els.count() - 1
    e = m.els[i]
    f = (i = m.idx)
    if e.kind = "input" then
      e.ed.visible = f
    else
      if f then
        tween(e.g, "scale", [1.07, 1.07], 0.15)
        e.ring.opacity = 1
      else
        tween(e.g, "scale", [1.0, 1.0], 0.15)
        e.ring.opacity = 0
      end if
    end if
  end for
  e = m.els[m.idx]
  top = e.y - m.scroll
  if top + e.h > 880 then m.scroll = e.y + e.h - 880
  if top < 60 then m.scroll = e.y - 60
  if e.row <= 1 then m.scroll = 0
  if m.scroll < 0 then m.scroll = 0
  tween(m.body, "translation", [470, 86 - m.scroll], 0.2)
end sub

sub moveRow(d as integer)
  cur = m.els[m.idx]
  r = cur.row + d
  while r >= 0 and r <= 9
    best = -1
    for i = 0 to m.els.count() - 1
      if m.els[i].row = r and best < 0 then best = i
    end for
    if best >= 0 then
      m.idx = best
      paint()
      return
    end if
    r = r + d
  end while
end sub

sub moveCol(d as integer)
  i = m.idx + d
  if i < 0 or i >= m.els.count() then return
  if m.els[i].row <> m.els[m.idx].row then return
  m.idx = i
  paint()
end sub

' ---------- actions ----------
sub activate()
  e = m.els[m.idx]
  if e.kind = "input" then
    titles = {jfServer: "Jellyfin server address", jfUser: "Jellyfin username", jfPass: "Jellyfin password", ipServer: "IPTV server address or M3U link", ipUser: "IPTV username", ipPass: "IPTV password"}
    ask(e.key, titles[e.key], toStr(m.f[e.key]))
    return
  end if
  a = e.act
  c = m.global.cfg
  if a = "jfConnect" then
    jfConnect()
  else if a = "ipConnect" then
    ipConnect()
  else if Left(a, 4) = "fmt:" then
    c.ipFmt = Mid(a, 5)
    setCfg(c)
    keep = m.idx
    draw()
    m.idx = keep
    paint()
  else if Left(a, 6) = "theme:" then
    th = Mid(a, 7)
    c.theme = th
    setCfg(c)
    if m.global.theme <> th then
      m.global.theme = th
      notify("Theme changed")
    end if
  else if a = "clear" then
    c.recents = []
    setCfg(c)
    notify("Recently watched cleared")
  else if a = "done" then
    close()
  end if
end sub

sub ask(key as string, title as string, value as string)
  d = CreateObject("roSGNode", "StandardKeyboardDialog")
  if d = invalid then d = CreateObject("roSGNode", "KeyboardDialog")
  d.title = title
  d.text = value
  d.buttons = ["OK", "Cancel"]
  d.observeField("buttonSelected", "onDlg")
  m.dlgKey = key
  m.dlg = d
  sc = scene()
  sc.dialog = d
end sub

sub onDlg()
  d = m.dlg
  if d.buttonSelected = 0 then
    v = d.text.Trim()
    k = m.dlgKey
    if k = "ipServer" then v = parseIp(v)
    if k = "jfServer" then v = normUrl(v)
    m.f[k] = v
    for each e in m.els
      if e.kind = "input" then showVal(e)
    end for
  end if
  d.close = true
  m.top.setFocus(true)
end sub

function normUrl(v as string) as string
  s = v.Trim()
  if s = "" then return s
  if Instr(1, s, "://") = 0 then s = "http://" + s
  ' a pasted browser link like .../jellyfin/web/#/home.html -> .../jellyfin
  i = Instr(1, LCase(s), "/web/")
  if i > 0 then s = Left(s, i - 1)
  i = Instr(1, s, "#")
  if i > 0 then s = Left(s, i - 1)
  if LCase(Right(s, 4)) = "/web" then s = Left(s, Len(s) - 4)
  while Right(s, 1) = "/"
    s = Left(s, Len(s) - 1)
  end while
  return s
end function

' accepts "host:port", a full URL, or a whole get.php?username=..&password=.. link
function parseIp(v as string) as string
  s = v.Trim()
  if Instr(1, s, "username=") > 0 then
    u = CreateObject("roRegex", "[?&]username=([^&]+)", "i").Match(s)
    pw = CreateObject("roRegex", "[?&]password=([^&]+)", "i").Match(s)
    if u.count() > 1 then m.f.ipUser = u[1]
    if pw.count() > 1 then m.f.ipPass = pw[1]
  end if
  s = normUrl(s)
  h = CreateObject("roRegex", "^(https?://[^/?#]+)", "i").Match(s)
  if h.count() > 1 then s = h[1]
  return s
end function

sub jfConnect()
  srv = normUrl(m.f.jfServer)
  if srv = "" or m.f.jfUser = "" then
    m.jfStatus.text = "Enter the server address and username first"
    m.jfStatus.color = m.p.err
    return
  end if
  m.jfStatus.text = "Connecting…"
  m.jfStatus.color = m.p.muted
  body = FormatJson({"Username": m.f.jfUser, "Pw": m.f.jfPass})
  api("auth", srv + "/Users/AuthenticateByName", {method: "POST", body: body, headers: jfHeaders(""), timeout: 15000})
  m.authSrv = srv
end sub

sub ipConnect()
  if m.f.ipServer = "" or m.f.ipUser = "" then
    setIpStatus("Enter the server, username and password first")
    m.ipStatus.color = m.p.err
    return
  end if
  setIpStatus("Connecting…")
  m.ipStatus.color = m.p.muted
  url = m.f.ipServer + "/player_api.php?username=" + enc(m.f.ipUser) + "&password=" + enc(m.f.ipPass)
  api("xtest", url, {timeout: 20000})
end sub

sub onApi(e as object)
  if not apiFresh(e) then return
  r = e.getData()
  c = m.global.cfg
  if r.kind = "auth" then
    tok = toStr(gv(r.data, "AccessToken"))
    if r.ok and tok <> "" then
      c.jfServer = m.authSrv
      c.jfUser = m.f.jfUser
      c.jfToken = tok
      c.jfUid = toStr(gv(gv(r.data, "User"), "Id"))
      setCfg(c)
      m.f.jfPass = ""
      setJfStatus()
      for each x in m.els
        if x.kind = "input" then showVal(x)
      end for
      if not isTrue(gv(m.global.alt, "on")) then scene().callFunc("jfSwitched", {})
    else
      if r.code = 401 then
        m.jfStatus.text = "Wrong username or password"
      else if r.code = 0 then
        m.jfStatus.text = "Can't reach that server"
      else
        m.jfStatus.text = "Sign-in failed (" + r.code.ToStr() + ")"
      end if
      m.jfStatus.color = m.p.err
    end if
  else if r.kind = "xtest" then
    ui = gv(r.data, "user_info")
    if r.ok and toStr(gv(ui, "auth")) = "1" then
      c.ipServer = m.f.ipServer
      c.ipUser = m.f.ipUser
      c.ipPass = m.f.ipPass
      setCfg(c)
      t = "Connected"
      ex = Int(num(gv(ui, "exp_date")))
      if ex > 0 then t = t + " · expires " + dateText(ex)
      setIpStatus(t)
      m.ipStatus.color = m.p.ok
      m.global.live.callFunc("load", {force: true})
    else
      if r.code = 0 then setIpStatus("Can't reach that server") else setIpStatus("Login failed — check the username and password")
      m.ipStatus.color = m.p.err
    end if
  else if r.kind = "secret" then
    tok = toStr(gv(r.data, "AccessToken"))
    if r.ok and tok <> "" then
      m.global.alt = {on: true, server: "http://192.168.1.167:8096", user: "olly", token: tok, uid: toStr(gv(gv(r.data, "User"), "Id"))}
      scene().callFunc("jfSwitched", {})
    end if
  end if
end sub

function dateText(sec as integer) as string
  d = CreateObject("roDateTime")
  d.FromSeconds(sec)
  mo = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
  dd = d.GetDayOfMonth()
  yy = d.GetYear()
  return dd.ToStr() + " " + mo[d.GetMonth() - 1] + " " + yy.ToStr()
end function

' ▲▲▼▼ within 3 seconds: switch to / back from the second account. Nothing on screen changes.
sub secretKey(key as string)
  now = msNow()
  keep = []
  for each s in m.seq
    if now - s.t < 3000 then keep.push(s)
  end for
  keep.push({k: key, t: now})
  m.seq = keep
  n = keep.count()
  if n >= 4 then
    if keep[n - 4].k = "up" and keep[n - 3].k = "up" and keep[n - 2].k = "down" and keep[n - 1].k = "down" then
      m.seq = []
      if isTrue(gv(m.global.alt, "on")) then
        m.global.alt = {}
        scene().callFunc("jfSwitched", {})
      else
        body = FormatJson({"Username": "olly", "Pw": "12345"})
        api("secret", "http://192.168.1.167:8096/Users/AuthenticateByName", {method: "POST", body: body, headers: jfHeaders(""), timeout: 10000})
      end if
    end if
  end if
end sub

sub close()
  scene().callFunc("pop", {})
end sub

function onKeyEvent(key as string, press as boolean) as boolean
  if not press then return true
  if key = "up" or key = "down" then secretKey(key) else m.seq = []
  if key = "back" then
    close()
  else if key = "up" then
    moveRow(-1)
  else if key = "down" then
    moveRow(1)
  else if key = "left" then
    moveCol(-1)
  else if key = "right" then
    moveCol(1)
  else if key = "OK" then
    activate()
  end if
  return true
end function
