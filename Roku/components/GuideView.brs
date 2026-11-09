' IPTV Guide: categories → channels (what's on now) → info, schedule + live preview
sub init()
  p = thm()
  m.p = p
  m.v = vid()
  m.live = m.global.live
  ' everything is painted except the preview "hole", where the video shows through
  rect(m.top, 0, 0, 1920, 126, p.gbg)
  rect(m.top, 0, 477, 1920, 603, p.gbg)
  rect(m.top, 0, 126, 1236, 351, p.gbg)
  rect(m.top, 1860, 126, 60, 351, p.gbg)
  m.pv = grp(m.top, 1236, 126)
  rect(m.pv, 0, 0, 624, 351, "0x000000FF")
  edge(m.pv, "thin24", 0, 0, 624, 351, "0x7F7F7F59")
  t1 = lbl(m.pv, 30, 132, "Press OK on a channel to preview it here", 24, "r", "0x9A9AA1FF", 564)
  t1.horizAlign = "center"
  t2 = lbl(m.pv, 30, 172, "OK again for full screen · * for options", 19, "r", "0x9A9AA1FF", 564)
  t2.horizAlign = "center"
  m.pvMsg = lbl(m.top, 1236, 285, "", 22, "r", "0xFFFFFFFF", 624)
  m.pvMsg.horizAlign = "center"
  lbl(m.top, 60, 38, "IPTV Guide", 50, "s", p.text)
  m.clock = lbl(m.top, 1360, 52, "", 30, "r", p.muted, 500)
  m.clock.horizAlign = "right"
  ' categories
  m.cats = CreateObject("roSGNode", "MarkupList")
  m.cats.itemComponentName = "CatItem"
  m.cats.itemSize = [428, 60]
  m.cats.itemSpacing = [0, 4]
  m.cats.numRows = 14
  m.cats.drawFocusFeedback = false
  m.cats.vertFocusAnimationStyle = "floatingFocus"
  m.cats.translation = [66, 132]
  m.top.appendChild(m.cats)
  m.kb = CreateObject("roSGNode", "KeyPad")
  m.kb.hint = "Channels & categories"
  m.kb.translation = [60, 132]
  m.kb.visible = false
  m.top.appendChild(m.kb)
  ' channels
  m.hTitle = lbl(m.top, 544, 128, "", 30, "s", p.text, 460)
  m.hCount = lbl(m.top, 1000, 138, "", 20, "r", p.muted, 192)
  m.hCount.horizAlign = "right"
  m.chs = CreateObject("roSGNode", "MarkupList")
  m.chs.itemComponentName = "ChItem"
  m.chs.itemSize = [664, 94]
  m.chs.itemSpacing = [0, 4]
  m.chs.numRows = 9
  m.chs.drawFocusFeedback = false
  m.chs.vertFocusAnimationStyle = "floatingFocus"
  m.chs.translation = [536, 188]
  m.top.appendChild(m.chs)
  m.empty = lbl(m.top, 556, 260, "", 24, "r", p.muted, 624)
  m.empty.horizAlign = "center"
  m.empty.wrap = true
  ' info + schedule
  m.info = grp(m.top, 1244, 494)
  rbox(m.info, 0, 0, 84, 52, 12, p.lgbg)
  m.iIni = lbl(m.info, 0, 0, "", 19, "b", p.muted, 84, 52)
  m.iIni.horizAlign = "center"
  m.iIni.vertAlign = "center"
  m.iLogo = pic(m.info, 6, 5, 72, 42, "scaleToFit")
  m.iName = lbl(m.info, 100, -2, "", 26, "s", p.text, 508)
  m.iSub = lbl(m.info, 100, 32, "", 19, "r", p.muted, 508)
  m.iProg = lbl(m.info, 0, 68, "", 27, "s", p.text, 608)
  m.iTime = lbl(m.info, 0, 104, "", 20, "r", p.muted, 608)
  m.iDesc = lbl(m.info, 0, 134, "", 20, "r", p.muted, 608)
  m.iDesc.wrap = true
  m.iDesc.maxLines = 2
  m.sched = grp(m.info, 0, 206)
  m.info.visible = false
  m.cats.observeField("itemFocused", "onCatFocus")
  m.cats.observeField("itemSelected", "onCatPick")
  m.chs.observeField("itemFocused", "onChFocus")
  m.chs.observeField("itemSelected", "onChPick")
  m.kb.observeField("text", "onType")
  m.catT = mkTimer(0.25, "showFocusedCat")
  m.infoT = mkTimer(0.4, "loadSched")
  m.typeT = mkTimer(0.25, "runSearch")
  m.clockT = mkTimer(10, "tick", true)
  m.searching = false
  m.rows = []
  m.list = []
  m.catIds = []
  m.curCat = ""
  m.prevId = ""
  m.live.observeFieldScoped("state", "onLive")
  m.v.observeFieldScoped("state", "onVid")
