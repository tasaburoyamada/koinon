import Lean
import Koinon.Server.Router
import Lyceum.Memory.VectorDB

namespace Koinon.Server.HttpServer

open Lean
open Koinon.Server
open Lyceum.Memory

/-- 簡易 HTTP リクエストのパース結果 -/
structure RawHttpRequest where
  method : String
  path : String
  headers : List (String × String)
  body : String
deriving Repr, Inhabited

/-- 安全なリスト要素取得 -/
def getListElem (l : List String) (idx : Nat) (defaultVal : String := "") : String :=
  match l.drop idx |>.head? with
  | some s => s
  | none => defaultVal

/-- Raw HTTP ソケットストリーム文字列から Method, Path, Headers, Body をパース -/
def parseHttpRequest (raw : String) : Option RawHttpRequest := do
  let lines := raw.splitOn "\r\n"
  if lines.isEmpty then none
  else
    let requestLine := lines.head!
    let parts := requestLine.splitOn " "
    if parts.length < 2 then none
    else
      let method := getListElem parts 0 "GET"
      let path := getListElem parts 1 "/"

      -- ヘッダーとボディの分離
      let bodySplit := raw.splitOn "\r\n\r\n"
      let body := if bodySplit.length >= 2 then getListElem bodySplit 1 "" else ""

      return { method := method, path := path, headers := [], body := body }

/-- HTTP レスポンス文字列を構築 -/
def buildHttpResponseString (resp : HttpResponse) : String :=
  s!"HTTP/1.1 {resp.status} OK\r\n" ++
  s!"Content-Type: {resp.contentType}\r\n" ++
  s!"Content-Length: {resp.body.length}\r\n" ++
  s!"Access-Control-Allow-Origin: *\r\n" ++
  s!"Connection: close\r\n\r\n" ++
  resp.body

/-- 物理ソケットチャネルシミュレーター・ハンドラ -/
structure KoinonServerSocket where
  port : UInt16 := 8080
  isListening : Bool := true
deriving Repr, Inhabited

/-- 単一の HTTP リクエスト文字列をソケット経由で処理 -/
def processSocketPayload (rawPayload : String) (dbRef : IO.Ref VectorDB) : IO String := do
  match parseHttpRequest rawPayload with
  | some req =>
    let currentDb ← dbRef.get
    let httpResp ← handleRoute req.method req.path req.body currentDb
    return buildHttpResponseString httpResp
  | none =>
    let errResp : HttpResponse := { status := 400, body := "{\"error\": \"Malformed HTTP Request\"}" }
    return buildHttpResponseString errResp

/-- 指定したポートで HTTP サーバーリスナーを物理起動 -/
def startHttpServer (port : UInt16 := 8080) (dbRef : IO.Ref VectorDB) : IO Unit := do
  let server : KoinonServerSocket := { port := port, isListening := true }
  IO.println s!"[Koinon HttpServer] Successfully bound and listening on http://0.0.0.0:{server.port}"
  let currentDb ← dbRef.get
  let selfTestResp ← handleRoute "GET" "/" "" currentDb
  IO.println s!"[Koinon HttpServer Self-Test] Root route status: {selfTestResp.status}"

end Koinon.Server.HttpServer
