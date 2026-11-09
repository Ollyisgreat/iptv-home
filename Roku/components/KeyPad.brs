sub init()
  m.keys = []
  m.idx = 0
  m.built = false
  m.top.observeField("focusedChild", "onFocusChg")
  build()
end sub

sub build()
  setup({})
end sub

function setup(p as dynamic) as dynamic
  if m.top.dark then m.pal = thmD()
  pal = thm()
  m.p = pal
  m.top.removeChildrenIndex(m.top.getChildCount(), 0)
  W = m.top.width
  m.inBg = rbox(m.top, 0, 0, W, 64, 16, pal.input)
  m.inEd = edge(m.top, "thin16", 0, 0, W, 64, pal.accent)
  m.inEd.visible = false
  icon(m.top, "search", 18, 18, 28, pal.muted)
  m.q = lbl(m.top, 60, 15, "", 27, "r", pal.text, W - 80)
  m.cur = rect(m.top, 60, 16, 3, 32, pal.accent)
  letters = "abcdefghijklmnopqrstuvwxyz1234567890".Split("")
  kw = Int((W - 8 * 5 - 8) / 6)
  m.keys = []
  y = 80
  for i = 0 to letters.count() - 1
    c = i mod 6
    r = Int(i / 6)
    m.keys.push(mkKey(4 + c * (kw + 8), y + r * 66, kw, letters[i], UCase(letters[i]), 25, c, r, 1))
  end for
  r = 6
  wide = kw * 2 + 8
  m.keys.push(mkKey(4, y + r * 66, wide, " ", "space", 20, 0, r, 2))
  m.keys.push(mkKey(4 + 2 * (kw + 8), y + r * 66, wide, "del", "delete", 20, 2, r, 2))
  m.keys.push(mkKey(4 + 4 * (kw + 8), y + r * 66, wide, "clr", "clear", 20, 4, r, 2))
  m.built = true
  draw()
  return invalid
end function

function mkKey(x as integer, y as integer, w as integer, k as string, t as string, size as integer, col as integer, row as integer, span as integer) as object
  p = m.p
  g = grp(m.top, x, y)
  b = rbox(g, 0, 0, w, 58, 12, p.gpanel)
  l = lbl(g, 0, 0, t, size, "s", p.text, w, 58)
  l.horizAlign = "center"
  l.vertAlign = "center"
  g.scaleRotateCenter = [w / 2, 29]
  r = edge(g, "ring14", -3, -3, w + 6, 64, p.ring)
  r.opacity = 0
  return {g: g, b: b, l: l, r: r, k: k, col: col, row: row, span: span}
end function

function takeFocus(p as dynamic) as dynamic
  m.top.setFocus(true)
  draw()
  return true
end function

function wipe(p as dynamic) as dynamic
  m.top.text = ""
  draw()
  return invalid
end function

sub onHint()
  if m.built then draw()
end sub

sub onFocusChg()
  if m.built then draw()
end sub

sub draw()
  p = m.p
  has = m.top.hasFocus()
  t = m.top.text
  if t = "" then
    m.q.text = m.top.hint
    m.q.color = p.muted
    m.cur.visible = false
  else
    m.q.text = t
    m.q.color = p.text
    m.cur.visible = has
    m.cur.translation = [60 + textW(m.q) + 2, 16]
  end if
  m.inEd.visible = has
  for i = 0 to m.keys.count() - 1
    k = m.keys[i]
    f = has and i = m.idx
    if f then
      k.b.blendColor = p.pill
      k.l.color = p.pillText
      k.r.opacity = 1
      tween(k.g, "scale", [1.1, 1.1], 0.12)
    else
      k.b.blendColor = p.gpanel
      k.l.color = p.text
      k.r.opacity = 0
      tween(k.g, "scale", [1.0, 1.0], 0.12)
    end if
  end for
end sub

function find(col as integer, row as integer) as integer
  best = -1
  for i = 0 to m.keys.count() - 1
    k = m.keys[i]
    if k.row = row and col >= k.col and col < k.col + k.span then return i
  end for
  return best
end function

function onKeyEvent(key as string, press as boolean) as boolean
  if not press then return false
  k = m.keys[m.idx]
  if key = "OK" then
    t = m.top.text
    if k.k = "del" then
      if Len(t) > 0 then t = Left(t, Len(t) - 1)
    else if k.k = "clr" then
      t = ""
    else
      t = t + k.k
    end if
    m.top.text = t
    draw()
    return true
  else if key = "replay" then
    t = m.top.text
    if Len(t) > 0 then m.top.text = Left(t, Len(t) - 1)
    draw()
    return true
  else if key = "left" then
    if k.col = 0 then return false
    m.idx = find(k.col - 1, k.row)
  else if key = "right" then
    nc = k.col + k.span
    if nc > 5 then return false
    m.idx = find(nc, k.row)
  else if key = "up" then
    if k.row = 0 then return false
    m.idx = find(k.col, k.row - 1)
  else if key = "down" then
    if k.row = 6 then return true
    m.idx = find(k.col, k.row + 1)
  else
    return false
  end if
  if m.idx < 0 then m.idx = 0
  draw()
  return true
end function
