module VecUtil where
open import Data.Nat using (ℕ; zero; suc)
open import Data.Fin using (Fin; 0F) renaming (zero to fzero; suc to fsuc)
open import Data.Vec using (Vec; lookup; tabulate; foldr; _∷_; []; _[_]=_; here; there)
open import Data.Fin.Subset using (Subset; _∪_) renaming (⊥ to ∅)
open import Data.Bool using (Bool; T; false; true; not)
open import Relation.Nullary using (Dec; ¬_; yes; no)
open import Data.Empty using (⊥; ⊥-elim)
import Relation.Binary.PropositionalEquality as Eq
open Eq using (_≡_; refl; subst; sym; trans; cong)
open Eq.≡-Reasoning
open import Data.Unit using (⊤; tt)

!-syntax = lookup
syntax !-syntax v i = v ! i

ifPresentOrElse : ∀{m} {A : Set} → Fin m → Subset m → (B : Fin m → A) → A → A
ifPresentOrElse i s f z with s ! i
... | false = z
... | true = f i

mapS : {n : ℕ} {A : Set} → Subset n → (B : Fin n → A) → A → Vec A n
mapS ss f z = tabulate λ i → ifPresentOrElse i ss f z

U : ∀ {m}{n} → Vec (Subset n) m → Subset n
U {n} = foldr _ _∪_ ∅

v[i]=v!i : ∀{n} {A : Set}
  → (V : Vec A n)
  → (i : Fin n)
  → V [ i ]= V ! i
v[i]=v!i (x ∷ V) Data.Fin.0F = here
v[i]=v!i (x ∷ V) (fsuc i) = there (v[i]=v!i V i)

s!i≡s[i] : ∀{n}{A : Set}{s : Vec A n}{i}{v}
  → s [ i ]= v
  → s ! i ≡ v
s!i≡s[i] here = refl
s!i≡s[i] (there p) = s!i≡s[i] p


_∈_ : ∀{n} → (p : Fin n) → (ss : Subset n) → Set
p ∈ ss = T(lookup ss p)

_∉_ : ∀{n} → (p : Fin n) → (ss : Subset n) → Set
p ∉ ss = ¬ T(lookup ss p)

_∈?_ : ∀{n} → (p : Fin n) → (ss : Subset n) → Dec (p ∈ ss)
0F ∈? (false ∷ z) = no (λ z → z)
0F ∈? (true ∷ z) = yes tt
fsuc p ∈? (x ∷ z) = p ∈? z