end sub

function open(p as dynamic) as dynamic
  m.global.playingId = ""
  m.top.setFocus(true)
  m.clockT.control = "start"
  tick()
  m.live.callFunc("load", {})
  onLive()
  return invalid
end function

function onReturn(p as dynamic) as dynamic
  ' back from full screen: carry on previewing whatever was last watched
  id = toStr(m.global.playingId)
  if id <> "" then
    s = m.live.callFunc("byId", {id: id})
    if s <> invalid then preview(s)
  end if
  refreshCatCounts()
  if m.curCat = "@fav" or m.curCat = "@recent" then showCat(m.curCat, true)
  return invalid
end function

sub tick()
  m.clock.text = hm()
end sub

sub onLive()
  st = m.live.state
  if st = "ready" then
    buildCats()
  else if st = "loading" then
    m.empty.text = "Loading channels…"
  else if st = "off" then
    m.empty.text = "Add your IPTV login in Settings first."
  else if st = "error" then
    m.empty.text = m.live.err
  end if
end sub

function fmtNum(n as integer) as string
  s = n.ToStr()
  out = ""
  while Len(s) > 3
    out = "," + Right(s, 3) + out
    s = Left(s, Len(s) - 3)
  end while
  return s + out
end function

sub buildCats()
  m.catData = m.live.callFunc("cats", {})
  root = CreateObject("roSGNode", "ContentNode")
  m.catIds = ["@search", "@fav", "@recent", "@all"]
  total = 0
  for each c in m.catData
    total = total + c.count
  end for
  addCat(root, "Search", "search", "")
  addCat(root, "Favourites", "fav", cntStr(liveFavs()))
  addCat(root, "Recently watched", "", cntStr(liveRecents()))
  addCat(root, "All channels", "", fmtNum(total))
  for each c in m.catData
    addCat(root, c.n, "", fmtNum(c.count))
    m.catIds.push(c.id)
  end for
  m.cats.content = root
  ' start where it's most useful
  first = toStr(m.global.guideCat)
  idx = -1
  for i = 0 to m.catIds.count() - 1
    if m.catIds[i] = first then idx = i
  end for
  if idx < 1 then
    idx = 3
    if liveRecents().count() > 0 then idx = 2
    if liveFavs().count() > 0 then idx = 1
  end if
  m.cats.jumpToItem = idx
  showCat(m.catIds[idx], false)
  if m.top.hasFocus() then m.cats.setFocus(true)
end sub

function cntStr(a as object) as string
  n = a.count()
  return n.ToStr()
end function

sub addCat(root as object, t as string, kind as string, n as string)
  c = root.createChild("ContentNode")
  c.title = t
  c.Album = kind
  c.ShortDescriptionLine1 = n
end sub

sub refreshCatCounts()
  root = m.cats.content
  if root = invalid then return
  if root.getChildCount() < 4 then return
  root.getChild(1).ShortDescriptionLine1 = cntStr(liveFavs())
  root.getChild(2).ShortDescriptionLine1 = cntStr(liveRecents())
end sub

sub onCatFocus()
  restart(m.catT)
end sub

