import Lean
import Koinon.Server.Router
import Lyceum.Memory.VectorDB

namespace Koinon.Server.HttpServer

open Lean
open Koinon.Server

/-- HTTP リクエストヘッダー構造体 -/
structure RawHttpRequest where
  method : String
  path : String
  headers : List (String × String)
  body : String
deriving Repr, Inhabited

/-- 簡易 HTTP リクエストライン ＆ ヘッダーパース -/
def parseHttpRequest (raw : String) : Option RawHttpRequest := Id.run do
  let parts := raw.splitOn "\r\n\r\n"
  let headerPart := parts.head?.getD ""
  let body := if parts.length > 1 then String.intercalate "\r\n\r\n" parts.tail! else ""
  
  let lines := headerPart.splitOn "\r\n"
  match lines.head?.map (·.splitOn " ") with
  | some [meth, path, _ver] =>
      return some { method := meth, path := path, headers := [], body := body }
  | _ => return none

/-- HTTP レスポンスをフォーマットされたソケットデータ文字列へ変換 -/
def formatHttpResponse (resp : HttpResponse) : String :=
  s!"HTTP/1.1 {resp.status} OK\r\n" ++
  s!"Content-Type: {resp.contentType}\r\n" ++
  s!"Content-Length: {resp.body.toUTF8.size}\r\n" ++
  s!"Access-Control-Allow-Origin: *\r\n" ++
  s!"Connection: close\r\n\r\n" ++
  resp.body

/-- 単一ソケットリクエストを処理してレスポンス文字列を生成する -/
def processRawRequest (rawInput : String) (db : Lyceum.Memory.VectorDB) : IO String := do
  match parseHttpRequest rawInput with
  | some req =>
      let resp ← handleRoute req.method req.path req.body db
      return formatHttpResponse resp
  | none =>
      let errResp : HttpResponse := { status := 400, body := "{\"error\": \"Malformed HTTP Request\"}" }
      return formatHttpResponse errResp

end Koinon.Server.HttpServer
