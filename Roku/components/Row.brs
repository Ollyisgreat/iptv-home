sub init()
  m.track = grp(m.top)
  m.nodes = []
  m.idx = 0
  m.scroll = 0
  m.has = false
  m.top.observeField("focusedChild", "onFocusChg")
end sub

function count(p as dynamic) as dynamic
  return m.nodes.count()
end function

sub build()
  if m.top.dark then m.pal = thmD()
  m.track.removeChildrenIndex(m.track.getChildCount(), 0)
  m.nodes = []
  items = m.top.items
  x = m.top.padL
  for i = 0 to items.count() - 1
    it = items[i]
    if i > 0 then
      g = m.top.gap
      if it.gapBefore <> invalid then g = it.gapBefore
      x = x + g
    end if
    t = toStr(it.ui)
    if t = "live" or t = "go" then
      n = makeLive(it, i)
    else if t = "pill" then
      n = makePill(it, i)
    else if t = "btn" then
      n = makeBtn(it, i)
    else
      n = makeCard(it, i)
    end if
    n.x = x
    n.root.translation = [x, 0]
    m.nodes.push(n)
    x = x + n.w
  end for
  m.idx = m.top.index
  if m.idx >= m.nodes.count() then m.idx = m.nodes.count() - 1
  if m.idx < 0 then m.idx = 0
  m.scroll = 0
  m.track.translation = [0, 0]
  ensureVisible(false)
  paint(false)
end sub

' ---------- item builders ----------
function makeCard(it as object, i as integer) as object
  p = thm()
  w = it.w
  h = it.h
  r = 22
  if it.r <> invalid then r = it.r
  root = grp(m.track)
  z = grp(root)
  z.scaleRotateCenter = [w / 2, h / 2]
  n = {root: root, z: z, w: w, h: h, kind: "card", tmove: 10, loaded: false}
  if it.tmove <> invalid then n.tmove = it.tmove
  rbox(z, 0, 0, w, h, r, hueColor(toStr(it.title)))
  ph = lbl(z, 26, 26, toStr(it.ph), 30, "s", "0xFFFFFFFF", w - 52, h - 52)
  ph.wrap = true
  ph.maxLines = 3
  ph.vertAlign = "bottom"
  if toStr(it.ph) = "" then ph.text = toStr(it.title)
  n.img = mpic(z, 0, 0, w, h)
  n.img.id = "i" + i.ToStr()
  n.alts = []
  if type(it.img) = "roArray" then
    for each u in it.img
      if toStr(u) <> "" then n.alts.push(u)
    end for
  else if toStr(it.img) <> "" then
    n.alts.push(it.img)
  end if
  n.ai = 0
  n.img.observeField("loadStatus", "onImg")
  if toStr(it.logo) <> "" then
    n.logo = pic(z, 34, 30, Int(w * 0.4), Int(h * 0.28), "scaleToFit")
    n.logo.id = "l" + i.ToStr()
    n.logoUri = it.logo
    n.logo.observeField("loadStatus", "onLogo")
  end if
  pct = num(it.pct)
  if pct > 1 and pct < 98 then
    rect(z, 24, h - 27, w - 48, 7, "0xFFFFFF59")
    rect(z, 24, h - 27, Int((w - 48) * pct / 100), 7, "0xFFFFFFFF")
  end if
  if isTrue(it.played) then
    rbox(z, w - 52, 14, 38, 38, 18, "0x00000099")
    icon(z, "check", w - 44, 22, 22, "0xFFFFFFFF")
  end if
  rr = r + 5
  n.ring = edge(z, "ring" + rr.ToStr(), -5, -5, w + 10, h + 10, p.ring)
  n.ring.opacity = 0
  ts = 28
  if it.tsize <> invalid then ts = it.tsize
  ms = 21
  if it.msize <> invalid then ms = it.msize
  tw = "r"
  if it.tweight <> invalid then tw = it.tweight
  tmt = 20
  if it.tmt <> invalid then tmt = it.tmt
  tx = 0
  n.tg = grp(root, 0, h + tmt)
  if isTrue(it.dot) then
    icon(n.tg, "dot", 0, Int(ts * 0.6 / 2), Int(ts * 0.6), p.accent)
    tx = Int(ts * 0.85)
  end if
  n.t = lbl(n.tg, tx, 0, it.title, ts, tw, p.text, w - tx)
  n.m = lbl(n.tg, 0, Int(ts * 1.22) + 4, it.meta, ms, "r", p.muted, w)
  return n
end function

