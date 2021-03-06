module introduction where
import Relation.Binary.PropositionalEquality as Eq
open Eq using (_≡_; refl; cong; sym)
open Eq.≡-Reasoning using (begin_; _≡⟨⟩_; _≡⟨_⟩_; _∎)
open import Data.Nat using (ℕ; zero; suc; _+_; _*_; _∸_)

+-assoc : ∀ (m n p : ℕ) → (m + n) + p ≡ m + (n + p)
+-assoc zero n p =
  begin
    (zero + n + p)
  ≡⟨⟩
    n + p
  ≡⟨⟩
    zero + (n + p)
  ∎
+-assoc (suc m) n p =
  begin
    (suc m + n) + p
  ≡⟨⟩
    suc (m + n) + p
  ≡⟨⟩
    suc ((m + n) + p)
  ≡⟨ cong suc (+-assoc m n p) ⟩
    suc (m + (n + p))
  ≡⟨⟩
    suc m + (n + p)
  ∎

+-identity : ∀ (m : ℕ) -> m + zero ≡ m
+-identity zero =
  begin
    zero + zero
  ≡⟨⟩
    zero
  ∎
+-identity (suc n) =
  begin
    suc n + zero
  ≡⟨⟩
    suc (n + zero)
  ≡⟨ cong suc (+-identity n) ⟩
    suc n
  ∎

+-suc : ∀ (m n : ℕ) ->  m + suc n ≡ suc (m + n)
+-suc zero n =
  begin
    zero + suc n
  ≡⟨⟩
    suc n
  ∎
+-suc (suc m) n =
  begin
    suc m + suc n
  ≡⟨⟩
    suc (m + suc n)
  ≡⟨ cong suc (+-suc m n) ⟩
    suc (suc (m + n))
  ∎

+-comm : ∀ (m n : ℕ) → m + n ≡ n + m
+-comm m zero =
  begin
    m + zero
  ≡⟨ +-identity m ⟩
    m
  ≡⟨⟩
    zero + m
  ∎
+-comm m (suc n) =
  begin
    m + suc n
  ≡⟨ +-suc m n ⟩
    suc (m + n)
  ≡⟨ cong suc (+-comm m n) ⟩
    suc (n + m)
  ≡⟨⟩
    suc n + m
  ∎

+-rearrange : ∀ (m n p q : ℕ) → (m + n) + (p + q) ≡ m + (n + p) + q
+-rearrange m n p q =
  begin
    (m + n) + (p + q)
  ≡⟨ +-assoc m n (p + q) ⟩
    m + (n + (p + q))
  ≡⟨ cong (m +_) (sym (+-assoc n p q)) ⟩
    m + ((n + p) + q)
  ≡⟨ sym (+-assoc m (n + p) q) ⟩
    (m + (n + p)) + q
  ∎

+-assocRewrite : ∀ (m n p : ℕ) → m + (n + p) ≡ (m + n) + p
+-assocRewrite zero n p = refl
+-assocRewrite (suc m) n p  rewrite +-assocRewrite m n p = refl

+-swap : ∀ (m n p : ℕ) → m + (n + p) ≡ n + (m + p)
+-swap m n p =
  begin
    m + (n + p)
  ≡⟨ sym (+-assoc m n p) ⟩
    (m + n) + p
  ≡⟨ cong (_+ p) (+-comm m n) ⟩
    (n + m) + p
  ≡⟨ +-assoc n m p ⟩
    n + (m + p)
  ∎

*-distrib-+ : ∀ (m n p : ℕ) → (m + n) * p ≡ m * p + n * p
*-distrib-+ zero n p = refl
*-distrib-+ (suc m) n p rewrite *-distrib-+ m n p = sym (+-assoc p (m * p) (n * p))

*-assoc : ∀ (m n p : ℕ) → (m * n) * p ≡ m * (n * p)
*-assoc zero n p = refl
*-assoc (suc m) n p  rewrite *-distrib-+ n (m * n) p  | *-assoc m n  p = refl


*-id : ∀ (n : ℕ) → n * (suc 0) ≡ n
*-id zero = refl
*-id (suc n)  rewrite *-id n = refl

*-nullo : ∀ (n : ℕ) → n * zero ≡ zero
*-nullo zero = refl
*-nullo (suc n) rewrite *-nullo n = refl

