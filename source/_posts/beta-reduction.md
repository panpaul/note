---
title: 使用Coq实现β-reduction
date: 2020-03-29 15:44:51
tags: Coq
---

如果问为什么要写这个？（~~其实是离散数学的作业~~）

<!--more-->

先做一些准备工作，把有关`λ演算`（~~我上课学过这个吗？~~）的东西定义出来。

```Coq
Require Import String.

Open Scope string_scope.

Check "x".

Inductive lambda : Set :=
| Var : string -> lambda
| App : lambda -> lambda -> lambda
| Abs : string -> lambda -> lambda
.

Delimit Scope lambda_scope with lambda.
Open Scope lambda_scope.


Notation "x ':' c2" := (Abs x c2)
  (at level 20, right associativity) : lambda_scope.
Notation "c1 ';' c2" := (App c1 c2)
  (at level 10, left associativity) : lambda_scope.

Notation "# x" := (Var x)
  (at level 5, no associativity) : lambda_scope.

Check # "x"; # "y".

Check ("x" : #"x"; #"y").
```

然后是构建几个辅助用的函数。这里`bound`用于找出受约束的变量，`fv`用于找出不受约束的变量，`s_is_free_for_x`是对`fv`的简单包装。

```Coq
Require Export List.
Import ListNotations.

Fixpoint bound term :=
  match term with 
  | # _ => []
  | x : t1 => x :: bound t1
  | t1 ; t2 =>  (bound t1) ++ (bound t2)
  end.

Fixpoint fv term :=
  match term with 
  | # x => [x]
  | x : t1 => remove string_dec x (fv t1)
  | t1 ; t2 =>  (fv t1) ++ (fv t2)
  end.

Compute fv ("x" : (#"x"); (#"y")).

Definition find_x l x :=
  let f y := if (string_dec x y) then true else false in
           find f l.

(* for the substitution (λx.(...y...))[s/y], to avoid
   side effect, s must have no free occurrence of x *)

Definition s_is_free_for_x s x :=
  let fv_in_s := fv s in  
  if find_x fv_in_s x then true else false.

Compute s_is_free_for_x  ("x" : (#"x"); (#"y")) "y".
```

接着是用于执行替换的函数。这里需要说明，在执行替换时可能需要进行`α-conversion`给变量重命名，但是由于`Coq`的一些原因，使得生成一个新的未出现过的变量较为复杂（与老师讨论后没有得到什么好的方案），故~~忽略了~~（犯下了）可能替换重名的错误。

```Coq
(* substition t[s/x] : no occurrence check! *)
Fixpoint substitution t x s :=
  match t with 
  | # v => if string_dec v x then s else t 
  | v : t1 => if string_dec v x then t
             else (* if s_is_free_for_x s v then
                     # "side effect: must do alpha conversion"
                   else *)
                    v : substitution t1 x s
  | t1 ; t2 => (substitution t1 x s) ; (substitution t2 x s)
  end.
  
Compute substitution ("y" : (#"x"); (#"y")) "x" ("x": #"x") .
```

再者，就是`β-reduction`的主体了。（有两种实现方式，其中那个`normal_step`就是作业要求补全的内容）

```Coq
(* reduction Innermost rightmost *)
Fixpoint inright_step t :=
  match t with
  | # v => None
  | v : t1 => let t1' := inright_step t1 in
             match t1' with
             | None => None
             | Some t1'' => Some  (v : t1'') 
             end
  | t1 ; t2 => let t2' := inright_step t2 in
              match t2' with
              | None => let t1' := inright_step t1 in
                       (* high risk of capture error *)
                       match t1' with
                       | None => match t1 with
                                | x : t1'' => Some (substitution' t1'' x t2)
                                | _ => None
                                end
                       | Some t1'' => Some (t1''; t2)
                       end
              | Some t2'' => Some (t1; t2'')
              end
  end.

(* reduction call_by _value *)
Fixpoint cbv t :=
  match t with
  | # v => None
  | v : t1 => let t1' := cbv t1 in
             match t1' with
             | None => None
             | Some t1'' => Some  (v : t1'') 
             end
  | t1 ; t2 => let t2' := cbv t2 in
              match t2' with
              | None => match t1 with
                       | v : t1' =>  Some (substitution t1' v t2)
                       | _ => match cbv t1 with
                             | None  => None
                             | Some t1'  => Some (t1'; t2)
                             end
                       end
              | Some t2'' => Some (t1; t2'')
              end
  end.

(* normal reduction: Outmost leftmost (call by name) 
   search the subterm of form ...((λx.M) ; N)... 
   (called a redex), then do the substitution M[N/x], 
   so called beta-reduction, then returns
   Some (...(M[N/x]...); if no redex, returns None.

   Outmost leftmost strategy is:

   recursive call normal_step t with:

   if term t is of form
   1/ (λx.M) N: return Some (M[N/y])
   2/ M N : M is not an abstraction
            if normal_step M return Some M',
            then return Some (M' N)
            else if normal_step N return Some N'
                 then return Some (M N')
                 else return None
   3/ (λx.M) : if normal_step M return Some M'
               then return Some (λx.M')
               else return None
   3/ x : return None
 *)

Fixpoint normal_step t:=
  match t with
  | t1 ; t2 => match t1 with
    | x : t1' => Some (substitution t1' x t2)
    | _ => let t1' := normal_step t1 in
      match t1' with
      | Some t1'' => Some (t1'' ; t2)
      | None => let t2' := normal_step t2 in
        match t2' with
        | None => None
        | Some t2'' => Some (t1 ; t2'')
        end
      end
    end
  | # v => None
  | v : t1 => let t1' := normal_step t1 in
    match t1' with
    | Some t1'' => Some (v : t1'')
    | None => None
    end
  end.
```

