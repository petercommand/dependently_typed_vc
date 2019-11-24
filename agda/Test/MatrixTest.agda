module Test.MatrixTest where
open import Data.Bool renaming (_≟_ to _≟B_)
open import Data.Field.Finite
open import Data.Fin hiding (_≟_)
open import Data.List
open import Data.Nat hiding (_≟_)
open import Data.Nat.Show renaming (show to showℕ)
open import Data.Product hiding (map)
open import Data.Unit hiding (_≟_)
open import Data.Vec hiding (_>>=_; map)

open import Relation.Binary.PropositionalEquality
open import Relation.Nullary

N = 21888242871839275222246405745257275088548364400416034343698204186575808495617

FF = FiniteField N
FField = isField N
FFinite = isFinite N

open import Language.Common


module Test where
  open import Language.Source FF FFinite (λ x → showℕ (FiniteField.elem x) )
  open import Language.Source.Utils FF FFinite (λ x → showℕ (FiniteField.elem x) )
  open import Language.TySize FF FFinite
  open import Language.Universe FF
  
  
  `Matrix : U → ℕ → ℕ → U
  `Matrix u m n = `Vec (`Vec u n) m
  
  f : ⟦ `Two ⟧ → U
  f t with t ≟B false
  f t | yes p = `Two
  f t | no ¬p = `One
  
  getMatrix : ∀ {u} {m} {n} → Source (`Matrix u m n) → Fin m → Fin n → Source u
  getMatrix s m n = getV (getV s m) n
  
  test : S-Monad (Source (`Matrix (`Σ `Two f) 20 10))
  test = do
    m₁ ← newI (`Matrix (`Σ `Two f) 20 10)
    m₂ ← newI (`Matrix (`Σ `Two f) 10 20)
    m₃ ← new (`Matrix (`Σ `Two f) 20 20)
    let elem₁ = getMatrix m₁ (# 9) (# 9)
    let elem₂ = getMatrix m₂ (# 4) (# 2)
    assertEq elem₁ (Lit (false , true))
    assertEq elem₂ (Lit (true , tt))
    return m₁
open Test

open import Codata.Musical.Colist using (Colist; fromList)
open import Codata.Musical.Notation

open import Data.Nat.Show

open import Compile.SourceIntermediate FF FField FFinite (λ x → show (FiniteField.elem x))
open import Language.Intermediate FF

open import Function

IR : _
IR = compileSource _ test

open import Language.Intermediate.Show FF (λ x → show (FiniteField.elem x))
open import IO

main' : IO _
main' = 
  let result = proj₁ (proj₂ IR) []
  in sequence′ (Codata.Musical.Colist.fromList (map (putStrLn ∘′ showIntermediate) result))


main = run main'
