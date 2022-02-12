/-
Copyright (c) 2020 Zhouhang Zhou. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Zhouhang Zhou
-/
import algebra.support

/-!
# Indicator function

- `indicator (s : set α) (f : α → β) (a : α)` is `f a` if `a ∈ s` and is `0` otherwise.
- `mul_indicator (s : set α) (f : α → β) (a : α)` is `f a` if `a ∈ s` and is `1` otherwise.


## Implementation note

In mathematics, an indicator function or a characteristic function is a function
used to indicate membership of an element in a set `s`,
having the value `1` for all elements of `s` and the value `0` otherwise.
But since it is usually used to restrict a function to a certain set `s`,
we let the indicator function take the value `f x` for some function `f`, instead of `1`.
If the usual indicator function is needed, just set `f` to be the constant function `λx, 1`.

## Tags
indicator, characteristic
-/

open_locale big_operators
open function

variables {α β ι M N : Type*}

namespace set

/-- `indicator s f a` is `f a` if `a ∈ s`, `0` otherwise.  -/
def indicator [has_zero M] (s : set α) [decidable_pred (∈ s)] (f : α → M) : α → M :=
λ x, if x ∈ s then f x else 0

section has_one
variables [has_one M] [has_one N] (s t : set α) [decidable_pred (∈ s)] [decidable_pred (∈ t)]
  (f g : α → M) {a : α}

/-- `mul_indicator s f a` is `f a` if `a ∈ s`, `1` otherwise.  -/
@[to_additive]
def mul_indicator : α → M := λ x, if x ∈ s then f x else 1

@[to_additive support.decidable_mem]
instance mul_support.decidable_mem [h : decidable_eq M] : decidable_pred (∈ mul_support f) :=
λ a, decidable_of_iff (f a ≠ 1) iff.rfl

@[simp, to_additive] lemma piecewise_eq_mul_indicator : s.piecewise f 1 = s.mul_indicator f := rfl

@[to_additive] lemma mul_indicator_apply (a : α) : mul_indicator s f a = if a ∈ s then f a else 1 :=
rfl

variables {s}

@[simp, to_additive] lemma mul_indicator_of_mem (h : a ∈ s) (f : α → M) :
  mul_indicator s f a = f a := if_pos h

@[simp, to_additive] lemma mul_indicator_of_not_mem (h : a ∉ s) (f : α → M) :
  mul_indicator s f a = 1 := if_neg h

variables (s)

@[to_additive] lemma mul_indicator_eq_one_or_self (a : α) :
  mul_indicator s f a = 1 ∨ mul_indicator s f a = f a :=
(ite_eq_or_eq _ _ _).symm

variables {s t f g}

@[simp, to_additive] lemma mul_indicator_apply_eq_self :
  s.mul_indicator f a = f a ↔ (a ∉ s → f a = 1) :=
ite_eq_left_iff.trans $ by rw [@eq_comm _ (f a)]

@[simp, to_additive] lemma mul_indicator_eq_self : s.mul_indicator f = f ↔ mul_support f ⊆ s :=
by simp only [funext_iff, subset_def, mem_mul_support, mul_indicator_apply_eq_self, not_imp_comm]

@[to_additive] lemma mul_indicator_eq_self_of_superset (h1 : s.mul_indicator f = f) (h2 : s ⊆ t) :
  t.mul_indicator f = f :=
by { rw mul_indicator_eq_self at h1 ⊢, exact subset.trans h1 h2 }

@[simp, to_additive] lemma mul_indicator_apply_eq_one :
  mul_indicator s f a = 1 ↔ (a ∈ s → f a = 1) :=
ite_eq_right_iff

@[simp, to_additive] lemma mul_indicator_eq_one :
  mul_indicator s f = (λ x, 1) ↔ disjoint (mul_support f) s :=
by simp only [funext_iff, mul_indicator_apply_eq_one, set.disjoint_left, mem_mul_support,
  not_imp_not]

@[simp, to_additive] lemma mul_indicator_eq_one' :
  mul_indicator s f = 1 ↔ disjoint (mul_support f) s :=
mul_indicator_eq_one

