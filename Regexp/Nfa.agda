module Nfa where
open import Data.Char as Char using (Char)
open import Data.Nat using (ℕ; zero; suc; _+_; _≤_; _≥_; _<?_; _≤?_; s≤s; z≤n)
open import Data.Fin
  using (Fin; inject+; 0F; raise)
  renaming (zero to fzero; suc to fsuc)
open import Data.Fin.Subset as Subset
  using (Subset; ⁅_⁆; _∪_; _∩_; _∈_; _⊆_; Nonempty)
  renaming (⊥ to ∅; ⊤ to FullSet)
open import Data.Fin.Subset.Properties using (x∈p∪q⁺)
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
    F with Nfa.S nfaL ∈? Nfa.F nfaL | Nfa.S nfaR ∈? Nfa.F nfaR
    F | yes ε∈l | yes ε∈r = true  ∷v Nfa.F nfaL ++ Nfa.F nfaR
    F | yes ε∈l | no ¬ε∈r = ∅ {1} ++ ∅          ++ Nfa.F nfaR
    F | no ¬ε∈l | yes ε∈r = ∅ {1} ++ Nfa.F nfaL ++ Nfa.F nfaR
    F | no ¬ε∈l | no ¬ε∈r = ∅ {1} ++ ∅          ++ Nfa.F nfaR

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

starNfa : ∀{n} → Nfa n → Nfa (1 + n)
starNfa {n} nfa =
  record
    { S = fzero
    ; δ = δ
    ; F = ⁅ fzero ⁆ ++ Nfa.F nfa
    }
  where
    δ : Fin (1 + n) → Char → Subset (1 + n)
    δ q c with splitAt 1 q
    δ q c | inj₁ z = ∅ ++ (Nfa.δ nfa (Nfa.S nfa) c)
    δ q c | inj₂ p with p ∈? Nfa.F nfa
    δ q c | inj₂ p | yes isf = ∅ ++ ((Nfa.δ nfa (Nfa.S nfa) c) ∪ (Nfa.δ nfa p) c)
    δ q c | inj₂ p | no ¬isf = ∅ ++                  (Nfa.δ nfa p) c

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
... | u with lem1ʳ {n} {m} (∅) (Nfa.δ nfaR o c) w v
... | i = fromExists (raise n w , (joinand i u))
union-accepts-right {n} {m} {c ∷ s} {q} {nfaL} {nfaR} p  | yes _ | no  _ | inj₂ o | refl with biglem {m}{c}{s} p
... | w , v , t with union-accepts-right {n}{m}{s}{w}{nfaL}{nfaR} t
... | u with lem1ʳ {n} {m} (∅) (Nfa.δ nfaR o c) w v
... | i = fromExists (raise n w , (joinand i u))
union-accepts-right {n} {m} {c ∷ s} {q} {nfaL} {nfaR} p  | no  _ | yes _ | inj₂ o | refl with biglem {m}{c}{s} p
... | w , v , t with union-accepts-right {n}{m}{s}{w}{nfaL}{nfaR} t
... | u with lem1ʳ {n} {m} (∅) (Nfa.δ nfaR o c) w v
... | i = fromExists (raise n w , (joinand i u))
union-accepts-right {n} {m} {c ∷ s} {q} {nfaL} {nfaR} p  | no  _ | no  _ | inj₂ o | refl with biglem {m}{c}{s} p
... | w , v , t with union-accepts-right {n}{m}{s}{w}{nfaL}{nfaR} t
... | u with lem1ʳ {n} {m} (∅) (Nfa.δ nfaR o c) w v
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
... | ur with lem1ˡ (Nfa.δ nfaL (Nfa.S nfaL) c) (Nfa.δ nfaR (Nfa.S nfaR) c) w t
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
... | ur with lem1ʳ (Nfa.δ nfaL (Nfa.S nfaL) c) (Nfa.δ nfaR (Nfa.S nfaR) c) w t
... | pur = fromExists ((raise n w) , (joinand pur ur))

union-closure : ∀{n m : ℕ} {s t : String} {nfaL : Nfa n} {nfaR : Nfa m}
  → (nfaL ↓ s) × (nfaR ↓ t)
  → let union = unionNfa nfaL nfaR in
    -------------------------
    ( union ↓ s × union ↓ t )
union-closure {n}{m}{s}{t}{nfaL}{nfaR} (fst , snd) = union-cl-l {n}{m}{s} fst ,  union-cl-r {n}{m}{t}  snd


concat-right-preserved : ∀{n m : ℕ} {v : String} {p}{nfaL : Nfa n} {nfaR : Nfa m}
  → T(accepts nfaR p v)
  → T(accepts (concatNfa nfaL nfaR) (raise 1 (raise n p)) v)
