sub init()
  m.pal = thmD()
  p = m.pal
  m.v = vid()
  ' top + bottom bars (shown with any key)
  m.ui = grp(m.top)
  m.ui.opacity = 0
  gt = pic(m.ui, 0, 0, 1920, 300, "scaleToFill")
  gt.uri = "pkg:/images/grad_down.png"
  gb = pic(m.ui, 0, 640, 1920, 440, "scaleToFill")
  gb.uri = "pkg:/images/grad_up.png"
  m.tTitle = lbl(m.ui, 90, 56, "", 44, "b", p.text, 1300)
  m.tSub = lbl(m.ui, 90, 116, "", 25, "r", "0xC7C7CCFF", 1300)
  m.tClock = lbl(m.ui, 1330, 56, "", 40, "s", p.text, 500)
  m.tClock.horizAlign = "right"
  m.tEnds = lbl(m.ui, 1330, 108, "", 21, "r", "0xC7C7CCFF", 500)
  m.tEnds.horizAlign = "right"
  m.barBg = rect(m.ui, 90, 896, 1740, 12, "0xFFFFFF38")
  m.barPos = rect(m.ui, 90, 896, 0, 12, "0xFFFFFFFF")
  m.thumb = icon(m.ui, "dot", 76, 888, 28, "0xFFFFFFFF")
  m.tipG = grp(m.ui, 0, 836)
  m.tipBg = rbox(m.tipG, 0, 0, 120, 48, 12, "0x000000BF")
  m.tip = lbl(m.tipG, 16, 8, "", 26, "s", p.text)
  m.tipG.visible = false
  m.tPos = lbl(m.ui, 90, 926, "", 23, "r", "0xC7C7CCFF")
  m.tDur = lbl(m.ui, 1330, 926, "", 23, "r", "0xC7C7CCFF", 500)
  m.tDur.horizAlign = "right"
  m.btnG = grp(m.ui, 90, 974)
  ' paused badge
  m.paused = grp(m.top, 885, 465)
  icon(m.paused, "dot", 0, 0, 150, "0x00000080")
  icon(m.paused, "pause", 45, 45, 60, "0xFFFFFFFF")
  m.paused.visible = false
  ' skip intro
  m.skip = grp(m.top, 0, 714)
  m.skipBg = rbox(m.skip, 0, 0, 10, 66, 32, "0x1E1E22D9")
  m.skipEd = edge(m.skip, "thin32", 0, 0, 10, 66, "0xFFFFFF80")
  m.skipL = lbl(m.skip, 36, 18, "Skip intro", 27, "s", p.text)
  m.skip.visible = false
  ' up next
  m.nxt = grp(m.top, 1070, 766)
  rbox(m.nxt, 0, 0, 760, 202, 25, "0x16171CF0")
  m.nImg = mpic(m.nxt, 22, 22, 280, 158)
  m.nLbl = lbl(m.nxt, 328, 30, "UP NEXT", 19, "b", "0xA1A1A8FF", 410)
  m.nTitle = lbl(m.nxt, 328, 60, "", 28, "b", p.text, 410)
  m.nTitle.wrap = true
  m.nTitle.maxLines = 2
  m.nHint = lbl(m.nxt, 328, 140, "", 20, "r", "0xC7C7CCFF", 410)
  m.nxt.visible = false
  m.msg = lbl(m.top, 160, 500, "", 30, "r", p.text, 1600)
  m.msg.horizAlign = "center"
  m.msg.wrap = true
  m.uiT = mkTimer(5, "autoHide")
  m.repT = mkTimer(10, "report", true)
  m.scrubT = mkTimer(0.7, "commitScrub")
  m.nextT = mkTimer(1, "nextTick", true)
  m.clockT = mkTimer(10, "clockTick", true)
  m.v.observeFieldScoped("state", "onState")
  m.v.observeFieldScoped("position", "onPos")
  m.shown = false
  m.zone = "bar"
  m.bi = 0
  m.scrub = -1
  m.lastKey = 0
  m.started = false
  m.segs = []
  m.rep = 0
  m.dur = 0
  m.count = 0
end sub

function onReturn(p as dynamic) as dynamic
  return invalid
