module Nfa where
open import Data.Char as Char using (Char)
open import Data.Nat using (ℕ; zero; suc; _+_; _≤_; _≥_; _<?_; _≤?_; s≤s; z≤n)
open import Data.Fin
  using (Fin; inject+; 0F; raise)
  renaming (zero to fzero; suc to fsuc)
open import Data.Fin.Subset as Subset
  using (Subset; ⁅_⁆; _∪_; _∩_; _∈_; Nonempty)
  renaming (⊥ to ∅; ⊤ to FullSet)
open import Data.Fin.Properties using (_≟_)
open import Data.Bool using (Bool; false; true; _∨_; _∧_; T)
open import Data.Bool.Properties using (T?)
open import Data.Product using (_×_; Σ; ∃; Σ-syntax; ∃-syntax; _,_; proj₁; proj₂)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.Unit using (⊤; tt)
open import Data.Empty using (⊥-elim)
open import Relation.Nullary using (Dec; yes; no; ¬_)
open import String using (String; _∷_; []; ++-idˡ; ++-idʳ) renaming (_++_ to _++ˢ_)
open import Data.Vec renaming (_∷_ to _∷v_; [] to []v) hiding (concat; splitAt)
open import Data.Vec.Properties
open import Data.Vec.Relation.Unary.Any using (index) renaming (any to any?)
open import VecUtil
open import Equivalence
import Relation.Binary.PropositionalEquality as Eq
open Eq using (_≡_; refl; subst; sym; trans; cong)

record Nfa (n : ℕ) : Set where
  field
    S : Fin n
    δ : Fin n → Char → Subset n
    F : Subset n

δ̂ : ∀{n} → Nfa n → (Subset n) → String → (Subset n)
δ̂ {n} nfa qs [] = qs
δ̂ {n} nfa qs (x ∷ s) = δ̂ nfa (onestep qs x) s
  where
    onestep : (Subset n) → Char → (Subset n)
    onestep qs c = U (mapS qs (λ q → Nfa.δ nfa q c) ∅)

infix 10 _↓′_
_↓′_ : ∀{n} → Nfa n → String → Set
nfa ↓′ s  = Nonempty ((Nfa.F nfa) ∩ (δ̂ nfa ⁅ Nfa.S nfa ⁆ s))


any : ∀{n} → (P : Fin n → Bool) → Bool
any {zero}  f = false
any {suc _} f = f fzero ∨ any λ x → f (fsuc x)

accepts : ∀{n} → Nfa n → Fin n → String → Bool
accepts nfa q []       = Nfa.F nfa ! q
accepts nfa q (c ∷ s) = any λ p → Nfa.δ nfa q c ! p ∧ accepts nfa p s

infix 10 _↓_
_↓_ : ∀{n} → Nfa n → String → Set
nfa ↓ s  = T (accepts nfa (Nfa.S nfa) s)


_↓?_ : ∀{n} → (nfa : Nfa n) → (s : String) → Dec (nfa ↓ s)
nfa ↓? s with accepts nfa (Nfa.S nfa) s
... | false = no (λ z → z)
... | true = yes tt

splitAt : ∀ m {n} → Fin (m + n) → Fin m ⊎ Fin n
splitAt zero    i        = inj₂ i
splitAt (suc m) fzero    = inj₁ fzero
splitAt (suc m) (fsuc i) = Data.Sum.map fsuc (λ x → x) (splitAt m i)

