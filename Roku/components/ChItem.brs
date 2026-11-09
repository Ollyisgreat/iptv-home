' one channel row: number · logo · name · what's on now + progress
sub init()
  m.built = false
  m.global.observeFieldScoped("playingId", "onPlaying")
end sub

sub build(dark as boolean)
  if m.built and m.dark = dark then return
  m.top.removeChildrenIndex(m.top.getChildCount(), 0)
  m.epgT = mkTimer(0.35, "fetchEpg")
  m.dark = dark
  if dark then m.pal = thmD() else m.pal = invalid
  p = thm()
  m.p = p
  m.bg = rbox(m.top, 0, 0, 664, 94, 18, p.pill)
  m.ring = edge(m.top, "ring22", -4, -4, 672, 102, p.ring)
  m.num = lbl(m.top, 18, 32, "", 21, "r", p.muted, 58)
  m.num.horizAlign = "right"
  m.lgb = rbox(m.top, 92, 16, 104, 62, 12, p.lgbg)
  m.logo = pic(m.top, 99, 22, 90, 50, "scaleToFit")
  m.logo.observeField("loadStatus", "onLogo")
  m.ini = lbl(m.top, 92, 16, "", 22, "b", p.muted, 104, 62)
  m.ini.horizAlign = "center"
  m.ini.vertAlign = "center"
  m.play = icon(m.top, "play", 212, 14, 22, p.accent)
  m.name = lbl(m.top, 212, 10, "", 25, "s", p.text, 400)
  m.now = lbl(m.top, 212, 44, "", 20, "r", p.muted, 400)
  m.barBg = rect(m.top, 212, 76, 280, 5, p.bar)
  m.bar = rect(m.top, 212, 76, 0, 5, p.accent)
  m.arc = icon(m.top, "catchup", 616, 34, 26, p.muted)
  m.built = true
  onFocus()
end sub

sub onContent()
  c = m.top.itemContent
  if c = invalid then return
  dark = false
  root = c.getParent()
  if root <> invalid then dark = isTrue(root.dark)
  build(dark)
  if m.watch <> invalid then m.watch.unobserveFieldScoped("Description")
  m.watch = c
  c.observeFieldScoped("Description", "onDesc")
  isCat = toStr(c.Album) = "category"
  m.num.text = toStr(c.ShortDescriptionLine1)
  nm = toStr(c.title)
  m.ini.text = initials(nm)
  m.ini.visible = true
  m.logo.visible = false
  m.logo.uri = ""
  if toStr(c.HDPosterUrl) <> "" then m.logo.uri = c.HDPosterUrl
  m.arc.visible = (toStr(c.Rating) = "a")
  if isCat then
    m.name.text = nm
    m.now.text = toStr(c.Description)
    m.barBg.visible = false
    m.bar.visible = false
    m.play.visible = false
    m.name.translation = [212, 10]
    return
  end if
  showPlaying()
  showEpg()
  if c.Description = "" then restart(m.epgT)
end sub

sub showPlaying()
  c = m.top.itemContent
  pl = (toStr(c.id) <> "" and toStr(c.id) = toStr(m.global.playingId))
  m.play.visible = pl
  if pl then m.name.translation = [244, 10] else m.name.translation = [212, 10]
  m.name.text = toStr(c.title)
end sub

sub onPlaying()
  if m.top.itemContent <> invalid and m.built then showPlaying()
end sub

' Description = now-showing title, ReleaseDate = "start|end"
sub showEpg()
  c = m.top.itemContent
  t = toStr(c.Description)
  m.now.text = t
  se = toStr(c.ReleaseDate).Split("|")
  has = (se.count() = 2 and t <> "" and t <> " ")
  m.barBg.visible = has
  m.bar.visible = has
  if has then
    s = se[0].ToInt()
    e = se[1].ToInt()
    f = 0.0
    if e > s then f = (nowSec() - s) / (e - s)
    if f < 0 then f = 0
    if f > 1 then f = 1
    m.bar.width = Int(280 * f)
  end if
end sub

sub fetchEpg()
  c = m.top.itemContent
  if c = invalid then return
  if c.Description <> "" then return
  root = c.getParent()
  if root = invalid then return
  o = root.owner
  if o <> invalid then o.callFunc("askEpg", c)
end sub

sub onDesc()
  if m.built then showEpg()
end sub

sub onLogo()
  st = m.logo.loadStatus
  if st = "ready" then
    m.logo.visible = true
    m.ini.visible = false
  else if st = "failed" then
    m.logo.visible = false
    m.ini.visible = true
  end if
end sub

sub onFocus()
  if not m.built then return
  p = m.p
  f = 0.0
  if m.top.listHasFocus then f = m.top.focusPercent
  m.bg.opacity = f
  m.ring.opacity = f
  if f > 0.5 then
    m.name.color = p.pillText
    m.now.color = p.focusMuted
    m.num.color = p.focusMuted
  else
    m.name.color = p.text
    m.now.color = p.muted
    m.num.color = p.muted
  end if
end sub
