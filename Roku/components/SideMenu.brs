' right-hand options panel (same as the web version's menus)
sub init()
  m.pal = thmD()
  p = m.pal
  sh = pic(m.top, 0, 0, 1920, 1080, "scaleToFill")
  sh.uri = "pkg:/images/grad_right.png"
  m.panel = grp(m.top, 1320, 0)
  rect(m.panel, 0, 0, 600, 1080, "0x121318F7")
  gl = pic(m.panel, -60, 0, 60, 1080, "scaleToFill")
  gl.uri = "pkg:/images/grad_left.png"
  m.title = lbl(m.panel, 48, 50, "", 36, "b", p.text, 520)
  m.clip = CreateObject("roSGNode", "Group")
  m.clip.clippingRect = [0, 120, 600, 930]
  m.panel.appendChild(m.clip)
  m.list = grp(m.clip, 0, 0)
  m.rows = []
  m.idx = 0
  m.scroll = 0
end sub

function onReturn(p as dynamic) as dynamic
  return invalid
end function

function open(p as object) as dynamic
  pal = m.pal
  m.title.text = toStr(p.title)
  m.items = p.items
  y = 128
  for i = 0 to m.items.count() - 1
    it = m.items[i]
    r = {y: y, header: isTrue(it.header)}
    if r.header then
      y = y + 22
      lbl(m.list, 56, y, UCase(toStr(it.label)), 18, "b", pal.muted, 500)
      y = y + 34
      r.h = 0
    else
      sub2 = toStr(it.subtxt)
      h = 66
      if sub2 <> "" then h = 92
      g = grp(m.list, 34, y)
      r.bg = rbox(g, 0, 0, 532, h, 16, pal.pill)
      r.bg.visible = false
      lx = 22
      if isTrue(it.sel) then
        r.ck = icon(g, "check", 22, Int((h - 24) / 2), 24, pal.ok)
        lx = 58
      end if
      if isTrue(it.cur) then
        r.ck = icon(g, "dot", 22, Int((h - 14) / 2), 14, pal.ok)
        lx = 46
      end if
      r.l = lbl(g, lx, 18, toStr(it.label), 25, "r", pal.text, 510 - lx)
      if sub2 <> "" then r.s = lbl(g, lx, 50, sub2, 19, "r", pal.muted, 510 - lx)
      r.g = g
      r.h = h
      y = y + h + 4
    end if
    m.rows.push(r)
  end for
  m.idx = -1
  move(1)
  m.top.setFocus(true)
  return invalid
end function

sub move(d as integer)
  i = m.idx
  n = m.rows.count()
  while true
    i = i + d
    if i < 0 or i >= n then return
    if not m.rows[i].header then exit while
  end while
  if m.idx >= 0 then paint(m.idx, false)
  m.idx = i
  paint(i, true)
  r = m.rows[i]
  top = r.y - m.scroll
  if top + r.h > 1040 then m.scroll = r.y + r.h - 1040
  if top < 130 then m.scroll = r.y - 130
  if i <= 1 then m.scroll = 0
  if m.scroll < 0 then m.scroll = 0
  tween(m.list, "translation", [0, -m.scroll], 0.18)
end sub

sub paint(i as integer, f as boolean)
  r = m.rows[i]
  if r.header then return
  r.bg.visible = f
  if f then r.l.color = m.pal.pillText else r.l.color = m.pal.text
  if r.s <> invalid then
    if f then r.s.color = m.pal.focusMuted else r.s.color = m.pal.muted
  end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
  if not press then return true
  if key = "up" then
    move(-1)
  else if key = "down" then
    move(1)
  else if key = "OK" then
    i = m.idx
    scene().callFunc("pop", {})
    m.top.chosen = i
  else if key = "back" or key = "left" then
    scene().callFunc("pop", {})
    m.top.chosen = -1
  end if
  return true
end function
