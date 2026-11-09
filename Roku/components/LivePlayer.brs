' full-screen live TV: ▲▼ zap · OK / ◀ channel list · ▶ options
sub init()
  m.pal = thmD()
  p = m.pal
  m.v = vid()
  m.live = m.global.live
  ' bottom info bar
  m.osd = grp(m.top)
  m.osd.opacity = 0
  g = pic(m.osd, 0, 600, 1920, 480, "scaleToFill")
  g.uri = "pkg:/images/grad_up.png"
  rbox(m.osd, 90, 900, 200, 120, 20, "0xFFFFFF1A")
  m.oLogo = pic(m.osd, 104, 912, 172, 96, "scaleToFit")
  m.oIni = lbl(m.osd, 90, 900, "", 38, "b", p.muted, 200, 120)
  m.oIni.horizAlign = "center"
  m.oIni.vertAlign = "center"
  m.oLogo.observeField("loadStatus", "onLogo")
  m.oNum = lbl(m.osd, 328, 774, "", 30, "r", "0xA1A1A8FF")
  m.oName = lbl(m.osd, 328, 766, "", 40, "b", p.text, 1100)
  m.oNow = lbl(m.osd, 328, 826, "", 31, "s", p.text, 1200)
  m.oT1 = lbl(m.osd, 328, 880, "", 21, "r", "0xC7C7CCFF")
  m.oBarBg = rect(m.osd, 0, 890, 760, 7, "0xFFFFFF40")
  m.oBar = rect(m.osd, 0, 890, 0, 7, "0xFFFFFFFF")
  m.oT2 = lbl(m.osd, 0, 880, "", 21, "r", "0xC7C7CCFF")
  m.oDesc = lbl(m.osd, 328, 920, "", 22, "r", "0xC7C7CCFF", 1150)
  m.oDesc.wrap = true
  m.oDesc.maxLines = 2
  m.oNext = lbl(m.osd, 328, 990, "", 22, "r", "0xA1A1A8FF", 1150)
  m.oClock = lbl(m.osd, 1330, 766, "", 40, "s", p.text, 500)
  m.oClock.horizAlign = "right"
  h1 = lbl(m.osd, 1230, 960, "Up / Down  change channel", 19, "r", "0xA1A1A8FF", 600)
  h1.horizAlign = "right"
  h2 = lbl(m.osd, 1230, 990, "OK / Left  channel list  ·  Right  options", 19, "r", "0xA1A1A8FF", 600)
  h2.horizAlign = "right"
  m.bigNum = lbl(m.top, 1130, 70, "", 90, "b", p.text, 700)
  m.bigNum.horizAlign = "right"
  m.bigNum.visible = false
  m.msg = lbl(m.top, 260, 480, "", 28, "r", p.text, 1400)
  m.msg.horizAlign = "center"
  m.msg.wrap = true
  ' channel list on the left (+ categories column with another ◀)
  m.side = grp(m.top)
  m.side.visible = false
  m.sideBg = rect(m.side, 0, 0, 760, 1080, "0x0A0B0FFC")
  m.sideSh = pic(m.side, 760, 0, 90, 1080, "scaleToFill")
  m.sideSh.uri = "pkg:/images/grad_left.png"
  m.catCol = grp(m.side, 0, 0)
  m.catCol.visible = false
  lbl(m.catCol, 50, 50, "Categories", 30, "s", p.text)
  m.cats = CreateObject("roSGNode", "MarkupList")
  m.cats.itemComponentName = "CatItem"
  m.cats.itemSize = [360, 60]
  m.cats.itemSpacing = [0, 4]
  m.cats.numRows = 14
  m.cats.drawFocusFeedback = false
  m.cats.vertFocusAnimationStyle = "floatingFocus"
  m.cats.translation = [44, 112]
  m.catCol.appendChild(m.cats)
  m.chCol = grp(m.side, 0, 0)
  m.sTitle = lbl(m.chCol, 48, 50, "", 30, "s", p.text, 460)
  m.sCount = lbl(m.chCol, 520, 60, "", 20, "r", "0xA1A1A8FF", 180)
  m.sCount.horizAlign = "right"
  m.chs = CreateObject("roSGNode", "MarkupList")
  m.chs.itemComponentName = "ChItem"
  m.chs.itemSize = [664, 94]
  m.chs.itemSpacing = [0, 4]
  m.chs.numRows = 9
  m.chs.drawFocusFeedback = false
  m.chs.vertFocusAnimationStyle = "floatingFocus"
  m.chs.translation = [34, 112]
  m.chCol.appendChild(m.chs)
  m.chs.observeField("itemSelected", "onListPick")
  m.chs.observeField("itemFocused", "onSideFocus")
  m.cats.observeField("itemSelected", "onCatPick")
  m.osdT = mkTimer(5, "hideOsd")
  m.numT = mkTimer(2, "hideNum")
  m.retryT = mkTimer(2, "retune")
  m.clockT = mkTimer(10, "tick", true)
  m.v.observeFieldScoped("state", "onState")
  m.retries = 0
  m.sideCats = false