end function

function open(p as object) as dynamic
  m.top.setFocus(true)
  m.clockT.control = "start"
  clockTick()
  start(p.item, Int(num(p.start)))
  return invalid
end function

' ---------- start playback ----------
sub start(it as object, startSec as integer)
  m.it = it
  m.startSec = startSec
  m.nextItem = invalid
  m.nextShown = false
  m.nextDismissed = false
  m.nxt.visible = false
  m.skip.visible = false
  m.segs = []
  m.msg.text = "Loading…"
  m.msg.visible = true
  if toStr(it.Type) = "Episode" then
    m.tTitle.text = toStr(it.SeriesName)
    m.tSub.text = epCode(it) + " · " + toStr(it.Name)
  else
    m.tTitle.text = toStr(it.Name)
    m.tSub.text = toStr(it.ProductionYear)
  end if
  buildBtns()
  a = acct()
  body = FormatJson({"DeviceProfile": rokuProfile(), "UserId": a.uid, "MaxStreamingBitrate": 60000000})
  jf("info", "/Items/" + toStr(it.Id) + "/PlaybackInfo?UserId=" + a.uid + "&IsPlayback=true&AutoOpenLiveStream=true&MaxStreamingBitrate=60000000", {method: "POST", body: body})
  jf("segs", "/MediaSegments/" + toStr(it.Id) + "?includeSegmentTypes=Intro&includeSegmentTypes=Outro")
  if toStr(it.Type) = "Episode" and toStr(it.SeriesId) <> "" then
    jf("nextep", "/Shows/" + toStr(it.SeriesId) + "/Episodes?UserId=" + a.uid + "&StartItemId=" + toStr(it.Id) + "&Limit=2&Fields=Overview")
  end if
end sub

function rokuProfile() as object
  di = CreateObject("roDeviceInfo")
  vc = "h264"
  r = di.CanDecodeVideo({Codec: "hevc"})
  if r <> invalid then
    if r.result = true then vc = vc + ",hevc"
  end if
  ac = "aac,mp3"
  r = di.CanDecodeAudio({Codec: "ac3"})
  if r <> invalid then
    if r.result = true then ac = ac + ",ac3"
  end if
  r = di.CanDecodeAudio({Codec: "eac3"})
  if r <> invalid then
    if r.result = true then ac = ac + ",eac3"
  end if
  return {
    "Name": "TV Home Roku",
    "MaxStreamingBitrate": 60000000,
    "MaxStaticBitrate": 100000000,
    "DirectPlayProfiles": [{"Container": "mp4,m4v,mov,mkv", "Type": "Video", "VideoCodec": vc, "AudioCodec": ac}],
    "TranscodingProfiles": [{"Container": "ts", "Type": "Video", "VideoCodec": "h264", "AudioCodec": "aac", "Context": "Streaming", "Protocol": "hls", "MaxAudioChannels": "2", "MinSegments": 1, "BreakOnNonKeyFrames": true}],
    "ContainerProfiles": [],
    "CodecProfiles": [],
    "SubtitleProfiles": [{"Format": "vtt", "Method": "External"}, {"Format": "srt", "Method": "External"}, {"Format": "subrip", "Method": "External"}, {"Format": "ass", "Method": "External"}, {"Format": "ssa", "Method": "External"}]
  }
end function

sub onApi(e as object)
  if not apiFresh(e) then return
  r = e.getData()
  k = r.kind
  if k = "info" then
    gotInfo(r)
  else if k = "segs" then
    m.segs = []
    l = gv(r.data, "Items")
    if l <> invalid then
      for each s in l
        m.segs.push({t: toStr(s.Type), s: ticksSec(s.StartTicks), e: ticksSec(s.EndTicks)})
      end for
    end if
  else if k = "nextep" then
    l = gv(r.data, "Items")
    if l <> invalid then
      if l.count() > 1 then m.nextItem = l[1]
    end if
    buildBtns()
  end if
end sub

