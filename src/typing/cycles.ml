(*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

open Name_def_ordering

let handle_element cx elt =
  match elt with
  | Normal _
  | Resolvable _ ->
    ()
  | Illegal { reason; recursion; payload = _; annot_locs } ->
    Flow_js.add_output cx (Error_message.ERecursiveDefinition { reason; recursion; annot_locs })

let handle_component cx scc =
  match scc with
  | Singleton elt -> handle_element cx elt
  | ResolvableSCC elts -> Nel.iter (handle_element cx) elts
  | IllegalSCC elts_blame ->
    let blame =
      Nel.map
        (fun { payload = elt; reason; recursion = blame; annot_locs } ->
          handle_element cx elt;
          (reason, blame, annot_locs))
        elts_blame
    in
    Flow_js.add_output cx Error_message.(EDefinitionCycle blame)