最后使用定义好的东西，执行`λ演算`试一下。（由于`Coq`不允许无限递归，所以我们老师引入`step`的机制控制递归调用的次数）

```Coq
(* define the variable used in Church Numerals *)
Definition x := # "x".
Definition y := # "y".
Definition z := # "z".
Definition a := # "a".
Definition b := # "b".
Definition c := # "c".
Definition m := # "m".
Definition n := # "n".
Definition f := # "f".
Definition p := # "p".

(* λfx.x *)
Definition ZERO := "f": "x": x.

(* λn.λfx.f(nfx) *)
Definition SUCC := "n": "f": "x": f; (n; f; x).

Compute SUCC.

Fixpoint steps (strategy: lambda -> option lambda) n count t :=
  match n with
  | 0 => (t, count) 
  | S n' => let t' := strategy t in
           match t' with
           | None => (t, count)
           | Some t'' => steps strategy n' (S count) t''
           end
  end.

Definition normal_steps n t := steps normal_step n 0 t.

Definition inright_steps n t := steps inright_step n 0 t. 

Definition cbv_steps n t := steps cbv n 0 t.

Compute cbv_steps 10  (SUCC; ZERO).

Theorem  church_rosser_ex01 : fst (cbv_steps 10 (SUCC; ZERO))
                              = fst (normal_steps 10 (SUCC; ZERO)).
Proof.
  simpl.
  reflexivity.
Qed.  

Definition ONE := SUCC; ZERO.

Definition TWO := SUCC; ONE.

Definition THREE := SUCC; TWO.

Definition FOUR := SUCC; THREE.

Definition FIVE := SUCC; FOUR.

(* ADD = λab.a SUCC b *) 
Definition ADD := "a": "b": (a; SUCC); b.

(* ADD' = λab.λfx.af(bfx) *)
Definition ADD' := "a": "b": "f" :"x": a; f; (b; f; x).

(* MULT = λab.a (ADD b) ZERO *)
Definition MULT := "a": "b": a; (ADD; b); ZERO.


Theorem  church_rosser_ex02 :
   fst (cbv_steps 100 (MULT; TWO; TWO))
 = fst (normal_steps 150 (MULT; TWO; TWO)).
Proof.
  simpl.
  reflexivity.
Qed.  

Compute (cbv_steps 200 (MULT; FOUR; FOUR)).
(* 53 steps *)

Compute steps inright_step 200 0 (MULT; FOUR; FOUR).
(* side effect occurs *)

(* TRUE = λxy.x *)
Definition TRUE := "x": "y": x.

(* FALSE = λxy.y *)
Definition FALSE := "x": "y": y.

(* LIF = λabc.abc *)
Definition LIF := "a": "b": "c":  a; b; c.

(* OR = λab.LIF a TRUE b *)
Definition OR := "a": "b": LIF; a; TRUE; b.

(* AND = λab.LIF a b FALSE *)
Definition AND := "a": "b": LIF; a; FALSE; b.

(* NOT = λa.LIF a FALSE TRUE *)
Definition NOT := "a": "b": LIF; a; FALSE; TRUE.

(* PAIR = λab.λx.IF x a b *)
Definition PAIR := "a": "b": "x": LIF; x; a; b.

(* FST = λa.a TRUE *)
Definition FST := "a": a; TRUE.

(* SND = λa.a FALSE *)
Definition SND := "a": a; FALSE.

(* PRED = λnfx.SND (n(λp.PAIR (f (FST p)) (FST p)) (PAIR x x)) *)
Definition PRED := "n": "f": "x": SND; (n;
                   ("p": PAIR; (f; (FST; p)); (FST; p))
                  ; (PAIR; x; x)).

(* ISZERO = λn.n (λx.FALSE) TRUE *)
Definition ISZERO := "n": n; ("x": FALSE); TRUE.

(* Y combinator:
   https://en.wikipedia.org/wiki/Fixed-point_combinator *)

(* FIX = λf.(λx.f(xx))(λx.f(xx)) *)
Definition FIX := "f": ("x": f; (x; x));  ("x": f; (x; x)).

Compute normal_steps 10 FIX.
Compute normal_steps 20 FIX.

(* diverge *)

(* SUM = FIX (λfn.LIF (ISZERO n) ZERO (ADD n (f (PRED n)))) *)
Definition SUM := FIX; ("f": "n": LIF; (ISZERO; n); ZERO;
                          (ADD; n; (f; (PRED; n)))).
   

Compute normal_steps 1000  (SUM; FOUR).
(* 786 steps to converge *)

(* FACT = FIX (λfn.LIF (ISZERO n) ONE (MULT n (f (PRED n)))) *)
Definition FACT := FIX; ("f": "n": LIF; (ISZERO; n); ONE;
                           (MULT; n; (f; (PRED; n)))).

Compute normal_steps 3000  (FACT; THREE).
(* 2109 to converge *)

(* cbv will diverge! *)
Compute cbv_steps 10  (SUM; ZERO).
Compute cbv_steps 100  (SUM; ZERO).

Compute normal_steps 20  (SUM; ZERO).
(* converge in 12 steps *)
```

最后不得不说，这次作业，虽然说是完成了，但是感觉知识上相差的还是太多。对于`λ演算`以及`丘奇计数`的了解太少。以后等有时间再学习并写一些关于这两者的笔记吧！