sub gotInfo(r as object)
  a = acct()
  d = r.data
  srcs = gv(d, "MediaSources")
  ok = false
  if r.ok and srcs <> invalid then ok = srcs.count() > 0
  if not ok then
    m.msg.text = "Couldn't start playback (" + r.code.ToStr() + "). Press Back."
    return
  end if
  ms = srcs[0]
  m.ms = ms
  m.psid = toStr(d.PlaySessionId)
  id = toStr(m.it.Id)
  if isTrue(ms.SupportsDirectPlay) then
    url = a.server + "/Videos/" + id + "/stream?static=true&MediaSourceId=" + toStr(ms.Id) + "&PlaySessionId=" + m.psid + "&api_key=" + a.token
    cont = LCase(toStr(ms.Container))
    fmt = "mp4"
    if Instr(1, cont, "mkv") > 0 or Instr(1, cont, "matroska") > 0 or Instr(1, cont, "webm") > 0 then fmt = "mkv"
    m.method = "DirectPlay"
  else if toStr(ms.TranscodingUrl) <> "" then
    url = a.server + toStr(ms.TranscodingUrl)
    if Instr(1, LCase(url), "api_key=") = 0 then url = url + "&api_key=" + a.token
    fmt = "hls"
    m.method = "Transcode"
  else
    m.msg.text = "This video can't be played on this Roku. Press Back."
    return
  end if
  subs = []
  streams = gv(ms, "MediaStreams")
  if streams <> invalid then
    for each st in streams
      if toStr(st.Type) = "Subtitle" and toStr(st.DeliveryMethod) = "External" and toStr(st.DeliveryUrl) <> "" then
        su = a.server + toStr(st.DeliveryUrl)
        if Instr(1, LCase(su), "api_key=") = 0 then
          if Instr(1, su, "?") > 0 then su = su + "&api_key=" + a.token else su = su + "?api_key=" + a.token
        end if
        lang = toStr(st.Language)
        if lang = "" then lang = "und"
        nm = toStr(st.DisplayTitle)
        if nm = "" then nm = lang
        subs.push({Language: lang, TrackName: su, Description: nm})
      end if
    end for
  end if
  m.dur = ticksSec(ms.RunTimeTicks)
  if m.dur <= 0 then m.dur = ticksSec(m.it.RunTimeTicks)
  cn = CreateObject("roSGNode", "ContentNode")
  cn.url = url
  cn.streamFormat = fmt
  cn.title = m.tTitle.text
  if subs.count() > 0 then cn.SubtitleTracks = subs
  if m.startSec > 0 then cn.PlayStart = m.startSec
  m.v.globalCaptionMode = "Off"
  showVid(0, 0, 1920, 1080)
  m.v.content = cn
  m.v.control = "play"
  m.started = true
  rep("/Sessions/Playing", m.startSec, false)
  m.repT.control = "start"
end sub

' ---------- reporting back to Jellyfin ----------
sub rep(path as string, sec as dynamic, keep as boolean)
  if m.ms = invalid then return
  aa = {"ItemId": toStr(m.it.Id), "MediaSourceId": toStr(m.ms.Id), "PlaySessionId": m.psid, "PlayMethod": m.method, "CanSeek": true, "IsPaused": (m.v.state = "paused"), "PositionTicks": "@@T@@"}
  s = Int(num(sec))
  t = "0"
  if s > 0 then t = s.ToStr() + "0000000"
  body = FormatJson(aa).Replace(Chr(34) + "@@T@@" + Chr(34), t)
  jf("rep" + path, path, {method: "POST", body: body, keep: keep})
end sub

sub report()
  if m.started then rep("/Sessions/Playing/Progress", m.v.position, false)
end sub

sub stopReport()
  if not m.started then return
  m.started = false
  m.repT.control = "stop"
  ps = m.v.position
  if m.v.state = "finished" and m.dur > 0 then ps = m.dur
  rep("/Sessions/Playing/Stopped", ps, true)
end sub

' ---------- state ----------
sub onState()
  s = m.v.state
  if s = "playing" then
    m.msg.visible = false
    m.paused.visible = false
  else if s = "paused" then
    m.paused.visible = true
  else if s = "buffering" then
    m.paused.visible = false
  else if s = "finished" then
    if m.nextItem <> invalid and not m.nextDismissed then
      playNext()
    else
      leave()
    end if
  else if s = "error" then
    m.msg.text = "Playback error: " + toStr(m.v.errorMsg) + chr(10) + "Press Back."
    m.msg.visible = true
    stopReport()
  end if
  if m.shown then drawBtns()
