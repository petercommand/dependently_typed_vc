open import Agda.Builtin.Nat

open import Data.Bool hiding (_≤_)
open import Data.Empty
open import Data.Finite
open import Data.List hiding (splitAt; take; length)
open import Data.List.Membership.Propositional
open import Data.List.Misc
open import Data.List.Monad
open import Data.List.Occ
open import Data.List.Properties
open import Data.List.Relation.Unary.Any hiding (map)
open import Data.List.Relation.Unary.Any.Properties
open import Data.Nat hiding (_⊔_)
open import Data.Nat.Max
open import Data.Nat.Properties
open import Data.Nat.Properties2
open import Data.Product hiding (map)
open import Data.Sum hiding (map)
open import Data.Unit hiding (_≤_)
open import Data.Vec hiding ([_]; _>>=_; splitAt; map; take) renaming (_++_ to _V++_)
open import Data.Vec.Split

open import Function

open import Relation.Binary
open import Relation.Binary.PropositionalEquality renaming ([_] to ℝ[_])
import Relation.Binary.HeterogeneousEquality
module HE = Relation.Binary.HeterogeneousEquality
open import Relation.Binary.HeterogeneousEquality.Core


open import Relation.Nullary

module Language.TySize (f : Set) (finite : Finite f) where
open import Language.Common
import Language.Universe

open import Level renaming (zero to lzero; suc to lsuc)

open Language.Universe f

open import Axiom.Extensionality.Propositional


postulate
  ext : ∀ {ℓ} {ℓ'} → Axiom.Extensionality.Propositional.Extensionality ℓ ℓ'

∈->>= : ∀ {a} {A : Set a} {b} {B : Set b} (l : List A) (f : A → List B) → ∀ x → x ∈ l → ∀ y → y ∈ f x → y ∈ l >>= f
∈->>= .(x ∷ _) f x (here refl) y mem' = ++⁺ˡ mem'
∈->>= .(_ ∷ _) f x (there mem) y mem' = ++⁺ʳ (f _) (∈->>= _ f x mem y mem')

∈->>=⁻ : ∀ {a} {A : Set a} {b} {B : Set b} (l : List A) (f : A → List B) → ∀ y → y ∈ l >>= f → ∃ (λ x → x ∈ l × y ∈ f x)
∈->>=⁻ (x ∷ l) f y y∈l>>=f with ++⁻ (f x) y∈l>>=f
∈->>=⁻ (x ∷ l) f y y∈l>>=f | inj₁ x₁ = x , (here refl) , x₁
∈->>=⁻ (x ∷ l) f y y∈l>>=f | inj₂ y₁ with ∈->>=⁻ l f y y₁
∈->>=⁻ (x ∷ l) f y y∈l>>=f | inj₂ y₁ | x₁ , x₁∈l , y₂∈fx₁ = x₁ , (there x₁∈l) , y₂∈fx₁

data _↔_ {a} {b} (A : Set a) (B : Set b) : Set (a ⊔ b) where
  iff : (A → B) → (B → A) → A ↔ B

∈->>=↔ : ∀ {a} {b} {A : Set a} {B : Set b} (l : List A) (f : A → List B) (y : B) → (y ∈ l >>= f) ↔ (∃ (λ x → x ∈ l × y ∈ f x))
∈->>=↔ l f y = iff (∈->>=⁻ l f y) converse
  where
    converse : ∃ (λ x → x ∈ l × y ∈ f x) → y ∈ (l >>= f)
    converse (x , x∈l , y∈fx) = ∈->>= l f x x∈l y y∈fx

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
occ->>= decA decB (x₁ ∷ l) f x y prf | yes refl rewrite occ++ decB y (f x₁) (l >>= f) = cong (_+_ (occ decB y (f x₁))) (occ->>= decA decB l f x y prf)
occ->>= decA decB (x₁ ∷ l) f x y prf | no ¬p rewrite occ++ decB y (f x₁) (l >>= f) | ¬∈→occ≡0 decB y _ (prf x₁ ¬p) = occ->>= decA decB l f x y prf