concatNfa : ∀{n m} → Nfa n → Nfa m → Nfa (1 + n + m)
concatNfa {n} {m} nfaL nfaR =
  record
    { S = fzero
    ; δ = δ
    ; F = F
    }
  where
    δ : Fin (1 + n + m) → Char → Subset (1 + n + m)
    δ q c with splitAt 1 q
    δ q c | inj₁ z with Nfa.S nfaL ∈? Nfa.F nfaL
    δ q c | inj₁ z | yes isf           = ∅ {1} ++ (Nfa.δ nfaL (Nfa.S nfaL) c) ++ (Nfa.δ nfaR (Nfa.S nfaR) c)
    δ q c | inj₁ z | no ¬isf           = ∅ {1} ++ (Nfa.δ nfaL (Nfa.S nfaL) c) ++             ∅
    δ q c | inj₂ mn with splitAt n mn
    δ q c | inj₂ mn | inj₁ l with l ∈? Nfa.F nfaL
    δ q c | inj₂ mn | inj₁ l | yes isf = ∅ {1} ++ (Nfa.δ nfaL l c)            ++ (Nfa.δ nfaR (Nfa.S nfaR) c)
    δ q c | inj₂ mn | inj₁ l | no ¬isf = ∅ {1} ++ (Nfa.δ nfaL l c)            ++             ∅
    δ q c | inj₂ mn | inj₂ r           = ∅ {1} ++             ∅               ++ (Nfa.δ nfaR r c)

    F : Subset (1 + n + m)
    F with Nfa.S nfaL ∈? Nfa.F nfaL
    F | yes p = ⁅ fzero ⁆ ++ (Nfa.F nfaR)
    F | no ¬p =     ∅     ++ (Nfa.F nfaR)

unionNfa : ∀{n m} → Nfa n → Nfa m → Nfa (1 + n + m)
unionNfa {n} {m} nfaL nfaR =
  record
    { S = fzero
    ; δ = δ
    ; F = sf ++ (Nfa.F nfaL) ++ (Nfa.F nfaR)
    }
  where
    δ : Fin (1 + n + m) → Char → Subset (1 + n + m)
    δ q c  with splitAt 1 q
    δ q c | inj₁ z                    = ∅ {1} ++ (Nfa.δ nfaL (Nfa.S nfaL) c) ++ (Nfa.δ nfaR (Nfa.S nfaR) c)
    δ q c | inj₂ f with splitAt n f
    δ q c | inj₂ f | inj₁ l with l ≟ Nfa.S nfaL
    δ q c | inj₂ f | inj₁ l | yes isS = ∅ {1} ++ (Nfa.δ nfaL l c)            ++ (Nfa.δ nfaR (Nfa.S nfaR) c)
    δ q c | inj₂ f | inj₁ l | no ¬isS = ∅ {1} ++ (Nfa.δ nfaL l c)            ++ ∅
    δ q c | inj₂ f | inj₂ r           = ∅ {1} ++ ∅                           ++ (Nfa.δ nfaR r c)

    sf : Subset 1
    sf with Nfa.S nfaL ∈? Nfa.F nfaL | Nfa.S nfaR ∈? Nfa.F nfaR
    sf | no ¬ε∈l | no ¬ε∈r = false ∷v []v
    sf | _     | _         = true ∷v []v

starNfa : ∀{n} → Nfa n → Nfa (suc n)
starNfa nfa with any? T? (Nfa.F nfa)
starNfa {n} nfa | yes p =
  record
    { S = fzero
    ; δ = δ
    ; F = ⁅ fzero ⁆ ++ Nfa.F nfa
    }
  where
    δ : Fin (suc n) → Char → Subset (suc n)
    δ q c with splitAt 1 q
    δ q c | inj₁ z = ∅ ++ (Nfa.δ nfa (Nfa.S nfa) c)
    δ q c | inj₂ p with p ∈? Nfa.F nfa
    δ q c | inj₂ p | yes isf = ∅ ++ (⁅ Nfa.S nfa ⁆ ∪ (Nfa.δ nfa p) c)
    δ q c | inj₂ p | no ¬isf = ∅ ++                  (Nfa.δ nfa p) c
starNfa {suc n} nfa | no ¬p =
  record
    { S = fzero
    ; δ = λ _ _ → ⁅ fsuc fzero ⁆
    ; F = ⁅ fzero ⁆
    }

injectOrR : ∀{u b} → T(b) → T(u ∨ b)
injectOrR {false} {true} tt = tt
injectOrR {true} {true} tt = tt