concat-right-preserved {n} {m} {[]} {p} {nfaL} {nfaR} acc  with Nfa.S nfaL ∈? Nfa.F nfaL | Nfa.S nfaR ∈? Nfa.F nfaR
...| yes _ | yes _ = lem1ʳ (Nfa.F nfaL) (Nfa.F nfaR) p acc
...| no  _ | yes _ = lem1ʳ (Nfa.F nfaL) (Nfa.F nfaR) p acc
...| yes _ | no  _ = lem1ʳ (∅ {n}) (Nfa.F nfaR) p acc
...| no  _ | no  _ = lem1ʳ (∅ {n}) (Nfa.F nfaR) p acc
concat-right-preserved {n} {m} {c ∷ v} {p} {nfaL} {nfaR} acc with  biglem {m}{c}{v} acc
... | w , t , f with splitAt n (raise n p) | splitAt-raise n m p
concat-right-preserved {n} {m} {c ∷ v} {.y} {nfaL} {nfaR} acc | w , t , f | inj₂ y | refl with  concat-right-preserved {_}{_}{v}{w}{nfaL}{nfaR} f
... | ind  with lem1ʳ (∅ {1 + n}) (Nfa.δ nfaR y c) w t
... | pur = fromExists (raise n w , joinand pur ind)

concat-inductive-left : ∀{n m : ℕ} {s v : String} {q} {nfaL : Nfa n} {nfaR : Nfa m}
  → T(accepts nfaL q s) × nfaR ↓ v
  → T(accepts (concatNfa nfaL nfaR) (raise 1 (inject+ m q)) (s ++ˢ v))
concat-inductive-left {n} {m} {[]} {[]} {q} {nfaL} {nfaR} (fst , snd) with Nfa.S nfaL ∈? Nfa.F nfaL | Nfa.S nfaR ∈? Nfa.F nfaR
...| yes ε∈l | yes ε∈r = lem1ˡ (Nfa.F nfaL) (Nfa.F nfaR) q fst
...| no ¬ε∈l | yes ε∈r = lem1ˡ (Nfa.F nfaL) (Nfa.F nfaR) q fst
...| yes ε∈l | no ¬ε∈r = ⊥-elim(¬ε∈r (lemmaLookupT snd))
...| no ¬ε∈l | no ¬ε∈r = ⊥-elim(¬ε∈r (lemmaLookupT snd))
concat-inductive-left {n} {m} {[]} {c ∷ v} {q} {nfaL} {nfaR} (fst , snd) with splitAt n (inject+ m q) | splitAt-inject+ n m q
concat-inductive-left {n} {m} {[]} {c ∷ v} {.x} {nfaL} {nfaR} (fst , snd) | inj₁ x | refl with x ∈? Nfa.F nfaL
concat-inductive-left {n} {m} {[]} {c ∷ v} {.x} {nfaL} {nfaR} (fst , snd) | inj₁ x | refl | yes p₁ with biglem {m}{c}{v} snd
... | w , t , f with lem1ʳ (Nfa.δ nfaL x c) (Nfa.δ nfaR (Nfa.S nfaR) c) w t
... | pur  = fromExists (raise n w , joinand pur (concat-right-preserved {n}{m}{v}{w}{nfaL}{nfaR} f))
concat-inductive-left {n} {m} {[]} {c ∷ v} {.x} {nfaL} {nfaR} (fst , snd) | inj₁ x | refl | no ¬p = ⊥-elim (¬p (lemmaLookupT fst))
concat-inductive-left {n} {m} {c ∷ s} {v} {q} {nfaL} {nfaR} (fst , snd) with biglem {n}{c}{s} fst
... | w , t , f with splitAt n (inject+ m q) | splitAt-inject+ n m q
concat-inductive-left {n} {m} {c ∷ s} {v} {.q} {nfaL} {nfaR} (fst , snd) | w , t , f | inj₁ q | refl with q ∈? Nfa.F nfaL
concat-inductive-left {n} {m} {c ∷ s} {v} {.q} {nfaL} {nfaR} (fst , snd) | w , t , f | inj₁ q | refl | yes p₁ with concat-inductive-left {n}{m}{s}{v}{w}{nfaL}{nfaR} (f , snd)
... | ind  with lem1ˡ (Nfa.δ nfaL q c) (Nfa.δ nfaR (Nfa.S nfaR) c) w t
... | pur = fromExists (inject+ m w , joinand pur ind)
concat-inductive-left {n} {m} {c ∷ s} {v} {.q}{nfaL} {nfaR} (fst , snd) | w , t , f | inj₁ q | refl | no ¬p with concat-inductive-left {n}{m}{s}{v}{w}{nfaL}{nfaR} (f , snd)
... | ind  with lem1ˡ (Nfa.δ nfaL q c) ∅ w t
... | pur = fromExists (inject+ m w , joinand pur ind)

