/-
Copyright (c) 2022 Sébastien Gouëzel. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Sébastien Gouëzel, Violeta Hernández Palacios
-/
import measure_theory.measurable_space_def
import set_theory.continuum
import set_theory.cofinality

/-!
# Cardinal of sigma-algebras

If a sigma-algebra is generated by a set of sets `s`, then the cardinality of the sigma-algebra is
bounded by `(max (#s) 2) ^ ω`. This is stated in `measurable_space.cardinal_generate_measurable_le`
and `measurable_space.cardinal_measurable_set_le`.

In particular, if `#s ≤ 𝔠`, then the generated sigma-algebra has cardinality at most `𝔠`, see
`measurable_space.cardinal_measurable_set_le_continuum`.

For the proof, we rely on an explicit inductive construction of the sigma-algebra generated by
`s` (instead of the inductive predicate `generate_measurable`). This transfinite inductive
construction is parameterized by an ordinal `< ω₁`, and the cardinality bound is preserved along
each step of the construction. We show in `measurable_space.generate_measurable_eq_rec` that this
indeed generates this sigma-algebra.
-/

universe u
variables {α : Type u}

open_locale cardinal
open cardinal set

local notation `ω₁`:= (aleph 1 : cardinal.{u}).ord.out.α

namespace measurable_space

/-- Transfinite induction construction of the sigma-algebra generated by a set of sets `s`. At each
step, we add all elements of `s`, the empty set, the complements of already constructed sets, and
countable unions of already constructed sets. We index this construction by an ordinal `< ω₁`, as
this will be enough to generate all sets in the sigma-algebra.

