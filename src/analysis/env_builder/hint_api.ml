(*
 * Copyright (c) Meta Platforms, Inc. and affiliates.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

(* In contextual typing we often need to perform decompositions on type hints before
 * we descend deeper into an expression during type checking. For example if an
 * object literal `{ f: (x) => x + 1 }` is checked with a hint `{ f: (number) => number }`
 * then we can check the value of property `f` with the hint `(number) => number`
 * and, further, use `number` as the type of `x`. *)

type ('t, 'targs, 'args) fun_call_implicit_instantiation_hints = {
  reason: Reason.t;
  return_hint: ('t, 'targs, 'args) hint;
  targs: 'targs Lazy.t;
  arg_list: 'args Lazy.t;
  arg_index: int;
}

and sentinel_refinement =
  | SingletonNum of float
  | SingletonBool of bool
  | SingletonStr of string
  | Null
  | Void
  | Member of Reason.t

and ('t, 'targs, 'args) hint_decomposition =
  (* Hint on `{ f: e }` becomes hint on `e` *)
  | Decomp_ObjProp of string
  (* Hint on `{ [k]: e }` becomes hint on `e` *)
  | Decomp_ObjComputed
  (* Hint on `{ ...e }` becomes hint on `e` *)
  | Decomp_ObjSpread
  (* Hint on array literal `[e]` becomes hint on `e` *)
  | Decomp_ArrElement of int
  (* Hint on array literal `[...e]` becomes hint on `e` *)
  | Decomp_ArrSpread of int
  (* Type of `await e` becomes hint on `e` *)
  | Decomp_Await
  (* Type of `o` in `o.m(..)` becomes the type of `o.m` *)
  | Decomp_MethodName of string
  (* Type of `o` in `o.#m(..)` becomes the type of `o.m` *)
  | Decomp_MethodPrivateName of string * ALoc.t list
  (* Type of `o` in `o[e](..)` becomes the type of `o[e]` *)
  | Decomp_MethodElem
  (* Type of `C` in `new C(..)` becomes the type of the constructor of C *)
  | Decomp_CallNew
  (* Type of the super-class becomes the type of the super constructor *)
  | Decomp_CallSuper
  (* Type of function becomes hint on the i-th argument *)
  | Decomp_FuncParam of int
  (* Type of function becomes hint on rest argument *)
  | Decomp_FuncRest of int (* number of params before rest params *)
  (* Type of function becomes hint on return *)
  | Decomp_FuncReturn
  (* Hint on call `f()` becomes hint on `f`. This is only meant to be used for the
   * case of immediate function call `(function() {})()`. *)
  | Comp_ImmediateFuncCall
  (* Type of C in `<C [props]/>` becomes hint on `props` *)
  | Decomp_JsxProps
  | Decomp_SentinelRefinement of sentinel_refinement SMap.t
  (* Type of f in f(...) is instantiated with arguments and return hint.
     Returns f if the type of f is not polymorphic. *)
  | Instantiate_Callee of ('t, 'targs, 'args) fun_call_implicit_instantiation_hints

and ('t, 'targs, 'args) hint =
  | Hint_t of 't
  | Hint_Decomp of (int * ('t, 'targs, 'args) hint_decomposition) Nel.t * 't
  (* The hint placeholder used in env_resolution to pass to expression type checkers.
     It will eventually be removed once we move all hint decomposition logic into env_resolution. *)
  | Hint_Placeholder
  | Hint_None

let string_of_hint_unknown_kind = function
  | Decomp_ObjProp _ -> "Decomp_ObjProp"
  | Decomp_ObjComputed -> "Decomp_ObjComputed"
  | Decomp_ObjSpread -> "Decomp_ObjSpread"
  | Decomp_ArrElement i -> Utils_js.spf "Decomp_ArrElement (%d)" i
  | Decomp_ArrSpread i -> Utils_js.spf "Decomp_ArrSpread (%d)" i
  | Decomp_MethodName _ -> "Decomp_MethodName"
  | Decomp_MethodPrivateName _ -> "Decomp_MethodPrivateName"
  | Decomp_MethodElem -> "Decomp_MethodElem"
  | Decomp_CallNew -> "Decomp_CallNew"
  | Decomp_CallSuper -> "Decomp_CallSuper"
  | Decomp_FuncParam i -> Utils_js.spf "Decomp_FuncParam (%d)" i
  | Decomp_FuncRest i -> Utils_js.spf "Decomp_FuncRest (%d)" i
  | Decomp_FuncReturn -> "Decomp_FuncReturn"
  | Comp_ImmediateFuncCall -> "Comp_ImmediateFuncCall"
  | Decomp_JsxProps -> "Decomp_JsxProps"
  | Decomp_SentinelRefinement _ -> "Decomp_SentinelRefinement"
  | Decomp_Await -> "Decomp_Await"
  | Instantiate_Callee _ -> "Instantiate_Callee"

let string_of_hint ~on_hint = function
  | Hint_t t -> Utils_js.spf "Hint_t (%s)" (on_hint t)
  | Hint_Decomp (ops, t) ->
    Utils_js.spf
      "Hint_Decomp (%s)(%s)"
      (Nel.map (fun (_, op) -> string_of_hint_unknown_kind op) ops
      |> Nel.to_list
      |> String.concat ", "
      )
      (on_hint t)
  | Hint_Placeholder -> "Hint_Placeholder"
  | Hint_None -> "Hint_None"

let decompose_hint decomp = function
  | Hint_t t -> Hint_Decomp (Nel.one (Reason.mk_id (), decomp), t)
  | Hint_Decomp (decomps, t) -> Hint_Decomp (Nel.cons (Reason.mk_id (), decomp) decomps, t)
  | Hint_Placeholder -> Hint_Placeholder
  | Hint_None -> Hint_None

let merge_hints h1 h2 =
  match h1 with
  | Hint_t _
  | Hint_Decomp _
  | Hint_Placeholder ->
    h1
  | Hint_None -> h2

let is_hint_none = function
  | Hint_None -> true
  | _ -> false

let rec map_decomp_op ~map_base_hint ~map_targs ~map_arg_list = function
  | Decomp_ObjProp prop -> Decomp_ObjProp prop
  | Decomp_ObjComputed -> Decomp_ObjComputed
  | Decomp_ObjSpread -> Decomp_ObjSpread
  | Decomp_ArrElement o -> Decomp_ArrElement o
  | Decomp_ArrSpread o -> Decomp_ArrSpread o
  | Decomp_Await -> Decomp_Await
  | Decomp_MethodName name -> Decomp_MethodName name
  | Decomp_MethodPrivateName (name, class_stack) -> Decomp_MethodPrivateName (name, class_stack)
  | Decomp_MethodElem -> Decomp_MethodElem
  | Decomp_CallNew -> Decomp_CallNew
  | Decomp_CallSuper -> Decomp_CallSuper
  | Decomp_FuncParam i -> Decomp_FuncParam i
  | Decomp_FuncRest i -> Decomp_FuncRest i
  | Decomp_FuncReturn -> Decomp_FuncReturn
  | Comp_ImmediateFuncCall -> Comp_ImmediateFuncCall
  | Decomp_JsxProps -> Decomp_JsxProps
  | Decomp_SentinelRefinement checks -> Decomp_SentinelRefinement checks
  | Instantiate_Callee { reason; return_hint; targs; arg_list; arg_index } ->
    Instantiate_Callee
      {
        reason;
        return_hint = map ~map_base_hint ~map_targs ~map_arg_list return_hint;
        targs = Lazy.map map_targs targs;
        arg_list = Lazy.map map_arg_list arg_list;
        arg_index;
      }

and map ~map_base_hint ~map_targs ~map_arg_list = function
  | Hint_t t -> Hint_t (map_base_hint t)
  | Hint_Decomp (ops, t) ->
    Hint_Decomp
      ( Nel.map (fun (i, op) -> (i, map_decomp_op ~map_base_hint ~map_targs ~map_arg_list op)) ops,
        map_base_hint t
      )
  | Hint_Placeholder -> Hint_Placeholder
  | Hint_None -> Hint_None