end sub

sub onPos()
  ps = m.v.position
  if m.shown then drawBar()
  ' skip intro
  inIntro = false
  for each sg in m.segs
    if sg.t = "Intro" and ps >= sg.s and ps < sg.e - 1 then inIntro = true
  end for
  if inIntro <> m.skip.visible then
    m.skip.visible = inIntro
    placeSkip()
  end if
  ' up next: credits segment, or the last 25 seconds
  if m.nextItem <> invalid and not m.nextShown and not m.nextDismissed then
    credits = false
    for each sg in m.segs
      if sg.t = "Outro" and ps >= sg.s then credits = true
    end for
    if m.dur > 0 and m.dur - ps <= 25 then credits = true
    if credits then showNext()
  end if
end sub

sub placeSkip()
  w = textW(m.skipL) + 72
  m.skipBg.width = w
  m.skipEd.width = w
  m.skip.translation = [1830 - w, 714]
  if m.shown then
    m.skipBg.blendColor = "0x1E1E22D9"
    m.skipL.color = "0xFFFFFFFF"
  else
    m.skipBg.blendColor = "0xFFFFFFFF"
    m.skipL.color = "0x111111FF"
  end if
end sub

sub showNext()
  m.nextShown = true
  e = m.nextItem
  m.nImg.uri = jfImg(e.Id, "Primary", 560)
  m.nTitle.text = epCode(e) + " · " + toStr(e.Name)
  m.count = 10
  m.nHint.text = "Playing in 10s · OK to play now"
  placeNext()
  m.nxt.visible = true
  m.nextT.control = "start"
end sub

sub placeNext()
  if m.shown then m.nxt.translation = [1070, 548] else m.nxt.translation = [1070, 788]
end sub

sub nextTick()
  m.count = m.count - 1
  if m.count <= 0 then
    m.nextT.control = "stop"
    playNext()
    return
  end if
  m.nHint.text = "Playing in " + m.count.ToStr() + "s · OK to play now"
end sub

sub playNext()
  m.nextT.control = "stop"
  n = m.nextItem
  if n = invalid then return
  stopReport()
  m.v.control = "stop"
  start(n, ticksSec(gv(gv(n, "UserData"), "PlaybackPositionTicks")))
end sub

sub leave()
  m.nextT.control = "stop"
  stopReport()
  m.v.unobserveFieldScoped("state")
  m.v.unobserveFieldScoped("position")
  m.v.control = "stop"
  hideVid()
  scene().callFunc("pop", {})
end sub

' ---------- on-screen controls ----------
sub showUI()
  if not m.shown then
    m.shown = true
    m.zone = "bar"
    tween(m.ui, "opacity", 1.0, 0.25)
    placeSkip()
    placeNext()
  end if
  clockTick()
  drawBar()
  drawBtns()
  restart(m.uiT)
end sub

sub hideUI()
  m.shown = false
  m.scrub = -1
  m.tipG.visible = false
  tween(m.ui, "opacity", 0.0, 0.25)
  placeSkip()
  placeNext()
end sub

sub autoHide()
  if m.v.state = "playing" and m.scrub < 0 then hideUI() else restart(m.uiT)
end sub

sub clockTick()
  m.tClock.text = hm()
  if m.dur > 0 then m.tEnds.text = "Ends at " + hm(nowSec() + Int(m.dur - m.v.position))
end sub

