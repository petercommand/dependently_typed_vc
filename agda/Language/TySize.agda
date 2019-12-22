open import Agda.Builtin.Nat

open import Data.Bool
open import Data.Empty
open import Data.Finite
open import Data.List hiding (splitAt; take; length)
open import Data.List.Membership.Propositional
open import Data.List.Misc
open import Data.List.Monad
open import Data.List.Properties
open import Data.List.Relation.Unary.Any hiding (map)
open import Data.List.Relation.Unary.Any.Properties
open import Data.Nat hiding (_⊔_)
open import Data.Nat.Max
open import Data.Nat.Properties
open import Data.Nat.Properties2
open import Data.Product hiding (map)
open import Data.Sum hiding (map)
open import Data.Unit
open import Data.Vec hiding ([_]; _>>=_; _++_; splitAt; map; take)
open import Data.Vec.Split

open import Function

open import Relation.Binary
open import Relation.Binary.PropositionalEquality renaming ([_] to ℝ[_])


open import Relation.Nullary

module Language.TySize (f : Set) (finite : Finite f) where
open import Language.Common
import Language.Universe

open import Level renaming (zero to lzero; suc to lsuc)

open Language.Universe f

open import Axiom.Extensionality.Propositional


postulate
  ext : ∀ {ℓ} {ℓ'} → Axiom.Extensionality.Propositional.Extensionality ℓ ℓ'

occAux : ∀ {ℓ} {A : Set ℓ} {a x : A} → Dec (a ≡ x) → ℕ → ℕ → ℕ
occAux (yes p) m n = m
occAux (no ¬p) m n = n

occAux₂ : ∀ {ℓ} {A : Set ℓ} (a x : A) (dec : Dec (a ≡ x)) m n → ¬ a ≡ x → occAux dec m n ≡ n
occAux₂ a x (yes p) m n neq = ⊥-elim (neq p)
occAux₂ a x (no ¬p) m n neq = refl

occ : ∀ {ℓ} {A : Set ℓ} → (Decidable {A = A} _≡_) → A → List A → ℕ
occ dec a [] = 0
occ dec a (x ∷ l) = occAux (dec a x) (suc (occ dec a l)) (occ dec a l)

occPrfIrr : ∀ {ℓ} {A : Set ℓ} → (dec dec' : Decidable {A = A} _≡_) → (v : A) (l : List A) → occ dec v l ≡ occ dec' v l
occPrfIrr dec dec' v [] = refl
occPrfIrr dec dec' v (x ∷ l) with dec v x | dec' v x
occPrfIrr dec dec' v (x ∷ l) | yes p | yes p₁ = cong suc (occPrfIrr dec dec' v l)
occPrfIrr dec dec' v (x ∷ l) | yes p | no ¬p = ⊥-elim (¬p p)
occPrfIrr dec dec' v (x ∷ l) | no ¬p | yes p = ⊥-elim (¬p p)
occPrfIrr dec dec' v (x ∷ l) | no ¬p | no ¬p₁ = occPrfIrr dec dec' v l

occLem : ∀ {ℓ} {A : Set ℓ} → (dec : Decidable {A = A} _≡_) → (x : A) (l l' : List A) → occ dec x (l ++ l') ≡ occ dec x l + occ dec x l'
occLem dec x [] l' = refl
occLem dec x (x₁ ∷ l) l' with dec x x₁
occLem dec x (x₁ ∷ l) l' | yes p = cong suc (occLem dec x l l')
occLem dec x (x₁ ∷ l) l' | no ¬p = occLem dec x l l'
∈->>= : ∀ {a} {A : Set a} {b} {B : Set b} (l : List A) (f : A → List B) → ∀ x → x ∈ l → ∀ y → y ∈ f x → y ∈ l >>= f
∈->>= .(x ∷ _) f x (here refl) y mem' = ++⁺ˡ mem'
∈->>= .(_ ∷ _) f x (there mem) y mem' = ++⁺ʳ (f _) (∈->>= _ f x mem y mem')