end sub

function onReturn(p as dynamic) as dynamic
  m.top.setFocus(true)
  return invalid
end function

function open(p as object) as dynamic
  m.chans = p.list
  m.idx = Int(num(p.index))
  m.ctx = toStr(p.ctx)
  if m.ctx = "" then m.ctx = "Channels"
  m.top.setFocus(true)
  m.clockT.control = "start"
  tune()
  return invalid
end function

sub tick()
  m.oClock.text = hm()
end sub

sub tune()
  if m.chans.count() = 0 then return
  s = m.chans[m.idx]
  m.cur = s
  m.retries = 0
  play(s)
  showOsd()
  m.bigNum.text = s.num
  m.bigNum.visible = (s.num <> "")
  restart(m.numT)
  addRecent(s)
  m.global.playingId = s.id
end sub

sub play(s as object)
  c = m.global.cfg
  cn = CreateObject("roSGNode", "ContentNode")
  cn.url = xLiveUrl(s.id)
  if c.ipFmt = "ts" then cn.streamFormat = "ts" else cn.streamFormat = "hls"
  cn.live = true
  cn.title = s.n
  showVid(0, 0, 1920, 1080)
  m.v.content = cn
  m.v.control = "play"
  m.msg.visible = false
end sub

sub retune()
  if m.cur <> invalid then play(m.cur)
end sub

sub onState()
  st = m.v.state
  if st = "playing" then
    m.msg.visible = false
    m.retries = 0
  else if st = "error" or st = "finished" then
    if m.retries < 3 then
      m.retries = m.retries + 1
      m.msg.text = "Reconnecting…"
      m.msg.visible = true
      restart(m.retryT)
    else
      m.msg.text = "This channel isn't working right now." + chr(10) + "Up / Down to try another, or Right for other streams."
      m.msg.visible = true
    end if
  end if
end sub

' ---------- info bar ----------
sub showOsd()
  s = m.cur
  if s = invalid then return
  tick()
  m.oNum.text = s.num
  nx = 328
  if s.num <> "" then nx = 328 + textW(m.oNum) + 18
  m.oName.translation = [nx, 766]
  m.oName.text = s.n
  m.oIni.text = initials(s.n)
  m.oIni.visible = true
  m.oLogo.visible = false
  m.oLogo.uri = s.i
  m.oNow.text = ""
  m.oT1.text = ""
  m.oT2.text = ""
  m.oBarBg.visible = false
  m.oBar.visible = false
  m.oDesc.text = ""
  m.oNext.text = ""
  api("epg", xBase() + "&action=get_short_epg&stream_id=" + s.id + "&limit=2")
  tween(m.osd, "opacity", 1.0, 0.25)
  restart(m.osdT)
end sub

sub hideOsd()
  tween(m.osd, "opacity", 0.0, 0.25)
end sub

sub hideNum()
  m.bigNum.visible = false
end sub

sub onLogo()
  if m.oLogo.loadStatus = "ready" then
    m.oLogo.visible = true
    m.oIni.visible = false
  end if