sub drawBar()
  ps = m.v.position
  if m.scrub >= 0 then ps = m.scrub
  d = m.dur
  if d <= 0 then d = m.v.duration
  f = 0.0
  if d > 0 then f = ps / d
  if f > 1 then f = 1
  w = Int(1740 * f)
  m.barPos.width = w
  focused = (m.zone = "bar")
  m.thumb.visible = focused
  m.thumb.translation = [76 + w, 888]
  if focused then
    m.barBg.height = 16
    m.barPos.height = 16
    m.barBg.translation = [90, 894]
    m.barPos.translation = [90, 894]
  else
    m.barBg.height = 12
    m.barPos.height = 12
    m.barBg.translation = [90, 896]
    m.barPos.translation = [90, 896]
  end if
  m.tPos.text = clockStr(ps)
  m.tDur.text = clockStr(d)
  if m.scrub >= 0 then
    m.tip.text = clockStr(m.scrub)
    tw = textW(m.tip) + 32
    m.tipBg.width = tw
    x = 90 + w - tw / 2
    if x < 40 then x = 40
    if x > 1880 - tw then x = 1880 - tw
    m.tipG.translation = [x, 830]
    m.tipG.visible = true
  else
    m.tipG.visible = false
  end if
end sub

sub buildBtns()
  m.btnG.removeChildrenIndex(m.btnG.getChildCount(), 0)
  defs = [{k: "pp", t: "Pause", ic: "pause"}, {k: "rw", t: "10s", ic: "restart"}, {k: "ff", t: "30s"}, {k: "audio", t: "Audio"}, {k: "subs", t: "Subtitles"}]
  if m.nextItem <> invalid then defs.push({k: "nextep", t: "Next episode"})
  m.btns = []
  x = 0
  for each d in defs
    g = grp(m.btnG, x, 0)
    b = {k: d.k, g: g}
    b.bg = rbox(g, 0, 0, 10, 52, 25, "0xFFFFFF1F")
    lx = 26
    if d.ic <> invalid then
      b.ic = icon(g, d.ic, 24, 14, 24, "0xFFFFFFFF")
      lx = 58
    end if
    b.l = lbl(g, lx, 12, d.t, 23, "s", "0xF5F5F7FF")
    w = lx + textW(b.l) + 26
    b.bg.width = w
    g.scaleRotateCenter = [w / 2, 26]
    x = x + w + 16
    m.btns.push(b)
  end for
  if m.bi >= m.btns.count() then m.bi = 0
  drawBtns()
end sub

sub drawBtns()
  if m.btns = invalid then return
  for i = 0 to m.btns.count() - 1
    b = m.btns[i]
    f = (m.zone = "btns" and m.bi = i)
    if b.k = "pp" then
      if m.v.state = "paused" then
        b.l.text = "Play"
        if b.ic <> invalid then b.ic.uri = "pkg:/images/i_play.png"
      else
        b.l.text = "Pause"
        if b.ic <> invalid then b.ic.uri = "pkg:/images/i_pause.png"
      end if
    end if
    if f then
      b.bg.blendColor = "0xFFFFFFFF"
      b.l.color = "0x111111FF"
      if b.ic <> invalid then b.ic.blendColor = "0x111111FF"
      tween(b.g, "scale", [1.06, 1.06], 0.15)
    else
      b.bg.blendColor = "0xFFFFFF1F"
      b.l.color = "0xF5F5F7FF"
      if b.ic <> invalid then b.ic.blendColor = "0xFFFFFFFF"
      tween(b.g, "scale", [1.0, 1.0], 0.15)
    end if
  end for
end sub

sub togglePause()
  if m.v.state = "paused" then m.v.control = "resume" else m.v.control = "pause"
end sub

' hold ◀ ▶ to scrub faster; the jump happens when you let go
sub scrubBy(d as integer)
  now = msNow()
  if now - m.lastKey < 450 then m.rep = m.rep + 1 else m.rep = 0
  m.lastKey = now
  stp = d
  if m.rep > 4 then stp = d * 3
  if m.rep > 12 then stp = d * 6
  if m.scrub < 0 then m.scrub = m.v.position
  m.scrub = m.scrub + stp
  if m.scrub < 0 then m.scrub = 0
  dd = m.dur
  if dd <= 0 then dd = m.v.duration
  if dd > 0 and m.scrub > dd - 2 then m.scrub = dd - 2
  showUI()
  restart(m.scrubT)
end sub

sub commitScrub()
  if m.scrub >= 0 then
    m.v.seek = m.scrub
    m.scrub = -1
    drawBar()
    report()
  end if
end sub

sub skipIntro()
  ps = m.v.position
  for each sg in m.segs
    if sg.t = "Intro" and ps >= sg.s and ps < sg.e then m.v.seek = sg.e
  end for
  m.skip.visible = false