injectOrL : ∀{u b} → T(u) → T(u ∨ b)
injectOrL {true} {true} t = tt
injectOrL {true} {false} t = tt

splitOr : ∀{u b} → T(u ∨ b) → T u ⊎ T b
splitOr {false} {true} t = inj₂ tt
splitOr {true} {false} t = inj₁ tt
splitOr {true} {true} t = inj₁ tt

anyToExists : ∀{n} {f : Fin n → Bool} → T (any f) → ∃[ i ] T(f i)
anyToExists {suc n} {f} t with splitOr {f 0F} {any (λ x → f (fsuc x))} t
anyToExists {suc n} {f} t | inj₁ x = 0F , x
anyToExists {suc n} {f} t | inj₂ y with anyToExists {_} {λ u → f (fsuc u)} y
anyToExists {suc n} {f} t | inj₂ y | fst , snd = fsuc fst , snd

fromExists : ∀{n} {f : Fin n → Bool} → ∃[ i ] T(f i) → T(any f)
fromExists {_} {f} (0F , snd) = injectOrL snd
fromExists {_} {f} (fsuc fst , snd) = injectOrR (fromExists ( fst , snd ))

splitand : ∀{a b} → T (a ∧ b) → T a × T b
splitand {true} {true} tt = tt , tt

biglem : ∀{n x xs q} {nfa : Nfa n} → T (accepts nfa q (x ∷ xs)) →  ∃[ p ] (T ((Nfa.δ nfa q x) ! p) × T (accepts nfa p xs))
biglem {n} {x} {xs} {q} {nfa} p with anyToExists {n} {λ z → (Nfa.δ nfa q x) ! z ∧ accepts nfa z xs} p
... | fst , snd = fst , (splitand {(Nfa.δ nfa q x) ! fst} {accepts nfa fst xs} snd)

lem1ˡ : ∀{n m} → (v : Vec Bool n) → (w : Vec Bool m)
  → (p : Fin n)
  → T (v ! p)
  → T ((v ++ w) ! (inject+ m p))
lem1ˡ v w p x = subst (λ v → T v) (sym (lookup-++ˡ v w p)) x

lem1ʳ : ∀{n m} → (v : Vec Bool n) → (w : Vec Bool m)
  → (p : Fin m)
  → T (w ! p)
  → T ((v ++ w) ! (raise n p))
lem1ʳ v w p x = subst (λ v → T v) (sym (lookup-++ʳ v w p)) x

lem3 : ∀{n} {w} {v : Subset n} → v [ w ]= true → T (v ! w)
lem3 t = subst (λ v → T v) (sym (s!i≡s[i] t)) tt

joinand : ∀{a} {b} → T a → T b → T (a ∧ b)
joinand {true} {true} _ _ = tt

splitAt-inject+ : ∀ m n i → splitAt m (inject+ n i) ≡ inj₁ i
splitAt-inject+ (suc m) n fzero = refl
splitAt-inject+ (suc m) n (fsuc i) rewrite splitAt-inject+ m n i = refl

splitAt-raise : ∀ m n i → splitAt m (raise {n} m i) ≡ inj₂ i
splitAt-raise zero    n i = refl
splitAt-raise (suc m) n i rewrite splitAt-raise m n i = refl

lemmaLookupT : ∀{n} {v : Vec Bool n} {w} → T(v ! w) → v [ w ]= true
lemmaLookupT {_} {x ∷v v} {0F} t with (x ∷v v) ! 0F
lemmaLookupT {_} {x ∷v v} {0F} t | true = here
lemmaLookupT {_} {x ∷v v} {fsuc w} t = there (lemmaLookupT t)


union-accepts-left : ∀{n m} {s} {q} {nfaL : Nfa n} {nfaR : Nfa m}
  → T (accepts nfaL q s)
  → T (accepts (unionNfa nfaL nfaR) (raise 1 (inject+ m q)) s)