end sub

sub onApi(e as object)
  r = e.getData()
  if Left(toStr(r.kind), 2) = "q:" then
    epgDone(r)
    return
  end if
  if not apiFresh(e) then return
  if r.kind <> "epg" then return
  l = epgList(r.data)
  if l.count() = 0 then
    m.oNow.text = "No programme information"
    return
  end if
  pr = l[0]
  m.oNow.text = pr.t
  m.oT1.text = hm(pr.s)
  x = 328 + textW(m.oT1) + 18
  m.oBarBg.translation = [x, 890]
  m.oBar.translation = [x, 890]
  m.oBar.width = Int(760 * epgPct(pr))
  m.oBarBg.visible = true
  m.oBar.visible = true
  m.oT2.text = hm(pr.e)
  m.oT2.translation = [x + 778, 880]
  m.oDesc.text = pr.d
  if l.count() > 1 then m.oNext.text = "Next  " + hm(l[1].s) + "  " + l[1].t
end sub

' ---------- side list ----------
sub showSide()
  m.side.visible = true
  m.sideCats = false
  m.catCol.visible = false
  m.chCol.translation = [0, 0]
  m.sideBg.width = 760
  m.sideSh.translation = [760, 0]
  m.sTitle.text = m.ctx
  nn = m.chans.count()
  m.sCount.text = nn.ToStr()
  m.side.visible = true
  fillList(m.chans)
  m.chs.jumpToItem = m.idx
  m.chs.setFocus(true)
  hideOsd()
end sub

sub fillList(list as object)
  root = CreateObject("roSGNode", "ContentNode")
  root.addFields({dark: true, owner: m.top})
  m.sideList = list
  m.sideBuilt = 0
  m.chs.content = root
  upto = 150
  if m.side.visible and list.count() > 0 then upto = m.idx + 100
  addSide(upto)
end sub

sub addSide(upto as integer)
  root = m.chs.content
  list = m.sideList
  if upto > list.count() then upto = list.count()
  for i = m.sideBuilt to upto - 1
    s = list[i]
    c = root.createChild("ContentNode")
    c.id = s.id
    c.title = s.n
    c.HDPosterUrl = s.i
    n1 = i + 1
    if s.num <> "" then c.ShortDescriptionLine1 = s.num else c.ShortDescriptionLine1 = n1.ToStr()
  end for
  if upto > m.sideBuilt then m.sideBuilt = upto
end sub

sub onSideFocus()
  if m.sideList = invalid then return
  if m.chs.itemFocused > m.sideBuilt - 30 and m.sideBuilt < m.sideList.count() then addSide(m.sideBuilt + 150)
end sub

sub showCats()
  m.sideCats = true
  m.catCol.visible = true
  m.chCol.translation = [420, 0]
  m.sideBg.width = 1180
  m.sideSh.translation = [1180, 0]
  data = m.live.callFunc("cats", {})
  m.catIds = ["@fav", "@recent", "@all"]
  root = CreateObject("roSGNode", "ContentNode")
  root.addFields({dark: true, w: 360})
  addCat(root, "Favourites", "fav")
  addCat(root, "Recently watched", "")
  addCat(root, "All channels", "")
  for each c in data
    addCat(root, c.n, "")
    m.catIds.push(c.id)
  end for
  m.cats.content = root
  m.cats.setFocus(true)
end sub

sub addCat(root as object, t as string, kind as string)
  c = root.createChild("ContentNode")
  c.title = t
  c.Album = kind
end sub

sub onCatPick()
  id = m.catIds[m.cats.itemSelected]
  list = m.live.callFunc("list", {cat: id})
  t = "All channels"
  if id = "@fav" then
    t = "Favourites"
  else if id = "@recent" then
    t = "Recently watched"
  else if id <> "@all" then
    t = m.live.callFunc("catName", {id: id})
  end if
  m.sTitle.text = t
  nn = list.count()
  m.sCount.text = nn.ToStr()
  m.pendingCtx = t
  fillList(list)
  m.chs.setFocus(true)
end sub

