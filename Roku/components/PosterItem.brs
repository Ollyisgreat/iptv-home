sub init()
  p = thm()
  m.cell = grp(m.top, 14, 14)
  m.z = grp(m.cell)
  m.z.scaleRotateCenter = [107, 160]
  m.ph = rbox(m.z, 0, 0, 214, 321, 18, p.card)
  m.phl = lbl(m.z, 18, 18, "", 24, "s", "0xFFFFFFFF", 178, 285)
  m.phl.wrap = true
  m.phl.maxLines = 4
  m.phl.vertAlign = "bottom"
  m.img = mpic(m.z, 0, 0, 214, 321)
  m.img.observeField("loadStatus", "onImg")
  m.chk = rbox(m.z, 162, 14, 38, 38, 18, "0x00000099")
  m.chkI = icon(m.z, "check", 170, 22, 22, "0xFFFFFFFF")
  m.barBg = rect(m.z, 14, 303, 186, 6, "0xFFFFFF59")
  m.bar = rect(m.z, 14, 303, 0, 6, "0xFFFFFFFF")
  m.ring = edge(m.z, "ring23", -5, -5, 224, 331, p.ring)
  m.ring.opacity = 0
  m.tg = grp(m.cell, 0, 335)
  m.t = lbl(m.tg, 0, 0, "", 21, "s", p.text, 214)
  m.m = lbl(m.tg, 0, 29, "", 18, "r", p.muted, 214)
end sub

sub onContent()
  c = m.top.itemContent
  if c = invalid then return
  t = toStr(c.title)
  m.t.text = t
  m.m.text = toStr(c.ShortDescriptionLine2)
  m.phl.text = t
  m.ph.blendColor = hueColor(t)
  m.img.visible = true
  m.img.uri = c.HDPosterUrl
  pl = isTrue(c.played)
  m.chk.visible = pl
  m.chkI.visible = pl
  pct = num(c.pct)
  sh = pct > 1 and pct < 98
  m.barBg.visible = sh
  m.bar.visible = sh
  if sh then m.bar.width = Int(186 * pct / 100)
end sub

sub onImg()
  if m.img.loadStatus = "failed" then m.img.visible = false
end sub

sub onFocus()
  f = 0.0
  if m.top.gridHasFocus then f = m.top.focusPercent
  s = 1 + 0.07 * f
  m.z.scale = [s, s]
  m.ring.opacity = f
  m.tg.translation = [0, 335 + 8 * f]
end sub