function makeLive(it as object, i as integer) as object
  p = thm()
  go = (toStr(it.ui) = "go")
  w = 340
  if go then w = 300
  root = grp(m.track)
  if toStr(it.group) <> "" then lbl(root, 4, 4, it.group, 22, "s", p.muted, 0)
  z = grp(root, 0, 46)
  z.scaleRotateCenter = [w / 2, 60]
  n = {root: root, z: z, w: w, h: 166, kind: "live", go: go, tmove: 0}
  if go then
    n.bg = rbox(z, 0, 0, w, 120, 24, p.accent)
    icon(z, "guide", 20, 34, 52, "0xFFFFFFFF")
    lbl(z, 88, 22, it.title, 24, "s", "0xFFFFFFFF", w - 104)
    s = lbl(z, 88, 54, it.subtxt, 18, "r", "0xFFFFFFD9", w - 104)
    s.wrap = true
    s.maxLines = 2
  else
    n.bg = rbox(z, 0, 0, w, 120, 24, p.glass)
    n.ed = edge(z, "thin24", 0, 0, w, 120, p.glassB)
    rbox(z, 20, 26, 96, 68, 12, p.lgbg)
    if toStr(it.logo) <> "" then
      lg = pic(z, 26, 32, 84, 56, "scaleToFit")
      lg.uri = it.logo
    else
      ini = lbl(z, 20, 26, initials(toStr(it.title)), 22, "b", p.muted, 96, 68)
      ini.horizAlign = "center"
      ini.vertAlign = "center"
    end if
    n.t = lbl(z, 132, 22, it.title, 24, "s", p.text, w - 152)
    n.m = lbl(z, 132, 54, it.meta, 19, "r", p.muted, w - 152)
    rect(z, 132, 88, w - 152, 5, p.bar)
    n.bar = rect(z, 132, 88, Int((w - 152) * num(it.pct)), 5, p.accent)
    n.barW = w - 152
  end if
  n.ring = edge(z, "ring29", -4, -4, w + 8, 128, p.ring)
  n.ring.opacity = 0
  return n
end function

function makePill(it as object, i as integer) as object
  p = thm()
  root = grp(m.track)
  z = grp(root)
  l = lbl(z, 24, 11, it.title, 22, "s", p.text)
  w = textW(l) + 48
  n = {root: root, z: z, w: w, h: 50, kind: "pill", sel: isTrue(it.sel), tmove: 0}
  n.bg = rbox(invalid, 0, 0, w, 50, 25, p.glass)
  z.insertChild(n.bg, 0)
  n.ed = edge(invalid, "thin25", 0, 0, w, 50, p.glassB)
  z.insertChild(n.ed, 1)
  n.t = l
  z.scaleRotateCenter = [w / 2, 25]
  n.ring = edge(z, "ring29", -4, -4, w + 8, 58, p.ring)
  n.ring.opacity = 0
  return n
end function

' pill button (detail page): optional icon, primary = accent
function makeBtn(it as object, i as integer) as object
  p = thm()
  root = grp(m.track)
  z = grp(root)
  pr = isTrue(it.primary)
  padX = 30
  if pr then padX = 40
  x = padX
  ic = invalid
  if toStr(it.icon) <> "" then
    ic = icon(z, it.icon, padX, 20, 24, p.text)
    x = padX + 34
  end if
  l = lbl(z, x, 16, it.title, 25, "s", p.text)
  w = x + textW(l) + padX
  n = {root: root, z: z, w: w, h: 64, kind: "btn", primary: pr, tmove: 0, t: l, ic: ic}
  if pr then
    n.bg = rbox(invalid, 0, 0, w, 64, 32, p.accent)
    l.color = "0xFFFFFFFF"
    if ic <> invalid then ic.blendColor = "0xFFFFFFFF"
  else
    n.bg = rbox(invalid, 0, 0, w, 64, 32, p.glass)
    n.ed = edge(invalid, "thin32", 0, 0, w, 64, p.glassB)
    z.insertChild(n.ed, 0)
  end if
  z.insertChild(n.bg, 0)
  z.scaleRotateCenter = [w / 2, 32]
  n.ring = edge(z, "ring36", -4, -4, w + 8, 72, p.ring)
  n.ring.opacity = 0
  return n
end function

' ---------- images ----------
sub onImg(e as object)
  po = e.getRoSGNode()
  i = Val(Mid(po.id, 2))
  n = m.nodes[i]
  if n = invalid then return
  if e.getData() = "failed" then
    n.ai = n.ai + 1
    if n.ai < n.alts.count() then
      po.uri = n.alts[n.ai]
    else
      po.visible = false
    end if
  end if
end sub

sub onLogo(e as object)
  po = e.getRoSGNode()
  st = e.getData()
  if st = "failed" then
    po.visible = false
  else if st = "ready" then
    i = Val(Mid(po.id, 2))
    n = m.nodes[i]
    if n = invalid then return
    bw = po.bitmapWidth
    bh = po.bitmapHeight
    if bw > 0 and bh > 0 then
      mw = n.w * 0.4
      mh = n.h * 0.28
      s = mw / bw
      if mh / bh < s then s = mh / bh
      po.width = Int(bw * s)
      po.height = Int(bh * s)
    end if
  end if
