let limit = ref 1000

let rec iter n e = (* 最適化処理をくりかえす (caml2html: main_iter) *)
  Format.eprintf "iteration %d@." n;
  if n = 0 then e else
  let e' = Elim.f (ConstFold.f (Inline.f (Assoc.f (Beta.f e)))) in
  if e = e' then e else
  iter (n - 1) e'

(*型を出力する関数*)
let rec printf_type oc = function
  | Unit -> Printf.fprintf oc "Unit\t"
  | Bool -> Printf.fprintf oc "Bool\t"
  | Int -> Printf.fprintf oc "Int\t"
  | Float -> Printf.fprintf oc "Float\t"
  | Fun (e1,e2) -> (Printf.fprintf oc "Fun\t(");(List.iter (printf_type oc) e1);(Printf.fprintf oc ",");printf_type oc e2;(Printf.fprintf oc ")")
  | Tuple e -> (Printf.fprintf oc "Tuple\t");(List.iter (printf_type oc) e)
  | Array e -> (Printf.fprintf oc "Array\t");printf_type oc e
  | Var {contents = None} ->(Printf.fprintf oc "Var\t{contents = None}")
  | Var {contents = Some x} ->(Printf.fprintf oc "Var\t{contents = Some ");printf_type oc x;(Printf.fprintf oc "}")

(*syntaxを出力する関数*)
let rec printf_syntax oc = function
  | Not(e) -> Printf.fprintf oc "Not\n";(printf_syntax oc e)
  | Neg(e) -> Printf.fprintf oc "Neg\n";(printf_syntax oc e)
  | Add(e1, e2) -> Printf.fprintf oc "Add\n";(printf_syntax oc e1);(printf_syntax oc e2)
  | Sub(e1, e2) -> Printf.fprintf oc "Sub\n";(printf_syntax oc e1);(printf_syntax oc e2)
  | Eq(e1, e2) -> Printf.fprintf oc "Eq\n";(printf_syntax oc e1);(printf_syntax oc e2)
  | LE(e1, e2) -> Printf.fprintf oc "LE\n";(printf_syntax oc e1);(printf_syntax oc e2)
  | FNeg(e) -> Printf.fprintf oc "FNeg\n";(printf_syntax oc e)
  | FAdd(e1, e2) -> Printf.fprintf oc "FAdd\n";(printf_syntax oc e1);(printf_syntax oc e2)
  | FSub(e1, e2) -> Printf.fprintf oc "FSub\n";(printf_syntax oc e1);(printf_syntax oc e2)
  | FMul(e1, e2) -> Printf.fprintf oc "FMul\n";(printf_syntax oc e1);(printf_syntax oc e2)
  | FDiv(e1, e2) -> Printf.fprintf oc "FDiv\n";(printf_syntax oc e1);(printf_syntax oc e2)
  | If(e1, e2, e3) -> Printf.fprintf oc "If\n";(printf_syntax oc e1);(printf_syntax oc e2);(printf_syntax oc e3)
  | Let(e1, e2, e3) -> Printf.fprintf oc "Let\n";(printf_syntax oc e1);(printf_syntax oc e2);(printf_syntax oc e3)
  | LetRec({ name = xt; args = yts; body = e1 }, e2) ->
      LetRec({ name = deref_id_typ xt;
               args = List.map deref_id_typ yts;
               body = deref_term e1 },
             deref_term e2)
  | App(e, es) -> App(deref_term e, List.map deref_term es)
  | Tuple(es) -> Tuple(List.map deref_term es)
  | LetTuple(xts, e1, e2) -> LetTuple(List.map deref_id_typ xts, deref_term e1, deref_term e2)
  | Array(e1, e2) -> Array(deref_term e1, deref_term e2)
  | Get(e1, e2) -> Get(deref_term e1, deref_term e2)
  | Put(e1, e2, e3) -> Put(deref_term e1, deref_term e2, deref_term e3)
  | Int e -> "%s" e
  | Bool e ->
  | Float e ->
  | Unit -> "Unit"
let lexbuf outchan l = (* バッファをコンパイルしてチャンネルへ出力する (caml2html: main_lexbuf) *)
  Id.counter := 0;
  Typing.extenv := M.empty;
  Emit.f outchan
    (RegAlloc.f
       (Simm.f
          (Virtual.f
             (Closure.f
                (iter !limit
                   (Alpha.f
                      (KNormal.f
                         (Typing.f
                            (Parser.exp Lexer.token l)))))))))

let syntaxbuf outchan l = (* バッファをコンパイルしてチャンネルへ出力する (caml2html: main_lexbuf) *)
  Id.counter := 0;
  Typing.extenv := M.empty;
	Printf.fprintf outchan "%s" (Parser.exp Lexer.token l)

let lexbuf outchan l = (* バッファをコンパイルしてチャンネルへ出力する (caml2html: main_lexbuf) *)
  Id.counter := 0;
  Typing.extenv := M.empty;
  Emit.f outchan
    (RegAlloc.f
       (Simm.f
          (Virtual.f
             (Closure.f
                (iter !limit
                   (Alpha.f
                      (KNormal.f
                         (Typing.f
                            (Parser.exp Lexer.token l)))))))))

let string s = lexbuf stdout (Lexing.from_string s) (* 文字列をコンパイルして標準出力に表示する (caml2html: main_string) *)

let file f = (* ファイルをコンパイルしてファイルに出力する (caml2html: main_file) *)
  let inchan = open_in (f ^ ".ml") in
  let outchan = open_out (f ^ ".s") in
  let syntaxchan = open_out (f ^ "_s.txt") in
  try
    lexbuf outchan (Lexing.from_channel inchan);
    syntaxbuf syntaxchan (Lexing.from_channel inchan);
    close_in inchan;
    close_out outchan;
    close_out syntaxchan;
  with e -> (close_in inchan; close_out outchan; raise e)

let () = (* ここからコンパイラの実行が開始される (caml2html: main_entry) *)
  let files = ref [] in
  Arg.parse
    [("-inline", Arg.Int(fun i -> Inline.threshold := i), "maximum size of functions inlined");
     ("-iter", Arg.Int(fun i -> limit := i), "maximum number of optimizations iterated")]
    (fun s -> files := !files @ [s])
    ("Mitou Min-Caml Compiler (C) Eijiro Sumii\n" ^
     Printf.sprintf "usage: %s [-inline m] [-iter n] ...filenames without \".ml\"..." Sys.argv.(0));
  List.iter
    (fun f -> ignore (file f))
    !files