Disjoint : ∀ {a} {A : Set a} → (l l' : List A) → Set a
Disjoint l l' = ∀ x → x ∈ l → ¬ x ∈ l'

¬∈→occ≡0 : ∀ {a} {A : Set a} (decA : Decidable {A = A} _≡_) → ∀ x l → ¬ x ∈ l → occ decA x l ≡ 0
¬∈→occ≡0 decA x [] ¬∈ = refl
¬∈→occ≡0 decA x (x₁ ∷ l) ¬∈ with decA x x₁
¬∈→occ≡0 decA x (.x ∷ l) ¬∈ | yes refl = ⊥-elim (¬∈ (here refl))
¬∈→occ≡0 decA x (x₁ ∷ l) ¬∈ | no ¬p = ¬∈→occ≡0 decA x l (λ x₂ → ¬∈ (there x₂))

occ->>= : ∀ {a} {A : Set a} {b} {B : Set b} (decA : Decidable {A = A} _≡_) (decB : Decidable {B = B} _≡_) (l : List A) (f : A → List B)
   → ∀ x y →
   (prf : ∀ x₁ → ¬ x ≡ x₁ → ¬ y ∈ f x₁) →
   occ decB y (l >>= f) ≡ (occ decA x l * occ decB y (f x))
occ->>= decA decB [] f x y prf = refl
occ->>= decA decB (x₁ ∷ l) f x y prf with decA x x₁
occ->>= decA decB (x₁ ∷ l) f x y prf | yes refl rewrite occLem decB y (f x₁) (l >>= f) = cong (_+_ (occ decB y (f x₁))) (occ->>= decA decB l f x y prf)
occ->>= decA decB (x₁ ∷ l) f x y prf | no ¬p rewrite occLem decB y (f x₁) (l >>= f) | ¬∈→occ≡0 decB y _ (prf x₁ ¬p) = occ->>= decA decB l f x y prf


∈->>=⁻ : ∀ {a} {A : Set a} {b} {B : Set b} (l : List A) (f : A → List B) → ∀ y → y ∈ l >>= f → ∃ (λ x → x ∈ l × y ∈ f x)
∈->>=⁻ (x ∷ l) f y y∈l>>=f with ++⁻ (f x) y∈l>>=f
∈->>=⁻ (x ∷ l) f y y∈l>>=f | inj₁ x₁ = x , (here refl) , x₁
∈->>=⁻ (x ∷ l) f y y∈l>>=f | inj₂ y₁ with ∈->>=⁻ l f y y₁
∈->>=⁻ (x ∷ l) f y y∈l>>=f | inj₂ y₁ | x₁ , x₁∈l , y₂∈fx₁ = x₁ , (there x₁∈l) , y₂∈fx₁



∈l-∈l'-∈r : ∀ {a} {A : Set a} {b} {B : A → Set b} {c} {C : Set c} (l : List A)  (_+_ : (x : A) → B x → C)
    → ∀ x y → x ∈ l → (l' : (x : A) → List (B x)) → y ∈ l' x → x + y ∈ (l Data.List.Monad.>>= λ r →
                                                                          l' r Data.List.Monad.>>= λ rs →
                                                                          r + rs ∷ [])
∈l-∈l'-∈r l _+_ x y mem l' mem' = ∈->>= l (λ z → l' z >>= (λ z₁ → (z + z₁) ∷ [])) x mem (x + y)
                                        (∈->>= (l' x) (λ z → (x + z) ∷ []) y mem' (x + y) (here refl))

map-proj₁->>= : ∀ {a} {A : Set a} {b} {B : A → Set b} → (l : List A) (f : (x : A) → B x) → map proj₁ (l >>= (λ r → (r , f r) ∷ [])) ≡ l
map-proj₁->>= [] f = refl
map-proj₁->>= (x ∷ l) f = cong (λ l → x ∷ l) (map-proj₁->>= l f)


module Enum where
  open import Data.List.Monad


  ¬∈[] : ∀ {ℓ} {A : Set ℓ} → (x : A) → ¬ x ∈ []
  ¬∈[] x ()
  
  ann : ∀ {ℓ} (A : Set ℓ) → A → A
  ann _ a = a

  genFunc : ∀ u (x : ⟦ u ⟧ → U)
      → List (Σ ⟦ u ⟧ (λ v → List ⟦ x v ⟧))
      → List (List (Σ ⟦ u ⟧ (λ v → ⟦ x v ⟧)))
  genFunc u x [] = [ [] ]
  genFunc u x (x₁ ∷ l) with genFunc u x l
  ... | acc = do
    ac ← acc
    choice ← proj₂ x₁
    return ((proj₁ x₁ , choice) ∷ ac)
    
  genFuncProj₁ : ∀ u (x : ⟦ u ⟧ → U)
      → (l : List (Σ ⟦ u ⟧ (λ v → List ⟦ x v ⟧)))
      → ∀ x₁ → x₁ ∈ genFunc u x l
      → map proj₁ x₁ ≡ map proj₁ l
  genFuncProj₁ u x [] x₁ (here refl) = refl
  genFuncProj₁ u x (x₂ ∷ l) x₁ x₁∈ with genFunc u x l | inspect (genFunc u x) l
  genFuncProj₁ u x (x₂ ∷ l) x₁ x₁∈ | t | ℝ[ refl ] with ∈->>=⁻ t (λ ac → proj₂ x₂ >>= (λ choice → ((proj₁ x₂ , choice) ∷ ac) ∷ [])) x₁ x₁∈
  ... | x₃ , x₃∈l , x₁∈fx₃ with ∈->>=⁻ (proj₂ x₂) (λ choice → ((proj₁ x₂ , choice) ∷ x₃) ∷ []) x₁ x₁∈fx₃
  ... | x₄ , x₄∈proj₂x₂ , here refl = cong (λ t → proj₁ x₂ ∷ t) (genFuncProj₁ u x l x₃ x₃∈l)

  piFromList : ∀ u (x : ⟦ u ⟧ → U)
      → (enough : List ⟦ u ⟧)
      → (l : List (Σ ⟦ u ⟧ (λ v → ⟦ x v ⟧)))
      → (map proj₁ l ≡ enough) → (dom : ⟦ u ⟧) → dom ∈ enough → ⟦ x dom ⟧
  piFromList u x .(d ∷ _) ((d , v) ∷ l) refl dom (here refl) = v
  piFromList u x (._ ∷ rest) (x₁ ∷ l) refl dom (there dom∈enough) = piFromList u x rest l refl dom dom∈enough



  piFromListProofIrre : ∀ u (x : ⟦ u ⟧ → U) → (enough : List ⟦ u ⟧)
      → (l l' : List (Σ ⟦ u ⟧ (λ v → ⟦ x v ⟧)))
      → l ≡ l'
      → (p₁ : map proj₁ l ≡ enough)
      → (p₂ : map proj₁ l' ≡ enough)
      → (dom : ⟦ u ⟧)
      → (p₃ : dom ∈ enough)
      → piFromList u x enough l p₁ dom p₃ ≡ piFromList u x enough l' p₂ dom p₃
  piFromListProofIrre u x .(fst ∷ map proj₁ l) ((fst , snd) ∷ l) .((fst , snd) ∷ l) refl refl refl .fst (here refl) = refl
  piFromListProofIrre u x .(fst ∷ map proj₁ l) ((fst , snd) ∷ l) .((fst , snd) ∷ l) refl refl refl dom (there p₃) = piFromListProofIrre u x (map proj₁ l) l l refl refl refl dom p₃
  
  listFuncToPi : ∀ u (x : ⟦ u ⟧ → U)
      → (eu : List ⟦ u ⟧)
      → (∀ x → x ∈ eu)
      → (l : List (List (Σ ⟦ u ⟧ (λ v → ⟦ x v ⟧))))
      → (∀ x → x ∈ l → map proj₁ x ≡ eu)
      → List ⟦ `Π u x ⟧
  listFuncToPi u x eu ∈eu [] proj₁l≡eu = []
  listFuncToPi u x eu ∈eu (l ∷ l₁) proj₁l≡eu = (λ dom → piFromList u x eu l (proj₁l≡eu l (here refl)) dom (∈eu dom))
                                                     ∷ listFuncToPi u x eu ∈eu l₁ (λ m m∈l → proj₁l≡eu m (there m∈l))


  safeLookup : ∀ {ℓ} {ℓ'} {A : Set ℓ} {B : A → Set ℓ'} → (elem : A) → (l : List (Σ A B)) (l' : List A) → map proj₁ l ≡ l' → elem ∈ l' → B elem
  safeLookup elem ((.elem , snd) ∷ l) .(elem ∷ map proj₁ l) refl (here refl) = snd
  safeLookup elem (x ∷ l) .(proj₁ x ∷ map proj₁ l) refl (there mem) = safeLookup elem l (map proj₁ l) refl mem


  f∈listFuncToPi : ∀ u x eu ∈eu funcs func eq f → (mem : func ∈ funcs) → f ≡ (λ d → piFromList u x eu func (eq func mem) d (∈eu d)) → f ∈ listFuncToPi u x eu ∈eu funcs eq
  f∈listFuncToPi u x eu ∈eu .(func ∷ _) func eq f (here refl) eq'' = here eq''
  f∈listFuncToPi u x eu ∈eu .(_ ∷ _) func eq f (there func∈funcs) eq'' = there
                                                                           (f∈listFuncToPi u x eu ∈eu _ func (λ x z → eq x (there z)) f
                                                                            func∈funcs eq'')


  enum : (u : U) → List ⟦ u ⟧
  enumComplete : ∀ u → (x : ⟦ u ⟧) → x ∈ enum u

  enum `One = [ tt ]
  enum `Two = false ∷ true ∷ []
  enum `Base = Finite.elems finite
  enum (`Vec u zero) = [ [] ]
  enum (`Vec u (suc x)) = do
    r ← enum u
    rs ← enum (`Vec u x)
    return (r ∷ rs)
  enum (`Σ u x) = do
    r ← enum u
    rs ← enum (x r)
    return (r , rs)
  enum (`Π u x) = let pairs = do
                        r ← enum u
                        return (r , enum (x r))
                      funcs = genFunc _ _ pairs
                  in listFuncToPi u x (enum u) (enumComplete u) funcs
                              (λ x₁ x₁∈genFunc →
                                  trans (genFuncProj₁ u x pairs x₁ x₁∈genFunc)
                                        (map-proj₁->>= (enum u) (enum ∘ x)))

  piToList : ∀ u x → (eu : List ⟦ u ⟧) → (f : ⟦ `Π u x ⟧) → List (Σ ⟦ u ⟧ λ v → ⟦ x v ⟧)
  piToList u x [] f = []
  piToList u x (x₁ ∷ eu) f = (x₁ , f x₁) ∷ piToList u x eu f


  piFromList∘piToList≗id : ∀ u x eu (∈eu : ∀ x → x ∈ eu) f p → ∀ t → f t ≡ piFromList u x eu (piToList u x eu f) p t (∈eu t)
  piFromList∘piToList≗id u x eu ∈eu f p t = aux u x eu f p t (∈eu t)
    where
      aux : ∀ u x eu f p t t∈eu → f t ≡ piFromList u x eu (piToList u x eu f) p t t∈eu
      aux u x (.t ∷ xs) f p t (here refl) with piToList u x xs f
      ... | t₁ with p
      ... | refl = refl
      aux u x (._ ∷ xs) f p t (there t∈eu) with piToList u x xs f | inspect (piToList u x xs) f
      ... | t₁ | ℝ[ prf ] with p
      ... | refl = trans (aux u x xs f (cong (map proj₁) prf) t t∈eu) (piFromListProofIrre u x (map proj₁ t₁) _ _ prf (cong (map proj₁) prf) refl t t∈eu)

  mem-occ : ∀ {ℓ} {A : Set ℓ} dec x (l : List A) → x ∈ l → occ dec x l ≥ 1
  mem-occ dec x .(x ∷ _) (here refl) with dec x x
  mem-occ dec x .(x ∷ _) (here refl) | yes p = s≤s z≤n
  mem-occ dec x .(x ∷ _) (here refl) | no ¬p = ⊥-elim (¬p refl)
  mem-occ dec x (x₁ ∷ xs) (there mem) with dec x x₁
  mem-occ dec x (x₁ ∷ xs) (there mem) | yes p = s≤s z≤n
  mem-occ dec x (x₁ ∷ xs) (there mem) | no ¬p = mem-occ dec x xs mem


  occ≡1→memUnique : ∀ {ℓ} {A : Set ℓ} → ∀ dec l l' → (uniq : ∀ v → ¬ v ∈ l' → occ dec v l ≡ 1) → ∀ (a : A) → (m₁ m₂ : a ∈ l) → ¬ a ∈ l' → m₁ ≡ m₂
  occ≡1→memUnique dec .(a ∷ _) l' uniq a (here refl) (here refl) ¬∈ = refl
  occ≡1→memUnique dec (a ∷ xs) l' uniq a (here refl) (there m₂) ¬∈ with uniq a ¬∈
  ... | occPrf with dec a a
  occ≡1→memUnique dec (a ∷ xs) l' uniq a (here refl) (there m₂) ¬∈ | occPrf | yes p with s≤s (mem-occ dec a xs m₂)
  ... | occ≥2 rewrite occPrf with occ≥2
  ... | s≤s ()
  occ≡1→memUnique dec (a ∷ xs) l' uniq a (here refl) (there m₂) ¬∈ | occPrf | no ¬p = ⊥-elim (¬p refl)
  occ≡1→memUnique dec (a ∷ xs) l' uniq a (there m₁) (here refl) ¬∈ with uniq a ¬∈
  ... | occPrf with dec a a
  occ≡1→memUnique dec (a ∷ xs) l' uniq a (there m₁) (here refl) ¬∈ | occPrf | yes p with s≤s (mem-occ dec a xs m₁)
  ... | occ≥2 rewrite occPrf with occ≥2
  ... | s≤s ()
  occ≡1→memUnique dec (a ∷ xs) l' uniq a (there m₁) (here refl) ¬∈ | occPrf | no ¬p = ⊥-elim (¬p refl)
  occ≡1→memUnique dec (x ∷ xs) l' uniq a (there m₁) (there m₂) ¬∈ with uniq a ¬∈
  ... | occPrf with dec a x
  occ≡1→memUnique dec (x ∷ xs) l' uniq a (there m₁) (there m₂) ¬∈ | occPrf | yes p with s≤s (mem-occ dec a xs m₁)
  ... | occ≥2 rewrite occPrf with occ≥2
  ... | s≤s () 
  occ≡1→memUnique dec (x ∷ xs) l' uniq a (there m₁) (there m₂) ¬∈ | occPrf | no ¬p = cong there (occ≡1→memUnique dec xs (x ∷ l') (λ v x₁ → trans (sym (occAux₂ v x (dec v x) _ _ λ x₂ → x₁ (here x₂))) (uniq v λ x₂ → x₁ (there x₂))) a m₁ m₂ λ x₁ → ¬∈ (lem x₁))
    where
      lem : ∀ (mem : a ∈ x ∷ l') → a ∈ l'
      lem (here refl) = ⊥-elim (¬p refl)
      lem (there mem) = mem

  {-
    Goal: to . from ≡ id

    Suppose that l ≡ l' ↔ from l ≡ from l'

    to . from ≡ id 
    ↔ (∀ l → to (from l) ≡ l )
    ↔ from (to (from l)) ≡ from l
    ↔ from l ≡ from l
  -}

  length : ∀ {ℓ} {A : Set ℓ} → List A → ℕ
  length [] = 0
  length (x ∷ l) = suc (length l)

  map-length : ∀ {ℓ} {ℓ'} {A : Set ℓ} {B : Set ℓ'} → (f : A → B) → (l : List A) → length (map f l) ≡ length l
  map-length f [] = refl
  map-length f (x ∷ l) = cong suc (map-length f l)

  take : ∀ {ℓ} {A : Set ℓ} → ℕ → List A → List A
  take zero l = []
  take (suc n) [] = []
  take (suc n) (x ∷ l) = x ∷ take n l

  piToList∘piFromList≗idLem : ∀ u x dec x₁ (x₂ : Σ ⟦ u ⟧ (λ v → ⟦ x v ⟧)) (px : proj₁ x₂ ≡ x₁) eu l (uniq : occ dec x₁ eu ≡ 1) p → (prf : x₁ ∈ eu) (prf' : x₂ ∈ l) → (x₁ , piFromList u x eu l p x₁ prf) ≡ x₂
  piToList∘piFromList≗idLem u x dec .(proj₁ x₂) x₂ px .(proj₁ x₂ ∷ map proj₁ _) .(x₂ ∷ _) uniq refl (here refl) (here refl) = refl
  piToList∘piFromList≗idLem u x dec x₁ x₂ px ._ .(_ ∷ _) uniq refl (here px₁) (there prf') = {!!}
  piToList∘piFromList≗idLem u x dec x₁ x₂ px .(_ ∷ _) .(_ ∷ _) uniq p (there prf) (here px₁) = {!!}
  piToList∘piFromList≗idLem u x dec x₁ x₂ px (_ ∷ .(map proj₁ l)) (_ ∷ l) uniq refl (there prf) (there prf') = piToList∘piFromList≗idLem u x dec x₁ x₂ px (map proj₁ l) l {!!} refl prf prf'

  piToList∘piFromList≗idAux : ∀ u x dec eu (∈eu : ∀ x → x ∈ eu) eu' eu'' (eq : eu'' ++ eu' ≡ eu) l l' l'' (lenEq : length eu' ≡ length l') (eq' : l'' ++ l' ≡ l) (uniq : ∀ v → occ dec v eu ≡ 1) p → piToList u x eu' (λ dom → piFromList u x eu l p dom (∈eu dom)) ≡ l'
  piToList∘piFromList≗idAux u x dec eu ∈eu [] eu'' eq l [] l'' lenEq eq' uniq p = refl
  piToList∘piFromList≗idAux u x dec eu ∈eu (x₁ ∷ eu') eu'' eq l (x₂ ∷ l') l'' lenEq refl uniq p
                      rewrite piToList∘piFromList≗idAux u x dec eu ∈eu eu' (eu'' ++ (x₁ ∷ []))
                                    (trans (++-assoc eu'' (x₁ ∷ []) eu') eq) l l' (l'' ++ (x₂ ∷ []))
                                    (cong (λ { (suc x) → x ; zero → zero }) lenEq)
                                    (++-assoc l'' (x₂ ∷ []) l') uniq p
                                       = cong (λ x → x ∷ l') (piToList∘piFromList≗idLem u x dec x₁ x₂ {!!} eu l (uniq x₁) p (∈eu x₁) {!!})


  piToList∘piFromList≗id : ∀ u x dec eu (∈eu : ∀ x → x ∈ eu) l (uniq : ∀ v → occ dec v eu ≡ 1) p → piToList u x eu (λ dom → piFromList u x eu l p dom (∈eu dom)) ≡ l
  piToList∘piFromList≗id u x dec eu ∈eu l uniq refl = piToList∘piFromList≗idAux u x dec eu ∈eu eu [] refl l l []  (map-length proj₁ l) refl uniq refl

  data FuncInst {ℓ} {ℓ'} (A : Set ℓ) (B : A → Set ℓ') : List (Σ A B) → List (Σ A (λ v → List (B v))) → Set (ℓ ⊔ ℓ') where
    InstNil : FuncInst A B [] []
    InstCons : ∀ l l' → (a : A) (b : B a) (ls : List (B a)) → b ∈ ls → (ins : FuncInst A B l l') → FuncInst A B ((a , b) ∷ l) ((a , ls) ∷ l')

  occ-listFuncToPi : ∀ u x eu ∈eu l eq dec dec' val → occ dec val (listFuncToPi u x eu ∈eu l eq) ≡ occ dec' (piToList u x eu val) l
  occ-listFuncToPi u x eu ∈eu [] eq dec dec' val = refl
  occ-listFuncToPi u x eu ∈eu (l ∷ l₁) eq dec dec' val with dec val (λ dom → piFromList u x eu l (eq l (here refl)) dom (∈eu dom))
  occ-listFuncToPi u x eu ∈eu (l ∷ l₁) eq dec dec' val | yes p with dec' (piToList u x eu val) l
  occ-listFuncToPi u x eu ∈eu (l ∷ l₁) eq dec dec' val | yes p | yes p₁ = cong suc (occ-listFuncToPi u x eu ∈eu l₁ (λ x₁ x₂ → eq x₁ (there x₂)) dec dec' val)
  occ-listFuncToPi u x eu ∈eu (l ∷ l₁) eq dec dec' val | yes p | no ¬p rewrite p = ⊥-elim (¬p {!!})
  occ-listFuncToPi u x eu ∈eu (l ∷ l₁) eq dec dec' val | no ¬p with dec' (piToList u x eu val) l
  occ-listFuncToPi u x eu ∈eu (l ∷ l₁) eq dec dec' val | no ¬p | yes refl = ⊥-elim (¬p (ext (λ t → piFromList∘piToList≗id u x eu ∈eu val
                                                                                                     (eq (piToList u x eu val) (here refl)) t)))
  occ-listFuncToPi u x eu ∈eu (l ∷ l₁) eq dec dec' val | no ¬p | no ¬p₁ = occ-listFuncToPi u x eu ∈eu l₁ (λ x₁ x₂ → eq x₁ (there x₂)) dec dec' val

  map-empty : ∀ {ℓ} {ℓ'} {A : Set ℓ} {B : Set ℓ'} → (m : List A) → (f : A → B) → map f m ≡ [] → m ≡ []
  map-empty [] f eq = refl
    
  genFuncLem : ∀ u x l f → FuncInst _ _ f l → f ∈ genFunc u x l
  genFuncLem u x .[] .[] InstNil = here refl
  genFuncLem u x .((a , ls) ∷ l') .((a , b) ∷ l) (InstCons l l' a b ls x₁ finst) with genFunc u x l' | inspect (genFunc u x) l'
  ... | t | ℝ[ refl ] = ∈->>= (genFunc u x l') _ l (genFuncLem u x l' l finst) ((a , b) ∷ l)
                            (∈->>= ls _ b x₁ ((a , b) ∷ l) (here refl))

  FuncInstLem : ∀ u x (f : ⟦ `Π u x ⟧) (l : List ⟦ u ⟧) → (∀ x₁ → f x₁ ∈ enum (x x₁)) → FuncInst ⟦ u ⟧ (λ v → ⟦ x v ⟧) (piToList u x l f) (l >>= (λ r → (r , enum (x r)) ∷ []))
  FuncInstLem u x f [] p = InstNil
  FuncInstLem u x f (x₁ ∷ l) p = InstCons (piToList u x l f) (l >>= (λ r → (r , enum (x r)) ∷ []))
                          x₁ (f x₁) (enum (x x₁)) (p x₁) (FuncInstLem u x f l p)


  enumComplete `One tt = here refl
  enumComplete `Two false = here refl
  enumComplete `Two true = there (here refl)
  enumComplete `Base x = Finite.a∈elems finite x
  enumComplete (`Vec u zero) [] = here refl
  enumComplete (`Vec u (suc x₁)) (x ∷ x₂) = ∈l-∈l'-∈r (enum u) _∷_ x x₂ (enumComplete u x) (λ _ → enum (`Vec u x₁)) (enumComplete (`Vec u x₁) x₂)
  enumComplete (`Σ u x₁) (fst , snd) = ∈l-∈l'-∈r (enum u) _,_ fst snd (enumComplete u fst) (λ r → enum (x₁ r)) (enumComplete (x₁ fst) snd)
  enumComplete (`Π u x₁) f = f∈listFuncToPi u x₁ (enum u) (enumComplete u) (genFunc _ _ (enum u >>= λ r → return (r , enum (x₁ r)))) (piToList u x₁ (enum u) f)
                                       (λ x x₃ → trans (genFuncProj₁ u x₁ (enum u >>= (λ r → return (r , enum (x₁ r)))) x x₃)
                                                       (map-proj₁->>= (enum u) (enum ∘ x₁))) f (genFuncLem u x₁ (enum u >>= (λ r → (r , enum (x₁ r)) ∷ [])) _ (FuncInstLem u x₁ f (enum u) (λ x → enumComplete (x₁ x) (f x))))
                                       (ext λ x → piFromList∘piToList≗id u x₁ (enum u) (enumComplete u) f (trans
                                                                         (genFuncProj₁ u x₁ (enum u >>= (λ r → (r , enum (x₁ r)) ∷ []))
                                                                                       (piToList u x₁ (enum u) f)
                                                                                         (genFuncLem u x₁ (enum u >>= (λ r → (r , enum (x₁ r)) ∷ []))
                                                                                           (piToList u x₁ (enum u) f)
                                                                                             (FuncInstLem u x₁ f (enum u)
                                                                                               (λ x₂ → enumComplete (x₁ x₂) (f x₂)))))
                                                                         (map-proj₁->>= (enum u) (λ x₂ → enum (x₁ x₂)))) x)

  

  enumUniqueLem : ∀ u x x₁ x₂ (val : Vec ⟦ u ⟧ x) → ¬ x₁ ≡ x₂ → ¬ x₁ ∷ val ∈ enum (`Vec u x) >>= (λ rs → ann (Vec ⟦ u ⟧ (suc x)) (x₂ ∷ rs) ∷ [])
  enumUniqueLem u x x₁ x₂ val neq mem with ∈->>=⁻ (enum (`Vec u x)) (λ rs → ann (Vec ⟦ u ⟧ (suc x)) (x₂ ∷ rs) ∷ []) (x₁ ∷ val) mem
  enumUniqueLem u x .x₂ x₂ .elem neq mem | elem , prf₁ , here refl = ⊥-elim (neq refl)

  enumUniqueLem₂ : ∀ u x x₁ x₂ (val : Vec ⟦ u ⟧ x) → ¬ val ≡ x₂ → ¬ x₁ ∷ val ∈ ann (Vec ⟦ u ⟧ (suc x)) (x₁ ∷ x₂) ∷ []
  enumUniqueLem₂ u x x₁ x₂ .x₂ neq (here refl) = ⊥-elim (neq refl)

  enumUnique : ∀ u → (val : ⟦ u ⟧) → (dec : ∀ {u} → Decidable {A = ⟦ u ⟧} _≡_) → occ dec val (enum u) ≡ 1
  enumUnique Language.Universe.`One tt dec with dec tt tt
  enumUnique Language.Universe.`One tt dec | yes p = refl
  enumUnique Language.Universe.`One tt dec | no ¬p = ⊥-elim (¬p refl)
  enumUnique Language.Universe.`Two val dec with dec val false
  enumUnique Language.Universe.`Two .false dec | yes refl with dec false true
  enumUnique Language.Universe.`Two .false dec | yes refl | no ¬p = refl
  enumUnique Language.Universe.`Two val dec | no ¬p with dec val true
  enumUnique Language.Universe.`Two val dec | no ¬p | yes p = refl
  enumUnique Language.Universe.`Two false dec | no ¬p | no ¬p₁ = ⊥-elim (¬p refl)
  enumUnique Language.Universe.`Two true dec | no ¬p | no ¬p₁ = ⊥-elim (¬p₁ refl)
  enumUnique Language.Universe.`Base val dec = {!!}
  enumUnique (Language.Universe.`Vec u zero) [] dec with dec {`Vec u zero} [] []
  enumUnique (Language.Universe.`Vec u zero) [] dec | yes p = refl
  enumUnique (Language.Universe.`Vec u zero) [] dec | no ¬p = ⊥-elim (¬p refl)
  enumUnique (Language.Universe.`Vec u (suc x)) (x₁ ∷ val) dec rewrite occ->>= dec dec (enum u) (λ r → enum (`Vec u x) >>= (λ rs → ann ⟦ `Vec u (suc x) ⟧ (r ∷ rs) ∷ [])) x₁ (x₁ ∷ val) (λ x₂ x₃ x₄ → enumUniqueLem u x x₁ x₂ val x₃ x₄)
                                                                     | enumUnique u x₁ dec
                                                                     | occ->>= dec dec (enum (`Vec u x)) (λ rs → ann ⟦ `Vec u (suc x) ⟧ (x₁ ∷ rs) ∷ []) val (x₁ ∷ val) λ x₂ x₃ x₄ → enumUniqueLem₂ u x x₁ x₂ val x₃ x₄
      with dec {`Vec u (suc x)} (x₁ ∷ val) (x₁ ∷ val)
  ... | yes p rewrite enumUnique (`Vec u x) val dec = refl
  ... | no ¬p = ⊥-elim (¬p refl)
  enumUnique (Language.Universe.`Σ u x) (fst , snd) dec rewrite occ->>= dec dec (enum u) (λ r → enum (x r) >>= (λ rs → (r , rs) ∷ [])) fst (fst , snd) {!!}
                                                              | enumUnique u fst dec
                                                              | occ->>= dec dec (enum (x fst))  (λ rs → ann ⟦ `Σ u x ⟧ (fst , rs) ∷ []) snd (fst , snd) {!!}
      with dec {`Σ u x} (fst , snd) (fst , snd)
  ... | yes p rewrite enumUnique (x fst) snd dec = refl
  ... | no ¬p = ⊥-elim (¬p refl)
  enumUnique (Language.Universe.`Π u x) val dec = {!!}

open Enum public

maxTySizeOver : ∀ {u} → List ⟦ u ⟧ → (⟦ u ⟧ → U) → ℕ
tySumOver : ∀ {u} → List ⟦ u ⟧ → (⟦ u ⟧ → U) → ℕ
tySize : U → ℕ


tySize `One = 1
tySize `Two = 1
tySize `Base = 1
tySize (`Vec u x) = x * tySize u
tySize (`Σ u x) = tySize u + maxTySizeOver (enum u) x
tySize (`Π u x) = tySumOver (enum u) x

maxTySizeOver [] fam = 0
maxTySizeOver (x ∷ l) fam = max (tySize (fam x)) (maxTySizeOver l fam)

tySumOver [] x = 0
tySumOver (x₁ ∷ l) x = tySize (x x₁) + tySumOver l x

∈→≥ : ∀ {u} → (elem : List ⟦ u ⟧) → (x : ⟦ u ⟧ → U) → (val : ⟦ u ⟧) → val ∈ elem → maxTySizeOver elem x ≥ tySize (x val)
∈→≥ (_ ∷ xs) x val (here refl) = max-left (tySize (x val)) (maxTySizeOver xs x)
∈→≥ (x₁ ∷ xs) x val (there mem) = max-monotoneᵣ (tySize (x x₁)) _ _ (∈→≥ xs x val mem)



maxTySizeLem : ∀ u (val : ⟦ u ⟧) (x : ⟦ u ⟧ → U) → maxTySizeOver (enum u) x ≥ tySize (x val)
maxTySizeLem u val x = ∈→≥ (enum u) x val (enumComplete _ val)



maxTyVecSizeEq : ∀ u (val : ⟦ u ⟧) (x : ⟦ u ⟧ → U) → maxTySizeOver (enum u) x ≡ tySize (x val) + (maxTySizeOver (enum u) x - tySize (x val))
maxTyVecSizeEq u val x = sym (trans (+-comm (tySize (x val)) (maxTySizeOver (enum u) x - tySize (x val)))
                            (a-b+b≡a _ _ (maxTySizeLem u val x)))

maxTySplitAux : ∀ u (val : ⟦ u ⟧) (x : ⟦ u ⟧ → U) → Vec ℕ (tySize (x val) + (maxTySizeOver (enum u) x - tySize (x val))) → Vec Var (tySize (x val)) × Vec Var (maxTySizeOver (enum u) x - tySize (x val))
maxTySplitAux u val x vec = splitAt (tySize (x val)) vec


maxTySplit : ∀ u (val : ⟦ u ⟧) (x : ⟦ u ⟧ → U) → Vec Var (maxTySizeOver (enum u) x) → Vec Var (tySize (x val)) × Vec Var (maxTySizeOver (enum u) x - tySize (x val))
maxTySplit u val x vec = maxTySplitAux u val x (subst (Vec ℕ) (maxTyVecSizeEq u val x) vec)