concat-closure : ∀{n m : ℕ} {s v : String} {nfaL : Nfa n} {nfaR : Nfa m}
  → (nfaL ↓ s) × (nfaR ↓ v)
    --------------------------------
  → (concatNfa nfaL nfaR) ↓ (s ++ˢ v)
concat-closure {n} {m} {[]} {[]} {nfaL} {nfaR} (fst , snd) with Nfa.S nfaL ∈? Nfa.F nfaL | Nfa.S nfaR ∈? Nfa.F nfaR
...| yes ε∈l | yes ε∈r = tt
...| yes ε∈l | no ¬ε∈r = ⊥-elim(¬ε∈r (lemmaLookupT snd))
...| no ¬ε∈l | yes ε∈r = ⊥-elim(¬ε∈l (lemmaLookupT fst))
...| no ¬ε∈l | no ¬ε∈r = ⊥-elim(¬ε∈l (lemmaLookupT fst))
concat-closure {n} {m} {[]} {c ∷ v} {nfaL} {nfaR} (fst , snd) with Nfa.S nfaL ∈? Nfa.F nfaL | v[i]=v!i (Nfa.F nfaL) (Nfa.S nfaL)
concat-closure {n} {m} {[]} {c ∷ v} {nfaL} {nfaR} (fst , snd) | yes p | _ with (Nfa.F nfaL) ! (Nfa.S nfaL)
concat-closure {n} {m} {[]} {c ∷ v} {nfaL} {nfaR} (fst , snd) | yes p | _ | true with biglem {m} {c}{v} snd
... | w , t , f with lem1ʳ (Nfa.δ nfaL (Nfa.S nfaL) c) (Nfa.δ nfaR (Nfa.S nfaR) c) w t
... | pur = fromExists (raise n w , joinand pur (concat-right-preserved {n}{m}{v} f))
concat-closure {n} {m} {[]} {c ∷ v} {nfaL} {nfaR} (fst , snd) | no ¬p | _ = ⊥-elim (¬p (lemmaLookupT fst))
concat-closure {n} {m} {c ∷ s} {v} {nfaL} {nfaR} (fst , snd) with biglem {n}{c}{s} fst
... | w , t , f  with concat-inductive-left {n}{m}{s}{v} (f , snd)
... | ur with Nfa.S nfaL ∈? Nfa.F nfaL | v[i]=v!i (Nfa.F nfaL) (Nfa.S nfaL)
concat-closure {n} {m} {c ∷ s} {v} {nfaL} {nfaR} (fst , snd) | w , t , f | ur | yes p | _ with lookup (Nfa.F nfaL) (Nfa.S nfaL)
concat-closure {n} {m} {c ∷ s} {v} {nfaL} {nfaR} (fst , snd) | w , t , f | ur | yes p | _ | false with lem1ˡ (Nfa.δ nfaL (Nfa.S nfaL) c) ∅ w t
... | pur = injectOrR (fromExists (inject+ m w , joinand pur ur))
concat-closure {n} {m} {c ∷ s} {v} {nfaL} {nfaR} (fst , snd) | w , t , f | ur | yes p | _ | true with lem1ˡ (Nfa.δ nfaL (Nfa.S nfaL) c) (Nfa.δ nfaR (Nfa.S nfaR) c) w t
... | pur = injectOrR (fromExists (inject+ m w , joinand pur ur))
concat-closure {n} {m} {c ∷ s} {v} {nfaL} {nfaR} (fst , snd) | w , t , f | ur | no ¬p | _  with lookup (Nfa.F nfaL) (Nfa.S nfaL)
concat-closure {n} {m} {c ∷ s} {v} {nfaL} {nfaR} (fst , snd) | w , t , f | ur | no ¬p | _ | false with lem1ˡ (Nfa.δ nfaL (Nfa.S nfaL) c) ∅ w t
... | pur = fromExists (inject+ m w , joinand pur ur)
concat-closure {n} {m} {c ∷ s} {v} {nfaL} {nfaR} (fst , snd) | w , t , f | ur | no ¬p | _ | true with lem1ˡ (Nfa.δ nfaL (Nfa.S nfaL) c) (Nfa.δ nfaR (Nfa.S nfaR) c) w t
... | pur = fromExists (inject+ m w , joinand pur ur)