@[to_additive] lemma mul_indicator_ne_one_iff (a : α) :
  s.mul_indicator f a ≠ 1 ↔ a ∈ s ∩ mul_support f :=
ite_ne_right_iff

@[simp, to_additive] lemma mul_support_mul_indicator :
  mul_support (s.mul_indicator f) = s ∩ mul_support f :=
ext $ λ x, by simp [mem_mul_support, mul_indicator_apply_eq_one]

/-- If a multiplicative indicator function is not equal to one at a point, then that
point is in the set. -/
@[to_additive] lemma mem_of_mul_indicator_ne_one (h : mul_indicator s f a ≠ 1) : a ∈ s :=
not_imp_comm.1 (λ hn, mul_indicator_of_not_mem hn f) h

@[to_additive] lemma eq_on_mul_indicator : eq_on (mul_indicator s f) f s :=
λ x hx, mul_indicator_of_mem hx f

@[to_additive] lemma mul_support_mul_indicator_subset : mul_support (s.mul_indicator f) ⊆ s :=
λ x hx, hx.imp_symm (λ h, mul_indicator_of_not_mem h f)

@[simp, to_additive] lemma mul_indicator_mul_support [decidable_eq M] :
  mul_indicator (mul_support f) f = f :=
mul_indicator_eq_self.2 subset.rfl

@[simp, to_additive] lemma mul_indicator_range_comp {ι : Sort*} (f : ι → α)
  [decidable_pred (∈ range f)](g : α → M) :
  mul_indicator (range f) g ∘ f = g ∘ f :=
piecewise_range_comp _ _ _

@[to_additive] lemma mul_indicator_congr (h : eq_on f g s) :
  mul_indicator s f = mul_indicator s g :=
funext $ λx, by { simp only [mul_indicator], split_ifs, { exact h h_1 }, refl }

@[simp, to_additive] lemma mul_indicator_univ (f : α → M) : mul_indicator (univ : set α) f = f :=
mul_indicator_eq_self.2 $ subset_univ _

@[simp, to_additive] lemma mul_indicator_empty [decidable_pred (∈ (∅ : set α))] (f : α → M) :
  mul_indicator (∅ : set α) f = λ a, 1 :=
mul_indicator_eq_one.2 $ disjoint_empty _

@[to_additive] lemma mul_indicator_empty' [decidable_pred (∈ (∅ : set α))] (f : α → M) :
  mul_indicator (∅ : set α) f = 1 :=
mul_indicator_empty f

variables (M s)

@[simp, to_additive] lemma mul_indicator_one : mul_indicator s (λ x, (1:M)) = λ x, (1:M) :=
mul_indicator_eq_one.2 $ by simp only [mul_support_one, empty_disjoint]

variables {s}

@[simp, to_additive] lemma mul_indicator_one' : s.mul_indicator (1 : α → M) = 1 :=
mul_indicator_one M s

variables (s t) {M}

@[to_additive] lemma mul_indicator_mul_indicator (f : α → M) :
  mul_indicator s (mul_indicator t f) = mul_indicator (s ∩ t) f :=
funext $ λx, by { simp only [mul_indicator], split_ifs, repeat {simp * at * {contextual := tt}} }

@[simp, to_additive] lemma mul_indicator_inter_mul_support [decidable_eq M] (f : α → M) :
  mul_indicator (s ∩ mul_support f) f = mul_indicator s f :=
by rw [← mul_indicator_mul_indicator, mul_indicator_mul_support]

variables {s}

@[to_additive] lemma comp_mul_indicator (h : M → β) (f : α → M) {x : α} :
  h (s.mul_indicator f x) = s.piecewise (h ∘ f) (const α (h 1)) x :=
s.apply_piecewise _ _ (λ _, h)

