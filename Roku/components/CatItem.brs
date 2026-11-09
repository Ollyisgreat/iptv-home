' a category row: Search pill, ★ Favourites, Recently watched, All channels, then provider categories
sub init()
  m.built = false
end sub

sub build(dark as boolean, w as integer)
  if m.built and m.dark = dark and m.w = w then return
  m.top.removeChildrenIndex(m.top.getChildCount(), 0)
  m.dark = dark
  m.w = w
  if dark then m.pal = thmD() else m.pal = invalid
  p = thm()
  m.p = p
  m.sel = rbox(m.top, 0, 0, w, 60, 16, p.gpanel)
  m.bg = rbox(m.top, 0, 0, w, 60, 16, p.pill)
  m.ring = edge(m.top, "ring20", -4, -4, w + 8, 68, p.ring)
  m.ic = icon(m.top, "search", 20, 16, 28, p.text)
  m.l = lbl(m.top, 20, 14, "", 25, "r", p.text, w - 110)
  m.n = lbl(m.top, w - 120, 20, "", 19, "r", p.muted, 100)
  m.n.horizAlign = "right"
  m.isSel = false
  m.kind = ""
  m.built = true
end sub

sub onContent()
  c = m.top.itemContent
  if c = invalid then return
  root = c.getParent()
  dark = false
  w = 428
  if root <> invalid then
    dark = isTrue(root.dark)
    if root.w <> invalid then w = root.w
  end if
  build(dark, w)
  kind = toStr(c.Album)
  m.kind = kind
  m.l.text = toStr(c.title)
  m.n.text = toStr(c.ShortDescriptionLine1)
  m.ic.visible = false
  m.l.translation = [20, 14]
  if kind = "search" then
    m.ic.uri = "pkg:/images/i_search.png"
    m.ic.visible = true
    m.l.translation = [62, 14]
  else if kind = "fav" then
    m.ic.uri = "pkg:/images/i_star.png"
    m.ic.width = 24
    m.ic.height = 24
    m.ic.translation = [20, 18]
    m.ic.visible = true
    m.l.translation = [54, 14]
  end if
  m.isSel = (toStr(c.Rating) = "sel" or kind = "search")
  onFocus()
end sub

sub onFocus()
  if not m.built then return
  p = m.p
  f = 0.0
  if m.top.listHasFocus then f = m.top.focusPercent
  m.bg.opacity = f
  m.ring.opacity = f
  m.sel.visible = m.isSel
  if f > 0.5 then
    m.l.color = p.pillText
    m.n.color = p.focusMuted
    m.ic.blendColor = p.pillText
  else
    m.l.color = p.text
    m.n.color = p.muted
    m.ic.blendColor = p.text
    if m.kind = "fav" then m.ic.blendColor = "0xF5B70AFF"
  end if
  if m.isSel then m.l.font = fnt("s", 25) else m.l.font = fnt("r", 25)
end sub
