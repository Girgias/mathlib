/-
Copyright (c) 2017 Mario Carneiro. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Mario Carneiro, Floris van Doorn
-/
import set_theory.cardinal_ordinal
/-!
# Cofinality

This file contains the definition of cofinality of a ordinal number and regular cardinals

## Main Definitions

* `ordinal.cof o` is the cofinality of the ordinal `o`.
  If `o` is the order type of the relation `<` on `α`, then `o.cof` is the smallest cardinality of a
  subset `s` of α that is *cofinal* in `α`, i.e. `∀ x : α, ∃ y ∈ s, ¬ y < x`.
* `cardinal.is_limit c` means that `c` is a (weak) limit cardinal: `c ≠ 0 ∧ ∀ x < c, succ x < c`.
* `cardinal.is_strong_limit c` means that `c` is a strong limit cardinal:
  `c ≠ 0 ∧ ∀ x < c, 2 ^ x < c`.
* `cardinal.is_regular c` means that `c` is a regular cardinal: `ω ≤ c ∧ c.ord.cof = c`.
* `cardinal.is_inaccessible c` means that `c` is strongly inaccessible:
  `ω < c ∧ is_regular c ∧ is_strong_limit c`.

## Main Statements

* `ordinal.infinite_pigeonhole_card`: the infinite pigeonhole principle
* `cardinal.lt_power_cof`: A consequence of König's theorem stating that `c < c ^ c.ord.cof` for
  `c ≥ ω`
* `cardinal.univ_inaccessible`: The type of ordinals in `Type u` form an inaccessible cardinal
  (in `Type v` with `v > u`). This shows (externally) that in `Type u` there are at least `u`
  inaccessible cardinals.

## Implementation Notes

* The cofinality is defined for ordinals.
  If `c` is a cardinal number, its cofinality is `c.ord.cof`.

## Tags

cofinality, regular cardinals, limits cardinals, inaccessible cardinals,
infinite pigeonhole principle
-/
noncomputable theory

open function cardinal set
open_locale classical cardinal

universes u v w

namespace ordinal

set_option pp.universes true

/-- Cofinality of an ordinal. This is the smallest cardinality of a type `ι` for which some family
  `f : ι → ordinal` has a least strict upper bound equal to the ordinal. It is defined for all
  ordinals, but `cof 0 = 0` and `cof (succ o) = 1`, so it is only really interesting on limit
  ordinals (when it is an infinite cardinal). -/