@[to_additive] lemma mul_indicator_comp_right (f : β → α) [decidable_pred (∈ f ⁻¹' s)] {g : α → M}
  {x : β} :
  mul_indicator (f ⁻¹' s) (g ∘ f) x = mul_indicator s g (f x) :=
by { simp only [mul_indicator], split_ifs; refl }

@[to_additive] lemma mul_indicator_comp_of_one {g : M → N} (hg : g 1 = 1) :
  mul_indicator s (g ∘ f) = g ∘ (mul_indicator s f) :=
begin
  funext,
  simp only [mul_indicator],
  split_ifs; simp [*]
end

@[to_additive] lemma comp_mul_indicator_const (c : M) (f : M → N) (hf : f 1 = 1) :
  (λ x, f (s.mul_indicator (λ x, c) x)) = s.mul_indicator (λ x, f c) :=
(mul_indicator_comp_of_one hf).symm

variables (s)

@[to_additive] lemma mul_indicator_preimage (f : α → M) (B : set M) :
  (mul_indicator s f)⁻¹' B = s.ite (f ⁻¹' B) (1 ⁻¹' B) :=
piecewise_preimage s f 1 B

@[to_additive] lemma mul_indicator_preimage_of_not_mem (f : α → M)
  {t : set M} (ht : (1:M) ∉ t) :
  (mul_indicator s f)⁻¹' t = f ⁻¹' t ∩ s :=
by simp [mul_indicator_preimage, pi.one_def, set.preimage_const_of_not_mem ht]

variables {s}

@[to_additive] lemma mem_range_mul_indicator {r : M} {f : α → M} :
  r ∈ range (mul_indicator s f) ↔ (r = 1 ∧ s ≠ univ) ∨ (r ∈ f '' s) :=
by simp [mul_indicator, ite_eq_iff, exists_or_distrib, eq_univ_iff_forall, and_comm, or_comm,
  @eq_comm _ r 1]

@[to_additive] lemma mul_indicator_rel_mul_indicator {r : M → M → Prop} (h1 : r 1 1)
  (ha : a ∈ s → r (f a) (g a)) :
  r (mul_indicator s f a) (mul_indicator s g a) :=
by { simp only [mul_indicator], split_ifs with has has, exacts [ha has, h1] }

end has_one

section monoid
variables [mul_one_class M] (f g : α → M) (s t : set α) [decidable_pred (∈ s)]
  [decidable_pred (∈ t)] {a : α}

@[to_additive] lemma mul_indicator_union_mul_inter_apply [decidable_pred (∈ s ∪ t)] (a : α) :
  mul_indicator (s ∪ t) f a * mul_indicator (s ∩ t) f a =
    mul_indicator s f a * mul_indicator t f a :=
by by_cases hs : a ∈ s; by_cases ht : a ∈ t; simp *

@[to_additive] lemma mul_indicator_union_mul_inter [decidable_pred (∈ s ∪ t)] :
  mul_indicator (s ∪ t) f * mul_indicator (s ∩ t) f = mul_indicator s f * mul_indicator t f :=
funext $ mul_indicator_union_mul_inter_apply f s t

variables {s t}

@[to_additive] lemma mul_indicator_union_of_not_mem_inter [decidable_pred (∈ s ∪ t)] (h : a ∉ s ∩ t)
  (f : α → M) :
  mul_indicator (s ∪ t) f a = mul_indicator s f a * mul_indicator t f a :=
by rw [← mul_indicator_union_mul_inter_apply f s t, mul_indicator_of_not_mem h, mul_one]

@[to_additive] lemma mul_indicator_union_of_disjoint [decidable_pred (∈ s ∪ t)] (h : disjoint s t)
  (f : α → M) :
  mul_indicator (s ∪ t) f = λa, mul_indicator s f a * mul_indicator t f a :=
funext $ λa, mul_indicator_union_of_not_mem_inter (λ ha, h ha) _

variables (s)

@[to_additive] lemma mul_indicator_mul (f g : α → M) :
  mul_indicator s (λa, f a * g a) = λa, mul_indicator s f a * mul_indicator s g a :=
by { funext, simp only [mul_indicator], split_ifs, { refl }, rw mul_one }

@[to_additive] lemma mul_indicator_mul' (f g : α → M) :
  mul_indicator s (f * g) = mul_indicator s f * mul_indicator s g :=
mul_indicator_mul s f g

@[simp, to_additive] lemma mul_indicator_compl_mul_self_apply (f : α → M) (a : α) :
  mul_indicator sᶜ f a * mul_indicator s f a = f a :=
classical.by_cases (λ ha : a ∈ s, by simp [ha]) (λ ha, by simp [ha])

@[simp, to_additive] lemma mul_indicator_compl_mul_self (f : α → M) :
  mul_indicator sᶜ f * mul_indicator s f = f :=
funext $ mul_indicator_compl_mul_self_apply s f

@[simp, to_additive] lemma mul_indicator_self_mul_compl_apply (f : α → M) (a : α) :
  mul_indicator s f a * mul_indicator sᶜ f a = f a :=
classical.by_cases (λ ha : a ∈ s, by simp [ha]) (λ ha, by simp [ha])

@[simp, to_additive] lemma mul_indicator_self_mul_compl (f : α → M) :
  mul_indicator s f * mul_indicator sᶜ f = f :=
funext $ mul_indicator_self_mul_compl_apply s f

@[to_additive] lemma mul_indicator_mul_eq_left [decidable_eq M] {f g : α → M}
  (h : disjoint (mul_support f) (mul_support g)) :
  (mul_support f).mul_indicator (f * g) = f :=
begin
  refine (mul_indicator_congr $ λ x hx, _).trans mul_indicator_mul_support,
  have : g x = 1, from nmem_mul_support.1 (disjoint_left.1 h hx),
  rw [pi.mul_apply, this, mul_one]
end

@[to_additive] lemma mul_indicator_mul_eq_right [decidable_eq M] {f g : α → M}
  (h : disjoint (mul_support f) (mul_support g)) :
  (mul_support g).mul_indicator (f * g) = g :=
begin
  refine (mul_indicator_congr $ λ x hx, _).trans mul_indicator_mul_support,
  have : f x = 1, from nmem_mul_support.1 (disjoint_right.1 h hx),
  rw [pi.mul_apply, this, one_mul]
end

variables (M)

/-- `set.mul_indicator` as a `monoid_hom`. -/
@[to_additive "`set.indicator` as an `add_monoid_hom`."]
def mul_indicator_hom : (α → M) →* (α → M) :=
{ to_fun := mul_indicator s,
  map_one' := mul_indicator_one M s,
  map_mul' := mul_indicator_mul s }

end monoid

section distrib_mul_action

variables {A : Type*} [add_monoid A] [monoid M] [distrib_mul_action M A] (s : set α)
  [decidable_pred (∈ s)]

lemma indicator_smul_apply (r : M) (f : α → A) (x : α) :
  indicator s (λ x, r • f x) x = r • indicator s f x :=
by { dunfold indicator, split_ifs, exacts [rfl, (smul_zero r).symm] }

lemma indicator_smul (r : M) (f : α → A) :
  indicator s (λ (x : α), r • f x) = λ (x : α), r • indicator s f x :=
funext $ indicator_smul_apply s r f

end distrib_mul_action

section group
variables {G : Type*} [group G] (s t : set α) [decidable_pred (∈ s)]  [decidable_pred (∈ t)]
  {f g : α → G} {a : α}

@[to_additive] lemma mul_indicator_inv' (f : α → G) :
  mul_indicator s (f⁻¹) = (mul_indicator s f)⁻¹ :=
(mul_indicator_hom G s).map_inv f

@[to_additive] lemma mul_indicator_inv (f : α → G) :
  mul_indicator s (λa, (f a)⁻¹) = λa, (mul_indicator s f a)⁻¹ :=
mul_indicator_inv' s f

@[to_additive] lemma mul_indicator_div (f g : α → G) : mul_indicator s (λ a, f a / g a) =
  λ a, mul_indicator s f a / mul_indicator s g a :=
(mul_indicator_hom G s).map_div f g

@[to_additive] lemma mul_indicator_div' (f g : α → G) :
  mul_indicator s (f / g) = mul_indicator s f / mul_indicator s g :=
mul_indicator_div s f g

@[to_additive] lemma mul_indicator_compl' (f : α → G) :
  mul_indicator sᶜ f = f * (mul_indicator s f)⁻¹ :=
eq_mul_inv_of_mul_eq $ s.mul_indicator_compl_mul_self f

@[to_additive] lemma mul_indicator_compl (f : α → G) : mul_indicator sᶜ f = f / mul_indicator s f :=
by rw [div_eq_mul_inv, mul_indicator_compl']

variables {s t}

@[to_additive] lemma mul_indicator_diff' (h : s ⊆ t) (f : α → G) :
  mul_indicator (t \ s) f = mul_indicator t f * (mul_indicator s f)⁻¹ :=
eq_mul_inv_of_mul_eq $ by simp_rw [pi.mul_def, ←mul_indicator_union_of_disjoint disjoint_diff.symm,
  diff_union_self, union_eq_self_of_subset_right h]

@[to_additive] lemma mul_indicator_diff (h : s ⊆ t) (f : α → G) :
  mul_indicator (t \ s) f = mul_indicator t f / mul_indicator s f :=
by rw [mul_indicator_diff' h, div_eq_mul_inv]

end group

section comm_monoid

variables [comm_monoid M]

/-- Consider a product of `g i (f i)` over a `finset`.  Suppose `g` is a
function such as `pow`, which maps a second argument of `1` to
`1`. Then if `f` is replaced by the corresponding multiplicative indicator
function, the `finset` may be replaced by a possibly larger `finset`
without changing the value of the sum. -/
@[to_additive] lemma prod_mul_indicator_subset_of_eq_one [has_one N] (f : α → N)
  (g : α → N → M) {s t : finset α} [decidable_pred (∈ (s : set α))] (h : s ⊆ t)
  (hg : ∀ a, g a 1 = 1) :
  ∏ i in s, g i (f i) = ∏ i in t, g i (mul_indicator ↑s f i) :=
begin
  rw ← finset.prod_subset h _,
  { apply finset.prod_congr rfl,
    intros i hi,
    congr,
    symmetry,
    exact mul_indicator_of_mem hi _ },
  { refine λ i hi hn, _,
    convert hg i,
    exact mul_indicator_of_not_mem hn _ }
end

/-- Consider a sum of `g i (f i)` over a `finset`.  Suppose `g` is a
function such as multiplication, which maps a second argument of 0 to
0.  (A typical use case would be a weighted sum of `f i * h i` or `f i
• h i`, where `f` gives the weights that are multiplied by some other
function `h`.)  Then if `f` is replaced by the corresponding indicator
function, the `finset` may be replaced by a possibly larger `finset`
without changing the value of the sum. -/
add_decl_doc set.sum_indicator_subset_of_eq_zero

@[to_additive] lemma prod_mul_indicator_subset (f : α → M) {s t : finset α}
  [decidable_pred (∈ (s : set α))] (h : s ⊆ t) :
  ∏ i in s, f i = ∏ i in t, mul_indicator ↑s f i :=
prod_mul_indicator_subset_of_eq_one _ (λ a b, b) h (λ _, rfl)

/-- Summing an indicator function over a possibly larger `finset` is
the same as summing the original function over the original
`finset`. -/
add_decl_doc sum_indicator_subset

@[to_additive] lemma _root_.finset.prod_mul_indicator_eq_prod_filter
  (s : finset ι) (f : ι → α → M) (t : ι → set α) [Π i, decidable_pred (∈ t i)] (g : ι → α) :
  ∏ i in s, mul_indicator (t i) (f i) (g i) = ∏ i in s.filter (λ i, g i ∈ t i), f i (g i) :=
begin
  refine (finset.prod_filter_mul_prod_filter_not s (λ i, g i ∈ t i) _).symm.trans _,
  refine eq.trans _ (mul_one _),
  exact congr_arg2 (*)
    (finset.prod_congr rfl $ λ x hx, mul_indicator_of_mem (finset.mem_filter.1 hx).2 _)
    (finset.prod_eq_one $ λ x hx, mul_indicator_of_not_mem (finset.mem_filter.1 hx).2 _)
end

@[to_additive] lemma mul_indicator_finset_prod (I : finset ι) (s : set α)
  [decidable_pred (∈ s)] (f : ι → α → M) :
  mul_indicator s (∏ i in I, f i) = ∏ i in I, mul_indicator s (f i) :=
(mul_indicator_hom M s).map_prod _ _

open_locale classical

@[to_additive] lemma mul_indicator_finset_bUnion {ι} (I : finset ι)
  (s : ι → set α) {f : α → M} : (∀ (i ∈ I) (j ∈ I), i ≠ j → disjoint (s i) (s j)) →
  mul_indicator (⋃ i ∈ I, s i) f = λ a, ∏ i in I, mul_indicator (s i) f a :=
begin
  refine finset.induction_on I _ _,
  { intro h, funext, simp },
  assume a I haI ih hI,
  funext,
  rw [finset.prod_insert haI, finset.set_bUnion_insert],
  convert mul_indicator_union_of_not_mem_inter _ _,
  rw ih,
  { assume i hi j hj hij,
    exact hI i (finset.mem_insert_of_mem hi) j (finset.mem_insert_of_mem hj) hij },
  simp only [not_exists, exists_prop, mem_Union, mem_inter_eq, not_and],
  assume hx a' ha',
  refine disjoint_left.1 (hI a (finset.mem_insert_self _ _) a' (finset.mem_insert_of_mem ha') _) hx,
  exact (ne_of_mem_of_not_mem ha' haI).symm
end

end comm_monoid

section mul_zero_class

variables [mul_zero_class M] (s t : set α) [decidable_pred (∈ s)] [decidable_pred (∈ t)]
  (f g : α → M) {a : α}

lemma indicator_mul : indicator s (λ a, f a * g a) = λ a, indicator s f a * indicator s g a :=
by { funext, simp only [indicator], split_ifs, { refl }, rw mul_zero }

lemma indicator_mul_left : indicator s (λ a, f a * g a) a = indicator s f a * g a :=
by { simp only [indicator], split_ifs, { refl }, rw [zero_mul] }

lemma indicator_mul_right : indicator s (λ a, f a * g a) a = f a * indicator s g a :=
by { simp only [indicator], split_ifs, { refl }, rw [mul_zero] }

lemma inter_indicator_mul (x : α) :
  (s ∩ t).indicator (λ x, f x * g x) x = s.indicator f x * t.indicator g x :=
by { rw [← set.indicator_indicator], simp [indicator] }

end mul_zero_class

section monoid_with_zero

variables [monoid_with_zero M] {s : set α} {t : set β} [decidable_pred (∈ s)] [decidable_pred (∈ t)]

lemma indicator_prod_one {x : α} {y : β} :
  (s ×ˢ t : set _).indicator (1 : _ → M) (x, y) = s.indicator 1 x * t.indicator 1 y :=
by simp [indicator, ← ite_and]

end monoid_with_zero

section order
variables [has_one M] [preorder M] {s t : set α} [decidable_pred (∈ s)] [decidable_pred (∈ t)]
  {f g : α → M} {a : α} {y : M}

@[to_additive] lemma mul_indicator_apply_le' (hfg : a ∈ s → f a ≤ y) (hg : a ∉ s → 1 ≤ y) :
  mul_indicator s f a ≤ y :=
if ha : a ∈ s then by simpa [ha] using hfg ha else by simpa [ha] using hg ha

@[to_additive] lemma mul_indicator_le' (hfg : ∀ a ∈ s, f a ≤ g a) (hg : ∀ a ∉ s, 1 ≤ g a) :
  mul_indicator s f ≤ g :=
λ a, mul_indicator_apply_le' (hfg _) (hg _)

@[to_additive] lemma le_mul_indicator_apply {y} (hfg : a ∈ s → y ≤ g a) (hf : a ∉ s → y ≤ 1) :
  y ≤ mul_indicator s g a :=
@mul_indicator_apply_le' α (order_dual M) ‹_› _ _ _ _ _ _ hfg hf

@[to_additive] lemma le_mul_indicator (hfg : ∀ a ∈ s, f a ≤ g a) (hf : ∀ a ∉ s, f a ≤ 1) :
  f ≤ mul_indicator s g :=
λ a, le_mul_indicator_apply (hfg _) (hf _)

@[to_additive indicator_apply_nonneg]
lemma one_le_mul_indicator_apply (h : a ∈ s → 1 ≤ f a) : 1 ≤ mul_indicator s f a :=
le_mul_indicator_apply h (λ _, le_rfl)

@[to_additive indicator_nonneg]
lemma one_le_mul_indicator (h : ∀ a ∈ s, 1 ≤ f a) (a : α) : 1 ≤ mul_indicator s f a :=
one_le_mul_indicator_apply (h a)

@[to_additive] lemma mul_indicator_apply_le_one (h : a ∈ s → f a ≤ 1) : mul_indicator s f a ≤ 1 :=
mul_indicator_apply_le' h (λ _, le_rfl)

@[to_additive] lemma mul_indicator_le_one (h : ∀ a ∈ s, f a ≤ 1) (a : α) :
  mul_indicator s f a ≤ 1 :=
mul_indicator_apply_le_one (h a)

@[to_additive] lemma mul_indicator_le_mul_indicator (h : f a ≤ g a) :
  mul_indicator s f a ≤ mul_indicator s g a :=
mul_indicator_rel_mul_indicator le_rfl (λ _, h)

attribute [mono] mul_indicator_le_mul_indicator indicator_le_indicator

@[to_additive] lemma mul_indicator_le_mul_indicator_of_subset (h : s ⊆ t) (hf : ∀ a, 1 ≤ f a)
  (a : α) :
  mul_indicator s f a ≤ mul_indicator t f a :=
mul_indicator_apply_le' (λ ha, le_mul_indicator_apply (λ _, le_rfl) (λ hat, (hat $ h ha).elim))
  (λ ha, one_le_mul_indicator_apply (λ _, hf _))

@[to_additive] lemma mul_indicator_le_self' (hf : ∀ x ∉ s, 1 ≤ f x) : mul_indicator s f ≤ f :=
mul_indicator_le' (λ _ _, le_rfl) hf

open_locale classical

@[to_additive] lemma mul_indicator_Union_apply {ι M} [complete_lattice M] [has_one M]
  (h1 : (⊥:M) = 1) (s : ι → set α) (f : α → M) (x : α) :
  mul_indicator (⋃ i, s i) f x = ⨆ i, mul_indicator (s i) f x :=
begin
  by_cases hx : x ∈ ⋃ i, s i,
  { rw [mul_indicator_of_mem hx],
    rw [mem_Union] at hx,
    refine le_antisymm _ (supr_le $ λ i, mul_indicator_le_self' (λ x hx, h1 ▸ bot_le) x),
    rcases hx with ⟨i, hi⟩,
    exact le_supr_of_le i (ge_of_eq $ mul_indicator_of_mem hi _) },
  { rw [mul_indicator_of_not_mem hx],
    simp only [mem_Union, not_exists] at hx,
    simp [hx, ← h1] }
end

end order

section canonically_ordered_monoid

variables [canonically_ordered_monoid M] (s : set α) [decidable_pred (∈ s)] {f g : α → M} {a : α}

@[to_additive] lemma mul_indicator_le_self (f : α → M) : mul_indicator s f ≤ f :=
mul_indicator_le_self' $ λ _ _, one_le _

variables {s}

@[to_additive] lemma mul_indicator_apply_le (hfg : a ∈ s → f a ≤ g a) : mul_indicator s f a ≤ g a :=
mul_indicator_apply_le' hfg $ λ _, one_le _

@[to_additive] lemma mul_indicator_le (hfg : ∀ a ∈ s, f a ≤ g a) : mul_indicator s f ≤ g :=
mul_indicator_le' hfg $ λ _ _, one_le _

end canonically_ordered_monoid

variables [linear_order β] [has_zero β] (s : set α) [decidable_pred (∈ s)] (f : α → β)

lemma indicator_le_indicator_nonneg : s.indicator f ≤ {x | 0 ≤ f x}.indicator f :=
begin
  intro x,
  simp_rw indicator_apply,
  split_ifs,
  { exact le_rfl, },
  { exact (not_le.mp h_1).le, },
  { exact h_1, },
  { exact le_rfl, },
end

lemma indicator_nonpos_le_indicator : {x | f x ≤ 0}.indicator f ≤ s.indicator f :=
@indicator_le_indicator_nonneg α (order_dual β) _ _ s _ f

end set

@[to_additive] lemma monoid_hom.map_mul_indicator {M N : Type*} [monoid M] [monoid N] (f : M →* N)
  (s : set α) [decidable_pred (∈ s)] (g : α → M) (x : α) :
  f (s.mul_indicator g x) = s.mul_indicator (f ∘ g) x :=
congr_fun (set.mul_indicator_comp_of_one f.map_one).symm x
