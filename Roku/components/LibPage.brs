sub init()
  p = thm()
  m.body = grp(m.top)
  m.cwHead = lbl(m.body, 110, 262, "Continue watching", 30, "s", p.text)
  m.cw = CreateObject("roSGNode", "Row")
  m.cw.zoom = 1.06
  m.body.appendChild(m.cw)
  m.gHead = grp(m.body, 110, 674)
  m.gTitle = lbl(m.gHead, 0, 0, "", 30, "s", p.text)
  m.gCount = lbl(m.gHead, 0, 8, "", 22, "r", p.muted)
  m.msg = lbl(m.body, 110, 740, "", 28, "r", p.muted, 1700)
  m.grid = CreateObject("roSGNode", "MarkupGrid")
  m.grid.itemComponentName = "PosterItem"
  m.grid.numColumns = 7
  m.grid.numRows = 3
  m.grid.itemSize = [242, 413]
  m.grid.itemSpacing = [5, 12]
  m.grid.drawFocusFeedback = false
  m.grid.vertFocusAnimationStyle = "floatingFocus"
  m.grid.translation = [96, 722]
  m.body.appendChild(m.grid)
  m.cw.observeField("selected", "onCw")
  m.grid.observeField("itemSelected", "onPick")
  m.grid.observeField("itemFocused", "onGridFocus")
  m.top.observeField("focusedChild", "onFocusChg")
  m.items = []
  m.cwItems = []
  m.total = 0
  m.busy = false
  m.loadedAt = -1
  m.down = false
end sub

function blur(p as dynamic) as dynamic
  m.cw.callFunc("blurRow", {})
  scrollTo(false)
  return invalid
end function

function reset(p as dynamic) as dynamic
  m.loadedAt = -1
  m.items = []
  m.cwItems = []
  m.grid.content = invalid
  m.cw.items = []
  return invalid
end function

function activate(p as dynamic) as dynamic
  if m.top.section = "movies" then m.gTitle.text = "All movies" else m.gTitle.text = "All shows"
  m.gCount.translation = [textW(m.gTitle) + 18, 8]
  if not jfOn() then
    m.cwHead.visible = false
    m.cw.visible = false
    m.grid.visible = false
    m.gHead.translation = [110, 262]
    m.msg.translation = [110, 330]
    m.msg.text = "Connect your Jellyfin server in Settings to see your library here."
    return invalid
  end if
  m.grid.visible = true
  fresh = (m.loadedAt < 0 or nowSec() - m.loadedAt > 600 or isTrue(gv(p, "force")))
  loadCw()
  if fresh then loadGrid()
  return invalid
end function

function onReturn(p as dynamic) as dynamic
  if jfOn() then loadCw()
  return invalid
end function

function takeFocus(p as dynamic) as dynamic
  if m.cw.visible and m.cwItems.count() > 0 then
    scrollTo(false)
    return m.cw.callFunc("takeFocus", {})
  end if
  if m.items.count() > 0 then
    focusGrid()
    return true
  end if
  return false
end function

sub focusGrid()
  m.cw.callFunc("blurRow", {})
  m.grid.setFocus(true)
  scrollTo(true)
end sub

' whole page slides up when you go into the grid (header fades away, like the web version)
sub scrollTo(down as boolean)
  if down = m.down then return
  m.down = down
  y = 0
  if down then y = 130 - Int(m.grid.translation[1])
  y = y + 14
  if y > 0 then y = 0
  tween(m.body, "translation", [0, y], 0.3)
  scene().callFunc("headerDown", {down: down and y < 0})
end sub

sub onFocusChg()
  if not m.top.isInFocusChain() then scrollTo(false)
end sub

' ---------- data ----------
sub loadCw()
  a = acct()
  f = "&Fields=ProductionYear,RunTimeTicks,ParentBackdropItemId&ImageTypeLimit=1&EnableImageTypes=Primary,Backdrop,Thumb"
  if m.top.section = "movies" then
    m.cwWant = 1
    m.cwRes = {}
    jf("cw1", "/Users/" + a.uid + "/Items/Resume?Limit=24&IncludeItemTypes=Movie&MediaTypes=Video" + f)
  else
    m.cwWant = 2
    m.cwRes = {}
    jf("cw1", "/Users/" + a.uid + "/Items/Resume?Limit=24&IncludeItemTypes=Episode&MediaTypes=Video" + f)
    jf("cw2", "/Shows/NextUp?UserId=" + a.uid + "&Limit=24" + f)
  end if
end sub

sub loadGrid()
  m.items = []
  m.total = 0
  m.busy = false
  m.loadedAt = nowSec()
  m.grid.content = CreateObject("roSGNode", "ContentNode")
  m.msg.text = ""
  more()
end sub