def cof (o : ordinal.{u}) : cardinal.{u} :=
Inf {a : cardinal | ∃ {ι} (f : ι → ordinal), lsub.{u u} f = o ∧ #ι = a}

private theorem card_mem_cof (o : ordinal) :
  o.card ∈ {a : cardinal.{u} | ∃ {ι} (f : ι → ordinal), lsub.{u u} f = o ∧ #ι = a} :=
⟨_, typein o.out.r, lsub_typein o, mk_ordinal_out o⟩

/-- The set in the definition of `cof` is nonempty. -/
theorem cof_nonempty {o} :
  {a : cardinal | ∃ {ι} (f : ι → ordinal), lsub.{u u} f = o ∧ #ι = a}.nonempty :=
⟨_, card_mem_cof o⟩

theorem cof_le_card (o : ordinal.{u}) : cof o ≤ o.card :=
cInf_le' (card_mem_cof o)

theorem cof_eq (o : ordinal) : ∃ {ι} (f : ι → ordinal), (lsub.{u u} f = o) ∧ #ι = cof o :=
Inf_mem cof_nonempty

theorem cof_le {ι} (f : ι → ordinal) : cof (lsub.{u u} f) ≤ #ι :=
cInf_le' ⟨ι, f, rfl, rfl⟩

theorem le_cof_iff {o : ordinal} {a : cardinal} :
  a ≤ cof o ↔ ∀ {ι} (f : ι → ordinal), lsub.{u u} f = o → a ≤ #ι :=
begin
  apply (le_cInf_iff'' cof_nonempty).trans,
  use λ H ι f hf, H _ ⟨ι, f, hf, rfl⟩,
  rintros H b ⟨ι, f, hf, hb⟩,
  rw ←hb,
  exact H _ hf
end

theorem lift_cof (o) : (cof o).lift = cof o.lift :=
sorry

theorem cof_ord_le (c : cardinal) : cof c.ord ≤ c :=
by simpa using cof_le_card c.ord

@[simp] theorem cof_zero : cof 0 = 0 :=
le_antisymm (by simpa using cof_le_card 0) (cardinal.zero_le _)

@[simp] theorem cof_zero_iff {o} : cof o = 0 ↔ o = 0 :=
begin
  refine ⟨λ h, _, by { rintro rfl, exact cof_zero }⟩,
  rcases cof_eq o with ⟨ι, f, hf, hι⟩,
  rw h at hι,
  rw [←hf, lsub_eq_zero_iff],
  exact mk_eq_zero_iff.1 hι
end

@[simp] theorem cof_succ (o : ordinal.{u}) : cof (succ o) = 1 :=
begin
  apply le_antisymm,
  { change (o + 1).cof ≤ 1,
    rw ←lsub_const.{u u} o,
    exact cof_le (λ _ : punit, o),
    apply_instance },
  { by_contra' h,
    rw [←cardinal.succ_zero, cardinal.lt_succ, cardinal.le_zero, cof_zero_iff] at h,
    have := succ_pos o,
    rw h at this,
    exact this.false }
end

@[simp] theorem cof_eq_one_iff_is_succ {o} : cof.{u} o = 1 ↔ ∃ a, o = succ a :=
begin
  refine ⟨λ h, _, _⟩,
  { rcases cof_eq o with ⟨ι, f, hf, hι⟩,
    rw h at hι,
    haveI : nonempty ι := begin
      rw [←mk_ne_zero_iff, hι], exact zero_ne_one.symm
    end,
    let i := classical.arbitrary ι,
    haveI : subsingleton ι := by rw [←le_one_iff_subsingleton, hι],
    use f i,
    have : f = (λ _, f i) := begin
      funext, rw subsingleton.elim x i,
    end,
    rw [this, lsub_const] at hf,
    exact hf.symm },
  { rintro ⟨a, rfl⟩,
    exact cof_succ a }
end

-- TODO: Put elsewhere.
theorem add_le_of_forall_add_lt {a b c : ordinal} (hb : b ≠ 0) (h : ∀ d < b, a + d < c) :
  a + b ≤ c :=
begin
  have hac : a ≤ c := begin
    rw ←ordinal.pos_iff_ne_zero at hb,
    convert (h _ hb).le,
    rw add_zero,
  end,
  have haca : a + (c - a) = c := by rwa ordinal.add_sub_cancel_of_le,
  rw ←haca,
  refine add_le_add_left _ a,
  by_contra' hb,
  have := h _ hb,
  rwa haca at this,
  exact this.false
end

@[simp] theorem cof_add (a b : ordinal.{u}) (h : b ≠ 0) : cof (a + b) = cof b :=
begin
  apply le_antisymm; apply (le_cof_iff.2 (λ ι f hf, _)),
  { convert cof_le (λ i, a + f i),
    refine le_antisymm
      (add_le_of_forall_add_lt h (λ c hc, _))
      (lsub_le.2 (λ i, add_lt_add_left _ _)),
    { by_contra' H,
      rw lsub_le at H,
      rw ←hf at hc,
      exact (lsub_le.{u u}.2 (λ i, (add_lt_add_iff_left a).1 (H i))).not_lt hc },
    { rw ← hf,
      apply lt_lsub } },
  { apply le_trans _ (mk_subtype_le (λ i, a ≤ f i)),
    convert cof_le (λ i : {i // a ≤ f i}, f ↑i - a),
    refine le_antisymm (le_of_forall_lt (λ c hc, _)) (lsub_le.2 (λ i, _)),
    { by_contra' H,
      suffices : lsub.{u u} f ≤ a + c,
      { rw hf at this,
        exact this.not_lt (add_lt_add_left hc a) },
      rw lsub_le at *,
      intro i,
      cases le_or_lt a (f i) with hi ha,
      { have : f i - a < c := H ⟨i, hi⟩,
        rwa [←add_lt_add_iff_left a, ordinal.add_sub_cancel_of_le hi] at this },
      { exact ha.trans_le (le_add_right a c) } },
    { rw [←add_lt_add_iff_left a, ordinal.add_sub_cancel_of_le i.prop, ←hf],
      apply lt_lsub } }
end

@[simp] theorem cof_cof (o : ordinal) : cof (cof o).ord= cof o :=
le_antisymm (le_trans (cof_le_card _) (by simp)) $
induction_on o $ λ α r _, by exactI
let ⟨S, hS, e₁⟩ := ord_cof_eq r,
    ⟨T, hT, e₂⟩ := cof_eq (subrel r S) in begin
  rw e₁ at e₂, rw ← e₂,
  refine le_trans (cof_type_le {a | ∃ h, (subtype.mk a h : S) ∈ T} (λ a, _)) ⟨⟨_, _⟩⟩,
  { rcases hS a with ⟨b, bS, br⟩,
    rcases hT ⟨b, bS⟩ with ⟨⟨c, cS⟩, cT, cs⟩,
    exact ⟨c, ⟨cS, cT⟩, is_order_connected.neg_trans cs br⟩ },
  { exact λ ⟨a, h⟩, ⟨⟨a, h.fst⟩, h.snd⟩ },
  { exact λ ⟨a, ha⟩ ⟨b, hb⟩ h,
      by injection h with h; congr; injection h },
end

theorem omega_le_cof {o} : ω ≤ cof o ↔ is_limit o :=
begin
  rcases zero_or_succ_or_limit o with rfl|⟨o,rfl⟩|l,
  { simp [not_zero_is_limit, cardinal.omega_ne_zero] },
  { simp [not_succ_is_limit, cardinal.one_lt_omega] },
  { simp [l], refine le_of_not_lt (λ h, _),
    cases cardinal.lt_omega.1 h with n e,
    have := cof_cof o,
    rw [e, ord_nat] at this,
    cases n,
    { simp at e, simpa [e, not_zero_is_limit] using l },
    { rw [← nat_cast_succ, cof_succ] at this,
      rw [← this, cof_eq_one_iff_is_succ] at e,
      rcases e with ⟨a, rfl⟩,
      exact not_succ_is_limit _ l } }
end

@[simp] theorem cof_omega : cof omega = ω :=
le_antisymm
  (by rw ← card_omega; apply cof_le_card)
  (omega_le_cof.2 omega_is_limit)

theorem cof_eq' (r : α → α → Prop) [is_well_order α r] (h : is_limit (type r)) :
  ∃ S : set α, (∀ a, ∃ b ∈ S, r a b) ∧ #S = cof (type r) :=
let ⟨S, H, e⟩ := cof_eq r in
⟨S, λ a,
  let a' := enum r _ (h.2 _ (typein_lt_type r a)) in
  let ⟨b, h, ab⟩ := H a' in
  ⟨b, h, (is_order_connected.conn a b a' $ (typein_lt_typein r).1
    (by rw typein_enum; apply ordinal.lt_succ_self)).resolve_right ab⟩,
e⟩

theorem cof_sup_le_lift {ι} (f : ι → ordinal) (H : ∀ i, f i < sup f) :
  cof (sup f) ≤ (#ι).lift :=
begin
  generalize e : sup f = o,
  refine ordinal.induction_on o _ e, introsI α r _ e',
  rw e' at H,
  refine le_trans (cof_type_le (set.range (λ i, enum r _ (H i))) _)
    ⟨embedding.of_surjective _ _⟩,
  { intro a, by_contra h,
    apply not_le_of_lt (typein_lt_type r a),
    rw [← e', sup_le],
    intro i,
    have h : ∀ (x : ι), r (enum r (f x) _) a, { simpa using h },
    simpa only [typein_enum] using le_of_lt ((typein_lt_typein r).2 (h i)) },
  { exact λ i, ⟨_, set.mem_range_self i.1⟩ },
  { intro a, rcases a with ⟨_, i, rfl⟩, exact ⟨⟨i⟩, by simp⟩ }
end

theorem cof_sup_le {ι} (f : ι → ordinal) (H : ∀ i, f i < sup.{u u} f) :
  cof (sup.{u u} f) ≤ #ι :=
by simpa using cof_sup_le_lift.{u u} f H

theorem cof_bsup_le_lift {o : ordinal} : ∀ (f : Π a < o, ordinal), (∀ i h, f i h < bsup o f) →
  cof (bsup o f) ≤ o.card.lift :=
induction_on o $ λ α r _ f H,
begin
  resetI,
  rw bsup_eq_sup' r rfl,
  refine cof_sup_le_lift _ _,
  rw ← bsup_eq_sup',
  exact λ a, H _ _
end

theorem cof_bsup_le {o : ordinal} : ∀ (f : Π a < o, ordinal), (∀ i h, f i h < bsup.{u u} o f) →
  cof (bsup.{u u} o f) ≤ o.card :=
induction_on o $ λ α r _ f H,
by simpa using cof_bsup_le_lift.{u u} f H

@[simp] theorem cof_univ : cof univ.{u v} = cardinal.univ :=
le_antisymm (cof_le_card _) begin
  refine le_of_forall_lt (λ c h, _),
  rcases lt_univ'.1 h with ⟨c, rfl⟩,
  rcases @cof_eq ordinal.{u} (<) _ with ⟨S, H, Se⟩,
  rw [univ, ← lift_cof, ← cardinal.lift_lift, cardinal.lift_lt, ← Se],
  refine lt_of_not_ge (λ h, _),
  cases cardinal.lift_down h with a e,
  refine quotient.induction_on a (λ α e, _) e,
  cases quotient.exact e with f,
  have f := equiv.ulift.symm.trans f,
  let g := λ a, (f a).1,
  let o := succ (sup.{u u} g),
  rcases H o with ⟨b, h, l⟩,
  refine l (lt_succ.2 _),
  rw ← show g (f.symm ⟨b, h⟩) = b, by dsimp [g]; simp,
  apply le_sup
end

theorem sup_lt_ord {ι} (f : ι → ordinal) {c : ordinal} (H1 : #ι < c.cof)
  (H2 : ∀ i, f i < c) : sup.{u u} f < c :=
begin
  apply lt_of_le_of_ne,
  { rw [sup_le], exact λ i, le_of_lt (H2 i) },
  rintro h, apply not_le_of_lt H1,
  simpa [sup_ord, H2, h] using cof_sup_le.{u} f
end

theorem sup_lt {ι} (f : ι → cardinal) {c : cardinal} (H1 : #ι < c.ord.cof)
  (H2 : ∀ i, f i < c) : cardinal.sup.{u u} f < c :=
by { rw [←ord_lt_ord, ←sup_ord], apply sup_lt_ord _ H1, intro i, rw ord_lt_ord, apply H2 }

/-- If the union of s is unbounded and s is smaller than the cofinality,
  then s has an unbounded member -/
theorem unbounded_of_unbounded_sUnion (r : α → α → Prop) [wo : is_well_order α r] {s : set (set α)}
  (h₁ : unbounded r $ ⋃₀ s) (h₂ : #s < strict_order.cof r) : ∃(x ∈ s), unbounded r x :=
begin
  by_contra h, simp only [not_exists, exists_prop, not_and, not_unbounded_iff] at h,
  apply not_le_of_lt h₂,
  let f : s → α := λ x : s, wo.wf.sup x (h x.1 x.2),
  let t : set α := range f,
  have : #t ≤ #s, exact mk_range_le, refine le_trans _ this,
  have : unbounded r t,
  { intro x, rcases h₁ x with ⟨y, ⟨c, hc, hy⟩, hxy⟩,
    refine ⟨f ⟨c, hc⟩, mem_range_self _, _⟩, intro hxz, apply hxy,
    refine trans (wo.wf.lt_sup _ hy) hxz },
  exact cardinal.min_le _ (subtype.mk t this)
end

/-- If the union of s is unbounded and s is smaller than the cofinality,
  then s has an unbounded member -/
theorem unbounded_of_unbounded_Union {α β : Type u} (r : α → α → Prop) [wo : is_well_order α r]
  (s : β → set α)
  (h₁ : unbounded r $ ⋃x, s x) (h₂ : #β < strict_order.cof r) : ∃x : β, unbounded r (s x) :=
begin
  rw [← sUnion_range] at h₁,
  have : #(range (λ (i : β), s i)) < strict_order.cof r := lt_of_le_of_lt mk_range_le h₂,
  rcases unbounded_of_unbounded_sUnion r h₁ this with ⟨_, ⟨x, rfl⟩, u⟩, exact ⟨x, u⟩
end

/-- The infinite pigeonhole principle -/
theorem infinite_pigeonhole {β α : Type u} (f : β → α) (h₁ : ω ≤ #β)
  (h₂ : #α < (#β).ord.cof) : ∃a : α, #(f ⁻¹' {a}) = #β :=
begin
  have : ¬∀a, #(f ⁻¹' {a}) < #β,
  { intro h,
    apply not_lt_of_ge (ge_of_eq $ mk_univ),
    rw [←@preimage_univ _ _ f, ←Union_of_singleton, preimage_Union],
    apply lt_of_le_of_lt mk_Union_le_sum_mk,
    apply lt_of_le_of_lt (sum_le_sup _),
    apply mul_lt_of_lt h₁ (lt_of_lt_of_le h₂ $ cof_ord_le _),
    exact sup_lt _ h₂ h },
  rw [not_forall] at this, cases this with x h,
  use x, apply le_antisymm _ (le_of_not_gt h),
  rw [le_mk_iff_exists_set], exact ⟨_, rfl⟩
end

/-- pigeonhole principle for a cardinality below the cardinality of the domain -/
theorem infinite_pigeonhole_card {β α : Type u} (f : β → α) (θ : cardinal) (hθ : θ ≤ #β)
  (h₁ : ω ≤ θ) (h₂ : #α < θ.ord.cof) : ∃a : α, θ ≤ #(f ⁻¹' {a}) :=
begin
  rcases le_mk_iff_exists_set.1 hθ with ⟨s, rfl⟩,
  cases infinite_pigeonhole (f ∘ subtype.val : s → α) h₁ h₂ with a ha,
  use a, rw [←ha, @preimage_comp _ _ _ subtype.val f],
  apply mk_preimage_of_injective _ _ subtype.val_injective
end

theorem infinite_pigeonhole_set {β α : Type u} {s : set β} (f : s → α) (θ : cardinal)
  (hθ : θ ≤ #s) (h₁ : ω ≤ θ) (h₂ : #α < θ.ord.cof) :
    ∃(a : α) (t : set β) (h : t ⊆ s), θ ≤ #t ∧ ∀{{x}} (hx : x ∈ t), f ⟨x, h hx⟩ = a :=
begin
  cases infinite_pigeonhole_card f θ hθ h₁ h₂ with a ha,
  refine ⟨a, {x | ∃(h : x ∈ s), f ⟨x, h⟩ = a}, _, _, _⟩,
  { rintro x ⟨hx, hx'⟩, exact hx },
  { refine le_trans ha _, apply ge_of_eq, apply quotient.sound, constructor,
    refine equiv.trans _ (equiv.subtype_subtype_equiv_subtype_exists _ _).symm,
    simp only [set_coe_eq_subtype, mem_singleton_iff, mem_preimage, mem_set_of_eq] },
  rintro x ⟨hx, hx'⟩, exact hx'
end

end ordinal

namespace cardinal
open ordinal

local infixr ^ := @pow cardinal.{u} cardinal cardinal.has_pow

/-- A cardinal is a limit if it is not zero or a successor
  cardinal. Note that `ω` is a limit cardinal by this definition. -/
def is_limit (c : cardinal) : Prop :=
c ≠ 0 ∧ ∀ x < c, succ x < c

/-- A cardinal is a strong limit if it is not zero and it is
  closed under powersets. Note that `ω` is a strong limit by this definition. -/
def is_strong_limit (c : cardinal) : Prop :=
c ≠ 0 ∧ ∀ x < c, 2 ^ x < c

theorem is_strong_limit.is_limit {c} (H : is_strong_limit c) : is_limit c :=
⟨H.1, λ x h, lt_of_le_of_lt (succ_le.2 $ cantor _) (H.2 _ h)⟩

/-- A cardinal is regular if it is infinite and it equals its own cofinality. -/
def is_regular (c : cardinal) : Prop :=
ω ≤ c ∧ c.ord.cof = c

lemma is_regular.pos {c : cardinal} (H : c.is_regular) : 0 < c :=
omega_pos.trans_le H.left

lemma is_regular.ord_pos {c : cardinal} (H : c.is_regular) : 0 < c.ord :=
by { rw cardinal.lt_ord, exact H.pos }

theorem cof_is_regular {o : ordinal} (h : o.is_limit) : is_regular o.cof :=
⟨omega_le_cof.2 h, cof_cof _⟩

theorem omega_is_regular : is_regular ω :=
⟨le_rfl, by simp⟩

theorem succ_is_regular {c : cardinal.{u}} (h : ω ≤ c) : is_regular (succ c) :=
⟨le_trans h (le_of_lt $ lt_succ_self _), begin
  refine le_antisymm (cof_ord_le _) (succ_le.2 _),
  cases quotient.exists_rep (succ c) with α αe, simp at αe,
  rcases ord_eq α with ⟨r, wo, re⟩, resetI,
  have := ord_is_limit (le_trans h $ le_of_lt $ lt_succ_self _),
  rw [← αe, re] at this ⊢,
  rcases cof_eq' r this with ⟨S, H, Se⟩,
  rw [← Se],
  apply lt_imp_lt_of_le_imp_le
    (λ (h : #S ≤ c), mul_le_mul_right' h c),
  rw [mul_eq_self h, ← succ_le, ← αe, ← sum_const'],
  refine le_trans _ (sum_le_sum (λ x:S, card (typein r x)) _ _),
  { simp only [← card_typein, ← mk_sigma],
    refine ⟨embedding.of_surjective _ _⟩,
    { exact λ x, x.2.1 },
    { exact λ a, let ⟨b, h, ab⟩ := H a in ⟨⟨⟨_, h⟩, _, ab⟩, rfl⟩ } },
  { intro i,
    rw [← lt_succ, ← lt_ord, ← αe, re],
    apply typein_lt_type }
end⟩

/--
A function whose codomain's cardinality is infinite but strictly smaller than its domain's
has a fiber with cardinality strictly great than the codomain.
-/
theorem infinite_pigeonhole_card_lt {β α : Type u} (f : β → α)
  (w : #α < #β) (w' : ω ≤ #α) :
  ∃ a : α, #α < #(f ⁻¹' {a}) :=
begin
  simp_rw [← succ_le],
  exact ordinal.infinite_pigeonhole_card f (#α).succ (succ_le.mpr w)
    (w'.trans (lt_succ_self _).le)
    ((lt_succ_self _).trans_le (succ_is_regular w').2.ge),
end

/--
A function whose codomain's cardinality is infinite but strictly smaller than its domain's
has an infinite fiber.
-/
theorem exists_infinite_fiber {β α : Type*} (f : β → α)
  (w : #α < #β) (w' : _root_.infinite α) :
  ∃ a : α, _root_.infinite (f ⁻¹' {a}) :=
begin
  simp_rw [cardinal.infinite_iff] at ⊢ w',
  cases infinite_pigeonhole_card_lt f w w' with a ha,
  exact ⟨a, w'.trans ha.le⟩,
end

/--
If an infinite type `β` can be expressed as a union of finite sets,
then the cardinality of the collection of those finite sets
must be at least the cardinality of `β`.
-/
lemma le_range_of_union_finset_eq_top
  {α β : Type*} [infinite β] (f : α → finset β) (w : (⋃ a, (f a : set β)) = ⊤) :
  #β ≤ #(range f) :=
begin
  have k : _root_.infinite (range f),
  { rw infinite_coe_iff,
    apply mt (union_finset_finite_of_range_finite f),
    rw w,
    exact infinite_univ, },
  by_contradiction h,
  simp only [not_le] at h,
  let u : Π b, ∃ a, b ∈ f a := λ b, by simpa using (w.ge : _) (set.mem_univ b),
  let u' : β → range f := λ b, ⟨f (u b).some, by simp⟩,
  have v' : ∀ a, u' ⁻¹' {⟨f a, by simp⟩} ≤ f a, begin rintros a p m,
    simp at m,
    rw ←m,
    apply (λ b, (u b).some_spec),
  end,
  obtain ⟨⟨-, ⟨a, rfl⟩⟩, p⟩ := exists_infinite_fiber u' h k,
  exact (@infinite.of_injective _ _ p (inclusion (v' a)) (inclusion_injective _)).false,
end

theorem sup_lt_ord_of_is_regular {ι} (f : ι → ordinal)
  {c} (hc : is_regular c) (H1 : #ι < c)
  (H2 : ∀ i, f i < c.ord) : ordinal.sup.{u u} f < c.ord :=
by { apply sup_lt_ord _ _ H2, rw [hc.2], exact H1 }

theorem sup_lt_of_is_regular {ι} (f : ι → cardinal)
  {c} (hc : is_regular c) (H1 : #ι < c)
  (H2 : ∀ i, f i < c) : sup.{u u} f < c :=
by { apply sup_lt _ _ H2, rwa [hc.2] }

theorem sum_lt_of_is_regular {ι} (f : ι → cardinal)
  {c} (hc : is_regular c) (H1 : #ι < c)
  (H2 : ∀ i, f i < c) : sum.{u u} f < c :=
lt_of_le_of_lt (sum_le_sup _) $ mul_lt_of_lt hc.1 H1 $
sup_lt_of_is_regular f hc H1 H2

/-- A cardinal is inaccessible if it is an uncountable regular strong limit cardinal. -/
def is_inaccessible (c : cardinal) :=
ω < c ∧ is_regular c ∧ is_strong_limit c

theorem is_inaccessible.mk {c}
 (h₁ : ω < c) (h₂ : c ≤ c.ord.cof) (h₃ : ∀ x < c, 2 ^ x < c) :
 is_inaccessible c :=
⟨h₁, ⟨le_of_lt h₁, le_antisymm (cof_ord_le _) h₂⟩,
  ne_of_gt (lt_trans omega_pos h₁), h₃⟩

/- Lean's foundations prove the existence of ω many inaccessible cardinals -/
theorem univ_inaccessible : is_inaccessible (univ.{u v}) :=
is_inaccessible.mk
  (by simpa using lift_lt_univ' ω)
  (by simp)
  (λ c h, begin
    rcases lt_univ'.1 h with ⟨c, rfl⟩,
    rw ← lift_two_power.{u (max (u+1) v)},
    apply lift_lt_univ'
  end)

theorem lt_power_cof {c : cardinal.{u}} : ω ≤ c → c < c ^ cof c.ord :=
quotient.induction_on c $ λ α h, begin
  rcases ord_eq α with ⟨r, wo, re⟩, resetI,
  have := ord_is_limit h,
  rw [mk_def, re] at this ⊢,
  rcases cof_eq' r this with ⟨S, H, Se⟩,
  have := sum_lt_prod (λ a:S, #{x // r x a}) (λ _, #α) (λ i, _),
  { simp only [cardinal.prod_const, cardinal.lift_id, ← Se, ← mk_sigma, power_def] at this ⊢,
    refine lt_of_le_of_lt _ this,
    refine ⟨embedding.of_surjective _ _⟩,
    { exact λ x, x.2.1 },
    { exact λ a, let ⟨b, h, ab⟩ := H a in ⟨⟨⟨_, h⟩, _, ab⟩, rfl⟩ } },
  { have := typein_lt_type r i,
    rwa [← re, lt_ord] at this }
end

theorem lt_cof_power {a b : cardinal} (ha : ω ≤ a) (b1 : 1 < b) :
  a < cof (b ^ a).ord :=
begin
  have b0 : b ≠ 0 := ne_of_gt (lt_trans zero_lt_one b1),
  apply lt_imp_lt_of_le_imp_le (power_le_power_left $ power_ne_zero a b0),
  rw [← power_mul, mul_eq_self ha],
  exact lt_power_cof (le_trans ha $ le_of_lt $ cantor' _ b1),
end

end cardinal
