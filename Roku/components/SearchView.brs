' search one section (movies / shows) – results narrow with every letter. Also shows folder contents.
sub init()
  p = thm()
  m.p = p
  rect(m.top, 0, 0, 1920, 1080, p.bg1)
  m.title = lbl(m.top, 60, 38, "", 50, "s", p.text)
  m.clock = lbl(m.top, 1360, 52, "", 30, "r", p.muted, 500)
  m.clock.horizAlign = "right"
  m.kb = CreateObject("roSGNode", "KeyPad")
  m.kb.translation = [60, 132]
  m.top.appendChild(m.kb)
  m.head = lbl(m.top, 560, 128, "", 30, "s", p.text, 900)
  m.count = lbl(m.top, 1460, 138, "", 20, "r", p.muted, 400)
  m.count.horizAlign = "right"
  m.grid = CreateObject("roSGNode", "MarkupGrid")
  m.grid.itemComponentName = "PosterItem"
  m.grid.numColumns = 5
  m.grid.numRows = 3
  m.grid.itemSize = [242, 413]
  m.grid.itemSpacing = [5, 12]
  m.grid.drawFocusFeedback = false
  m.grid.vertFocusAnimationStyle = "floatingFocus"
  m.grid.translation = [566, 182]
  m.top.appendChild(m.grid)
  m.msg = lbl(m.top, 580, 260, "", 26, "r", p.muted, 1200)
  m.msg.wrap = true
  m.kb.observeField("text", "onType")
  m.grid.observeField("itemSelected", "onPick")
  m.typeT = mkTimer(0.35, "runSearch")
  m.items = []
end sub

function onReturn(p as dynamic) as dynamic
  return invalid
end function

function open(p as object) as dynamic
  m.clock.text = hm()
  m.mode = toStr(p.mode)
  if m.mode = "folder" then
    ' a folder / collection: no keyboard, just the grid
    m.kb.visible = false
    m.title.text = toStr(p.item.Name)
    m.grid.numColumns = 7
    m.grid.translation = [96, 182]
    m.msg.translation = [110, 260]
    m.head.translation = [110, 128]
    m.head.text = ""
    jf("res", "/Users/" + acct().uid + "/Items?ParentId=" + toStr(p.item.Id) + "&SortBy=SortName&Fields=ProductionYear,ChildCount,RunTimeTicks&EnableImageTypes=Primary&ImageTypeLimit=1&Limit=300")
    m.grid.setFocus(true)
    return invalid
  end if
  if m.mode = "movies" then
    m.title.text = "Search movies"
    m.types = "Movie"
  else
    m.title.text = "Search shows"
    m.types = "Series"
  end if
  m.kb.hint = "Type a title"
  m.kb.callFunc("takeFocus", {})
  m.msg.text = "Start typing — results narrow with every letter."
  return invalid
end function

sub onType()
  restart(m.typeT)
end sub

sub runSearch()
  q = m.kb.text.Trim()
  if q = "" then
    m.grid.content = invalid
    m.items = []
    m.head.text = ""
    m.count.text = ""
    m.msg.text = "Start typing — results narrow with every letter."
    return
  end if
  m.q = q
  jf("res", "/Users/" + acct().uid + "/Items?SearchTerm=" + enc(q) + "&IncludeItemTypes=" + m.types + "&Recursive=true&Limit=60&Fields=ProductionYear,ChildCount,RunTimeTicks&EnableImageTypes=Primary&ImageTypeLimit=1")
end sub

sub onApi(e as object)
  if not apiFresh(e) then return
  r = e.getData()
  l = gv(r.data, "Items")
  if l = invalid then l = []
  m.items = l
  root = CreateObject("roSGNode", "ContentNode")
  for each it in l
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
  m.grid.content = root
  if m.mode <> "folder" then m.head.text = "Results"
  n = l.count()
  m.count.text = n.ToStr()
  if n = 0 then
    if m.mode = "folder" then m.msg.text = "Nothing in here." else m.msg.text = "Nothing matches " + Chr(34) + toStr(m.q) + Chr(34) + "."
  else
    m.msg.text = ""
  end if
end sub

sub onPick()
  it = m.items[m.grid.itemSelected]
  if it <> invalid then openItem(it)
end sub

function onKeyEvent(key as string, press as boolean) as boolean
  if not press then return true
  if key = "back" then
    if m.grid.hasFocus() and m.mode <> "folder" then
      m.kb.callFunc("takeFocus", {})
    else
      scene().callFunc("pop", {})
    end if
  else if key = "right" then
    if m.kb.isInFocusChain() and m.items.count() > 0 then m.grid.setFocus(true)
  else if key = "left" then
    if m.grid.hasFocus() and m.mode <> "folder" then m.kb.callFunc("takeFocus", {})
  end if
  return true
end function