*-uno : ∀ (n m : ℕ) → n + n * m ≡ n * suc m
*-uno zero m rewrite *-nullo m | *-id m | +-identity m = refl
*-uno (suc n) m =
  begin
    (suc n) + (suc n * m)
  ≡⟨⟩
    suc (n + suc n * m)
  ≡⟨⟩
    suc (n + suc n * m)
  ≡⟨⟩
    suc (n + (m + n * m))
  ≡⟨ cong suc (sym (+-assoc n m (n * m))) ⟩
    suc ((n + m) + n * m)
  ≡⟨ cong suc (cong (_+ n * m) (+-comm n m)) ⟩
    suc ((m + n) + n * m)
  ≡⟨ cong suc (+-assoc m n (n * m)) ⟩
    suc (m + (n + n * m))
  ≡⟨ cong suc (cong (m +_) (*-uno n m)) ⟩
    suc (m + n * suc m)
  ≡⟨⟩
    suc m + n * suc m
  ≡⟨⟩
    suc n * suc m
  ∎

*-comm : ∀ (m n : ℕ) → m * n ≡ n * m
*-comm zero n  rewrite *-nullo n = refl
*-comm (suc m) n rewrite *-comm m n | *-uno n m = refl

0∸n≡0 : ∀ (n : ℕ) → zero ∸ n ≡ zero
0∸n≡0 zero = refl
0∸n≡0 (suc n) = refl

∸-+-assoc : ∀ (m n p : ℕ) → m ∸ n ∸ p ≡ m ∸ (n + p)
∸-+-assoc zero n p rewrite 0∸n≡0 (n + p) |  0∸n≡0 n  | 0∸n≡0 p  = refl
∸-+-assoc (suc m) zero p = refl
∸-+-assoc (suc m) (suc n) p rewrite ∸-+-assoc m n p = refl

data Bin : Set where
  ⟨⟩ : Bin
  _O : Bin → Bin
  _I : Bin → Bin

inc : Bin → Bin
inc ⟨⟩ = ⟨⟩ I
inc (prec O) = prec I
inc (prec I) = (inc prec) O

natToBin : ℕ → Bin
natToBin zero = ⟨⟩ O
natToBin (suc n) = inc (natToBin n)

binToNat : Bin → ℕ
binToNat ⟨⟩ = 0
binToNat (b O) = 2 * binToNat b
binToNat (b I) = suc (2 * binToNat b)

lemma1 : ∀ (b : Bin) → suc (binToNat (b I)) ≡ 2 + binToNat b * 2
lemma1 ⟨⟩ = refl
lemma1 (b O) =
  begin
    suc (binToNat ((b O) I))
  ≡⟨⟩
    suc (suc (2 * (binToNat (b O))))
  ≡⟨ cong suc (cong suc (*-comm 2 (binToNat (b O)))) ⟩
    suc (suc (binToNat (b O) * 2))
  ≡⟨⟩
    2 + binToNat (b O) * 2
  ∎
lemma1 (b I) =
  begin
    suc (binToNat ((b I) I))
  ≡⟨⟩
    suc (suc (2 * binToNat (b I)))
  ≡⟨ cong suc (cong suc (*-comm 2 (binToNat (b I)))) ⟩
    2 + binToNat (b I) * 2
  ∎

binLaw1 : ∀ (b : Bin) → binToNat (inc b) ≡ suc (binToNat b)
binLaw1 ⟨⟩ = refl
binLaw1 (b O) = refl
binLaw1 (b I) =
  begin
    binToNat (inc (b I))
  ≡⟨⟩
    binToNat (inc b O)
  ≡⟨⟩
    2 * binToNat (inc b)
  ≡⟨ cong (2 *_) (binLaw1 (b)) ⟩
    2 * (suc (binToNat b))
  ≡⟨ *-comm 2 (suc (binToNat b))⟩
    (suc (binToNat b)) * 2
  ≡⟨ *-distrib-+ 1 (binToNat b) 2 ⟩
    2 + ((binToNat b) * 2)
  ≡⟨ sym (lemma1 b) ⟩
    suc (binToNat (b I))
  ∎

binLaw2 : ∀ (n : ℕ) → binToNat (natToBin n) ≡ n
binLaw2 zero = refl
binLaw2 (suc n) =
  begin
    binToNat (natToBin (suc n))
  ≡⟨⟩
    binToNat (inc (natToBin n))
  ≡⟨ binLaw1 (natToBin n) ⟩
    suc (binToNat (natToBin n))
  ≡⟨ cong suc (binLaw2 n) ⟩
    suc n
  ∎

-- Claim:  natToBin (binToNat b) ≡ b
-- does not hold: natToBin (binToNat ⟨⟩) = ⟨⟩ O  and so ⟨⟩ O /= ⟨⟩