sub showFocusedCat()
  if m.searching then return
  i = m.cats.itemFocused
  if i < 1 or i >= m.catIds.count() then return
  if m.catIds[i] <> m.curCat then showCat(m.catIds[i], false)
end sub

sub showCat(id as string, keep as boolean)
  root = m.cats.content
  if root = invalid then return
  for i = 0 to m.catIds.count() - 1
    if m.catIds[i] = m.curCat or m.catIds[i] = id then
      if m.catIds[i] = id then root.getChild(i).Rating = "sel" else root.getChild(i).Rating = ""
    end if
  end for
  m.curCat = id
  m.global.guideCat = id
  list = m.live.callFunc("list", {cat: id})
  title = "All channels"
  if id = "@fav" then
    title = "Favourites"
  else if id = "@recent" then
    title = "Recently watched"
  else if id <> "@all" then
    title = m.live.callFunc("catName", {id: id})
  end if
  rows = []
  for each s in list
    rows.push({k: "ch", s: s})
  end for
  empty = "No channels here."
  if id = "@fav" then empty = "No favourites yet." + chr(10) + "Press * on a channel to add it."
  if id = "@recent" then empty = "Channels you watch will appear here."
  setRows(title, rows, empty, keep)
end sub

sub setRows(title as string, rows as object, emptyText as string, keep as boolean)
  m.hTitle.text = title
  n = 0
  for each r in rows
    if r.k = "ch" then n = n + 1
  end for
  m.hCount.text = fmtNum(n) + " channels"
  m.rows = rows
  m.list = []
  for each r in rows
    if r.k = "ch" then m.list.push(r.s)
  end for
  fi = 0
  if keep then fi = m.chs.itemFocused
  m.built = 0
  root = CreateObject("roSGNode", "ContentNode")
  root.addFields({owner: m.top})
  m.chs.content = root
  ' big lists are built a page at a time (keeps the box responsive)
  addRows(fi + 150)
  if fi > 0 and fi < rows.count() then m.chs.jumpToItem = fi
  if rows.count() = 0 then m.empty.text = emptyText else m.empty.text = ""
  if rows.count() > 0 then onChFocus() else m.info.visible = false
end sub

sub addRows(upto as integer)
  root = m.chs.content
  if upto > m.rows.count() then upto = m.rows.count()
  for i = m.built to upto - 1
    r = m.rows[i]
    c = root.createChild("ContentNode")
    if r.k = "cat" then
      c.title = r.n
      c.Album = "category"
      c.Description = fmtNum(r.count) + " channels"
    else
      s = r.s
      c.id = s.id
      c.title = s.n
      c.HDPosterUrl = s.i
      n1 = i + 1
      if s.num <> "" then c.ShortDescriptionLine1 = s.num else c.ShortDescriptionLine1 = n1.ToStr()
      if isTrue(s.a) then c.Rating = "a"
    end if
  end for
  if upto > m.built then m.built = upto
end sub

sub onCatPick()
  i = m.cats.itemSelected
  if i = 0 then
    enterSearch()
    return
  end if
  if m.catIds[i] <> m.curCat then showCat(m.catIds[i], false)
  if m.rows.count() > 0 then m.chs.setFocus(true)
end sub

' ---------- search: every letter narrows channels + categories ----------
sub enterSearch()
  m.searching = true
  m.cats.visible = false
  m.kb.visible = true
  m.kb.callFunc("takeFocus", {})
  runSearch()
end sub

sub exitSearch()
  m.searching = false
  m.kb.visible = false
  m.cats.visible = true
  m.cats.setFocus(true)
  c = m.curCat
  m.curCat = ""
  if c = "" then c = "@all"
  showCat(c, false)
end sub

sub onType()
  restart(m.typeT)
end sub