end sub

' only load artwork that's on (or near) the screen
sub lazy()
  lo = m.scroll - 700
  hi = m.scroll + 1920 + 900
  for each n in m.nodes
    if n.kind = "card" and not n.loaded then
      if n.x + n.w > lo and n.x < hi then
        n.loaded = true
        if n.alts.count() > 0 then n.img.uri = n.alts[0] else n.img.visible = false
        if n.logoUri <> invalid then n.logo.uri = n.logoUri
      end if
    end if
  end for
end sub

' ---------- focus ----------
sub onFocusChg()
  h = m.top.hasFocus()
  if h <> m.has then
    m.has = h
    paint(true)
  end if
end sub

function blurRow(p as dynamic) as dynamic
  if m.has then
    m.has = false
    paint(true)
  end if
  return invalid
end function

function takeFocus(p as dynamic) as dynamic
  if m.nodes.count() = 0 then return false
  if p <> invalid then
    if p.index <> invalid then
      m.idx = p.index
      if m.idx >= m.nodes.count() then m.idx = m.nodes.count() - 1
      if m.idx < 0 then m.idx = 0
      ensureVisible(true)
    end if
  end if
  m.top.setFocus(true)
  m.has = true
  paint(true)
  m.top.focused = m.idx
  return true
end function

sub ensureVisible(anim as boolean)
  if m.nodes.count() = 0 then
    lazy()
    return
  end if
  n = m.nodes[m.idx]
  pad = m.top.padL
  if n.x + n.w - m.scroll > 1920 - pad then m.scroll = n.x + n.w - (1920 - pad)
  if n.x - m.scroll < pad then m.scroll = n.x - pad
  if m.scroll < 0 then m.scroll = 0
  if anim then
    tween(m.track, "translation", [-m.scroll, 0], 0.3)
  else
    m.track.translation = [-m.scroll, 0]
  end if
  lazy()
end sub

sub paint(anim as boolean)
  p = thm()
  d = 0.0
  if anim then d = 0.22
  for i = 0 to m.nodes.count() - 1
    n = m.nodes[i]
    f = m.has and i = m.idx
    zoom = m.top.zoom
    if n.kind = "live" then zoom = 1.07
    if n.kind = "pill" or n.kind = "btn" then zoom = 1.07
    if f then
      tween(n.z, "scale", [zoom, zoom], d)
      tween(n.ring, "opacity", 1.0, d)
    else
      tween(n.z, "scale", [1.0, 1.0], d)
      tween(n.ring, "opacity", 0.0, d)
    end if
    if n.kind = "live" and not n.go then
      if f then
        n.bg.blendColor = p.pill
        n.ed.visible = false
        n.t.color = p.pillText
        n.m.color = p.focusMuted
      else
        n.bg.blendColor = p.glass
        n.ed.visible = true
        n.t.color = p.text
        n.m.color = p.muted
      end if
    else if n.kind = "pill" then
      if n.sel or f then
        n.bg.blendColor = p.text
        n.t.color = p.bg1
        n.ed.visible = false
        if f then
          n.bg.blendColor = p.pill
          n.t.color = p.pillText
        end if
      else
        n.bg.blendColor = p.glass
        n.t.color = p.text
        n.ed.visible = true
      end if
    end if
  end for
  moveTitles(d)
end sub

' focused card's title + meta slide down a touch, like the web version
sub moveTitles(d as float)
  for i = 0 to m.nodes.count() - 1
    n = m.nodes[i]
    if n.tg <> invalid then
      if n.ty = invalid then n.ty = n.tg.translation[1]
      y = n.ty
      if m.has and i = m.idx then y = n.ty + n.tmove
      tween(n.tg, "translation", [0, y], d)
    end if
  end for
end sub

function setItem(p as dynamic) as dynamic
  n = m.nodes[p.i]
  if n = invalid then return invalid
  if p.meta <> invalid and n.m <> invalid then n.m.text = p.meta
  if p.pct <> invalid and n.bar <> invalid then n.bar.width = Int(n.barW * num(p.pct))
  if p.sel <> invalid and n.kind = "pill" then
    n.sel = isTrue(p.sel)
    paint(false)
  end if
  return invalid
end function

function onKeyEvent(key as string, press as boolean) as boolean
  if not press then return false
  if key = "left" then
    if m.idx > 0 then
      m.idx = m.idx - 1
      ensureVisible(true)
      paint(true)
      m.top.focused = m.idx
      return true
    end if
    return false
  else if key = "right" then
    if m.idx < m.nodes.count() - 1 then
      m.idx = m.idx + 1
      ensureVisible(true)
      paint(true)
      m.top.focused = m.idx
    end if
    return true
  else if key = "OK" then
    m.top.selected = m.idx
    return true
  else if key = "options" then
    m.top.optionsKey = m.idx
    return true
  end if
  return false
end function
