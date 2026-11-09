
' ---------- "what's on now" queue for list rows (3 at a time, top to bottom, cached 5 min) ----------
function askEpg(n as dynamic) as dynamic
  if n = invalid then return invalid
  if m.eq = invalid then
    m.eq = {queue: [], pend: {}, fly: {}, active: 0, n: 0}
    m.eqT = mkTimer(0.05, "epgPump")
  end if
  id = toStr(n.id)
  if id = "" then return invalid
  c = m.global.epgCache[id]
  if c <> invalid then
    if nowSec() - c.at < 300 then
      epgPut(n, c.res)
      return invalid
    end if
  end if
  f = m.eq.fly[id]
  if f <> invalid then
    f.push(n)
    return invalid
  end if
  for i = m.eq.queue.count() - 1 to 0 step -1
    if m.eq.queue[i] = id then m.eq.queue.Delete(i)
  end for
  m.eq.queue.Push(id)
  if m.eq.pend[id] = invalid then m.eq.pend[id] = []
  m.eq.pend[id].push(n)
  ' scrolled past quickly? forget the oldest asks
  if m.eq.queue.count() > 40 then
    gone = m.eq.queue.Shift()
    m.eq.pend.Delete(gone)
  end if
  restart(m.eqT)
  return invalid
end function

sub epgPump()
  if m.eq = invalid then return
  if not ipOn() then return
  while m.eq.active < 3 and m.eq.queue.count() > 0
    id = m.eq.queue.Shift()
    nodes = m.eq.pend[id]
    m.eq.pend.Delete(id)
    if nodes = invalid then nodes = []
    m.eq.fly[id] = nodes
    m.eq.active = m.eq.active + 1
    api("q:" + id, xBase() + "&action=get_short_epg&stream_id=" + id + "&limit=2", {timeout: 12000})
  end while
end sub

' call from onApi for kinds starting with "q:"
sub epgDone(r as object)
  id = Mid(toStr(r.kind), 3)
  m.tasks.Delete(toStr(r.kind))
  m.eq.active = m.eq.active - 1
  if m.eq.active < 0 then m.eq.active = 0
  l = epgList(r.data)
  res = {t: " ", s: 0, e: 0, n: ""}
  if l.count() > 0 then
    res.t = l[0].t
    res.s = l[0].s
    res.e = l[0].e
    if l.count() > 1 then res.n = l[1].t
  end if
  if r.ok then
    cache = m.global.epgCache
    if cache.count() > 400 then cache = {}
    cache[id] = {at: nowSec(), res: res}
    m.global.epgCache = cache
  end if
  nodes = m.eq.fly[id]
  m.eq.fly.Delete(id)
  if nodes <> invalid then
    for each n in nodes
      epgPut(n, res)
    end for
  end if
  epgPump()
end sub

sub epgPut(n as object, res as object)
  n.TitleSeason = res.n
  n.ReleaseDate = toStr(res.s) + "|" + toStr(res.e)
  n.Description = res.t
end sub