sub runSearch()
  if not m.searching then return
  q = m.kb.text.Trim()
  if q = "" then
    setRows("Search", [], "Start typing — results narrow with every letter.", false)
    m.hCount.text = ""
    return
  end if
  res = m.live.callFunc("search", {q: q})
  rows = []
  for each c in res.cats
    rows.push({k: "cat", id: c.id, n: c.n, count: c.count})
  end for
  for each s in res.chs
    rows.push({k: "ch", s: s})
  end for
  setRows("Results for " + Chr(34) + q + Chr(34), rows, "Nothing matches " + Chr(34) + q + Chr(34) + ".", false)
end sub

' ---------- channel info + schedule ----------
sub onChFocus()
  if m.chs.itemFocused > m.built - 30 and m.built < m.rows.count() then addRows(m.built + 150)
  r = m.rows[m.chs.itemFocused]
  if r = invalid then return
  if r.k <> "ch" then
    m.info.visible = false
    return
  end if
  s = r.s
  m.info.visible = true
  m.iLogo.uri = s.i
  m.iIni.text = ""
  if s.i = "" then m.iIni.text = initials(s.n)
  m.iName.text = s.n
  cn = m.live.callFunc("catName", {id: s.c})
  if s.num <> "" then m.iSub.text = joinDot(["Ch " + s.num, cn]) else m.iSub.text = cn
  m.iProg.text = ""
  m.iTime.text = ""
  m.iDesc.text = ""
  m.sched.removeChildrenIndex(m.sched.getChildCount(), 0)
  m.infoFor = s.id
  restart(m.infoT)
end sub

sub loadSched()
  if toStr(m.infoFor) = "" then return
  api("sched", xBase() + "&action=get_short_epg&stream_id=" + m.infoFor + "&limit=8")
end sub

sub onApi(e as object)
  r = e.getData()
  if Left(toStr(r.kind), 2) = "q:" then
    epgDone(r)
    return
  end if
  if not apiFresh(e) then return
  if r.kind <> "sched" then return
  p = m.p
  l = epgList(r.data)
  m.sched.removeChildrenIndex(m.sched.getChildCount(), 0)
  if l.count() = 0 then
    m.iProg.text = "No programme information"
    return
  end if
  now = l[0]
  m.iProg.text = now.t
  minsLeft = Int((now.e - nowSec()) / 60)
  tt = hm(now.s) + " – " + hm(now.e)
  if minsLeft > 0 then tt = tt + " · " + minsLeft.ToStr() + "m left"
  m.iTime.text = tt
  m.iDesc.text = now.d
  y = 0
  for i = 0 to l.count() - 1
    if y > 300 then exit for
    pr = l[i]
    if i = 0 then rbox(m.sched, 0, y, 610, 50, 14, p.gpanel)
    lbl(m.sched, 16, y + 13, hm(pr.s), 20, "r", p.muted, 170)
    lbl(m.sched, 200, y + 11, pr.t, 22, "r", p.text, 330)
    if i = 0 then
      rbox(m.sched, 540, y + 12, 56, 26, 8, "0xFF3B30FF")
      lv = lbl(m.sched, 540, y + 12, "LIVE", 16, "b", "0xFFFFFFFF", 56, 26)
      lv.horizAlign = "center"
      lv.vertAlign = "center"
    end if
    y = y + 53
  end for
end sub

' ---------- preview + full screen ----------
sub onChPick()
  r = m.rows[m.chs.itemSelected]
  if r = invalid then return
  if r.k = "cat" then
    m.searching = false
    m.kb.visible = false
    m.cats.visible = true
    for i = 0 to m.catIds.count() - 1
      if m.catIds[i] = r.id then m.cats.jumpToItem = i
    end for
    showCat(r.id, false)
    m.chs.setFocus(true)
    return
  end if
  if r.s.id = m.prevId and m.v.visible then
    full(r.s)
  else
    preview(r.s)
  end if
end sub

sub preview(s as object)
  c = m.global.cfg
  m.prevId = s.id
  m.global.playingId = s.id
  cn = CreateObject("roSGNode", "ContentNode")
  cn.url = xLiveUrl(s.id)
  if c.ipFmt = "ts" then cn.streamFormat = "ts" else cn.streamFormat = "hls"
  cn.live = true
  cn.title = s.n
  showVid(1236, 126, 624, 351)
  m.v.content = cn
  m.v.control = "play"
  m.pv.visible = false
  m.pvMsg.text = "Loading…"
  m.pvMsg.visible = true
  addRecent(s)
  refreshCatCounts()