end sub

sub btnAction(k as string)
  if k = "pp" then
    togglePause()
  else if k = "rw" then
    m.v.seek = m.v.position - 10
  else if k = "ff" then
    m.v.seek = m.v.position + 30
  else if k = "audio" then
    trackMenu("audio")
  else if k = "subs" then
    trackMenu("subs")
  else if k = "nextep" then
    playNext()
  end if
end sub

sub trackMenu(kind as string)
  items = []
  m.trk = []
  if kind = "audio" then
    cur = toStr(m.v.currentAudioTrack)
    for each t in m.v.availableAudioTracks
      nm = toStr(t.Name)
      if nm = "" then nm = toStr(t.Language)
      if nm = "" then nm = "Track " + toStr(t.Track)
      items.push({label: nm, subtxt: toStr(t.Format), sel: toStr(t.Track) = cur})
      m.trk.push(toStr(t.Track))
    end for
    if items.count() = 0 then items.push({label: "Default"})
  else
    on = (m.v.globalCaptionMode = "On")
    items.push({label: "Off", sel: not on})
    m.trk.push("")
    cur = toStr(m.v.currentSubtitleTrack)
    for each t in m.v.availableSubtitleTracks
      nm = toStr(t.Description)
      if nm = "" then nm = toStr(t.Language)
      items.push({label: nm, sel: on and toStr(t.TrackName) = cur})
      m.trk.push(toStr(t.TrackName))
    end for
  end if
  m.trkKind = kind
  mn = scene().callFunc("push", {view: "SideMenu", title: iif(kind = "audio", "Audio", "Subtitles"), items: items})
  mn.observeField("chosen", "onTrack")
end sub

function iif(c as boolean, a as dynamic, b as dynamic) as dynamic
  if c then return a
  return b
end function

sub onTrack(e as object)
  i = e.getData()
  if i < 0 or i >= m.trk.count() then return
  t = m.trk[i]
  if m.trkKind = "audio" then
    if t <> "" then m.v.audioTrack = t
  else
    if t = "" then
      m.v.globalCaptionMode = "Off"
    else
      m.v.subtitleTrack = t
      m.v.globalCaptionMode = "On"
    end if
  end if
  showUI()
end sub

function onKeyEvent(key as string, press as boolean) as boolean
  if not press then return true
  if key = "back" then
    if m.nxt.visible then
      m.nxt.visible = false
      m.nextDismissed = true
      m.nextT.control = "stop"
    else if m.shown then
      hideUI()
    else
      leave()
    end if
    return true
  end if
  if key = "play" then
    togglePause()
    showUI()
    return true
  else if key = "rewind" then
    scrubBy(-30)
    return true
  else if key = "fastforward" then
    scrubBy(30)
    return true
  else if key = "replay" then
    m.v.seek = m.v.position - 10
    showUI()
    return true
  end if
  if not m.shown then
    if key = "OK" then
      if m.skip.visible then
        skipIntro()
      else if m.nxt.visible then
        playNext()
      else
        togglePause()
        showUI()
      end if
    else if key = "left" then
      scrubBy(-10)
    else if key = "right" then
      scrubBy(10)
    else
      showUI()
    end if
    return true
  end if
  restart(m.uiT)
  if m.zone = "bar" then
    if key = "left" then
      scrubBy(-10)
    else if key = "right" then
      scrubBy(10)
    else if key = "OK" then
      if m.scrub >= 0 then commitScrub() else togglePause()
    else if key = "down" then
      m.zone = "btns"
      drawBar()
      drawBtns()
    else if key = "up" then
      if m.skip.visible then skipIntro()
    end if
  else
    if key = "left" then
      if m.bi > 0 then m.bi = m.bi - 1
      drawBtns()
    else if key = "right" then
      if m.bi < m.btns.count() - 1 then m.bi = m.bi + 1
      drawBtns()
    else if key = "up" then
      m.zone = "bar"
      drawBar()
      drawBtns()
    else if key = "OK" then
      btnAction(m.btns[m.bi].k)
    end if
  end if
  return true
end function