injectUnionʳ : ∀{n} {q} {set : Subset n} → T(set ! q) → (inj : Subset n) → T((set ∪ inj) ! q)
injectUnionʳ {n} {q} {set} t inj with set ! q  | v[i]=v!i set q
... | true | u =  subst (λ y → T y) (sym (s!i≡s[i] (x∈p∪q⁺ {_}{set}{inj} (inj₁ u)))) tt

injectUnionˡ : ∀{n} {q} {set : Subset n} → T(set ! q) → (inj : Subset n) → T((inj ∪ set) ! q)
injectUnionˡ {n} {q} {set} t inj with set ! q  | v[i]=v!i set q
... | true | u =  subst (λ y → T y) (sym (s!i≡s[i] (x∈p∪q⁺ {_}{inj} (inj₂ u)))) tt

star-preserved : ∀{n}{s}{q}{nfa : Nfa n}
  → T(accepts nfa q s)
  → T(accepts (starNfa nfa) (raise 1 q) s)
star-preserved {n} {[]} {q} {nfa} p = p
star-preserved {n} {c ∷ s} {q} {nfa} p with biglem {n}{c}{s} p
... | w , t , f with q ∈? Nfa.F nfa
star-preserved {n} {c ∷ s} {q} {nfa} p | w , t , f | yes p₁ with star-preserved {n}{s}{w}{nfa} f
... | ind = fromExists (w , joinand (injectUnionˡ t (Nfa.δ nfa (Nfa.S nfa) c)) ind)
star-preserved {n} {c ∷ s} {q} {nfa} p | w , t , f | no ¬p with  star-preserved {n}{s}{w}{nfa} f
... | ind = fromExists (w , joinand t ind)

star-inductive : ∀{n}{s v}{q} {nfa : Nfa n}
  → T(accepts nfa q s) × (starNfa nfa) ↓ v
  → T(accepts (starNfa nfa) (raise 1 q) (s ++ˢ v))
star-inductive {n} {[]} {[]} {q} {nfa} (fst , snd) = fst
star-inductive {n} {[]} {c ∷ v} {q} {nfa} (fst , snd) with q ∈? Nfa.F nfa
star-inductive {n} {[]} {c ∷ v} {q} {nfa} (fst , snd) | yes p with anyToExists {n} {λ x →
          lookup (Nfa.δ nfa (Nfa.S nfa) c) x ∧
          accepts (starNfa nfa) (fsuc x) v } snd
star-inductive {n} {[]} {c ∷ v} {q} {nfa} (fst , snd) | yes p | w , f with splitand {lookup (Nfa.δ nfa (Nfa.S nfa) c) w} {accepts (starNfa nfa) (fsuc w) v} f
star-inductive {n} {[]} {c ∷ v} {q} {nfa} (fst , snd) | yes p | w , f | f1 , f2 = fromExists (w , (joinand (injectUnionʳ {n} {w} {Nfa.δ nfa (Nfa.S nfa) c} f1 (Nfa.δ nfa q c)) f2))
star-inductive {n} {[]} {c ∷ v} {q} {nfa} (fst , snd) | no ¬p = ⊥-elim(¬p (lemmaLookupT fst))
star-inductive {n} {c ∷ s} {v} {q} {nfa} (fst , snd) with biglem {n}{c}{s} fst
... | w , t , f with q ∈? Nfa.F nfa
star-inductive {n} {c ∷ s} {v} {q} {nfa} (fst , snd) | w , t , f | yes p with star-inductive {n}{s}{v}{w}{nfa} (f , snd)
... | ind = fromExists (w , joinand (injectUnionˡ t (Nfa.δ nfa (Nfa.S nfa) c)) ind)
star-inductive {n} {c ∷ s} {v} {q} {nfa} (fst , snd) | w , t , f | no ¬p with star-inductive {n}{s}{v}{w}{nfa} (f , snd)
... | ind = fromExists (w , joinand t ind)


star-closure : ∀{n} {s v : String} {nfa : Nfa n}
  → nfa ↓ s × (starNfa nfa) ↓ v
    ---------------------------
  → (starNfa nfa) ↓ (s ++ˢ v)
star-closure {n} {[]} {[]} {nfa} (fst , snd) = tt
star-closure {n} {c ∷ s} {[]} {nfa} (fst , snd) rewrite ++-idʳ (s) with biglem {n} {c} {s} fst
... | w , t , f = fromExists (w , (joinand t (star-preserved {n}{s}{w} {nfa} f)))
star-closure {n} {[]} {c ∷ v} {nfa} (fst , snd) rewrite ++-idˡ (c ∷ v) = snd
star-closure {n} {c ∷ s} {v} {nfa} (fst , snd) with biglem {n} {c} {s} fst
... | w , t , f = fromExists (w , (joinand t (star-inductive {n}{s}{v}{w}{nfa} (f , snd))))










--
