/-
Copyright (c) 2017 Johannes Hölzl. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johannes Hölzl

Type of functions with finite support.

Functions with finite support provide the basis for the following concrete instances:

 * ℕ →₀ α: Polynomials (where α is a ring)
 * (σ →₀ ℕ) →₀ α: Multivariate Polynomials (again α is a ring, and σ are variable names)
 * α →₀ ℕ: Multisets
 * α →₀ ℤ: Abelian groups freely generated by α
 * β →₀ α: Linear combinations over β where α is the scalar ring

Most of the theory assumes that the range is a commutative monoid. This gives us the big sum
operator as a powerful way to construct `finsupp` elements.

A general advice is to not use α →₀ β directly, as the type class setup might not be fitting.
The best is to define a copy and select the instances best suited.

-/
import data.finset data.set.finite algebra.big_operators algebra.module
open finset
variables {α : Type*} {β : Type*} {γ : Type*} {δ : Type*} {ι : Type*}
  {α₁ : Type*} {α₂ : Type*} {β₁ : Type*} {β₂ : Type*}

reserve infix ` →₀ `:25

/-- `finsupp α β`, denoted `α →₀ β`, is the type of functions `f : α → β` such that
  `f x = 0` for all but finitely many `x`. -/
structure finsupp (α : Type*) (β : Type*) [has_zero β] :=
(support            : finset α)
(to_fun             : α → β)
(mem_support_to_fun : ∀a, a ∈ support ↔ to_fun a ≠ 0)

infix →₀ := finsupp

namespace finsupp

section basic
variable [has_zero β]

instance : has_coe_to_fun (α →₀ β) := ⟨λ_, α → β, finsupp.to_fun⟩

instance : has_zero (α →₀ β) := ⟨⟨∅, (λ_, 0), by simp⟩⟩

@[simp] lemma zero_apply {a : α} : (0 : α →₀ β) a = 0 := rfl

@[simp] lemma support_zero : (0 : α →₀ β).support = ∅ := rfl

instance : inhabited (α →₀ β) := ⟨0⟩

@[simp] lemma mem_support_iff (f : α →₀ β) : ∀a:α, a ∈ f.support ↔ f a ≠ 0 :=
f.mem_support_to_fun

@[extensionality]
lemma ext : ∀{f g : α →₀ β}, (∀a, f a = g a) → f = g
| ⟨s, f, hf⟩ ⟨t, g, hg⟩ h :=
  begin
    have : f = g, { funext a, exact h a },
    subst this,
    have : s = t, { simp [finset.ext, hf, hg] },
    subst this
  end

@[simp] lemma support_eq_empty [decidable_eq β] {f : α →₀ β} : f.support = ∅ ↔ f = 0 :=
⟨assume h, ext $ assume a, by simp [finset.ext] at h; exact h a, by simp {contextual:=tt}⟩

instance [decidable_eq α] [decidable_eq β] : decidable_eq (α →₀ β) :=
assume f g, decidable_of_iff (f.support = g.support ∧ (∀a∈f.support, f a = g a))
  ⟨assume ⟨h₁, h₂⟩, ext $ assume a,
      if h : a ∈ f.support then h₂ a h else
        have hf : f a = 0, by rwa [f.mem_support_iff, not_not] at h,
        have hg : g a = 0, by rwa [h₁, g.mem_support_iff, not_not] at h,
        by rw [hf, hg],
    by intro h; subst h; simp⟩

lemma finite_supp (f : α →₀ β) : set.finite {a | f a ≠ 0} :=
⟨set.fintype_of_finset f.support f.mem_support_iff⟩

lemma support_subset_iff {s : set α} {f : α →₀ β} [decidable_eq α] :
  ↑f.support ⊆ s ↔ (∀a∉s, f a = 0) :=
by simp [set.subset_def];
   exact forall_congr (assume a, @not_imp_comm _ _ (classical.dec _) (classical.dec _))

end basic

section single
variables [decidable_eq α] [decidable_eq β] [has_zero β] {a a' : α} {b : β}

/-- `single a b` is the finitely supported function which has
  value `b` at `a` and zero otherwise. -/
def single (a : α) (b : β) : α →₀ β :=
⟨(if b = 0 then ∅ else {a}), (λa', if a = a' then b else 0),
  begin intro a', by_cases hb : b = 0; by_cases a = a'; simp [h, hb], simp [ne.symm h, h] end⟩

lemma single_apply : (single a b : α →₀ β) a' = (if a = a' then b else 0) :=
rfl

@[simp] lemma single_eq_same : (single a b : α →₀ β) a = b :=
by simp [single_apply]

