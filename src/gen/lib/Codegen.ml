(*
   Emit OCaml code for parsing.
*)

open Printf

let save filename data =
  let oc = open_out filename in
  output_string oc data;
  close_out oc

let make_dir path =
  if not (Sys.file_exists path) then
    Unix.mkdir path 0o777

let make_lib_dir opt_dir =
  let dir =
    match opt_dir with
    | None -> "lib"
    | Some path -> Filename.concat path "lib"
  in
  make_dir dir;
  dir

let make_bin_dir opt_dir =
  let dir =
    match opt_dir with
    | None -> "bin"
    | Some path -> Filename.concat path "bin"
  in
  make_dir dir;
  dir

let make_lib_path opt_dir filename =
  Filename.concat (make_lib_dir opt_dir) filename

let make_bin_path opt_dir filename =
  Filename.concat (make_bin_dir opt_dir) filename

let generate_main ~lang ~lib_module_name ~cst_module_name ~parse_module_name =
  sprintf "\
(* Generated by ocaml-tree-sitter. *)

open %s

let () =
  Tree_sitter_run.Main.run
    ~lang:%S
    ~parse_source_file:%s.parse_source_file
    ~parse_input_tree:%s.parse_input_tree
    ~dump_tree:%s.dump_tree
"
    lib_module_name
    lang
    parse_module_name
    parse_module_name
    cst_module_name

let ocaml ?out_dir ~lang grammar =
  let cst_module_name = "CST" in
  let parse_module_name = "Parse" in
  let boilerplate_module_name = "Boilerplate" in
  let main_module_name = "Main" in
  let cst_ml = make_lib_path out_dir (sprintf "%s.ml" cst_module_name) in
  let parse_ml = make_lib_path out_dir (sprintf "%s.ml" parse_module_name) in
  let parse_mli = make_lib_path out_dir (sprintf "%s.mli" parse_module_name) in
  let boilerplate_ml =
    make_lib_path out_dir (sprintf "%s.ml" boilerplate_module_name) in
  let main_ml = make_bin_path out_dir (sprintf "%s.ml" main_module_name) in
  let lib_module_name = sprintf "Tree_sitter_%s" lang in

  let cst_code = Codegen_CST.generate grammar in
  let parse_mli_code, parse_ml_code =
    Codegen_parse.generate grammar ~cst_module_name in
  let boilerplate_code =
    Codegen_boilerplate.generate grammar ~cst_module_name in
  let main_code =
    generate_main ~lang ~lib_module_name ~cst_module_name ~parse_module_name in
  save cst_ml cst_code;
  save parse_mli parse_mli_code;
  save parse_ml parse_ml_code;
  save boilerplate_ml boilerplate_code;
  save main_ml main_code