union-accepts-left {n} {m} {[]} {q} {nfaL} {nfaR} x with Nfa.S nfaL ∈? Nfa.F nfaL | Nfa.S nfaR ∈? Nfa.F nfaR | lem1ˡ (Nfa.F nfaL) (Nfa.F nfaR) q x
...| yes _ | yes _ | v = v
...| yes _ | no  _ | v = v
...| no  _ | yes _ | v = v
...| no  _ | no  _ | v = v
union-accepts-left {n} {m} {c ∷ s} {q} {nfaL} {nfaR} x with Nfa.S nfaL ∈? Nfa.F nfaL | Nfa.S nfaR ∈? Nfa.F nfaR | splitAt n (inject+ m q) | splitAt-inject+ n m q
union-accepts-left {n} {m} {c ∷ s} {_} {nfaL} {nfaR} x | yes _ | yes _ | inj₁ o | refl with o ≟ Nfa.S nfaL | biglem {n}{c}{s} x
union-accepts-left {n} {m} {c ∷ s} {_} {nfaL} {nfaR} x | yes _ | yes _ | inj₁ o | refl | yes _ | w , v , t with union-accepts-left {n}{m}{s}{w}{nfaL}{nfaR} t
... | u with lem1ˡ (Nfa.δ nfaL o c) (Nfa.δ nfaR (Nfa.S nfaR) c) w (lem3 {n}{w}{Nfa.δ nfaL o c} (lemmaLookupT v))
... | i = fromExists (inject+ m w , (joinand i u))
union-accepts-left {n} {m} {c ∷ s} {_} {nfaL} {nfaR} x | yes _ | yes _ | inj₁ o | refl | no  _ | w , v , t
  with union-accepts-left {n}{m}{s}{w}{nfaL}{nfaR} t
    | lem1ˡ {n}{m} (Nfa.δ nfaL o c) ∅ w (lem3 {n}{w}{Nfa.δ nfaL o c} (lemmaLookupT v))
... | u | i = fromExists (inject+ m w , (joinand i u))
union-accepts-left {n} {m} {c ∷ s} {q} {nfaL} {nfaR} x | yes _ | no _ | inj₁ o | refl with o ≟ Nfa.S nfaL | biglem {n}{c}{s} x
union-accepts-left {n} {m} {c ∷ s} {_} {nfaL} {nfaR} x | yes _ | no _ | inj₁ o | refl | yes _ | w , v , t with union-accepts-left {n}{m}{s}{w}{nfaL}{nfaR} t
... | u with lem1ˡ (Nfa.δ nfaL o c) (Nfa.δ nfaR (Nfa.S nfaR) c) w (lem3 {n}{w}{Nfa.δ nfaL o c} (lemmaLookupT v))
... | i = fromExists (inject+ m w , (joinand i u))
union-accepts-left {n} {m} {c ∷ s} {_} {nfaL} {nfaR} x | yes _ | no _ | inj₁ o | refl | no  _ | w , v , t
  with union-accepts-left {n}{m}{s}{w}{nfaL}{nfaR} t
    | lem1ˡ {n}{m} (Nfa.δ nfaL o c) ∅ w (lem3 {n}{w}{Nfa.δ nfaL o c} (lemmaLookupT v))
... | u | i = fromExists (inject+ m w , (joinand i u))
union-accepts-left {n} {m} {c ∷ s} {_} {nfaL} {nfaR} x | no _ | yes _ | inj₁ o | refl with o ≟ Nfa.S nfaL | biglem {n}{c}{s} x
union-accepts-left {n} {m} {c ∷ s} {_} {nfaL} {nfaR} x | no _ | yes _ | inj₁ o | refl | yes _ | w , v , t with union-accepts-left {n}{m}{s}{w}{nfaL}{nfaR} t
... | u with lem1ˡ (Nfa.δ nfaL o c) (Nfa.δ nfaR (Nfa.S nfaR) c) w (lem3 {n}{w}{Nfa.δ nfaL o c} (lemmaLookupT v))
... | i = fromExists (inject+ m w , (joinand i u))
union-accepts-left {n} {m} {c ∷ s} {_} {nfaL} {nfaR} x | no _ | yes _ | inj₁ o | refl | no  _ | w , v , t
  with union-accepts-left {n}{m}{s}{w}{nfaL}{nfaR} t
    | lem1ˡ {n}{m} (Nfa.δ nfaL o c) ∅ w (lem3 {n}{w}{Nfa.δ nfaL o c} (lemmaLookupT v))
