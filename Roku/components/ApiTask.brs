sub init()
  m.top.functionName = "go"
end sub

sub go()
  res = fetch(m.top.url, m.top.method, m.top.body, m.top.headers, m.top.timeout)
  if res.ok and m.top.mode = "xstreams" then res.data = slimStreams(res.data)
  res.kind = m.top.kind
  m.top.result = res
end sub

function fetch(url as string, method as string, body as string, headers as dynamic, timeoutMs as integer) as object
  res = {ok: false, code: 0, data: invalid, text: ""}
  if url = "" then return res
  port = CreateObject("roMessagePort")
  t = CreateObject("roUrlTransfer")
  t.SetMessagePort(port)
  t.SetUrl(url)
  t.SetCertificatesFile("common:/certs/ca-bundle.crt")
  t.InitClientCertificates()
  t.EnableEncodings(true)
  t.RetainBodyOnError(true)
  t.AddHeader("Accept", "application/json")
  if headers <> invalid then
    for each k in headers
      t.AddHeader(k, headers[k])
    end for
  end if
  if method = "" then method = "GET"
  if method = "GET" then
    ok = t.AsyncGetToString()
  else if method = "POST" then
    ok = t.AsyncPostFromString(body)
  else
    t.SetRequest(method)
    ok = t.AsyncGetToString()
  end if
  if not ok then return res
  msg = wait(timeoutMs, port)
  if type(msg) <> "roUrlEvent" then
    t.AsyncCancel()
    res.text = "timeout"
    return res
  end if
  code = msg.GetResponseCode()
  s = msg.GetString()
  res.code = code
  res.ok = (code >= 200 and code < 300)
  if s = invalid then s = ""
  if s <> "" then
    d = ParseJson(s)
    if d = invalid then
      res.text = Left(s, 300)
    else
      res.data = d
    end if
  end if
  if not res.ok and res.text = "" then res.text = msg.GetFailureReason()
  return res
end function

' Xtream live list -> small records (keeps memory and copying down)
function slimStreams(a as dynamic) as dynamic
  if type(a) <> "roArray" then return invalid
  out = []
  for each s in a
    if s <> invalid then
      n = toStr(s.name)
      out.push({n: n, l: LCase(n), id: toStr(s.stream_id), c: toStr(s.category_id), i: toStr(s.stream_icon), num: toStr(s.num), a: isTrue(s.tv_archive)})
    end if
  end for
  return out
end function