This construction is very similar to that of the Borel hierarchy. -/
def generate_measurable_rec (s : set (set α)) : ω₁ → set (set α)
| i := let S := ⋃ j : {j // j <₁ i}, generate_measurable_rec j.1 in
    s ∪ {∅} ∪ compl '' S ∪ set.range (λ (f : ℕ → S), ⋃ n, (f n).1)
using_well_founded {dec_tac := `[exact j.2]}

theorem self_subset_generate_measurable_rec (s : set (set α)) (i : ω₁) :
  s ⊆ generate_measurable_rec s i :=
begin
  unfold generate_measurable_rec,
  apply_rules [subset_union_of_subset_left],
  exact subset_rfl
end

theorem empty_mem_generate_measurable_rec (s : set (set α)) (i : ω₁) :
  ∅ ∈ generate_measurable_rec s i :=
begin
  unfold generate_measurable_rec,
  exact mem_union_left _ (mem_union_left _ (mem_union_right _ (mem_singleton ∅)))
end

theorem compl_mem_generate_measurable_rec {s : set (set α)} {i j : ω₁} (h : j <₁ i) {t : set α}
  (ht : t ∈ generate_measurable_rec s j) : tᶜ ∈ generate_measurable_rec s i :=
begin
  unfold generate_measurable_rec,
  exact mem_union_left _ (mem_union_right _ ⟨t, mem_Union.2 ⟨⟨j, h⟩, ht⟩, rfl⟩)
end

theorem Union_mem_generate_measurable_rec {s : set (set α)} {i : ω₁}
  {f : ℕ → set α} (hf : ∀ n, ∃ j <₁ i, f n ∈ generate_measurable_rec s j) :
  (⋃ n, f n) ∈ generate_measurable_rec s i :=
begin
  unfold generate_measurable_rec,
  exact mem_union_right _ ⟨λ n, ⟨f n, let ⟨j, hj, hf⟩ := hf n in mem_Union.2 ⟨⟨j, hj⟩, hf⟩⟩, rfl⟩
end

theorem generate_measurable_rec.cases_on {s : set (set α)} {i : ω₁} {t : set α}
  (ht : t ∈ generate_measurable_rec s i) :
  t ∈ s ∨ t = ∅ ∨ (∃ j <₁ i, tᶜ ∈ generate_measurable_rec s j) ∨
  ∃ (f : ℕ → set α), (∀ n, ∃ j <₁ i, f n ∈ generate_measurable_rec s j) ∧ t = ⋃ n, f n :=
begin
  unfold generate_measurable_rec at ht,
  rcases ht with (((h | h) | ⟨t, ⟨_, ⟨j, rfl⟩, ht⟩, rfl⟩) | ⟨f, hf⟩),
  { exact or.inl h },
  { exact or.inr (or.inl h) },
  { rw compl_compl,
    exact or.inr (or.inr (or.inl ⟨j, j.prop, ht⟩)) },
  { apply_rules [or.inr],
    refine ⟨λ n, (f n).1, λ n, _, hf.symm⟩,
    rcases (f n).2 with ⟨t, ⟨j, rfl⟩, ht⟩,
    exact ⟨j, j.2, ht⟩ }
end

theorem generate_measurable_rec_subset (s : set (set α)) {i j : ω₁} (h : i <₁ j) :
  generate_measurable_rec s i ⊆ generate_measurable_rec s j :=
λ x hx, begin
  convert Union_mem_generate_measurable_rec (λ n, ⟨i, h, hx⟩),
  exact (Union_const x).symm
end

/-- At each step of the inductive construction, the cardinality bound `≤ (max (#s) 2) ^ ω` holds. -/
lemma cardinal_generate_measurable_rec_le (s : set (set α)) (i : ω₁) :
  #(generate_measurable_rec s i) ≤ (max (#s) 2) ^ omega.{u} :=
begin
  apply (aleph 1).ord.out.wo.wf.induction i,
  assume i IH,
  have A := omega_le_aleph 1,
  have B : aleph 1 ≤ (max (#s) 2) ^ omega.{u} :=
    aleph_one_le_continuum.trans (power_le_power_right (le_max_right _ _)),
  have C : omega.{u} ≤ (max (#s) 2) ^ omega.{u} := A.trans B,
  have J : #(⋃ (j : {j // j < i}), generate_measurable_rec s j.1) ≤ (max (#s) 2) ^ omega.{u},
  { apply (mk_Union_le _).trans,
    have D : cardinal.sup.{u u} (λ (j : {j // j <₁ i}), #(generate_measurable_rec s j.1)) ≤ _ :=
      cardinal.sup_le.2 (λ ⟨j, hj⟩, IH j hj),
    apply (mul_le_mul' ((mk_subtype_le _).trans (aleph 1).mk_ord_out.le) D).trans,
    rw mul_eq_max A C,
    exact max_le B le_rfl },
  rw [generate_measurable_rec],
  apply_rules [(mk_union_le _ _).trans, add_le_of_le C, mk_image_le.trans],
  { exact (le_max_left _ _).trans (self_le_power _ one_lt_omega.le) },
  { rw [mk_singleton],
    exact one_lt_omega.le.trans C },
  { apply mk_range_le.trans,
    simp only [mk_pi, subtype.val_eq_coe, prod_const, lift_uzero, mk_denumerable, lift_omega],
    have := @power_le_power_right _ _ omega.{u} J,
    rwa [← power_mul, omega_mul_omega] at this }
end

/-- `generate_measurable_rec s` generates precisely the smallest sigma-algebra containing `s`. -/
theorem generate_measurable_eq_rec (s : set (set α)) :
  {t | generate_measurable s t} = ⋃ i, generate_measurable_rec s i :=
begin
  ext t, refine ⟨λ ht, _, λ ht, _⟩,
  { haveI : nonempty ω₁, by simp [← mk_ne_zero_iff, ne_of_gt, (aleph 1).mk_ord_out, aleph_pos 1],
    inhabit ω₁,
    induction ht with u hu u hu IH f hf IH,
    { exact mem_Union.2 ⟨default, self_subset_generate_measurable_rec s _ hu⟩ },
    { exact mem_Union.2 ⟨default, empty_mem_generate_measurable_rec s _⟩ },
    { rcases mem_Union.1 IH with ⟨i, hi⟩,
      obtain ⟨j, hj⟩ : ∃ j, i <₁ j := ordinal.has_succ_of_is_limit
        (by { rw ordinal.type_out, exact ord_aleph_is_limit 1 }) _,
      exact mem_Union.2 ⟨j, compl_mem_generate_measurable_rec hj hi⟩ },
    { have : ∀ n, ∃ i, f n ∈ generate_measurable_rec s i := λ n, by simpa using IH n,
      choose I hI using this,
      refine mem_Union.2 ⟨ordinal.enum (<₁) (ordinal.lsub (λ n, ordinal.typein.{u} (<₁) (I n))) _,
        Union_mem_generate_measurable_rec (λ n, ⟨I n, _, hI n⟩)⟩,
      { rw ordinal.type_out,
        refine ordinal.lsub_lt_ord_lift _ (λ i, ordinal.typein_lt_self _),
        rw [mk_denumerable, lift_omega, is_regular_aleph_one.2],
        exact omega_lt_aleph_one },
      { rw [←ordinal.typein_lt_typein (<₁), ordinal.typein_enum],
        apply ordinal.lt_lsub (λ n : ℕ, _) } } },
  { rcases ht with ⟨t, ⟨i, rfl⟩, hx⟩,
    revert t,
    apply (aleph 1).ord.out.wo.wf.induction i,
    intros j H t ht,
    rcases generate_measurable_rec.cases_on ht with (h | rfl | ⟨k, hk, ht'⟩ | ⟨f, hf, rfl⟩),
    { exact generate_measurable.basic t h },
    { exact generate_measurable.empty },
    { rw ←compl_compl t,
      exact generate_measurable.compl _ (H _ hk _ ht') },
    { exact generate_measurable.union _ (λ n, let ⟨k, hk, hf'⟩ := hf n in H _ hk _ hf') } }
end

/-- If a sigma-algebra is generated by a set of sets `s`, then the sigma-algebra has cardinality at
most `(max (#s) 2) ^ ω`. -/
theorem cardinal_generate_measurable_le (s : set (set α)) :
  #{t | generate_measurable s t} ≤ (max (#s) 2) ^ omega.{u} :=
begin
  rw generate_measurable_eq_rec,
  apply (mk_Union_le _).trans,
  rw (aleph 1).mk_ord_out,
  refine le_trans (mul_le_mul' aleph_one_le_continuum
    (cardinal.sup_le.2 (λ i, cardinal_generate_measurable_rec_le s i))) _,
  have := power_le_power_right (le_max_right (#s) 2),
  rw mul_eq_max omega_le_continuum (omega_le_continuum.trans this),
  exact max_le this le_rfl
end

/-- If a sigma-algebra is generated by a set of sets `s`, then the sigma-algebra has cardinality at
most `(max (#s) 2) ^ ω`. -/
theorem cardinal_measurable_set_le :
  ∀ s, #{t | @measurable_set α (generate_from s) t} ≤ (max (#s) 2) ^ omega.{u} :=
cardinal_generate_measurable_le

/-- If a sigma-algebra is generated by a set of sets `s` with cardinality at most the continuum,
then the sigma algebra has the same cardinality bound. -/
theorem cardinal_generate_measurable_le_continuum {s : set (set α)} (hs : #s ≤ 𝔠) :
  #{t | generate_measurable s t} ≤ 𝔠 :=
(cardinal_generate_measurable_le s).trans begin
  rw ←continuum_power_omega,
  exact_mod_cast power_le_power_right (max_le hs (nat_lt_continuum 2).le)
end

/-- If a sigma-algebra is generated by a set of sets `s` with cardinality at most the continuum,
then the sigma algebra has the same cardinality bound. -/
theorem cardinal_measurable_set_le_continuum {s : set (set α)} :
  #s ≤ 𝔠 → #{t | @measurable_set α (generate_from s) t} ≤ 𝔠 :=
cardinal_generate_measurable_le_continuum

end measurable_space
