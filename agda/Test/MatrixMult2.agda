{-# OPTIONS --prop #-}
module Test.MatrixMult2 where
open import Data.Bool renaming (_≟_ to _≟B_)
open import Data.Field
open import Data.Field.Prime
open import Data.Fin hiding (_≟_; _+_)
open import Data.Fin.Properties hiding (≤-trans)
open import Data.List hiding (splitAt; map)
open import Data.MaybeC 
import Data.Map
module M = Data.Map
open import Data.Map using (Map)
open import Data.Nat renaming (_≟_ to _ℕ≟_)
open import Data.Nat.DivMod
open import Data.Nat.Primality
open import Data.Nat.Properties
open import Data.Nat.Show renaming (show to showℕ)
open import Data.Product hiding (map)
open import Data.ProductPrime
open import Data.Unit hiding (_≟_)
open import Data.Vec hiding (_>>=_; splitAt) renaming (_++_ to _V++_)
open import Data.Vec.Split
open import Function

open import Relation.Binary.PropositionalEquality
open import Relation.Nullary
open import Relation.Nullary.Decidable hiding (map)

open import TypeClass.Ord

N = 21888242871839275222246405745257275088548364400416034343698204186575808495617

choice = 1
input1 = 99
input2 = 100
input3 = 384
input4 = 390

postulate
  nPrime : Prime N

FF = PrimeField N
FField = isField N nPrime
FFinite = isFinite N nPrime

open Field FField renaming ( _+_ to _+F_
                           ; _*_ to _*F_
                           ; -_ to -F_
                           ; 1/_ to 1F/_
                           ; zero to zerof
                           ; one to onef)


open import Language.Common


module Test where
  open import Language.Source FF FFinite (λ x → showℕ (PrimeField.elem x) )
  open import Language.Source.Utils FF FFinite (λ x → showℕ (PrimeField.elem x) )
  open import Language.TySize FF FFinite
  open import Language.Universe FF

  _**_ : ℕ → ℕ → ℕ
  m ** zero = 1
  m ** suc n = (m ** n) * m

  data Bits : ℕ → Set where
    zero one : Bits 1
    0+ : ∀ {n} → Bits n → Bits (suc n)
    1+ : ∀ {n} → Bits n → Bits (suc n)

  data BitsR : ℕ → Set where
    zero one : BitsR 1
    2n : ∀ {n} → BitsR n → BitsR (suc n)
    2n+1 : ∀ {n} → BitsR n → BitsR (suc n)

  bitsToℕAux : ∀ {n} → Bits n → ℕ → ℕ
  bitsToℕAux zero acc = acc * 2
  bitsToℕAux one acc = acc * 2 + 1
  bitsToℕAux (0+ b) acc = bitsToℕAux b (acc * 2)
  bitsToℕAux (1+ b) acc = bitsToℕAux b (acc * 2 + 1)

  bitsToℕ : ∀ {n} → Bits n → ℕ
  bitsToℕ b = bitsToℕAux b 0

  /Fin2 : ∀ {n} → Fin (2 ** (suc n)) → Fin (2 ** n)
  /Fin2 {n} f = fromℕ≤ {toℕ f / 2} (*-cancelʳ-< (toℕ f / 2) (2 ** n) (≤-trans (s≤s (m/n*n≤m (toℕ f) 2)) (toℕ<n f)))

  %Fin2 : ∀ {n} → Fin (suc n) → Bool
  %Fin2 f with toℕ f % 2 
  %Fin2 f | 0F = false
  %Fin2 f | suc a = true

  **-suc : ∀ n → ∃ (λ m → 2 ** n ≡ suc m)
  **-suc 0F = 0F , refl
  **-suc (suc n) with **-suc n
  ... | m , prf rewrite prf = suc (m * 2F) , refl
  
  Fin2→BitsR : ∀ n → Fin (2 ** (suc n)) → BitsR (suc n)
  Fin2→BitsR 0F 0F = zero
  Fin2→BitsR 0F 1F = one
  Fin2→BitsR (suc n) f with **-suc (suc (suc n))
  Fin2→BitsR (suc n) f | m , prf with %Fin2 (subst Fin prf f)
  Fin2→BitsR (suc n) f | _       | false = 2n (Fin2→BitsR n (/Fin2 {suc n} f))
  Fin2→BitsR (suc n) f | _       | true = 2n+1 (Fin2→BitsR n (/Fin2 {suc n} f))

  BitsR→BitsAux : ∀ {m n} → BitsR m → Bits n → Bits (m + n)
  BitsR→BitsAux zero acc = 0+ acc
  BitsR→BitsAux one acc = 1+ acc
  BitsR→BitsAux {suc m} {n} (2n b) acc rewrite sym (+-suc m n) = BitsR→BitsAux b (0+ acc)
  BitsR→BitsAux {suc m} {n} (2n+1 b) acc rewrite sym (+-suc m n) = BitsR→BitsAux b (1+ acc)

  BitsR→Bits : ∀ {m} → BitsR m → Bits m
  BitsR→Bits zero = zero
  BitsR→Bits one = one
  BitsR→Bits {suc m} (2n b) rewrite +-comm 1 m = BitsR→BitsAux b zero
  BitsR→Bits {suc m} (2n+1 b) rewrite +-comm 1 m = BitsR→BitsAux b one

  Fin2→Bits : ∀ n → Fin (2 ** (suc n)) → Bits (suc n)
  Fin2→Bits n f = BitsR→Bits (Fin2→BitsR n f)

  Σₙ'F : (ℕ → U) → ℕ → ℕ → ⟦ `Two ⟧ → U
  Σₙ' : (ℕ → U) → ℕ → ℕ → U
  
  Σₙ'F ty m acc false = Σₙ' ty m (acc * 2)
  Σₙ'F ty m acc true = Σₙ' ty m (acc * 2 + 1)

  Σₙ' ty 0 acc = ty acc
  Σₙ' ty (suc m) acc = `Σ `Two (Σₙ'F ty m acc)

  Σₙ : (ℕ → U) → ℕ → U
  Σₙ ty m = Σₙ' ty m 0

  ΣₙIndSizeAux : (ty : ℕ → U) (n acc : ℕ) → Vec ℕ (tySize (Σₙ' ty n acc)) → Vec ℕ n
  ΣₙIndSizeAux ty 0F acc vec = []
  ΣₙIndSizeAux ty (suc n) acc vec with splitAt (tySize `Two) vec
  ... | fst ∷ [] , snd with maxTySplit `Two false (Σₙ'F ty n acc) snd
  ... | snd₁ , snd₂ = fst ∷ ΣₙIndSizeAux ty n (acc * 2) snd₁

  ΣₙIndSize : (ty : ℕ → U) (n : ℕ) → Vec ℕ (tySize (Σₙ ty n)) → Vec ℕ n
  ΣₙIndSize ty n vec = ΣₙIndSizeAux ty n 0 vec

  ΣₙLitSizeAux : (ty : ℕ → U) (n acc : ℕ) → ⟦ Σₙ' ty n acc ⟧ → Vec ⟦ `Base ⟧ n
  ΣₙLitSizeAux ty 0 acc lit = []
  ΣₙLitSizeAux ty (suc n) acc (false , snd₁) = fieldElem nPrime 0 ∷ ΣₙLitSizeAux ty n (acc * 2) snd₁
  ΣₙLitSizeAux ty (suc n) acc (true , snd₁) = fieldElem nPrime 1 ∷ ΣₙLitSizeAux ty n (acc * 2 + 1) snd₁

  ΣₙLitSize : (ty : ℕ → U) (n : ℕ) → ⟦ Σₙ ty n ⟧ → Vec ⟦ `Base ⟧ n
  ΣₙLitSize ty n lit = ΣₙLitSizeAux ty n 0 lit

  ΣₙSize : (ty : ℕ → U) (n : ℕ) → Source (Σₙ ty n) → Vec (Source `Two) n
  ΣₙSize ty n s = ΣₙSizeAux n 0 s
    where
      ΣₙSizeAux : (n acc : ℕ) → Source (Σₙ' ty n acc) → Vec (Source `Two) n
      ΣₙSizeAux 0F acc s = []
      ΣₙSizeAux (suc n) acc (Ind refl x₁) with splitAt (tySize `Two) x₁
      ... | fst , snd   with maxTySplit `Two false (Σₙ'F ty n acc) snd
      ... | snd₁ , snd₂ = Ind refl fst ∷ ΣₙSizeAux n (acc * 2) (Ind refl snd₁)
      ΣₙSizeAux (suc n) acc (Lit (false , snd₁)) = Lit false ∷ ΣₙSizeAux n (acc * 2) (Lit snd₁)
      ΣₙSizeAux (suc n) acc (Lit (true , snd₁)) = Lit true ∷ ΣₙSizeAux n (acc * 2 + 1) (Lit snd₁)

  `Matrix : U → ℕ → ℕ → U
  `Matrix ty m n = Σₙ (λ m → Σₙ (λ n → `Vec (`Vec ty n) m) n) m

  matrixIndSizeAux : (m n acc : ℕ) → Vec ℕ (tySize (Σₙ' (λ m → Σₙ (λ n → `Vec (`Vec `Base n) m) n) m acc)) → Vec ℕ (m + n)
  matrixIndSizeAux 0F n acc vec = ΣₙIndSize (λ n → `Vec (`Vec `Base n) acc) n vec
  matrixIndSizeAux (suc m) n acc vec with splitAt (tySize `Two) vec
  ... | fst ∷ [] , snd   with maxTySplit `Two false (Σₙ'F (λ m → Σₙ (λ n → `Vec (`Vec `Base n) m) n) m acc) snd
  ... | snd₁ , snd₂ = fst ∷ matrixIndSizeAux m n (acc * 2) snd₁

  matrixIndSize : (m n : ℕ) → Vec ℕ (tySize (`Matrix `Base m n)) → Vec ℕ (m + n)
  matrixIndSize m n vec = matrixIndSizeAux m n 0 vec

  matrixLitSizeAux : (m n acc : ℕ) → ⟦ Σₙ' (λ m → Σₙ (λ n → `Vec (`Vec `Base n) m) n) m acc ⟧ → Vec ⟦ `Base ⟧ (m + n)
  matrixLitSizeAux 0 n acc lit = ΣₙLitSize (λ n → `Vec (`Vec `Base n) acc) n lit
  matrixLitSizeAux (suc m) n acc (false , snd₁) = fieldElem nPrime 0 ∷ matrixLitSizeAux m n (acc * 2) snd₁
  matrixLitSizeAux (suc m) n acc (true , snd₁) = fieldElem nPrime 1 ∷ matrixLitSizeAux m n (acc * 2 + 1) snd₁

  matrixLitSize : (m n : ℕ) → ⟦ `Matrix `Base m n ⟧ → Vec ⟦ `Base ⟧ (m + n)
  matrixLitSize m n lit = matrixLitSizeAux m n 0 lit

  matrixSize : (m n : ℕ) {o : ℕ} → {_ : True (m ℕ≟ suc o)} → Source (`Matrix `Base m n) → Source (`Vec `Base (m + n))
  matrixSize (suc m) n (Ind refl x) = Ind (cong suc (sym (*-identityʳ (m + n)))) (matrixIndSize (suc m) n x)
  matrixSize (suc m) n (Lit x) = Lit (matrixLitSize (suc m) n x)

  conΣₙ' : (u : ℕ → U) {n : ℕ} (sz : Bits n) (acc : ℕ) → ⟦ u (bitsToℕAux sz acc) ⟧ → ⟦ Σₙ' u n acc ⟧
  conΣₙ' u zero acc lit = false , lit
  conΣₙ' u one acc lit = true , lit
  conΣₙ' u (0+ sz) acc lit = false , conΣₙ' u sz (acc * 2) lit
  conΣₙ' u (1+ sz) acc lit = true , conΣₙ' u sz (acc * 2 + 1) lit

  conΣℕ : (n : ℕ) (sz : Fin (2 ** n)) → ℕ
  conΣℕ 0 sz = 0
  conΣℕ (suc n) sz = bitsToℕ (Fin2→Bits n sz)

  conΣₙ : (u : ℕ → U) (n : ℕ) (sz : Fin (2 ** n)) → ⟦ u (conΣℕ n sz) ⟧ → ⟦ Σₙ u n ⟧
  conΣₙ u 0 sz lit = lit
  conΣₙ u (suc n) sz lit = conΣₙ' u (Fin2→Bits n sz) 0 lit

  conMatrix : (u : U) (m n : ℕ)
    → (sz₁ : Fin (2 ** m)) → (sz₂ : Fin (2 ** n))
    → ⟦ `Vec (`Vec u (conΣℕ n sz₂)) (conΣℕ m sz₁) ⟧ → ⟦ `Matrix u m n ⟧
  conMatrix u m n sz₁ sz₂ lit = conΣₙ (λ m → Σₙ (λ n → `Vec (`Vec u n) m) n) m sz₁
                                  (conΣₙ (λ n → `Vec (`Vec u n) (conΣℕ m sz₁)) n sz₂ lit)

  matrix₁ : ⟦ `Matrix `Base 5 5 ⟧
  matrix₁ = conMatrix `Base 5 5 (# 3) (# 4)
               (map (map (fieldElem nPrime))
                 ((1 ∷  2 ∷  3 ∷  4 ∷ []) ∷
                  (5 ∷  6 ∷  7 ∷  8 ∷ []) ∷
                  (9 ∷ 10 ∷ 11 ∷ 12 ∷ []) ∷ []))

  Σ-proj₁ : ∀ {u} {x : ⟦ u ⟧ → U} → Source (`Σ u x) → Source u
  Σ-proj₁ {u} (Ind refl x₁) with splitAt (tySize u) x₁
  ... | fst , snd = Ind refl fst
  Σ-proj₁ (Lit (fst , snd)) = Lit fst

  var : ℕ → Source `Base
  var n = Ind refl (n ∷ [])

  lor : Var → Var → S-Monad Var
  lor n₁ n₂ = do
    r ← S-Monad.newVar
    assertEq (Add (Add (var n₁) (var n₂)) (Mul (Lit (-F onef)) (Mul (var n₁) (var n₂)))) (var r)
    return r
  lnot : Var → S-Monad Var
  lnot n = do
    v ← S-Monad.newVar
    assertEq (Add (Lit onef) (Mul (Lit (-F onef)) (var n))) (var v)
    return v
  limp : Var → Var → S-Monad Var
  limp n₁ n₂ = do
    notℕ₁ ← lnot n₁
    lor notℕ₁ n₂
  
  assertEqWithCond : ∀ {n} → Var → Vec Var n → Vec Var n → S-Monad ⊤
  assertEqWithCond v [] [] = return tt
  assertEqWithCond v (x₁ ∷ vec₁) (x₂ ∷ vec₂) = do
    assertEq (Mul (var v) (var x₁)) (Mul (var v) (var x₂))
    assertEqWithCond v vec₁ vec₂

  matrixMult : ∀ {m n o} → Source (`Matrix `Base m n) → Source (`Matrix `Base n o) → S-Monad (Source (`Matrix `Base m o))
  matrixMult {m} {n} {o} x y = do
    r ← S-Monad.newVars (tySize (`Matrix `Base m o))
    iterM (2 ** m) (λ sz₁ → do
      iterM (2 ** n) (λ sz₂ → do
        iterM (2 ** o) (λ sz₃ → do
          {!matrixIndSize m n!})))
    {!!}
  test : S-Monad (Source (`Vec `Base 10))
  test = do
    r ← S-Monad.newVars (tySize (`Matrix `Base 5 5))
    return (Ind refl (matrixIndSize 5 5 r))
open Test

open import Compile.Generate FF FField FFinite (λ x → showℕ (PrimeField.elem x)) PrimeField.elem (fieldElem nPrime)

open import IO

main = let inputAss = []
       in run (genMain N test inputAss)