end sub

sub onVid()
  if m.prevId = "" then return
  st = m.v.state
  if st = "playing" then
    m.pvMsg.visible = false
  else if st = "error" then
    m.pvMsg.text = "This channel isn't working right now"
    m.pvMsg.visible = true
  else if st = "buffering" then
    m.pvMsg.text = "Loading…"
    m.pvMsg.visible = true
  end if
end sub

sub full(s as object)
  idx = 0
  for i = 0 to m.list.count() - 1
    if m.list[i].id = s.id then idx = i
  end for
  m.pvMsg.visible = false
  scene().callFunc("push", {view: "LivePlayer", list: m.list, index: idx, ctx: m.hTitle.text, fromGuide: true})
end sub

sub stopPreview()
  m.prevId = ""
  m.v.control = "stop"
  hideVid()
  m.global.playingId = ""
end sub

sub close()
  stopPreview()
  m.live.unobserveFieldScoped("state")
  m.v.unobserveFieldScoped("state")
  scene().callFunc("pop", {})
end sub

' ---------- options (*) ----------
sub chMenu()
  r = m.rows[m.chs.itemFocused]
  if r = invalid then return
  if r.k <> "ch" then return
  s = r.s
  m.menuCh = s
  items = [{label: "Watch full screen"}]
  if isFav(s.id) then items.push({label: "Remove from favourites"}) else items.push({label: "Add to favourites"})
  items.push({label: "Other streams for this channel", subtxt: "Same channel from other categories"})
  if m.curCat = "@recent" then items.push({label: "Remove from recently watched"})
  items.push({label: "Refresh channel list", subtxt: "Reload everything from your provider"})
  m.menuItems = items
  mn = scene().callFunc("push", {view: "SideMenu", title: s.n, items: items})
  mn.observeField("chosen", "onMenu")
end sub

sub onMenu(e as object)
  i = e.getData()
  if i < 0 then return
  l = m.menuItems[i].label
  s = m.menuCh
  if l = "Watch full screen" then
    full(s)
  else if l = "Other streams for this channel" then
    alts = m.live.callFunc("alts", {id: s.id, n: s.n})
    rows = [{k: "ch", s: s}]
    for each a in alts
      rows.push({k: "ch", s: a})
    end for
    setRows("Other streams: " + s.n, rows, "", false)
    if alts.count() = 0 then notify("No other streams found for this channel")
  else if l = "Remove from recently watched" then
    removeRecent(s.id)
    refreshCatCounts()
    showCat("@recent", true)
  else if l = "Refresh channel list" then
    m.live.callFunc("load", {force: true})
    notify("Refreshing channels…")
  else
    toggleFav(s)
    refreshCatCounts()
    if m.curCat = "@fav" then showCat("@fav", true)
  end if
end sub

function onKeyEvent(key as string, press as boolean) as boolean
  if not press then return true
  if key = "back" then
    if m.chs.hasFocus() then
      if m.searching then m.kb.callFunc("takeFocus", {}) else m.cats.setFocus(true)
    else if m.searching then
      exitSearch()
    else
      close()
    end if
    return true
  else if key = "right" then
    if (m.cats.hasFocus() or m.kb.isInFocusChain()) and m.rows.count() > 0 then m.chs.setFocus(true)
  else if key = "left" then
    if m.chs.hasFocus() then
      if m.searching then m.kb.callFunc("takeFocus", {}) else m.cats.setFocus(true)
    end if
  else if key = "options" then
    if m.chs.hasFocus() then chMenu()
  else if key = "play" then
    if m.chs.hasFocus() then
      r = m.rows[m.chs.itemFocused]
      if r <> invalid then
        if r.k = "ch" then full(r.s)
      end if
    end if
  end if
  return true
end function
