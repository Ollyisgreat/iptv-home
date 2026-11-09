sub init()
  m.sig = ""
  m.streams = []
  m.byCat = {}
  m.byId = {}
  m.catList = []
  m.catNames = {}
end sub

' p.force = true reloads even if this login is already loaded
function load(p as dynamic) as dynamic
  c = m.global.cfg
  if not ipOn() then
    m.sig = ""
    m.top.state = "off"
    return invalid
  end if
  sig = c.ipServer + "|" + c.ipUser + "|" + c.ipPass
  force = false
  if p <> invalid then force = isTrue(p.force)
  if sig = m.sig and not force then
    if m.top.state = "ready" or m.top.state = "loading" then return invalid
  end if
  m.sig = sig
  m.gotCats = invalid
  m.gotStreams = invalid
  m.top.state = "loading"
  api("cats", xBase() + "&action=get_live_categories", {timeout: 30000})
  api("streams", xBase() + "&action=get_live_streams", {mode: "xstreams", timeout: 120000})
  return invalid
end function

sub onApi(e as object)
  if not apiFresh(e) then return
  r = e.getData()
  if not r.ok or type(r.data) <> "roArray" then
    m.sig = ""
    if r.code = 401 or r.code = 403 then
      m.top.err = "Your IPTV provider rejected the login (" + r.code.ToStr() + "). Check it in Settings."
    else if r.code = 0 then
      m.top.err = "Couldn't reach your IPTV provider. Check the server address in Settings."
    else
      m.top.err = "Your IPTV provider sent something unexpected (" + r.code.ToStr() + ")."
    end if
    m.top.state = "error"
    return
  end if
  if r.kind = "cats" then m.gotCats = r.data else m.gotStreams = r.data
  if m.gotCats <> invalid and m.gotStreams <> invalid then build()
end sub

sub build()
  m.streams = m.gotStreams
  m.byCat = {}
  m.byId = {}
  for each s in m.streams
    m.byId[s.id] = s
    a = m.byCat[s.c]
    if a = invalid then
      a = []
      m.byCat[s.c] = a
    end if
    a.push(s)
  end for
  m.catList = []
  m.catNames = {}
  for each c in m.gotCats
    id = toStr(c.category_id)
    a = m.byCat[id]
    if a <> invalid then
      n = toStr(c.category_name)
      m.catList.push({id: id, n: n, l: LCase(n), count: a.count()})
      m.catNames[id] = n
    end if
  end for
  m.gotCats = invalid
  m.gotStreams = invalid
  m.top.state = "ready"
end sub

function cats(p as dynamic) as dynamic
  out = []
  for each c in m.catList
    out.push({id: c.id, n: c.n, count: c.count})
  end for
  return out
end function

function catName(p as dynamic) as dynamic
  n = m.catNames[toStr(p.id)]
  if n = invalid then return ""
  return n
end function

' p.cat = category id, "@all", "@fav" or "@recent"
function list(p as dynamic) as dynamic
  id = toStr(p.cat)
  if id = "@all" then return m.streams
  if id = "@fav" then return resolve(liveFavs())
  if id = "@recent" then return resolve(liveRecents())
  a = m.byCat[id]
  if a = invalid then return []
  return a
end function

' saved favourites/recents carry name + logo, so they still show before the list loads
function resolve(saved as object) as object
  out = []
  for each f in saved
    s = m.byId[toStr(f.id)]
    if s = invalid then s = {id: toStr(f.id), n: toStr(f.n), l: LCase(toStr(f.n)), i: toStr(f.i), num: toStr(f.num), c: toStr(f.c), a: false}
    out.push(s)
  end for
  return out
end function

function byId(p as dynamic) as dynamic
  return m.byId[toStr(p.id)]
end function

' every word has to match; categories first, then channels
function search(p as dynamic) as dynamic
  q = LCase(toStr(p.q)).Trim()
  res = {cats: [], chs: []}
  if q = "" then return res
  words = q.Tokenize(" ")
  for each c in m.catList
    if hasAll(c.l, words) then
      res.cats.push({id: c.id, n: c.n, count: c.count})
      if res.cats.count() >= 30 then exit for
    end if
  end for
  for each s in m.streams
    if hasAll(s.l, words) then
      res.chs.push(s)
      if res.chs.count() >= 250 then exit for
    end if
  end for
  return res
end function

function hasAll(s as string, words as object) as boolean
  for each w in words
    if Instr(1, s, w) = 0 then return false
  end for
  return true
end function

' the same channel from other providers/categories: "UK: Sky Sports Main Event FHD" ~ "Sky Sports Main Event HD"
function alts(p as dynamic) as dynamic
  core = coreName(toStr(p.n))
  out = []
  if core = "" then return out
  for each s in m.streams
    if s.id <> toStr(p.id) then
      if Instr(1, s.l, core) > 0 then
        if coreName(s.n) = core then out.push(s)
      end if
    end if
    if out.count() >= 60 then exit for
  end for
  return out
end function

function coreName(n as string) as string
  s = LCase(n)
  s = CreateObject("roRegex", "^\s*[a-z]{2,4}\s*[:|\-]\s*", "").Replace(s, "")
  s = CreateObject("roRegex", "[\(\[][^\)\]]*[\)\]]", "").ReplaceAll(s, " ")
  s = CreateObject("roRegex", "\b(fhd|uhd|hd|sd|4k|hevc|h265|backup|raw|vip|50fps|60fps)\b", "").ReplaceAll(s, " ")
  s = CreateObject("roRegex", "[^a-z0-9+]+", "").ReplaceAll(s, " ")
  s = CreateObject("roRegex", "\s+", "").ReplaceAll(s, " ")
  return s.Trim()
end function