sub more()
  if m.busy then return
  n = m.items.count()
  if m.total > 0 and n >= m.total then return
  m.busy = true
  typ = "Movie"
  if m.top.section = "shows" then typ = "Series"
  jf("page", "/Users/" + acct().uid + "/Items?IncludeItemTypes=" + typ + "&Recursive=true&SortBy=SortName&SortOrder=Ascending&StartIndex=" + n.ToStr() + "&Limit=105&Fields=ProductionYear,ChildCount,RunTimeTicks,Genres&EnableImageTypes=Primary,Backdrop&ImageTypeLimit=1")
end sub

sub onApi(e as object)
  if not apiFresh(e) then return
  r = e.getData()
  d = r.data
  if type(d) = "roAssociativeArray" and r.kind <> "page" then d = d.Items
  if r.kind = "page" then
    m.busy = false
    if not r.ok or d = invalid then
      if m.items.count() = 0 then
        if r.code = 401 then m.msg.text = "Jellyfin sign-in expired — reconnect in Settings" else m.msg.text = "Can't reach Jellyfin"
      end if
      return
    end if
    t = d.TotalRecordCount
    add = d.Items
    if add = invalid then add = []
    if t = invalid then t = m.items.count() + add.count()
    m.total = t
    root = m.grid.content
    for each it in add
      m.items.push(it)
      c = root.createChild("ContentNode")
      c.title = toStr(it.Name)
      c.HDPosterUrl = jfImg(it.Id, "Primary", 330)
      if toStr(it.Type) = "Series" then
        c.ShortDescriptionLine2 = joinDot([toStr(it.ProductionYear), seasonsText(it)])
      else
        c.ShortDescriptionLine2 = joinDot([toStr(it.ProductionYear), dur(ticksSec(it.RunTimeTicks))])
      end if
      c.addFields({pct: pctOf(it), played: isTrue(gv(gv(it, "UserData"), "Played"))})
    end for
    m.gCount.text = toStr(m.total)
    if m.items.count() = 0 then m.msg.text = "Nothing in this library yet."
    return
  end if
  if type(d) <> "roArray" then d = []
  m.cwRes[r.kind] = d
  m.cwWant = m.cwWant - 1
  if m.cwWant > 0 then return
  seen = {}
  out = []
  for each kk in ["cw1", "cw2"]
    l = m.cwRes[kk]
    if l <> invalid then
      for each it in l
        k = toStr(it.SeriesId)
        if k = "" then k = toStr(it.Id)
        if seen[k] = invalid then
          seen[k] = true
          out.push(it)
        end if
      end for
    end if
  end for
  m.cwItems = out
  showCw()
end sub

sub showCw()
  items = []
  for each it in m.cwItems
    ep = toStr(it.Type) = "Episode"
    if ep then
      bid = toStr(it.ParentBackdropItemId)
      if bid = "" then bid = toStr(it.SeriesId)
      imgs = [jfImg(it.Id, "Primary", 800), jfImg(bid, "Backdrop", 800)]
      t = toStr(it.SeriesName)
      mt = epCode(it) + " · " + toStr(it.Name)
    else
      imgs = [jfImg(it.Id, "Backdrop", 800), jfImg(it.Id, "Thumb", 800), jfImg(it.Id, "Primary", 800)]
      t = toStr(it.Name)
      mt = joinDot([toStr(it.ProductionYear), dur(ticksSec(it.RunTimeTicks))])
    end if
    items.push({ui: "card", w: 400, h: 225, r: 20, title: t, meta: mt, img: imgs, pct: pctOf(it), tsize: 24, tweight: "s", msize: 20, tmt: 16, tmove: 8})
  end for
  has = items.count() > 0
  m.cwHead.visible = has
  m.cw.visible = has
  had = m.cw.hasFocus()
  m.cw.index = m.cw.focused
  m.cw.items = items
  if has then
    m.cw.translation = [0, 322]
    m.gHead.translation = [110, 674]
    m.grid.translation = [96, 722]
    m.msg.translation = [110, 740]
    if had then m.cw.callFunc("takeFocus", {})
  else
    m.gHead.translation = [110, 262]
    m.grid.translation = [96, 310]
    m.msg.translation = [110, 330]
    if had then focusGrid()
  end if
end sub

sub onCw()
  it = m.cwItems[m.cw.selected]
  if it <> invalid then openItem(it)
end sub

sub onPick()
  it = m.items[m.grid.itemSelected]
  if it <> invalid then openItem(it)
end sub

sub onGridFocus()
  if m.grid.itemFocused >= m.items.count() - 21 then more()
end sub

function onKeyEvent(key as string, press as boolean) as boolean
  if not press then return false
  if key = "down" and m.cw.hasFocus() then
    if m.items.count() > 0 then focusGrid()
    return true
  else if key = "up" and m.grid.hasFocus() then
    if m.cw.visible and m.cwItems.count() > 0 then
      scrollTo(false)
      m.cw.callFunc("takeFocus", {})
      return true
    end if
    scrollTo(false)
    return false
  else if key = "down" then
    return true
  end if
  return false
end function