∈l-∈l'-∈r : ∀ {a} {A : Set a} {b} {B : A → Set b} {c} {C : Set c} (l : List A)  (_+_ : (x : A) → B x → C)
    → ∀ x y → x ∈ l → (l' : (x : A) → List (B x)) → y ∈ l' x → x + y ∈ (l >>= λ r →
                                                                        l' r >>= λ rs →
                                                                        return (r + rs))
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
      → (∀ elem → elem ∈ eu)
      → (l : List (List (Σ ⟦ u ⟧ (λ v → ⟦ x v ⟧))))
      → (∀ elem → elem ∈ l → map proj₁ elem ≡ eu)
      → List ⟦ `Π u x ⟧
  listFuncToPi u x eu ∈eu [] proj₁l≡eu = []
  listFuncToPi u x eu ∈eu (l ∷ l₁) proj₁l≡eu = (λ dom → piFromList u x eu l (proj₁l≡eu l (here refl)) dom (∈eu dom))
                                                     ∷ listFuncToPi u x eu ∈eu l₁ (λ m m∈l → proj₁l≡eu m (there m∈l))


  safeLookup : ∀ {ℓ} {ℓ'} {A : Set ℓ} {B : A → Set ℓ'} → (elem : A) → (l : List (Σ A B)) (l' : List A) → map proj₁ l ≡ l' → elem ∈ l' → B elem
  safeLookup elem ((.elem , snd) ∷ l) .(elem ∷ map proj₁ l) refl (here refl) = snd
  safeLookup elem (x ∷ l) .(proj₁ x ∷ map proj₁ l) refl (there mem) = safeLookup elem l (map proj₁ l) refl mem


  f∈listFuncToPi : ∀ (u : U) (x : ⟦ u ⟧ → U)
                   (eu : List ⟦ u ⟧)
                   (∈eu : ∀ elem → elem ∈ eu)
                   (funcs : List (List (Σ ⟦ u ⟧ (λ v → ⟦ x v ⟧))))
                   (func : List (Σ ⟦ u ⟧ (λ v → ⟦ x v ⟧)))
                   (eq : (x₁ : List (Σ ⟦ u ⟧ (λ v → ⟦ x v ⟧))) →
                            x₁ ∈ funcs → map proj₁ x₁ ≡ eu)
                   (f : ⟦ `Π u x ⟧)
                   → (mem : func ∈ funcs)
                   → f ≡ (λ d → piFromList u x eu func (eq func mem) d (∈eu d))
                   → f ∈ listFuncToPi u x eu ∈eu funcs eq
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
  enum (`Π u x) =
                  let pairs = do
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

 


  dec-tuple : ∀ {u} {x : ⟦ u ⟧ → U} → (∀ {u} → Decidable {A = ⟦ u ⟧} _≡_) → Decidable {A = Σ ⟦ u ⟧ (λ v → ⟦ x v ⟧)} _≡_
  dec-tuple dec (fst , snd) (fst₁ , snd₁) with dec fst fst₁
  dec-tuple dec (fst , snd) (.fst , snd₁) | yes refl with dec snd snd₁
  dec-tuple dec (fst , snd) (.fst , .snd) | yes refl | yes refl = yes refl
  dec-tuple dec (fst , snd) (.fst , snd₁) | yes refl | no ¬p = no (λ { refl → ¬p refl })
  dec-tuple dec (fst , snd) (fst₁ , snd₁) | no ¬p = no (λ { refl → ¬p refl })

  private
    length : ∀ {ℓ} {A : Set ℓ} → List A → ℕ
    length [] = 0
    length (x ∷ l) = suc (length l)
  
    map-length : ∀ {ℓ} {ℓ'} {A : Set ℓ} {B : Set ℓ'} → (f : A → B) → (l : List A) → length (map f l) ≡ length l
    map-length f [] = refl
    map-length f (x ∷ l) = cong suc (map-length f l)
  
    map-++ : ∀ {ℓ} {ℓ'} {A : Set ℓ} {B : Set ℓ'} → (f : A → B) → (l₁ l₂ : List A) → map f (l₁ ++ l₂) ≡ map f l₁ ++ map f l₂
    map-++ f [] l₂ = refl
    map-++ f (x ∷ l₁) l₂ = cong (_∷_ (f x)) (map-++ f l₁ l₂)
  
    ++-length : ∀ {ℓ} {A : Set ℓ} → (l l' : List A) → length (l ++ l') ≡ length l + length l'
    ++-length [] l' = refl
    ++-length (x ∷ l) l' = cong suc (++-length l l')
  
    take : ∀ {ℓ} {A : Set ℓ} → ℕ → List A → List A
    take zero l = []
    take (suc n) [] = []
    take (suc n) (x ∷ l) = x ∷ take n l

  dec≡0→dec-tuple≡0 : ∀ u (x : ⟦ u ⟧ → U) (dec : ∀ {u} → Decidable {A = ⟦ u ⟧} _≡_) (fst : ⟦ u ⟧) (snd : ⟦ x fst ⟧) xs → occ dec fst (map proj₁ xs) ≡ 0 → occ (dec-tuple dec) (ann ⟦ `Σ u x ⟧ (fst , snd)) xs ≡ 0
  dec≡0→dec-tuple≡0 u x dec fst snd [] oc = refl
  dec≡0→dec-tuple≡0 u x dec fst snd (x₁ ∷ xs) oc with dec fst (proj₁ x₁)
  dec≡0→dec-tuple≡0 u x dec fst snd (x₁ ∷ xs) oc | no ¬p = dec≡0→dec-tuple≡0 u x dec fst snd xs oc

  piFromListLem : ∀ u x (dec : ∀ {u} → Decidable {A = ⟦ u ⟧} _≡_) x₁ (x₂ : Σ ⟦ u ⟧ (λ v → ⟦ x v ⟧)) (px : proj₁ x₂ ≡ x₁) eu l (uniq : occ dec x₁ eu ≡ 1) p → (prf : x₁ ∈ eu) (prf' : x₂ ∈ l) → (x₁ , piFromList u x eu l p x₁ prf) ≡ x₂
  piFromListLem u x dec .(proj₁ x₂) x₂ px .(proj₁ x₂ ∷ map proj₁ _) .(x₂ ∷ _) uniq refl (here refl) (here refl) = refl
  piFromListLem u x dec x₁ x₂ refl x₃ (x₄ ∷ xs) uniq refl (here refl) m@(there prf') with mem-occ (dec-tuple dec) _ _ m
  ... | t with dec (proj₁ x₄) (proj₁ x₄)
  piFromListLem u x dec ._ (._ , snd₁) refl .(map proj₁ ((fst , snd) ∷ xs)) ((fst , snd) ∷ xs) uniq refl (here refl) (there prf') | t | yes refl with dec snd₁ snd
  piFromListLem u x dec _ (_ , .snd) refl .(map proj₁ ((fst , snd) ∷ xs)) ((fst , snd) ∷ xs) uniq refl (here refl) (there prf') | t | yes refl | yes refl = refl
  piFromListLem u x dec _ (_ , snd₁) refl .(map proj₁ ((fst , snd) ∷ xs)) ((fst , snd) ∷ xs) uniq refl (here refl) (there prf') | t | yes refl | no ¬p rewrite dec≡0→dec-tuple≡0 u x dec fst snd₁ xs (cong pred uniq) with t
  ... | ()
  piFromListLem u x dec .(proj₁ x₄) (.(proj₁ x₄) , _) refl .(map proj₁ (x₄ ∷ xs)) (x₄ ∷ xs) uniq refl (here refl) (there prf') | t | no ¬p = ⊥-elim (¬p refl)
  piFromListLem u x dec .(proj₁ x₂) x₂ refl .(proj₁ x₂ ∷ map proj₁ _) .(x₂ ∷ _) uniq refl (there prf) (here refl) with s≤s (mem-occ dec _ _ prf)
  ... | t with dec (proj₁ x₂) (proj₁ x₂)
  piFromListLem u x dec .(proj₁ x₂) x₂ refl .(map proj₁ (x₂ ∷ _)) .(x₂ ∷ _) uniq refl (there prf) (here refl) | t | yes p rewrite uniq with t
  ... | s≤s ()
  piFromListLem u x dec .(proj₁ x₂) x₂ refl .(map proj₁ (x₂ ∷ _)) .(x₂ ∷ _) uniq refl (there prf) (here refl) | t | no ¬p = ⊥-elim (¬p refl)
  piFromListLem u x dec .(proj₁ x₂) x₂ refl (.(proj₁ x₃) ∷ .(map proj₁ l)) (x₃ ∷ l) uniq refl (there prf) (there prf') with dec (proj₁ x₂) (proj₁ x₃)
  piFromListLem u x dec ._ (._ , snd) refl _ (x₃ ∷ l) uniq refl (there prf) (there prf') | yes refl with mem-occ dec _ _ prf
  ... | t rewrite cong pred uniq with t
  ... | ()
  piFromListLem u x dec .(proj₁ x₂) x₂ refl (.(proj₁ x₃) ∷ .(map proj₁ l)) (x₃ ∷ l) uniq refl (there prf) (there prf') | no ¬p = piFromListLem u x dec (proj₁ x₂) x₂ refl (map proj₁ l) l uniq refl prf prf'

  piToList∘piFromList≡idAux : ∀ u x (dec : ∀ {u} → Decidable {A = ⟦ u ⟧} _≡_) eu (∈eu : ∀ x → x ∈ eu) eu' eu'' (eq : eu'' ++ eu' ≡ eu) l l' l'' (lenEq : length eu' ≡ length l') (eq' : l'' ++ l' ≡ l) (uniq : ∀ v → occ dec v eu ≡ 1) (p : map proj₁ l ≡ eu) → piToList u x eu' (λ dom → piFromList u x eu l p dom (∈eu dom)) ≡ l'
  piToList∘piFromList≡idAux u x dec eu ∈eu [] eu'' eq l [] l'' lenEq eq' uniq p = refl
  piToList∘piFromList≡idAux u x dec eu ∈eu (x₁ ∷ eu') eu'' eq l (x₂ ∷ l') l'' lenEq refl uniq refl
                      rewrite piToList∘piFromList≡idAux u x dec eu ∈eu eu' (eu'' ++ (x₁ ∷ []))
                                    (trans (++-assoc eu'' (x₁ ∷ []) eu') eq) l l' (l'' ++ (x₂ ∷ []))
                                    (cong pred lenEq)
                                    (++-assoc l'' (x₂ ∷ []) l') uniq refl
                                       = cong (λ x → x ∷ l') (piFromListLem u x dec x₁ x₂ (sym (cong (head' x₁) lem'' )) eu l (uniq x₁) refl (∈eu x₁) (++⁺ʳ l'' (here refl)))
      where

        lem : ∀ {ℓ} {A : Set ℓ} → (l₁ l₂ l₃ l₄ : List A) → length (l₁ ++ l₂) ≡ length (l₃ ++ l₄) → length l₂ ≡ length l₄ → length l₁ ≡ length l₃
        lem [] l₂ [] l₄ eq eq' = refl
        lem [] l₂ (x ∷ l₃) l₄ eq eq' rewrite ++-length l₃ l₄ | eq' = ⊥-elim (m≢1+n+m (length l₄) eq)
        lem (x ∷ l₁) l₂ [] l₄ eq eq' rewrite ++-length l₁ l₂ | eq' = ⊥-elim (m≢1+n+m (length l₄) (sym eq))
        lem (x ∷ l₁) l₂ (x₁ ∷ l₃) l₄ eq eq' = cong suc (lem l₁ l₂ l₃ l₄ (suc-injective eq) eq')


        lem' : ∀ {ℓ} {A : Set ℓ} → (l₁ l₂ l₃ l₄ : List A) → l₁ ++ l₂ ≡ l₃ ++ l₄ → length l₁ ≡ length l₃ → l₂ ≡ l₄
        lem' [] l₂ [] l₄ eq eq' = eq
        lem' (x ∷ l₁) l₂ (x₁ ∷ l₃) l₄ eq eq' = lem' l₁ l₂ l₃ l₄ (cong tail' eq) (cong pred eq')

        lem'' : x₁ ∷ eu' ≡ map proj₁ (x₂ ∷ l')
        lem'' rewrite map-++ proj₁ l'' (x₂ ∷ l') = lem' eu'' (x₁ ∷ eu') (map proj₁ l'') (proj₁ x₂ ∷ map proj₁ l') eq (lem eu'' (x₁ ∷ eu') (map proj₁ l'') (proj₁ x₂ ∷ map proj₁ l') (cong length eq) (trans lenEq (cong suc (sym (map-length proj₁ l')))))
  piToList∘piFromList≡id : ∀ u x (dec : ∀ {u} → Decidable {A = ⟦ u ⟧} _≡_)  eu (∈eu : ∀ x → x ∈ eu) l (uniq : ∀ v → occ dec v eu ≡ 1) (p : map proj₁ l ≡ eu) → piToList u x eu (λ dom → piFromList u x eu l p dom (∈eu dom)) ≡ l
  piToList∘piFromList≡id u x dec eu ∈eu l uniq refl = piToList∘piFromList≡idAux u x dec eu ∈eu eu [] refl l l []  (map-length proj₁ l) refl uniq refl

  data FuncInst {ℓ} {ℓ'} (A : Set ℓ) (B : A → Set ℓ') : List (Σ A B) → List (Σ A (λ v → List (B v))) → Set (ℓ ⊔ ℓ') where
    InstNil : FuncInst A B [] []
    InstCons : ∀ l l' → (a : A) (b : B a) (ls : List (B a)) → b ∈ ls → (ins : FuncInst A B l l') → FuncInst A B ((a , b) ∷ l) ((a , ls) ∷ l')

  occ-listFuncToPi : ∀ (u : U) (x : ⟦ u ⟧ → U)
                    (eu : List ⟦ u ⟧)
                    (∈eu : ∀ elem → elem ∈ eu)
                    (l : List (List (Σ ⟦ u ⟧ (λ v → ⟦ x v ⟧))))
                    (eq : (elem : List (Σ ⟦ u ⟧ (λ v → ⟦ x v ⟧))) →
                             elem ∈ l → map proj₁ elem ≡ eu)
                    (dec : Decidable {A = ⟦ `Π u x ⟧} _≡_)
                    (dec' : Decidable {A = List (Σ ⟦ u ⟧ (λ v → ⟦ x v ⟧))} _≡_)
                    (dec'' : ∀ {u} → Decidable {A = ⟦ u ⟧} _≡_)
                    (uniq : (v : ⟦ u ⟧) → occ dec'' v eu ≡ 1)
                    (f : ⟦ `Π u x ⟧)
                    → occ dec f (listFuncToPi u x eu ∈eu l eq) ≡ occ dec' (piToList u x eu f) l
  occ-listFuncToPi u x eu ∈eu [] eq dec dec' dec'' uniq val = refl
  occ-listFuncToPi u x eu ∈eu (l ∷ l₁) eq dec dec' dec'' uniq val with dec val (λ dom → piFromList u x eu l (eq l (here refl)) dom (∈eu dom))
  occ-listFuncToPi u x eu ∈eu (l ∷ l₁) eq dec dec' dec'' uniq val | yes p with dec' (piToList u x eu val) l
  occ-listFuncToPi u x eu ∈eu (l ∷ l₁) eq dec dec' dec'' uniq val | yes p | yes p₁ = cong suc (occ-listFuncToPi u x eu ∈eu l₁ (λ x₁ x₂ → eq x₁ (there x₂)) dec dec' dec'' uniq val)
  occ-listFuncToPi u x eu ∈eu (l ∷ l₁) eq dec dec' dec'' uniq val | yes p | no ¬p rewrite p = ⊥-elim (¬p (piToList∘piFromList≡id u x dec'' eu ∈eu l uniq (eq l (here refl)) ))
  occ-listFuncToPi u x eu ∈eu (l ∷ l₁) eq dec dec' dec'' uniq val | no ¬p with dec' (piToList u x eu val) l
  occ-listFuncToPi u x eu ∈eu (l ∷ l₁) eq dec dec' dec'' uniq val | no ¬p | yes refl = ⊥-elim (¬p (ext (λ t → piFromList∘piToList≗id u x eu ∈eu val
                                                                                                     (eq (piToList u x eu val) (here refl)) t)))
  occ-listFuncToPi u x eu ∈eu (l ∷ l₁) eq dec dec' dec'' uniq val | no ¬p | no ¬p₁ = occ-listFuncToPi u x eu ∈eu l₁ (λ x₁ x₂ → eq x₁ (there x₂)) dec dec' dec'' uniq val

  map-empty : ∀ {ℓ} {ℓ'} {A : Set ℓ} {B : Set ℓ'} → (m : List A) → (f : A → B) → map f m ≡ [] → m ≡ []
  map-empty [] f eq = refl
    
  FuncInst→genFunc : ∀ u x (l : List (Σ ⟦ u ⟧ (λ v → List ⟦ x v ⟧))) (f : List (Σ ⟦ u ⟧ (λ v → ⟦ x v ⟧))) → FuncInst ⟦ u ⟧ (λ z → ⟦ x z ⟧) f l → f ∈ genFunc u x l
  FuncInst→genFunc u x .[] .[] InstNil = here refl
  FuncInst→genFunc u x .((a , ls) ∷ l') .((a , b) ∷ l) (InstCons l l' a b ls x₁ finst) with genFunc u x l' | inspect (genFunc u x) l'
  ... | t | ℝ[ refl ] = ∈->>= (genFunc u x l') _ l (FuncInst→genFunc u x l' l finst) ((a , b) ∷ l)
                            (∈->>= ls _ b x₁ ((a , b) ∷ l) (here refl))

  genFunc→FuncInst : ∀ u x l f → f ∈ genFunc u x l → FuncInst ⟦ u ⟧ (λ z → ⟦ x z ⟧) f l
  genFunc→FuncInst u x [] .[] (here refl) = InstNil
  genFunc→FuncInst u x (x₁ ∷ l) f mem with ∈->>=⁻ (genFunc u x l) (λ ac → proj₂ x₁ >>= (λ choice → ((proj₁ x₁ , choice) ∷ ac) ∷ [])) f mem
  genFunc→FuncInst u x (x₁ ∷ l) [] mem | fst , snd , trd with ∈->>=⁻ (proj₂ x₁) (λ choice → ((proj₁ x₁ , choice) ∷ fst) ∷ []) _ trd
  genFunc→FuncInst u x (x₁ ∷ l) [] mem | fst , snd , trd | fst₁ , fst₂ , here ()
  genFunc→FuncInst u x (x₁ ∷ l) [] mem | fst , snd , trd | fst₁ , fst₂ , there ()
  genFunc→FuncInst u x (x₁ ∷ l) (x₂ ∷ f) mem | fst , snd , trd with ∈->>=⁻ (proj₂ x₁) (λ choice → ((proj₁ x₁ , choice) ∷ fst) ∷ []) _ trd
  genFunc→FuncInst u x ((fst₃ , snd₁) ∷ l) (.(fst₃ , fst₁) ∷ .fst) mem | fst , snd , trd | fst₁ , fst₂ , here refl = InstCons fst l fst₃ fst₁ snd₁ fst₂ (genFunc→FuncInst u x l fst snd)

  FuncInstLem : ∀ u x (f : ⟦ `Π u x ⟧) (l : List ⟦ u ⟧) → FuncInst ⟦ u ⟧ (λ v → ⟦ x v ⟧) (piToList u x l f) (l >>= (λ r → (r , enum (x r)) ∷ []))
  FuncInstLem u x f [] = InstNil
  FuncInstLem u x f (x₁ ∷ l) = InstCons (piToList u x l f) (l >>= (λ r → (r , enum (x r)) ∷ []))
                          x₁ (f x₁) (enum (x x₁)) (enumComplete (x x₁) (f x₁)) (FuncInstLem u x f l)


  enumComplete `One tt = here refl
  enumComplete `Two false = here refl
  enumComplete `Two true = there (here refl)
  enumComplete `Base x = Finite.a∈elems finite x
  enumComplete (`Vec u zero) [] = here refl
  enumComplete (`Vec u (suc x₁)) (x ∷ x₂) = ∈l-∈l'-∈r (enum u) _∷_ x x₂ (enumComplete u x) (λ _ → enum (`Vec u x₁)) (enumComplete (`Vec u x₁) x₂)
  enumComplete (`Σ u x₁) (fst , snd) = ∈l-∈l'-∈r (enum u) _,_ fst snd (enumComplete u fst) (λ r → enum (x₁ r)) (enumComplete (x₁ fst) snd)
  enumComplete (`Π u x₁) f =
     let pairs = do
           r ← enum u
           return (r , enum (x₁ r))
         genFuncs = genFunc u x₁ pairs
         fToList = piToList u x₁ (enum u) f
         fToListFuncInstPairs = FuncInstLem u x₁ f (enum u)
         fToList∈genFuncs = FuncInst→genFunc u x₁ pairs fToList fToListFuncInstPairs
         prf = trans
                  (genFuncProj₁ u x₁ pairs fToList fToList∈genFuncs)
                  (map-proj₁->>= (enum u) (λ x₂ → enum (x₁ x₂)))
         f≗piFromList∘piToList = piFromList∘piToList≗id u x₁ (enum u) (enumComplete u) f prf
     in f∈listFuncToPi u x₁ (enum u) (enumComplete u) genFuncs fToList _ f fToList∈genFuncs (ext f≗piFromList∘piToList)


  genFuncUniqueLem : ∀ u (x : ⟦ u ⟧ → U) (eu : List ⟦ u ⟧) (x₂ : ⟦ u ⟧) (ls : List ⟦ x x₂ ⟧) (x₃ : List (Σ ⟦ u ⟧ (λ v → ⟦ x v ⟧))) (f : ⟦ `Π u x ⟧) → ¬ piToList u x eu f ≡ x₃
      → ¬ ((x₂ , f x₂) ∷ (piToList u x eu f)) ∈ ann (List (List ⟦ `Σ u x ⟧)) (ls >>= (λ choice → ((x₂ , choice) ∷ x₃) ∷ []))
  genFuncUniqueLem u x eu x₂ ls x₃ f x₄ x₅ with ∈->>=⁻ ls (λ choice → ((x₂ , choice) ∷ x₃) ∷ []) ((x₂ , f x₂) ∷ piToList u x eu f) x₅
  genFuncUniqueLem u x eu x₂ ls .(piToList u x eu f) f x₄ x₅ | .(f x₂) , p₁ , here refl = x₄ refl


  genFuncUnique : ∀ u (x : ⟦ u ⟧ → U)
     (dec : Decidable {A = List (Σ ⟦ u ⟧ (λ v → ⟦ x v ⟧))} _≡_)
     (dec' : ∀ v → Decidable {A = ⟦ x v ⟧} _≡_)
     (eu : List ⟦ u ⟧)
     (f : ⟦ `Π u x ⟧)
    → (l : List (Σ ⟦ u ⟧ (λ v → List ⟦ x v ⟧)))
    → map proj₁ l ≡ eu
    → (∀ elem → elem ∈ l → ∀ (t : ⟦ x (proj₁ elem) ⟧) → t ∈ proj₂ elem → occ (dec' (proj₁ elem)) t (proj₂ elem) ≡ 1)
    → FuncInst ⟦ u ⟧ (λ v → ⟦ x v ⟧) (piToList u x eu f) l
    → occ dec (piToList u x eu f) (genFunc u x l) ≡ 1
  genFuncUnique u x dec dec' [] f [] eq prf inst with dec [] []
  genFuncUnique u x dec dec' [] f [] eq prf inst | yes p = refl
  genFuncUnique u x dec dec' [] f [] eq prf inst | no ¬p = ⊥-elim (¬p refl)
  genFuncUnique u x dec dec' (x₂ ∷ eu) f (.(x₂ , ls) ∷ l) eq prf (InstCons .(piToList u x eu f) .l .x₂ .(f x₂) ls x₁ inst)
      with genFuncUnique u x dec dec' eu f l (cong tail' eq) (λ elem x₃ t x₄ → prf elem (there x₃) t x₄) inst
  ... | ind rewrite occ->>= dec dec (genFunc u x l) (λ ac → ls >>= (λ choice → ((x₂ , choice) ∷ ac) ∷ [])) (piToList u x eu f) ((x₂ , f x₂) ∷ piToList u x eu f) (λ x₃ x₄ x₅ → genFuncUniqueLem u x eu x₂ ls x₃ f x₄ x₅)
                  | ind
                  | occ->>= (dec' x₂) dec ls (λ choice → ((x₂ , choice) ∷ piToList u x eu f) ∷ []) (f x₂) ((x₂ , f x₂) ∷ piToList u x eu f) (λ { x₃ x₄ (here refl) → x₄ refl})
                  | prf (x₂ , ls) (here refl) (f x₂) x₁
      with dec ((x₂ , f x₂) ∷ piToList u x eu f) ((x₂ , f x₂) ∷ piToList u x eu f)
  ... | yes p = refl
  ... | no ¬p = ⊥-elim (¬p refl)

  enumUniqueLem : ∀ u x x₁ x₂ (val : Vec ⟦ u ⟧ x) → ¬ x₁ ≡ x₂ → ¬ x₁ ∷ val ∈ enum (`Vec u x) >>= (λ rs → ann (Vec ⟦ u ⟧ (suc x)) (x₂ ∷ rs) ∷ [])
  enumUniqueLem u x x₁ x₂ val neq mem with ∈->>=⁻ (enum (`Vec u x)) (λ rs → ann (Vec ⟦ u ⟧ (suc x)) (x₂ ∷ rs) ∷ []) (x₁ ∷ val) mem
  enumUniqueLem u x .x₂ x₂ .elem neq mem | elem , prf₁ , here refl = ⊥-elim (neq refl)

  enumUniqueLem₂ : ∀ u x x₁ x₂ (val : Vec ⟦ u ⟧ x) → ¬ val ≡ x₂ → ¬ x₁ ∷ val ∈ ann (Vec ⟦ u ⟧ (suc x)) (x₁ ∷ x₂) ∷ []
  enumUniqueLem₂ u x x₁ x₂ .x₂ neq (here refl) = ⊥-elim (neq refl)

  enumUniqueLem₃ : ∀ u x (x₁ : ⟦ u ⟧) fst snd → ¬ fst ≡ x₁ → ¬ (fst , snd) ∈ ann (List ⟦ `Σ u x ⟧) (enum (x x₁) >>= (λ rs → (x₁ , rs) ∷ []))
  enumUniqueLem₃ u x x₁ fst snd neq mem with ∈->>=⁻ (enum (x x₁)) (λ rs → (x₁ , rs) ∷ []) (fst , snd) mem
  enumUniqueLem₃ u x x₁ .x₁ .x' neq mem | x' , p₁ , here refl = neq refl

  enumUnique : ∀ u → (val : ⟦ u ⟧) → (dec : ∀ {u} → Decidable {A = ⟦ u ⟧} _≡_) → occ dec val (enum u) ≡ 1
  enumUnique `One tt dec with dec tt tt
  enumUnique `One tt dec | yes p = refl
  enumUnique `One tt dec | no ¬p = ⊥-elim (¬p refl)
  enumUnique `Two val dec with dec val false
  enumUnique `Two .false dec | yes refl with dec false true
  enumUnique `Two .false dec | yes refl | no ¬p = refl
  enumUnique `Two val dec | no ¬p with dec val true
  enumUnique `Two val dec | no ¬p | yes p = refl
  enumUnique `Two false dec | no ¬p | no ¬p₁ = ⊥-elim (¬p refl)
  enumUnique `Two true dec | no ¬p | no ¬p₁ = ⊥-elim (¬p₁ refl)
  enumUnique `Base val dec = Finite.occ-1 finite val dec
  enumUnique (`Vec u zero) [] dec with dec {`Vec u zero} [] []
  enumUnique (`Vec u zero) [] dec | yes p = refl
  enumUnique (`Vec u zero) [] dec | no ¬p = ⊥-elim (¬p refl)
  enumUnique (`Vec u (suc x)) (x₁ ∷ val) dec rewrite occ->>= dec dec (enum u) (λ r → enum (`Vec u x) >>= (λ rs → ann ⟦ `Vec u (suc x) ⟧ (r ∷ rs) ∷ [])) x₁ (x₁ ∷ val) (λ x₂ x₃ x₄ → enumUniqueLem u x x₁ x₂ val x₃ x₄)
                                                                     | enumUnique u x₁ dec
                                                                     | occ->>= dec dec (enum (`Vec u x)) (λ rs → ann ⟦ `Vec u (suc x) ⟧ (x₁ ∷ rs) ∷ []) val (x₁ ∷ val) λ x₂ x₃ x₄ → enumUniqueLem₂ u x x₁ x₂ val x₃ x₄
      with dec {`Vec u (suc x)} (x₁ ∷ val) (x₁ ∷ val)
  ... | yes p rewrite enumUnique (`Vec u x) val dec = refl
  ... | no ¬p = ⊥-elim (¬p refl)
  enumUnique (`Σ u x) (fst , snd) dec rewrite occ->>= dec dec (enum u) (λ r → enum (x r) >>= (λ rs → (r , rs) ∷ [])) fst (fst , snd) (λ x₁ x₂ x₃ → enumUniqueLem₃ u x x₁ fst snd x₂ x₃)
                                                              | enumUnique u fst dec
                                                              | occ->>= dec dec (enum (x fst))  (λ rs → ann ⟦ `Σ u x ⟧ (fst , rs) ∷ []) snd (fst , snd) (λ { x₁ x₂ (here refl) → x₂ refl})
      with dec {`Σ u x} (fst , snd) (fst , snd)
  ... | yes p rewrite enumUnique (x fst) snd dec = refl
  ... | no ¬p = ⊥-elim (¬p refl)
  enumUnique (`Π u x) val dec = 
     trans (
       occ-listFuncToPi u x (enum u) (enumComplete u) (genFunc u x (enum u >>= (λ r → (r , enum (x r)) ∷ []))) (λ x₁ x₁∈genFunc →
          trans
          (genFuncProj₁ u x (enum u >>= (λ r → (r , enum (x r)) ∷ [])) x₁
           x₁∈genFunc)
          (map-proj₁->>= (enum u) (λ x₂ → enum (x x₂)))) dec (≡-dec (dec-tuple dec)) dec (λ v → enumUnique u v dec) val)
       (genFuncUnique u x (≡-dec (dec-tuple dec)) (λ v → dec {x v})
            (enum u) val (enum u >>= (λ r → (r , enum (x r)) ∷ []))
            (map-proj₁->>= (enum u) (λ r → enum (x r))) lem (FuncInstLem u x val (enum u)))
    where
      lem : (elem : Σ ⟦ u ⟧ (λ v → List ⟦ x v ⟧))
          → elem ∈ (enum u >>= (λ r → (r , enum (x r)) ∷ []))
          → (t : ⟦ x (proj₁ elem) ⟧)
          → t ∈ proj₂ elem
          → occ dec t (proj₂ elem) ≡ 1
      lem elem me t t∈ with ∈->>=⁻ (enum u) (λ r → (r , enum (x r)) ∷ []) elem me
      lem .(fst , enum (x fst)) me t t∈ | fst , fst₁ , here refl = enumUnique (x fst) t dec
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

maxTySplitCorrect : ∀ u val x vec → vec HE.≅ proj₁ (maxTySplit u val x vec) V++ proj₂ (maxTySplit u val x vec)
maxTySplitCorrect u val x vec with splitAtCorrect (tySize (x val)) (subst (Vec ℕ) (maxTyVecSizeEq u val x) vec)
... | eq with splitAt (tySize (x val)) (subst (Vec ℕ) (maxTyVecSizeEq u val x) vec)
... | fst , snd = HE.trans
                    (HE.sym
                     (HE.≡-subst-removable (Vec ℕ)
                      (maxTyVecSizeEq u val x)
                      vec))
                    (HE.trans (≡-to-≅ eq) HE.refl)
