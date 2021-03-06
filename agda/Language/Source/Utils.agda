open import Data.Fin hiding (_+_)
open import Data.Finite
open import Data.List hiding ([_]; splitAt)
open import Data.List.Membership.Propositional
open import Data.List.Relation.Unary.Any hiding (map)
open import Data.Map hiding (toList)
open import Data.Nat
open import Data.Nat.Properties
open import Data.Product
open import Data.String hiding (_++_; toList)
open import Data.Sum
open import Data.Unit
open import Data.Vec hiding (_++_; _>>=_; splitAt)
open import Data.Vec.Split

open import Function

open import Language.Common

open import Relation.Binary.PropositionalEquality hiding ([_])
open import Relation.Nullary.Decidable


module Language.Source.Utils (f : Set) (finite : Finite f) (showf : f → String) where

open import Language.Source f finite showf
open import Language.TySize f finite
open import Language.Universe f

module S-Monad where
  import Control.RWS

  import Function.Endomorphism.Propositional using (Endo)

  module Assert = Function.Endomorphism.Propositional (List (∃ (λ u → Source u × Source u)))
  --
  module Input = Function.Endomorphism.Propositional (List ℕ)
  --
  module AssertOrHint = Function.Endomorphism.Propositional (List (∃ (λ u → Source u × Source u) ⊎ (Map Var ℕ → Map Var ℕ)))
  open Control.RWS ⊤ (AssertOrHint.Endo × Input.Endo) Var (id , id) (λ a b → proj₁ a ∘′ proj₁ b , proj₂ a ∘′ proj₂ b) renaming (RWSMonad to S-Monad) public



  newVar : S-Monad Var
  newVar = do
    v ← get
    put (1 + v)
    return v


  newVars : ∀ n → S-Monad (Vec Var n)
  newVars zero = return []
  newVars (suc n) = do
    v ← newVar
    rest ← newVars n
    return (v ∷ rest)


open S-Monad hiding (newVar; newVars) public
open S-Monad using (newVar; newVars)

addHint : (Map Var ℕ → Map Var ℕ) → S-Monad ⊤
addHint h = tell ((λ x → inj₂ h ∷ [] ++ x) , id)

assertEq : ∀ {u} → Source u → Source u → S-Monad ⊤
assertEq {u} s₁ s₂ = tell ((λ x → inj₁ (u , s₁ , s₂) ∷ [] ++ x) , id)

new : ∀ u → S-Monad (Source u)
new u = do
  vec ← newVars (tySize u)
  return (Ind refl vec)

newI : ∀ u → S-Monad (Source u)
newI u = do
  vec ← newVars (tySize u)
  tell (id , (λ x → toList vec ++ x))
  return (Ind refl vec)

getV : ∀ {u} {x} → Source (`Vec u x) → Fin x → Source u
getV {u} {suc x} (Ind refl x₁) f with splitAt (tySize u) x₁
getV {u} {suc x} (Ind refl x₁) 0F | fst , snd = Ind refl fst
getV {u} {suc x} (Ind refl x₁) (suc f) | fst , snd = getV (Ind refl snd) f
getV (Lit (x ∷ x₁)) 0F = Lit x
getV (Lit (x ∷ x₁)) (suc f) = getV (Lit x₁) f

iterM : ∀ {ℓ} {A : Set ℓ} (n : ℕ) → (Fin n → S-Monad A) → S-Monad (Vec A n)
iterM 0F act = return []
iterM (suc n) act = do
  r ← act (#_ n {suc n} {fromWitness ≤-refl})
  rs ← iterM n (λ m → act (castF (inject+ 1 m)))
  return (r ∷ rs)
 where
  castF : Fin (n + 1) → Fin (1 + n)
  castF f rewrite +-comm 1 n = f

appAux : ∀ {u} {x : ⟦ u ⟧ → U} → (eu : List ⟦ u ⟧) → (val : ⟦ u ⟧) → (mem : val ∈ eu) → Vec ℕ (tySumOver eu x) → S-Monad (Source (x val))
appAux {_} {x} .(val ∷ _) val (here refl) vec with splitAt (tySize (x val)) vec
... | fst , _ = return (Ind refl fst)
appAux {_} {x} (x₁ ∷ _) val (there mem) vec with splitAt (tySize (x x₁)) vec
... | _ , rest = appAux _ val mem rest

app : ∀ {u} {x : ⟦ u ⟧ → U} → Source (`Π u x) → (val : ⟦ u ⟧) → S-Monad (Source (x val))
app {u} (Ind refl x₁) val = appAux (enum u) val (enumComplete u val) x₁
app (Lit x) val = return (Lit (x val))