@[simp] lemma single_eq_of_ne (h : a ≠ a') : (single a b : α →₀ β) a' = 0 :=
by simp [single_apply, h]

@[simp] lemma single_zero : (single a 0 : α →₀ β) = 0 :=
ext $ assume a',
begin
  by_cases h : a = a',
  { rw [h, single_eq_same, zero_apply] },
  { rw [single_eq_of_ne h, zero_apply] }
end

lemma support_single_ne_zero (hb : b ≠ 0) : (single a b).support = {a} :=
if_neg hb

lemma support_single_subset : (single a b).support ⊆ {a} :=
by by_cases b = 0; simp [support_single_ne_zero, h]

end single

section on_finset
variables [decidable_eq β] [has_zero β]

/-- `on_finset s f hf` is the finsupp function representing `f` restricted to the set `s`.
The function needs to be 0 outside of `s`. Use this when the set needs filtered anyway, otherwise
often better set representation is available. -/
def on_finset (s : finset α) (f : α → β) (hf : ∀a, f a ≠ 0 → a ∈ s) : α →₀ β :=
⟨s.filter (λa, f a ≠ 0), f,
  assume a, classical.by_cases
    (assume h : f a = 0, by simp [h])
    (assume h : f a ≠ 0, by simp [h, hf])⟩

@[simp] lemma on_finset_apply {s : finset α} {f : α → β} {hf a} :
  (on_finset s f hf : α →₀ β) a = f a :=
rfl

@[simp] lemma support_on_finset_subset {s : finset α} {f : α → β} {hf} :
  (on_finset s f hf).support ⊆ s :=
by simp [on_finset]

end on_finset

section map_range
variables [has_zero β₁] [has_zero β₂] [decidable_eq β₂]

/-- The composition of `f : β₁ → β₂` and `g : α →₀ β₁` is
  `map_range f hf g : α →₀ β₂`, well defined when `f 0 = 0`. -/
def map_range (f : β₁ → β₂) (hf : f 0 = 0) (g : α →₀ β₁) : α →₀ β₂ :=
on_finset g.support (f ∘ g) $
  assume a, by rw [mem_support_iff, not_imp_not]; simp [hf] {contextual := tt}

@[simp] lemma map_range_apply {f : β₁ → β₂} {hf : f 0 = 0} {g : α →₀ β₁} {a : α} :
  map_range f hf g a = f (g a) :=
rfl

lemma support_map_range {f : β₁ → β₂} {hf : f 0 = 0} {g : α →₀ β₁} :
  (map_range f hf g).support ⊆ g.support :=
support_on_finset_subset

variables [decidable_eq α] [decidable_eq β₁]
@[simp] lemma map_range_single {f : β₁ → β₂} {hf : f 0 = 0} {a : α} {b : β₁} :
  map_range f hf (single a b) = single a (f b) :=
finsupp.ext $ λ a', by by_cases a = a'; [{subst a', simp}, simp [h, hf]]

end map_range

section zip_with
variables [has_zero β] [has_zero β₁] [has_zero β₂] [decidable_eq α] [decidable_eq β]

/-- `zip_with f hf g₁ g₂` is the finitely supported function satisfying
  `zip_with f hf g₁ g₂ a = f (g₁ a) (g₂ a)`, and well defined when `f 0 0 = 0`. -/
def zip_with (f : β₁ → β₂ → β) (hf : f 0 0 = 0) (g₁ : α →₀ β₁) (g₂ : α →₀ β₂) : (α →₀ β) :=
on_finset (g₁.support ∪ g₂.support) (λa, f (g₁ a) (g₂ a)) $
  assume a, classical.by_cases
    (assume h : g₁ a = 0, by simp [h]; rw [not_imp_not]; simp [hf] {contextual := tt})
    (assume h : g₁ a ≠ 0, by simp [h])

@[simp] lemma zip_with_apply
  {f : β₁ → β₂ → β} {hf : f 0 0 = 0} {g₁ : α →₀ β₁} {g₂ : α →₀ β₂} {a : α} :
  zip_with f hf g₁ g₂ a = f (g₁ a) (g₂ a) :=
rfl

lemma support_zip_with {f : β₁ → β₂ → β} {hf : f 0 0 = 0} {g₁ : α →₀ β₁} {g₂ : α →₀ β₂} :
  (zip_with f hf g₁ g₂).support ⊆ g₁.support ∪ g₂.support :=
support_on_finset_subset

end zip_with

section erase
variables [decidable_eq α] [decidable_eq β]

def erase [has_zero β] (a : α) (f : α →₀ β) : α →₀ β :=
⟨f.support.erase a, (λa', if a' = a then 0 else f a'),
  assume a', by by_cases a' = a; simp [h]⟩

@[simp] lemma support_erase [has_zero β] {a : α} {f : α →₀ β} :
  (f.erase a).support = f.support.erase a :=
rfl

@[simp] lemma erase_same [has_zero β] {a : α} {f : α →₀ β} : (f.erase a) a = 0 :=
if_pos rfl

@[simp] lemma erase_ne [has_zero β] {a a' : α} {f : α →₀ β} (h : a' ≠ a) : (f.erase a) a' = f a' :=
if_neg h

end erase

-- [to_additive finsupp.sum] for finsupp.prod doesn't work, the equation lemmas are not generated
/-- `sum f g` is the sum of `g a (f a)` over the support of `f`. -/
def sum [has_zero β] [add_comm_monoid γ] (f : α →₀ β) (g : α → β → γ) : γ :=
f.support.sum (λa, g a (f a))

/-- `prod f g` is the product of `g a (f a)` over the support of `f`. -/
@[to_additive finsupp.sum]
def prod [has_zero β] [comm_monoid γ] (f : α →₀ β) (g : α → β → γ) : γ :=
f.support.prod (λa, g a (f a))
attribute [to_additive finsupp.sum.equations._eqn_1] finsupp.prod.equations._eqn_1

@[to_additive finsupp.sum_map_range_index]
lemma prod_map_range_index [has_zero β₁] [has_zero β₂] [comm_monoid γ] [decidable_eq β₂]
  {f : β₁ → β₂} {hf : f 0 = 0} {g : α →₀ β₁} {h : α → β₂ → γ} (h0 : ∀a, h a 0 = 1) :
  (map_range f hf g).prod h = g.prod (λa b, h a (f b)) :=
finset.prod_subset support_map_range $ by simp [h0] {contextual := tt}

@[to_additive finsupp.sum_zero_index]
lemma prod_zero_index [add_comm_monoid β] [comm_monoid γ] {h : α → β → γ} :
  (0 : α →₀ β).prod h = 1 :=
by simp [finsupp.prod]

section decidable
variables [decidable_eq α] [decidable_eq β]

section add_monoid
variables [add_monoid β]

@[to_additive finsupp.sum_single_index]
lemma prod_single_index [comm_monoid γ] {a : α} {b : β} {h : α → β → γ} (h_zero : h a 0 = 1) :
  (single a b).prod h = h a b :=
begin
  by_cases h : b = 0,
  { simp [h, prod_zero_index, h_zero], refl },
  { simp [finsupp.prod, support_single_ne_zero h] }
end

instance : has_add (α →₀ β) := ⟨zip_with (+) (add_zero 0)⟩

@[simp] lemma add_apply {g₁ g₂ : α →₀ β} {a : α} : (g₁ + g₂) a = g₁ a + g₂ a :=
rfl

lemma support_add {g₁ g₂ : α →₀ β} : (g₁ + g₂).support ⊆ g₁.support ∪ g₂.support :=
support_zip_with

lemma support_add_eq {g₁ g₂ : α →₀ β} (h : disjoint g₁.support g₂.support):
  (g₁ + g₂).support = g₁.support ∪ g₂.support :=
le_antisymm support_zip_with $ assume a ha,
(finset.mem_union.1 ha).elim
  (assume ha, have a ∉ g₂.support, from disjoint_left.1 h ha, by simp * at *)
  (assume ha, have a ∉ g₁.support, from disjoint_right.1 h ha, by simp * at *)

@[simp] lemma single_add {a : α} {b₁ b₂ : β} : single a (b₁ + b₂) = single a b₁ + single a b₂ :=
ext $ assume a',
begin
  by_cases h : a = a',
  { rw [h, add_apply, single_eq_same, single_eq_same, single_eq_same] },
  { rw [add_apply, single_eq_of_ne h, single_eq_of_ne h, single_eq_of_ne h, zero_add] }
end

instance : add_monoid (α →₀ β) :=
{ add_monoid .
  zero      := 0,
  add       := (+),
  add_assoc := assume ⟨s, f, hf⟩ ⟨t, g, hg⟩ ⟨u, h, hh⟩, ext $ assume a, add_assoc _ _ _,
  zero_add  := assume ⟨s, f, hf⟩, ext $ assume a, zero_add _,
  add_zero  := assume ⟨s, f, hf⟩, ext $ assume a, add_zero _ }

lemma single_add_erase {a : α} {f : α →₀ β} : single a (f a) + f.erase a = f :=
ext $ λ a',
if h : a = a' then by subst h; simp
else by simp [ne.symm h, h]

lemma erase_add_single {a : α} {f : α →₀ β} : f.erase a + single a (f a) = f :=
ext $ λ a',
if h : a = a' then by subst h; simp
else by simp [ne.symm h, h]

protected theorem induction {p : (α →₀ β) → Prop} (f : α →₀ β)
  (h0 : p 0) (ha : ∀a b (f : α →₀ β), a ∉ f.support → b ≠ 0 → p f → p (single a b + f)) :
  p f :=
suffices ∀s (f : α →₀ β), f.support = s → p f, from this _ _ rfl,
assume s, finset.induction_on s (by simp [h0] {contextual := tt}) $
assume a s has ih f hf,
suffices p (single a (f a) + f.erase a), by rwa [single_add_erase] at this,
begin
  apply ha,
  { simp },
  { rw [← mem_support_iff _ a, hf], simp },
  { apply ih _ _,
    simp [hf, has, finset.erase_insert] }
end

lemma induction₂ {p : (α →₀ β) → Prop} (f : α →₀ β)
  (h0 : p 0) (ha : ∀a b (f : α →₀ β), a ∉ f.support → b ≠ 0 → p f → p (f + single a b)) :
  p f :=
suffices ∀s (f : α →₀ β), f.support = s → p f, from this _ _ rfl,
assume s, finset.induction_on s (by simp [h0] {contextual := tt}) $
assume a s has ih f hf,
suffices p (f.erase a + single a (f a)), by rwa [erase_add_single] at this,
begin
  apply ha,
  { simp },
  { rw [← mem_support_iff _ a, hf], simp },
  { apply ih _ _,
    simp [hf, has, finset.erase_insert] }
end

end add_monoid

instance [add_comm_monoid β] : add_comm_monoid (α →₀ β) :=
{ add_comm := assume ⟨s, f, _⟩ ⟨t, g, _⟩, ext $ assume a, add_comm _ _,
  .. finsupp.add_monoid }

instance [add_group β] : add_group (α →₀ β) :=
{ neg          := map_range (has_neg.neg) neg_zero,
  add_left_neg := assume ⟨s, f, _⟩, ext $ assume x, add_left_neg _,
  .. finsupp.add_monoid }

lemma single_multiset_sum [add_comm_monoid β] [decidable_eq α] [decidable_eq β]
  (s : multiset β) (a : α) : single a s.sum = (s.map (single a)).sum :=
multiset.induction_on s (by simp) (by simp {contextual := tt})

lemma single_finset_sum [add_comm_monoid β] [decidable_eq α] [decidable_eq β]
  (s : finset γ) (f : γ → β) (a : α) : single a (s.sum f) = s.sum (λb, single a (f b)) :=
begin
  transitivity,
  apply single_multiset_sum,
  rw [multiset.map_map],
  refl
end

lemma single_sum [has_zero γ] [add_comm_monoid β] [decidable_eq α] [decidable_eq β]
  (s : δ →₀ γ) (f : δ → γ → β) (a : α) : single a (s.sum f) = s.sum (λd c, single a (f d c)) :=
single_finset_sum _ _ _


@[to_additive finsupp.sum_neg_index]
lemma prod_neg_index [add_group β] [comm_monoid γ]
  {g : α →₀ β} {h : α → β → γ} (h0 : ∀a, h a 0 = 1) :
  (-g).prod h = g.prod (λa b, h a (- b)) :=
prod_map_range_index h0

@[simp] lemma neg_apply [add_group β] {g : α →₀ β} {a : α} : (- g) a = - g a := rfl

@[simp] lemma sub_apply [add_group β] {g₁ g₂ : α →₀ β} {a : α} : (g₁ - g₂) a = g₁ a - g₂ a := rfl

@[simp] lemma support_neg [add_group β] {f : α →₀ β} : support (-f) = support f :=
finset.subset.antisymm
  support_map_range
  (calc support f = support (- (- f)) : by simp
     ... ⊆ support (- f) : support_map_range)

instance [add_comm_group β] : add_comm_group (α →₀ β) :=
{ add_comm := add_comm, ..finsupp.add_group }

@[simp] lemma sum_apply [has_zero β₁] [add_comm_monoid β]
  {f : α₁ →₀ β₁} {g : α₁ → β₁ → α →₀ β} {a₂ : α} :
  (f.sum g) a₂ = f.sum (λa₁ b, g a₁ b a₂) :=
(finset.sum_hom (λf : α →₀ β, f a₂) rfl (assume a b, rfl)).symm

lemma support_sum [has_zero β₁] [add_comm_monoid β]
  {f : α₁ →₀ β₁} {g : α₁ → β₁ → (α →₀ β)} :
  (f.sum g).support ⊆ f.support.bind (λa, (g a (f a)).support) :=
have ∀a₁ : α, f.sum (λ (a : α₁) (b : β₁), (g a b) a₁) ≠ 0 →
    (∃ (a : α₁), f a ≠ 0 ∧ ¬ (g a (f a)) a₁ = 0),
  from assume a₁ h,
  let ⟨a, ha, ne⟩ := finset.exists_ne_zero_of_sum_ne_zero h in
  ⟨a, (f.mem_support_iff a).mp ha, ne⟩,
by simpa [finset.subset_iff, mem_support_iff, finset.mem_bind, sum_apply] using this

@[simp] lemma sum_zero [add_comm_monoid β] [add_comm_monoid γ] {f : α →₀ β} :
  f.sum (λa b, (0 : γ)) = 0 :=
finset.sum_const_zero

@[simp] lemma sum_add  [add_comm_monoid β] [add_comm_monoid γ] {f : α →₀ β}
  {h₁ h₂ : α → β → γ} :
  f.sum (λa b, h₁ a b + h₂ a b) = f.sum h₁ + f.sum h₂ :=
finset.sum_add_distrib

@[simp] lemma sum_neg [add_comm_monoid β] [add_comm_group γ] {f : α →₀ β}
  {h : α → β → γ} : f.sum (λa b, - h a b) = - f.sum h :=
finset.sum_hom (@has_neg.neg γ _) neg_zero (assume a b, neg_add _ _)

@[simp] lemma sum_single [add_comm_monoid β] {f : α →₀ β} :
  f.sum single = f :=
have ∀a:α, f.sum (λa' b, ite (a' = a) b 0) =
    ({a} : finset α).sum (λa', ite (a' = a) (f a') 0),
begin
  intro a,
  by_cases h : a ∈ f.support,
  { have : (finset.singleton a : finset α) ⊆ f.support,
      { simp [finset.subset_iff, *] at * },
    refine (finset.sum_subset this _).symm,
    simp {contextual := tt} },
  { transitivity (f.support.sum (λa, (0 : β))),
    { refine (finset.sum_congr rfl _),
      intros a' ha',
      have h: a' ≠ a,
        { assume eq, simp * at * },
      simp * at * },
    { simp * at * } }
end,
ext $ assume a, by simp [single_apply, this]

@[to_additive finsupp.sum_add_index]
lemma prod_add_index [add_comm_monoid β] [comm_monoid γ] {f g : α →₀ β}
  {h : α → β → γ} (h_zero : ∀a, h a 0 = 1) (h_add : ∀a b₁ b₂, h a (b₁ + b₂) = h a b₁ * h a b₂) :
  (f + g).prod h = f.prod h * g.prod h :=
have f_eq : (f.support ∪ g.support).prod (λa, h a (f a)) = f.prod h,
  from (finset.prod_subset finset.subset_union_left $
    by simp [mem_support_iff, h_zero] {contextual := tt}).symm,
have g_eq : (f.support ∪ g.support).prod (λa, h a (g a)) = g.prod h,
  from (finset.prod_subset finset.subset_union_right $
    by simp [mem_support_iff, h_zero] {contextual := tt}).symm,
calc (f + g).support.prod (λa, h a ((f + g) a)) =
      (f.support ∪ g.support).prod (λa, h a ((f + g) a)) :
    finset.prod_subset support_add $
      by simp [mem_support_iff, h_zero] {contextual := tt}
  ... = (f.support ∪ g.support).prod (λa, h a (f a)) *
      (f.support ∪ g.support).prod (λa, h a (g a)) :
    by simp [h_add, finset.prod_mul_distrib]
  ... = _ : by rw [f_eq, g_eq]

lemma sum_sub_index [add_comm_group β] [add_comm_group γ] {f g : α →₀ β}
  {h : α → β → γ} (h_sub : ∀a b₁ b₂, h a (b₁ - b₂) = h a b₁ - h a b₂) :
  (f - g).sum h = f.sum h - g.sum h :=
have h_zero : ∀a, h a 0 = 0,
  from assume a,
  have h a (0 - 0) = h a 0 - h a 0, from h_sub a 0 0,
  by simpa using this,
have h_neg : ∀a b, h a (- b) = - h a b,
  from assume a b,
  have h a (0 - b) = h a 0 - h a b, from h_sub a 0 b,
  by simpa [h_zero] using this,
have h_add : ∀a b₁ b₂, h a (b₁ + b₂) = h a b₁ + h a b₂,
  from assume a b₁ b₂,
  have h a (b₁ - (- b₂)) = h a b₁ - h a (- b₂), from h_sub a b₁ (-b₂),
  by simpa [h_neg] using this,
calc (f - g).sum h = (f + - g).sum h : by simp
  ... = f.sum h + - g.sum h : by simp [sum_add_index, sum_neg_index, h_add, h_zero, h_neg]
  ... = _ : by simp

@[to_additive finsupp.sum_finset_sum_index]
lemma prod_finset_sum_index [add_comm_monoid β] [comm_monoid γ] [decidable_eq ι]
  {s : finset ι} {g : ι → α →₀ β}
  {h : α → β → γ} (h_zero : ∀a, h a 0 = 1) (h_add : ∀a b₁ b₂, h a (b₁ + b₂) = h a b₁ * h a b₂):
  s.prod (λi, (g i).prod h) = (s.sum g).prod h :=
finset.induction_on s
  (by simp [prod_zero_index])
  (by simp [prod_add_index, h_zero, h_add] {contextual := tt})

@[to_additive finsupp.sum_sum_index]
lemma prod_sum_index
  [decidable_eq α₁] [add_comm_monoid β₁] [add_comm_monoid β] [comm_monoid γ]
  {f : α₁ →₀ β₁} {g : α₁ → β₁ → α →₀ β}
  {h : α → β → γ} (h_zero : ∀a, h a 0 = 1) (h_add : ∀a b₁ b₂, h a (b₁ + b₂) = h a b₁ * h a b₂):
  (f.sum g).prod h = f.prod (λa b, (g a b).prod h) :=
(prod_finset_sum_index h_zero h_add).symm

lemma multiset_sum_sum_index
  [decidable_eq α] [decidable_eq β] [add_comm_monoid β] [add_comm_monoid γ]
  (f : multiset (α →₀ β)) (h : α → β → γ)
  (h₀ : ∀a, h a 0 = 0) (h₁ : ∀ (a : α) (b₁ b₂ : β), h a (b₁ + b₂) = h a b₁ + h a b₂) :
  (f.sum.sum h) = (f.map $ λg:α →₀ β, g.sum h).sum :=
multiset.induction_on f (by simp [finsupp.sum_zero_index])
  (assume a s ih, by simp [finsupp.sum_add_index h₀ h₁, ih] {contextual := tt})

lemma multiset_map_sum [has_zero β] {f : α →₀ β} {m : γ → δ} {h : α → β → multiset γ} :
  multiset.map m (f.sum h) = f.sum (λa b, (h a b).map m) :=
(finset.sum_hom _ (multiset.map_zero m) (multiset.map_add m)).symm

lemma multiset_sum_sum [has_zero β] [add_comm_monoid γ] {f : α →₀ β} {h : α → β → multiset γ} :
  multiset.sum (f.sum h) = f.sum (λa b, multiset.sum (h a b)) :=
begin
  refine (finset.sum_hom multiset.sum _ _).symm,
  exact multiset.sum_zero,
  exact multiset.sum_add
end

section map_domain
variables [decidable_eq α₁] [decidable_eq α₂] [add_comm_monoid β] {v v₁ v₂ : α →₀ β}

/-- Given `f : α₁ → α₂` and `v : α₁ →₀ β`, `map_domain f v : α₂ →₀ β`
  is the finitely supported function whose value at `a : α₂` is the sum
  of `v x` over all `x` such that `f x = a`. -/
def map_domain (f : α₁ → α₂) (v : α₁ →₀ β) : α₂ →₀ β :=
v.sum $ λa, single (f a)

lemma map_domain_id : map_domain id v = v :=
sum_single

lemma map_domain_comp {f : α → α₁} {g : α₁ → α₂} :
  map_domain (g ∘ f) v = map_domain g (map_domain f v) :=
by simp [map_domain, sum_sum_index, sum_single_index]

lemma map_domain_single {f : α → α₁} {a : α} {b : β} : map_domain f (single a b) = single (f a) b :=
sum_single_index (by simp)

lemma map_domain_zero {f : α → α₂} : map_domain f 0 = (0 : α₂ →₀ β) :=
sum_zero_index

lemma map_domain_congr {f g : α → α₂} (h : ∀x∈v.support, f x = g x) :
  v.map_domain f = v.map_domain g :=
finset.sum_congr rfl $ by simp [*] at * {contextual := tt}

lemma map_domain_add {f : α → α₂} : map_domain f (v₁ + v₂) = map_domain f v₁ + map_domain f v₂ :=
sum_add_index (by simp) (by simp)

lemma map_domain_finset_sum [decidable_eq ι] {f : α → α₂} {s : finset ι} {v : ι → α →₀ β} :
  map_domain f (s.sum v) = s.sum (λi, map_domain f (v i)) :=
by refine (sum_finset_sum_index _ _).symm; simp

lemma map_domain_sum [has_zero β₁] {f : α → α₂} {s : α →₀ β₁} {v : α → β₁ → α →₀ β} :
  map_domain f (s.sum v) = s.sum (λa b, map_domain f (v a b)) :=
by refine (sum_finset_sum_index _ _).symm; simp

lemma map_domain_support {f : α → α₂} {s : α →₀ β} :
  (s.map_domain f).support ⊆ s.support.image f :=
finset.subset.trans support_sum $
  finset.subset.trans (finset.bind_mono $ assume a ha, support_single_subset) $
  by rw [finset.bind_singleton]; exact subset.refl _

@[to_additive finsupp.sum_map_domain_index]
lemma prod_map_domain_index [comm_monoid γ] {f : α → α₂} {s : α →₀ β}
  {h : α₂ → β → γ} (h_zero : ∀a, h a 0 = 1) (h_add : ∀a b₁ b₂, h a (b₁ + b₂) = h a b₁ * h a b₂) :
  (s.map_domain f).prod h = s.prod (λa b, h (f a) b) :=
by simp [map_domain, prod_sum_index, h_zero, h_add, prod_single_index]

end map_domain

/-- The product of `f g : α →₀ β` is the finitely supported function
  whose value at `a` is the sum of `f x * g y` over all pairs `x, y`
  such that `x + y = a`. (Think of the product of multivariate
  polynomials where `α` is the monoid of monomial exponents.) -/
instance [has_add α] [semiring β] : has_mul (α →₀ β) :=
⟨λf g, f.sum $ λa₁ b₁, g.sum $ λa₂ b₂, single (a₁ + a₂) (b₁ * b₂)⟩

lemma mul_def [has_add α] [semiring β] {f g : α →₀ β} :
  f * g = (f.sum $ λa₁ b₁, g.sum $ λa₂ b₂, single (a₁ + a₂) (b₁ * b₂)) := rfl

/-- The unit of the multiplication is `single 0 1`, i.e. the function
  that is 1 at 0 and zero elsewhere. -/
instance [has_zero α] [has_zero β] [has_one β] : has_one (α →₀ β) :=
⟨single 0 1⟩

lemma one_def [has_zero α] [has_zero β] [has_one β] : 1 = (single 0 1 : α →₀ β) := rfl

section filter -- TODO: remove filter? build upon subtype_domain?
section has_zero
variables [has_zero β] {p : α → Prop} [decidable_pred p] {f : α →₀ β}

/-- `filter p f` is the function which is `f a` if `p a` is true and 0 otherwise. -/
def filter (p : α → Prop) [decidable_pred p] (f : α →₀ β) : α →₀ β :=
on_finset f.support (λa, if p a then f a else 0) (assume a, by by_cases (p a); simp [h])

@[simp] lemma filter_apply_pos {a : α} (h : p a) : f.filter p a = f a :=
if_pos h

@[simp] lemma filter_apply_neg {a : α} (h : ¬ p a) : f.filter p a = 0 :=
if_neg h

@[simp] lemma support_filter : (f.filter p).support = f.support.filter p :=
finset.ext.mpr $ assume a, by by_cases p a; simp *

end has_zero

lemma filter_pos_add_filter_neg [add_monoid β] {f : α →₀ β} {p : α → Prop}
  [decidable_pred p] [decidable_pred (λa, ¬ p a)] :
  f.filter p + f.filter (λa, ¬ p a) = f :=
finsupp.ext $ assume a, by by_cases p a; simp *

end filter

section subtype_domain

variables {α' : Type*} [has_zero δ] {p : α → Prop} [decidable_pred p]

section zero
variables [has_zero β] {v v' : α' →₀ β}

/-- `subtype_domain p f` is the restriction of the finitely supported function
  `f` to the subtype `p`. -/
def subtype_domain (p : α → Prop) [decidable_pred p] (f : α →₀ β) : (subtype p →₀ β) :=
⟨f.support.subtype p, f ∘ subtype.val, by simp⟩

@[simp] lemma support_subtype_domain {f : α →₀ β} :
  (subtype_domain p f).support = f.support.subtype p :=
rfl

@[simp] lemma subtype_domain_apply {a : subtype p} {v : α →₀ β} :
  (subtype_domain p v) a = v (a.val) :=
rfl

@[simp] lemma subtype_domain_zero : subtype_domain p (0 : α →₀ β) = 0 :=
rfl

@[to_additive finsupp.sum_subtype_domain_index]
lemma prod_subtype_domain_index [comm_monoid γ] {v : α →₀ β}
  {h : α → β → γ} (hp : ∀x∈v.support, p x) :
  (v.subtype_domain p).prod (λa b, h a.1 b) = v.prod h :=
prod_bij (λp _, p.val)
  (by simp)
  (by simp)
  (assume ⟨a₀, ha₀⟩ ⟨a₁, ha₁⟩, by simp)
  (begin simp; exact assume b hb, ⟨b, hp _ (by simp [hb]), by simp [hb]⟩ end)

end zero

section monoid
variables [add_monoid β] {v v' : α' →₀ β}

@[simp] lemma subtype_domain_add {v v' : α →₀ β} :
  (v + v').subtype_domain p = v.subtype_domain p + v'.subtype_domain p :=
ext $ by simp

end monoid

section comm_monoid
variables [add_comm_monoid β]

lemma subtype_domain_sum {s : finset γ} {h : γ → α →₀ β} :
  (s.sum h).subtype_domain p = s.sum (λc, (h c).subtype_domain p) :=
eq.symm (finset.sum_hom _ subtype_domain_zero $ assume v v', subtype_domain_add)

lemma subtype_domain_finsupp_sum {s : γ →₀ δ} {h : γ → δ → α →₀ β} :
  (s.sum h).subtype_domain p = s.sum (λc d, (h c d).subtype_domain p) :=
subtype_domain_sum

end comm_monoid

section group
variables [add_group β] {v v' : α' →₀ β}

@[simp] lemma subtype_domain_neg {v : α →₀ β} :
  (- v).subtype_domain p = - v.subtype_domain p :=
ext $ by simp

@[simp] lemma subtype_domain_sub {v v' : α →₀ β} :
  (v - v').subtype_domain p = v.subtype_domain p - v'.subtype_domain p :=
ext $ by simp

end group

end subtype_domain

section multiset

def to_multiset (f : α →₀ ℕ) : multiset α :=
f.sum (λa n, add_monoid.smul n {a})

@[simp] lemma count_to_multiset [decidable_eq α] (f : α →₀ ℕ) (a : α) :
  f.to_multiset.count a = f a :=
calc f.to_multiset.count a = f.sum (λx n, (add_monoid.smul n {x} : multiset α).count a) :
    (finset.sum_hom _ (multiset.count_zero a) (multiset.count_add a)).symm
  ... = f.sum (λx n, n * ({x} : multiset α).count a) : by simp
  ... = f.sum (λx n, n * (x :: 0 : multiset α).count a) : rfl
  ... = f a * (a :: 0 : multiset α).count a :
    begin
      refine sum_eq_single _ _ _,
      { simp [multiset.count_cons_of_ne, nat.mul_eq_zero, multiset.count_eq_zero, eq_comm]
        {contextual := tt} },
      { simp }
    end
  ... = f a : by simp [multiset.count_singleton]

def of_multiset [decidable_eq α] (m : multiset α) : α →₀ ℕ :=
on_finset m.to_finset (λa, m.count a) $ by simp [multiset.count_eq_zero]

@[simp] lemma of_multiset_apply [decidable_eq α] (m : multiset α) (a : α) :
  of_multiset m a = m.count a :=
rfl

def equiv_multiset [decidable_eq α] : (α →₀ ℕ) ≃ (multiset α) :=
⟨ to_multiset, of_multiset, assume f, finsupp.ext $ by simp, assume m, multiset.ext.2 $ by simp ⟩

lemma mem_support_multiset_sum [decidable_eq α] [decidable_eq β] [add_comm_monoid β]
  {s : multiset (α →₀ β)} (a : α) :
  a ∈ s.sum.support → ∃f∈s, a ∈ (f : α →₀ β).support :=
multiset.induction_on s (by simp)
  begin
    assume f s ih ha,
    by_cases a ∈ f.support,
    { exact ⟨f, multiset.mem_cons_self _ _, h⟩ },
    { simp at h,
      simp [h] at ha,
      simp [ha] at ih,
      rcases ih with ⟨f', h₀, h₁⟩,
      exact ⟨f', multiset.mem_cons_of_mem h₀, by simpa using h₁⟩ }
  end

lemma mem_support_finset_sum [decidable_eq α] [decidable_eq β] [add_comm_monoid β]
  {s : finset γ} {h : γ → α →₀ β} (a : α) (ha : a ∈ (s.sum h).support) : ∃c∈s, a ∈ (h c).support :=
let ⟨f, hf, hfa⟩ := mem_support_multiset_sum a ha in
let ⟨c, hc, eq⟩ := multiset.mem_map.1 hf in
⟨c, hc, eq.symm ▸ hfa⟩

lemma mem_support_single [decidable_eq α] [decidable_eq β] [has_zero β] (a a' : α) (b : β) :
  a ∈ (single a' b).support ↔ a = a' ∧ b ≠ 0 :=
classical.by_cases
  (assume : b = 0, by simp [this])
  (assume : b ≠ 0, by simp [this, -mem_support_iff, support_single_ne_zero])

end multiset

section curry_uncurry

protected def curry [decidable_eq α] [decidable_eq β] [decidable_eq γ] [add_comm_monoid γ]
  (f : (α × β) →₀ γ) : α →₀ (β →₀ γ) :=
f.sum $ λp c, single p.1 (single p.2 c)

lemma sum_curry_index
  [decidable_eq α] [decidable_eq β] [decidable_eq γ] [add_comm_monoid γ] [add_comm_monoid δ]
  (f : (α × β) →₀ γ) (g : α → β → γ → δ)
  (hg₀ : ∀ a b, g a b 0 = 0) (hg₁ : ∀a b c₀ c₁, g a b (c₀ + c₁) = g a b c₀ + g a b c₁) :
  f.curry.sum (λa f, f.sum (g a)) = f.sum (λp c, g p.1 p.2 c) :=
begin
  rw [finsupp.curry],
  transitivity,
  { exact sum_sum_index (assume a, sum_zero_index)
      (assume a b₀ b₁, sum_add_index (assume a, hg₀ _ _) (assume c d₀ d₁, hg₁ _ _ _ _)) },
  congr, funext p c,
  transitivity,
  { exact sum_single_index sum_zero_index },
  exact sum_single_index (hg₀ _ _)
end

protected def uncurry [decidable_eq α] [decidable_eq β] [decidable_eq γ] [add_comm_monoid γ]
  (f : α →₀ (β →₀ γ)) : (α × β) →₀ γ :=
f.sum $ λa g, g.sum $ λb c, single (a, b) c

def finsupp_prod_equiv [add_comm_monoid γ] [decidable_eq α] [decidable_eq β] [decidable_eq γ] :
  ((α × β) →₀ γ) ≃ (α →₀ (β →₀ γ)) :=
⟨ finsupp.curry, finsupp.uncurry,
  assume f, by simp [finsupp.curry, finsupp.uncurry, sum_sum_index, sum_zero_index, sum_add_index,
    sum_single_index],
  assume f, by simp [finsupp.curry, finsupp.uncurry, sum_sum_index, sum_zero_index, sum_add_index,
    sum_single_index, (single_sum _ _ _).symm] ⟩

end curry_uncurry

section
variables [add_monoid α] [semiring β]

-- TODO: the simplifier unfolds 0 in the instance proof!
private lemma zero_mul (f : α →₀ β) : 0 * f = 0 := by simp [mul_def, sum_zero_index]
private lemma mul_zero (f : α →₀ β) : f * 0 = 0 := by simp [mul_def, sum_zero_index]
private lemma left_distrib (a b c : α →₀ β) : a * (b + c) = a * b + a * c :=
by simp [mul_def, sum_add_index, mul_add]
private lemma right_distrib (a b c : α →₀ β) : (a + b) * c = a * c + b * c :=
by simp [mul_def, sum_add_index, add_mul]

def to_semiring : semiring (α →₀ β) :=
{ one       := 1,
  mul       := (*),
  one_mul   := assume f, by simp [mul_def, one_def, sum_single_index],
  mul_one   := assume f, by simp [mul_def, one_def, sum_single_index],
  zero_mul  := zero_mul,
  mul_zero  := mul_zero,
  mul_assoc := assume f g h,
    by simp [mul_def, sum_sum_index, sum_zero_index, sum_add_index, sum_single_index,
        add_mul, mul_add, mul_assoc],
  left_distrib  := left_distrib,
  right_distrib := right_distrib,
  .. finsupp.add_comm_monoid }

end

local attribute [instance] to_semiring

def to_comm_semiring [add_comm_monoid α] [comm_semiring β] : comm_semiring (α →₀ β) :=
{ mul_comm := assume f g,
  begin
    simp [mul_def, finsupp.sum, mul_comm],
    rw [finset.sum_comm],
    simp
  end,
  .. finsupp.to_semiring }

local attribute [instance] to_comm_semiring

def to_ring [add_monoid α] [ring β] : ring (α →₀ β) :=
{ neg := has_neg.neg,
  add_left_neg := add_left_neg,
  .. finsupp.to_semiring }

def to_comm_ring [add_comm_monoid α] [comm_ring β] : comm_ring (α →₀ β) :=
{ mul_comm := mul_comm, .. finsupp.to_ring}

lemma single_mul_single [has_add α] [semiring β] {a₁ a₂ : α} {b₁ b₂ : β}:
  single a₁ b₁ * single a₂ b₂ = single (a₁ + a₂) (b₁ * b₂) :=
by simp [mul_def, sum_single_index]

lemma prod_single [decidable_eq ι] [add_comm_monoid α] [comm_semiring β]
  {s : finset ι} {a : ι → α} {b : ι → β} :
  s.prod (λi, single (a i) (b i)) = single (s.sum a) (s.prod b) :=
finset.induction_on s (by simp [one_def]) (by simp [single_mul_single] {contextual := tt})

section
variable (β)

def to_has_scalar' [ring γ] [module γ β] : has_scalar γ (α →₀ β) := ⟨λa v, v.map_range ((•) a) (smul_zero)⟩
local attribute [instance] to_has_scalar'

@[simp] lemma smul_apply' [ring γ] [module γ β] {a : α} {b : γ} {v : α →₀ β} :
  (b • v) a = b • (v a) := rfl

def to_module [ring γ] [module γ β] : module γ (α →₀ β) :=
{ smul     := (•),
  smul_add := assume a x y, finsupp.ext $ by simp [smul_add],
  add_smul := assume a x y, finsupp.ext $ by simp [add_smul],
  one_smul := assume x, finsupp.ext $ by simp,
  mul_smul := assume r s x, finsupp.ext $ by simp [smul_smul],
  .. finsupp.add_comm_group }

end

def to_has_scalar [ring β] : has_scalar β (α →₀ β) := to_has_scalar' β
local attribute [instance] to_has_scalar

@[simp] lemma smul_apply [ring β] {a : α} {b : β} {v : α →₀ β} :
  (b • v) a = b • (v a) := rfl

lemma sum_smul_index [ring β] [add_comm_monoid γ] {g : α →₀ β} {b : β} {h : α → β → γ}
  (h0 : ∀i, h i 0 = 0) : (b • g).sum h = g.sum (λi a, h i (b * a)) :=
finsupp.sum_map_range_index h0

end decidable

section
variables [semiring β] [semiring γ]

lemma sum_mul (b : γ) (s : α →₀ β) {f : α → β → γ} :
  (s.sum f) * b = s.sum (λ a c, (f a (s a)) * b) :=
by simp [finsupp.sum, finset.sum_mul]

lemma mul_sum [semiring β] [semiring γ] (b : γ) (s : α →₀ β) {f : α → β → γ} :
  b * (s.sum f) = s.sum (λ a c, b * (f a (s a))) :=
by simp [finsupp.sum, finset.mul_sum]

end

end finsupp