... | u | i = fromExists (inject+ m w , (joinand i u))
union-accepts-left {n} {m} {c ∷ s} {_} {nfaL} {nfaR} x | no _ | no _ | inj₁ o | refl with o ≟ Nfa.S nfaL | biglem {n}{c}{s} x
union-accepts-left {n} {m} {c ∷ s} {_} {nfaL} {nfaR} x | no _ | no _ | inj₁ o | refl | yes _ | w , v , t with union-accepts-left {n}{m}{s}{w}{nfaL}{nfaR} t
... | u with lem1ˡ (Nfa.δ nfaL o c) (Nfa.δ nfaR (Nfa.S nfaR) c) w (lem3 {n}{w}{Nfa.δ nfaL o c} (lemmaLookupT v))
... | i = fromExists (inject+ m w , (joinand i u))
union-accepts-left {n} {m} {c ∷ s} {_} {nfaL} {nfaR} x | no _ | no _ | inj₁ o | refl | no  _ | w , v , t
  with union-accepts-left {n}{m}{s}{w}{nfaL}{nfaR} t
    | lem1ˡ {n}{m} (Nfa.δ nfaL o c) ∅ w (lem3 {n}{w}{Nfa.δ nfaL o c} (lemmaLookupT v))
... | u | i = fromExists (inject+ m w , (joinand i u))


union-accepts-right : ∀{n m} {s} {q} {nfaL : Nfa n} {nfaR : Nfa m}
  → T (accepts nfaR q s)
  → T (accepts (unionNfa nfaL nfaR) (raise (1 + n) q) s)
union-accepts-right {n} {m} {[]} {q} {nfaL} {nfaR} p with Nfa.S nfaL ∈? Nfa.F nfaL | Nfa.S nfaR ∈? Nfa.F nfaR | lem1ʳ (Nfa.F nfaL) (Nfa.F nfaR) q p
... | yes _ | yes _ | v = v
... | yes _ | no  _ | v = v
... | no  _ | yes _ | v = v
... | no  _ | no  _ | v = v
union-accepts-right {n} {m} {c ∷ s} {q} {nfaL} {nfaR} p
  with Nfa.S nfaL ∈? Nfa.F nfaL
    | Nfa.S nfaR ∈? Nfa.F nfaR
    | splitAt n (raise n q)
    | splitAt-raise n m q