sub onListPick()
  i = m.chs.itemSelected
  if m.sideList = invalid then return
  m.chans = m.sideList
  if m.pendingCtx <> invalid then m.ctx = m.pendingCtx
  m.idx = i
  hideSide()
  tune()
end sub

sub hideSide()
  m.side.visible = false
  m.top.setFocus(true)
end sub

' ---------- options ----------
sub options()
  s = m.cur
  if s = invalid then return
  items = []
  if isFav(s.id) then items.push({label: "Remove from favourites"}) else items.push({label: "Add to favourites"})
  items.push({label: "Other streams for this channel", subtxt: "Same channel from other categories"})
  items.push({label: "Refresh channel list", subtxt: "Reload everything from your provider"})
  m.optFavs = liveFavs()
  if m.optFavs.count() > 0 then
    items.push({label: "Favourites", header: true})
    for each f in m.optFavs
      items.push({label: toStr(f.n), cur: toStr(f.id) = s.id})
    end for
  end if
  m.optItems = items
  m.optMode = "main"
  mn = scene().callFunc("push", {view: "SideMenu", title: s.n, items: items})
  mn.observeField("chosen", "onOpt")
end sub

sub onOpt(e as object)
  i = e.getData()
  if i < 0 then return
  if m.optMode = "alts" then
    s = m.alts[i]
    if s <> invalid then
      m.chans = m.alts
      m.idx = i
      m.ctx = "Other streams"
      tune()
    end if
    return
  end if
  l = m.optItems[i].label
  if i <= 2 then
    if l = "Other streams for this channel" then
      m.alts = [m.cur]
      for each a in m.live.callFunc("alts", {id: m.cur.id, n: m.cur.n})
        m.alts.push(a)
      end for
      if m.alts.count() <= 1 then
        notify("No other streams found for this channel")
        return
      end if
      items = []
      for each a in m.alts
        items.push({label: a.n, subtxt: m.live.callFunc("catName", {id: a.c}), cur: a.id = m.cur.id})
      end for
      m.optMode = "alts"
      mn = scene().callFunc("push", {view: "SideMenu", title: "Other streams", items: items})
      mn.observeField("chosen", "onOpt")
    else if l = "Refresh channel list" then
      m.live.callFunc("load", {force: true})
      notify("Refreshing channels…")
    else
      toggleFav(m.cur)
    end if
    return
  end if
  ' a favourite from the quick list
  fi = i - 4
  favList = m.live.callFunc("list", {cat: "@fav"})
  if fi >= 0 and fi < favList.count() then
    m.chans = favList
    m.idx = fi
    m.ctx = "Favourites"
    tune()
  end if
end sub

sub leave()
  m.v.unobserveFieldScoped("state")
  m.v.control = "stop"
  hideVid()
  scene().callFunc("pop", {})
end sub

function onKeyEvent(key as string, press as boolean) as boolean
  if not press then return true
  if m.side.visible then
    if key = "back" or key = "right" then
      if m.sideCats and key = "back" then
        m.sideCats = false
        m.catCol.visible = false
        m.chCol.translation = [0, 0]
        m.sideBg.width = 760
        m.sideSh.translation = [760, 0]
        m.chs.setFocus(true)
      else if m.sideCats and m.cats.hasFocus() then
        m.chs.setFocus(true)
      else
        hideSide()
      end if
    else if key = "left" then
      if m.chs.hasFocus() then
        if m.sideCats then m.cats.setFocus(true) else showCats()
      end if
    end if
    return true
  end if
  n = m.chans.count()
  if key = "up" then
    m.idx = (m.idx - 1 + n) mod n
    tune()
  else if key = "down" then
    m.idx = (m.idx + 1) mod n
    tune()
  else if key = "OK" or key = "left" then
    showSide()
  else if key = "right" or key = "options" then
    options()
  else if key = "play" then
    if m.v.state = "paused" then m.v.control = "resume" else m.v.control = "pause"
    showOsd()
  else if key = "back" then
    leave()
  else
    showOsd()
  end if
  return true
end function