union-accepts-right {n} {m} {c ∷ s} {q} {nfaL} {nfaR} p | yes _ | yes _ | inj₂ o | refl with biglem {m}{c}{s} p
... | w , v , t with union-accepts-right {n}{m}{s}{w}{nfaL}{nfaR} t
... | u with lem1ʳ {n} {m} (∅) (Nfa.δ nfaR o c) w (lem3 {m}{w}{Nfa.δ nfaR o c} (lemmaLookupT v))
... | i = fromExists (raise n w , (joinand i u))
union-accepts-right {n} {m} {c ∷ s} {q} {nfaL} {nfaR} p  | yes _ | no  _ | inj₂ o | refl with biglem {m}{c}{s} p
... | w , v , t with union-accepts-right {n}{m}{s}{w}{nfaL}{nfaR} t
... | u with lem1ʳ {n} {m} (∅) (Nfa.δ nfaR o c) w (lem3 {m}{w}{Nfa.δ nfaR o c} (lemmaLookupT v))
... | i = fromExists (raise n w , (joinand i u))
union-accepts-right {n} {m} {c ∷ s} {q} {nfaL} {nfaR} p  | no  _ | yes _ | inj₂ o | refl with biglem {m}{c}{s} p
... | w , v , t with union-accepts-right {n}{m}{s}{w}{nfaL}{nfaR} t
... | u with lem1ʳ {n} {m} (∅) (Nfa.δ nfaR o c) w (lem3 {m}{w}{Nfa.δ nfaR o c} (lemmaLookupT v))
... | i = fromExists (raise n w , (joinand i u))
union-accepts-right {n} {m} {c ∷ s} {q} {nfaL} {nfaR} p  | no  _ | no  _ | inj₂ o | refl with biglem {m}{c}{s} p
... | w , v , t with union-accepts-right {n}{m}{s}{w}{nfaL}{nfaR} t
... | u with lem1ʳ {n} {m} (∅) (Nfa.δ nfaR o c) w (lem3 {m}{w}{Nfa.δ nfaR o c} (lemmaLookupT v))
... | i = fromExists (raise n w , (joinand i u))

union-cl-l : ∀{n m : ℕ} {s : String} {nfaL : Nfa n} {nfaR : Nfa m}
  → nfaL ↓ s → unionNfa nfaL nfaR ↓ s
union-cl-l {n} {m} {[]} {nfaL} {nfaR} p with Nfa.S nfaL ∈? Nfa.F nfaL | Nfa.S nfaR ∈? Nfa.F nfaR
... | yes _  | yes _ = tt
... | yes _  | no  _ = tt
... | no  _  | yes _ = tt
... | no  ¬p | no  _ = ⊥-elim (¬p (lemmaLookupT p))
union-cl-l {n} {m} {c ∷ s} {nfaL} {nfaR} p with biglem {n} {c} {s} p
union-cl-l {n} {m} {c ∷ s} {nfaL} {nfaR} p | w , t , f   with union-accepts-left {n}{m}{s}{w}{nfaL}{nfaR} f
... | ur with subst (λ i → T i) (sym (lookup-++ˡ (Nfa.δ nfaL (Nfa.S nfaL) c) (Nfa.δ nfaR (Nfa.S nfaR) c) w)) t
... | pur = fromExists ((inject+ m w) , (joinand pur ur))

union-cl-r : ∀{n m : ℕ} {s : String} {nfaL : Nfa n} {nfaR : Nfa m}
  → nfaR ↓ s → unionNfa nfaL nfaR ↓ s
union-cl-r {n} {m} {[]} {nfaL} {nfaR} p with Nfa.S nfaL ∈? Nfa.F nfaL | Nfa.S nfaR ∈? Nfa.F nfaR
... | yes _ | yes _ = tt
... | yes _ | no  _ = tt
... | no  _ | yes _ = tt
... | no  _ | no ¬p = ⊥-elim (¬p (lemmaLookupT p))
union-cl-r {n} {m} {c ∷ s} {nfaL} {nfaR} p with  biglem {m} {c} {s} p
... | w , t , f with union-accepts-right {n}{m}{s}{w}{nfaL}{nfaR} f
... | ur with subst (λ i → T i) (sym (lookup-++ʳ (Nfa.δ nfaL (Nfa.S nfaL) c) (Nfa.δ nfaR (Nfa.S nfaR) c) w)) t
... | pur = fromExists ((raise n w) , (joinand pur ur))

union-closure : ∀{n m : ℕ} {s t : String} {nfaL : Nfa n} {nfaR : Nfa m}
  → (nfaL ↓ s) × (nfaR ↓ t)
  → let union = unionNfa nfaL nfaR in
    -------------------------
    ( union ↓ s × union ↓ t )
union-closure {n}{m}{s}{t}{nfaL}{nfaR} (fst , snd) = union-cl-l {n}{m}{s} fst ,  union-cl-r {n}{m}{t}  snd






--
