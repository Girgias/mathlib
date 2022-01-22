/-
Copyright (c) 2020 Yury G. Kudryashov. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Yury G. Kudryashov
-/
import analysis.convex.function
import analysis.convex.strict
import measure_theory.function.ae_eq_of_integral

/-!
# Jensen's inequality for integrals

In this file we prove several versions of Jensen's inequality. Here we list key differences between
these lemmas and explain how they affect names of the lemmas.

- We prove inequalities for convex functions (in the namespaces `convex_on` and `strict_convex_on`):
  `g ((μ univ)⁻¹ • ∫ x, f x ∂μ) ≤ (μ univ)⁻¹ • ∫ x, g (f x) ∂μ`, and for convex sets (int the
  namespace `convex`): if `∀ᵐ x ∂μ, f x ∈ s`, then `(μ univ)⁻¹ • ∫ x, f x ∂μ ∈ s`.

- We prove inequalities for average values over the whole space w.r.t. to a finite measure
  (`...smul_integral...`), to a probability measure (`...integral...`), or over a set
  (`...smul_set_integral...`).

- We prove strict inequality (has `lt` in the name, all versions but one are in the
  `strict_convex_on` namespace) and non-strict inequalities.

## Tags

convex, integral, center mass, Jensen's inequality
-/

open measure_theory measure_theory.measure metric set filter topological_space function
open_locale topological_space big_operators ennreal convex

variables {α E F : Type*} {m0 : measurable_space α}
  [normed_group E] [normed_space ℝ E] [complete_space E]
  [topological_space.second_countable_topology E] [measurable_space E] [borel_space E]
  [normed_group F] [normed_space ℝ F] [complete_space F]
  [topological_space.second_countable_topology F] [measurable_space F] [borel_space F]
  {μ : measure α} {s : set E}

namespace measure_theory

variable (μ)
include m0

noncomputable def average (f : α → E) := (μ univ).to_real⁻¹ • ∫ x, f x ∂μ

notation `⨍` binders `, ` r:(scoped:60 f, f) ` ∂` μ:70 := average μ r
notation `⨍` binders `, ` r:(scoped:60 f, average volume f) := r
notation `⨍` binders ` in ` s `, ` r:(scoped:60 f, f) ` ∂` μ:70 := average (measure.restrict μ s) r
notation `⨍` binders ` in ` s `, ` r:(scoped:60 f, average (measure.restrict volume s) f) := r

@[simp] lemma average_zero : ⨍ x, (0 : E) ∂μ = 0 := by rw [average, integral_zero, smul_zero]

@[simp] lemma average_zero_measure (f : α → E) : ⨍ x, f x ∂(0 : measure α) = 0 :=
by rw [average, integral_zero_measure, smul_zero]

lemma average_eq_integral [is_probability_measure μ] (f : α → E) :
  ⨍ x, f x ∂μ = ∫ x, f x ∂μ :=
by rw [average, measure_univ, ennreal.one_to_real, inv_one, one_smul]

@[simp] lemma measure_smul_average [is_finite_measure μ] (f : α → E) :
  (μ univ).to_real • ⨍ x, f x ∂μ = ∫ x, f x ∂μ :=
begin
  cases eq_or_ne μ 0 with hμ hμ,
  { rw [hμ, integral_zero_measure, average_zero_measure, smul_zero] },
  { rw [average, smul_inv_smul₀],
    refine (ennreal.to_real_pos _ $ measure_ne_top _ _).ne',
    rwa [ne.def, measure_univ_eq_zero] }
end

lemma set_average_eq (f : α → E) (s : set α) :
  ⨍ x in s, f x ∂μ = (μ s).to_real⁻¹ • ∫ x in s, f x ∂μ :=
by rw [average, restrict_apply_univ]

variable {μ}

lemma average_congr {f g : α → E} (h : f =ᵐ[μ] g) : ⨍ x, f x ∂μ = ⨍ x, g x ∂μ :=
by simp only [average, integral_congr_ae h]

lemma average_add_measure [is_finite_measure μ] {ν : measure α} [is_finite_measure ν] {f : α → E}
  (hμ : integrable f μ) (hν : integrable f ν) :
  ⨍ x, f x ∂(μ + ν) =
    ((μ univ).to_real / ((μ univ).to_real + (ν univ).to_real)) • ⨍ x, f x ∂μ +
      ((ν univ).to_real / ((μ univ).to_real + (ν univ).to_real)) • ⨍ x, f x ∂ν :=
begin
  simp only [div_eq_inv_mul, mul_smul, measure_smul_average, ← smul_add,
    ← integral_add_measure hμ hν, ← ennreal.to_real_add (measure_ne_top μ _) (measure_ne_top ν _)],
  rw [average, measure.add_apply]
end

lemma average_pair {f : α → E} {g : α → F} (hfi : integrable f μ) (hgi : integrable g μ) :
  ⨍ x, (f x, g x) ∂μ = (⨍ x, f x ∂μ, ⨍ x, g x ∂μ) :=
by simp only [average, integral_pair hfi hgi, prod.smul_mk]

lemma measure_smul_set_average (f : α → E) {s : set α} (h : μ s ≠ ∞) :
  (μ s).to_real • ⨍ x in s, f x ∂μ = ∫ x in s, f x ∂μ :=
by { haveI := fact.mk h.lt_top, rw [← measure_smul_average, restrict_apply_univ] }

lemma average_union {f : α → E} {s t : set α} (hd : ae_disjoint μ s t)
  (ht : null_measurable_set t μ) (hsμ : μ s ≠ ⊤) (htμ : μ t ≠ ⊤)
  (hfs : integrable_on f s μ) (hft : integrable_on f t μ) :
  ⨍ x in s ∪ t, f x ∂μ =
    ((μ s).to_real / ((μ s).to_real + (μ t).to_real)) • ⨍ x in s, f x ∂μ +
      ((μ t).to_real / ((μ s).to_real + (μ t).to_real)) • ⨍ x in t, f x ∂μ :=
begin
  haveI := fact.mk hsμ.lt_top, haveI := fact.mk htμ.lt_top,
  rw [restrict_union₀ hd ht, average_add_measure hfs hft, restrict_apply_univ, restrict_apply_univ]
end

lemma average_union_mem_open_segment {f : α → E} {s t : set α} (hd : ae_disjoint μ s t)
  (ht : null_measurable_set t μ) (hs₀ : μ s ≠ 0) (ht₀ : μ t ≠ 0) (hsμ : μ s ≠ ⊤) (htμ : μ t ≠ ⊤)
  (hfs : integrable_on f s μ) (hft : integrable_on f t μ) :
  ⨍ x in s ∪ t, f x ∂μ ∈ open_segment ℝ (⨍ x in s, f x ∂μ) (⨍ x in t, f x ∂μ) :=
begin
  replace hs₀ : 0 < (μ s).to_real, from ennreal.to_real_pos hs₀ hsμ,
  replace ht₀ : 0 < (μ t).to_real, from ennreal.to_real_pos ht₀ htμ,
  refine mem_open_segment_iff_div.mpr ⟨(μ s).to_real, (μ t).to_real, hs₀, ht₀,
    (average_union hd ht hsμ htμ hfs hft).symm⟩
end

lemma average_union_mem_segment {f : α → E} {s t : set α} (hd : ae_disjoint μ s t)
  (ht : null_measurable_set t μ) (hsμ : μ s ≠ ⊤) (htμ : μ t ≠ ⊤)
  (hfs : integrable_on f s μ) (hft : integrable_on f t μ) :
  ⨍ x in s ∪ t, f x ∂μ ∈ [⨍ x in s, f x ∂μ -[ℝ] ⨍ x in t, f x ∂μ] :=
begin
  by_cases hse : μ s = 0,
  { rw ← ae_eq_empty at hse,
    rw [restrict_congr_set (hse.union eventually_eq.rfl), empty_union],
    exact right_mem_segment _ _ _ },
  { refine mem_segment_iff_div.mpr ⟨(μ s).to_real, (μ t).to_real, ennreal.to_real_nonneg,
      ennreal.to_real_nonneg, _, (average_union hd ht hsμ htμ hfs hft).symm⟩,
    calc 0 < (μ s).to_real : ennreal.to_real_pos hse hsμ
    ... ≤ _ : le_add_of_nonneg_right ennreal.to_real_nonneg }
end

lemma average_mem_open_segment_compl_self [is_finite_measure μ] {f : α → E} {s : set α}
  (hs : null_measurable_set s μ) (hs₀ : μ s ≠ 0) (hsc₀ : μ sᶜ ≠ 0) (hfi : integrable f μ) :
  ⨍ x, f x ∂μ ∈ open_segment ℝ (⨍ x in s, f x ∂μ) (⨍ x in sᶜ, f x ∂μ) :=
by simpa only [union_compl_self, restrict_univ]
  using average_union_mem_open_segment ae_disjoint_compl_right hs.compl hs₀ hsc₀
    (measure_ne_top _ _) (measure_ne_top _ _) hfi.integrable_on hfi.integrable_on

end measure_theory

open measure_theory

/-!
### Non-strict Jensen's inequality
-/

/-- An auxiliary lemma for `convex.smul_integral_mem`. -/
protected lemma convex.average_mem_of_measurable
  [is_finite_measure μ] {s : set E} (hs : convex ℝ s) (hsc : is_closed s)
  (hμ : μ ≠ 0) {f : α → E} (hfs : ∀ᵐ x ∂μ, f x ∈ s) (hfi : integrable f μ) (hfm : measurable f) :
  ⨍ x, f x ∂μ ∈ s :=
begin
  unfreezingI { rcases eq_empty_or_nonempty s with rfl|⟨y₀, h₀⟩ },
  { refine (hμ _).elim, simpa using hfs },
  rw ← hsc.closure_eq at hfs,
  have hc : integrable (λ _, y₀) μ := integrable_const _,
  set F : ℕ → simple_func α E := simple_func.approx_on f hfm s y₀ h₀,
  have : tendsto (λ n, (F n).integral μ) at_top (𝓝 $ ∫ x, f x ∂μ),
  { simp only [simple_func.integral_eq_integral _
      (simple_func.integrable_approx_on hfm hfi h₀ hc _)],
    exact tendsto_integral_of_L1 _ hfi
      (eventually_of_forall $ simple_func.integrable_approx_on hfm hfi h₀ hc)
      (simple_func.tendsto_approx_on_L1_nnnorm hfm h₀ hfs (hfi.sub hc).2) },
  refine hsc.mem_of_tendsto (tendsto_const_nhds.smul this) (eventually_of_forall $ λ n, _),
  have : ∑ y in (F n).range, (μ ((F n) ⁻¹' {y})).to_real = (μ univ).to_real,
    by rw [← (F n).sum_range_measure_preimage_singleton, @ennreal.to_real_sum _ _
      (λ y, μ ((F n) ⁻¹' {y})) (λ _ _, (measure_ne_top _ _))],
  rw [← this, simple_func.integral],
  refine hs.center_mass_mem (λ _ _, ennreal.to_real_nonneg) _ _,
  { rw this,
    exact ennreal.to_real_pos (mt measure.measure_univ_eq_zero.mp hμ) (measure_ne_top _ _) },
  { simp only [simple_func.mem_range],
    rintros _ ⟨x, rfl⟩,
    exact simple_func.approx_on_mem hfm h₀ n x }
end

/-- If `μ` is a non-zero finite measure on `α`, `s` is a convex closed set in `E`, and `f` is an
integrable function sending `μ`-a.e. points to `s`, then the average value of `f` belongs to `s`:
`⨍ x, f x ∂μ ∈ s`. See also `convex.center_mass_mem` for a finite sum version of this lemma. -/
lemma convex.average_mem [is_finite_measure μ] {s : set E} (hs : convex ℝ s) (hsc : is_closed s)
  (hμ : μ ≠ 0) {f : α → E} (hfs : ∀ᵐ x ∂μ, f x ∈ s) (hfi : integrable f μ) :
  ⨍ x, f x ∂μ ∈ s :=
begin
  have : ∀ᵐ (x : α) ∂μ, hfi.ae_measurable.mk f x ∈ s,
  { filter_upwards [hfs, hfi.ae_measurable.ae_eq_mk],
    assume a ha h,
    rwa ← h },
  rw average_congr hfi.ae_measurable.ae_eq_mk,
  exact convex.average_mem_of_measurable hs hsc hμ this
    (hfi.congr hfi.ae_measurable.ae_eq_mk) hfi.ae_measurable.measurable_mk
end

/-- If `μ` is a non-zero finite measure on `α`, `s` is a convex closed set in `E`, and `f` is an
integrable function sending `μ`-a.e. points to `s`, then the average value of `f` belongs to `s`:
`⨍ x, f x ∂μ ∈ s`. See also `convex.center_mass_mem` for a finite sum version of this lemma. -/
lemma convex.set_average_mem {t : set α} {s : set E} (hs : convex ℝ s) (hsc : is_closed s)
  (h0 : μ t ≠ 0) (ht : μ t ≠ ∞) {f : α → E} (hfs : ∀ᵐ x ∂μ.restrict t, f x ∈ s)
  (hfi : integrable_on f t μ) :
  ⨍ x in t, f x ∂μ ∈ s :=
begin
  haveI : fact (μ t < ∞) := ⟨ht.lt_top⟩,
  refine hs.average_mem hsc _ hfs hfi,
  rwa [ne.def, restrict_eq_zero]
end

/-- If `μ` is a probability measure on `α`, `s` is a convex closed set in `E`, and `f` is an
integrable function sending `μ`-a.e. points to `s`, then the expected value of `f` belongs to `s`:
`∫ x, f x ∂μ ∈ s`. See also `convex.sum_mem` for a finite sum version of this lemma. -/
lemma convex.integral_mem [is_probability_measure μ] {s : set E} (hs : convex ℝ s)
  (hsc : is_closed s) {f : α → E} (hf : ∀ᵐ x ∂μ, f x ∈ s) (hfi : integrable f μ) :
  ∫ x, f x ∂μ ∈ s :=
average_eq_integral μ f ▸ hs.average_mem hsc (is_probability_measure.ne_zero _) hf hfi

lemma convex_on.average_mem_epigraph [is_finite_measure μ] {s : set E} {g : E → ℝ}
  (hg : convex_on ℝ s g) (hgc : continuous_on g s) (hsc : is_closed s) (hμ : μ ≠ 0) {f : α → E}
  (hfs : ∀ᵐ x ∂μ, f x ∈ s) (hfi : integrable f μ) (hgi : integrable (g ∘ f) μ) :
  (⨍ x, f x ∂μ, ⨍ x, g (f x) ∂μ) ∈ {p : E × ℝ | p.1 ∈ s ∧ g p.1 ≤ p.2} :=
have ht_mem : ∀ᵐ x ∂μ, (f x, g (f x)) ∈ {p : E × ℝ | p.1 ∈ s ∧ g p.1 ≤ p.2},
  from hfs.mono (λ x hx, ⟨hx, le_rfl⟩),
by simpa only [average_pair hfi hgi]
  using hg.convex_epigraph.average_mem (hsc.epigraph hgc) hμ ht_mem (hfi.prod_mk hgi)

/-- Jensen's inequality: if a function `g : E → ℝ` is convex and continuous on a convex closed set
`s`, `μ` is a finite non-zero measure on `α`, and `f : α → E` is a function sending `μ`-a.e. points
to `s`, then the value of `g` at the average value of `f` is less than or equal to the average value
of `g ∘ f` provided that both `f` and `g ∘ f` are integrable. See also `convex.map_center_mass_le`
for a finite sum version of this lemma. -/
lemma convex_on.map_average_le [is_finite_measure μ] {s : set E} {g : E → ℝ}
  (hg : convex_on ℝ s g) (hgc : continuous_on g s) (hsc : is_closed s) (hμ : μ ≠ 0) {f : α → E}
  (hfs : ∀ᵐ x ∂μ, f x ∈ s) (hfi : integrable f μ) (hgi : integrable (g ∘ f) μ) :
  g (⨍ x, f x ∂μ) ≤ ⨍ x, g (f x) ∂μ :=
(hg.average_mem_epigraph hgc hsc hμ hfs hfi hgi).2

/-- Jensen's inequality: if a function `g : E → ℝ` is convex and continuous on a convex closed set
`s`, `μ` is a finite non-zero measure on `α`, and `f : α → E` is a function sending `μ`-a.e. points
of a set `t` to `s`, then the value of `g` at the average value of `f` over `t` is less than or
equal to the average value of `g ∘ f` over `t` provided that both `f` and `g ∘ f` are
integrable. -/
lemma convex_on.set_average_mem_epigraph {s : set E} {g : E → ℝ} (hg : convex_on ℝ s g)
  (hgc : continuous_on g s) (hsc : is_closed s) {t : set α} (h0 : μ t ≠ 0)
  (ht : μ t ≠ ∞) {f : α → E} (hfs : ∀ᵐ x ∂μ.restrict t, f x ∈ s) (hfi : integrable_on f t μ)
  (hgi : integrable_on (g ∘ f) t μ) :
  (⨍ x in t, f x ∂μ, ⨍ x in t, g (f x) ∂μ) ∈ {p : E × ℝ | p.1 ∈ s ∧ g p.1 ≤ p.2} :=
begin
  haveI : fact (μ t < ∞) := ⟨ht.lt_top⟩,
  refine hg.average_mem_epigraph hgc hsc _ hfs hfi hgi,
  rwa [ne.def, restrict_eq_zero]
end

/-- Jensen's inequality: if a function `g : E → ℝ` is convex and continuous on a convex closed set
`s`, `μ` is a finite non-zero measure on `α`, and `f : α → E` is a function sending `μ`-a.e. points
of a set `t` to `s`, then the value of `g` at the average value of `f` over `t` is less than or
equal to the average value of `g ∘ f` over `t` provided that both `f` and `g ∘ f` are
integrable. -/
lemma convex_on.map_set_average_le {s : set E} {g : E → ℝ} (hg : convex_on ℝ s g)
  (hgc : continuous_on g s) (hsc : is_closed s) {t : set α} (h0 : μ t ≠ 0)
  (ht : μ t ≠ ∞) {f : α → E} (hfs : ∀ᵐ x ∂μ.restrict t, f x ∈ s) (hfi : integrable_on f t μ)
  (hgi : integrable_on (g ∘ f) t μ) :
  g (⨍ x in t, f x ∂μ) ≤ ⨍ x in t, g (f x) ∂μ :=
(hg.set_average_mem_epigraph hgc hsc h0 ht hfs hfi hgi).2

/-- Convex **Jensen's inequality**: if a function `g : E → ℝ` is convex and continuous on a convex
closed set `s`, `μ` is a probability measure on `α`, and `f : α → E` is a function sending `μ`-a.e.
points to `s`, then the value of `g` at the expected value of `f` is less than or equal to the
expected value of `g ∘ f` provided that both `f` and `g ∘ f` are integrable. See also
`convex_on.map_center_mass_le` for a finite sum version of this lemma. -/
lemma convex_on.map_integral_le [is_probability_measure μ] {s : set E} {g : E → ℝ}
  (hg : convex_on ℝ s g) (hgc : continuous_on g s) (hsc : is_closed s) {f : α → E}
  (hfs : ∀ᵐ x ∂μ, f x ∈ s) (hfi : integrable f μ) (hgi : integrable (g ∘ f) μ) :
  g (∫ x, f x ∂μ) ≤ ∫ x, g (f x) ∂μ :=
by simpa only [average_eq_integral]
  using hg.map_average_le hgc hsc (is_probability_measure.ne_zero μ) hfs hfi hgi

lemma measure_theory.integrable.ae_eq_const_or_exists_average_ne_compl [is_finite_measure μ]
  {f : α → E} (hfi : integrable f μ) :
  (f =ᵐ[μ] const α (⨍ x, f x ∂μ)) ∨ ∃ s, measurable_set s ∧ μ s ≠ 0 ∧ μ sᶜ ≠ 0 ∧
    ⨍ x in s, f x ∂μ ≠ ⨍ x in sᶜ, f x ∂μ :=
begin
  refine or_iff_not_imp_right.mpr (λ H, _), push_neg at H,
  refine hfi.ae_eq_of_forall_set_integral_eq _ _ (integrable_const _) (λ s hs hs', _), clear hs',
  simp only [const_apply, set_integral_const],
  by_cases h₀ : μ s = 0,
  { rw [restrict_eq_zero.2 h₀, integral_zero_measure, h₀, ennreal.zero_to_real, zero_smul] },
  by_cases h₀' : μ sᶜ = 0,
  { rw ← ae_eq_univ at h₀',
    rw [restrict_congr_set h₀', restrict_univ, measure_congr h₀', measure_smul_average] },
  have := average_mem_open_segment_compl_self hs.null_measurable_set h₀ h₀' hfi,
  rw [← H s hs h₀ h₀', open_segment_same, mem_singleton_iff] at this,
  rw [this, measure_smul_set_average _ (measure_ne_top μ _)]
end

lemma convex.average_mem_interior_of_set [is_finite_measure μ] {t : set α} {s : set E}
  (hs : convex ℝ s) (hsc : is_closed s) (h0 : μ t ≠ 0) {f : α → E} (hfs : ∀ᵐ x ∂μ, f x ∈ s)
  (hfi : integrable f μ) (ht : ⨍ x in t, f x ∂μ ∈ interior s) :
  ⨍ x, f x ∂μ ∈ interior s :=
begin
  rw ← measure_to_measurable at h0, rw ← restrict_to_measurable (measure_ne_top μ t) at ht,
  by_cases h0' : μ (to_measurable μ t)ᶜ = 0,
  { rw ← ae_eq_univ at h0',
    rwa [restrict_congr_set h0', restrict_univ] at ht },
  exact hs.open_segment_subset_interior ht
    (hs.set_average_mem hsc h0' (measure_ne_top _ _) (ae_restrict_of_ae hfs) hfi.integrable_on)
    (average_mem_open_segment_compl_self (measurable_set_to_measurable μ t).null_measurable_set
      h0 h0' hfi)
end

lemma strict_convex.ae_eq_const_or_average_mem_interior [is_finite_measure μ] {s : set E}
  (hs : strict_convex ℝ s) (hsc : is_closed s) {f : α → E} (hfs : ∀ᵐ x ∂μ, f x ∈ s)
  (hfi : integrable f μ) :
  f =ᵐ[μ] const α (⨍ x, f x ∂μ) ∨ ⨍ x, f x ∂μ ∈ interior s :=
begin
  have : ∀ {t}, μ t ≠ 0 → ⨍ x in t, f x ∂μ ∈ s,
    from λ t ht, hs.convex.set_average_mem hsc ht (measure_ne_top _ _) (ae_restrict_of_ae hfs)
      hfi.integrable_on,
  refine hfi.ae_eq_const_or_exists_average_ne_compl.imp_right _,
  rintro ⟨t, hm, h₀, h₀', hne⟩,
  exact hs.open_segment_subset (this h₀) (this h₀') hne
    (average_mem_open_segment_compl_self hm.null_measurable_set h₀ h₀' hfi)
end

lemma strict_convex_on.ae_eq_const_or_map_average_lt [is_finite_measure μ] {s : set E} {g : E → ℝ}
  (hg : strict_convex_on ℝ s g) (hgc : continuous_on g s) (hsc : is_closed s) {f : α → E}
  (hfs : ∀ᵐ x ∂μ, f x ∈ s) (hfi : integrable f μ) (hgi : integrable (g ∘ f) μ) :
  f =ᵐ[μ] const α (⨍ x, f x ∂μ) ∨ g (⨍ x, f x ∂μ) < ⨍ x, g (f x) ∂μ :=
begin
  have : ∀ {t}, μ t ≠ 0 → ⨍ x in t, f x ∂μ ∈ s ∧ g (⨍ x in t, f x ∂μ) ≤ ⨍ x in t, g (f x) ∂μ,
    from λ t ht, hg.convex_on.set_average_mem_epigraph hgc hsc ht (measure_ne_top _ _)
      (ae_restrict_of_ae hfs) hfi.integrable_on hgi.integrable_on,
  refine hfi.ae_eq_const_or_exists_average_ne_compl.imp_right _,
  rintro ⟨t, hm, h₀, h₀', hne⟩,
  rcases average_mem_open_segment_compl_self hm.null_measurable_set h₀ h₀' (hfi.prod_mk hgi)
    with ⟨a, b, ha, hb, hab, h_avg⟩,
  simp only [average_pair hfi hgi, average_pair hfi.integrable_on hgi.integrable_on, prod.smul_mk,
    prod.mk_add_mk, prod.mk.inj_iff, (∘)] at h_avg,
  rw [← h_avg.1, ← h_avg.2],
  calc g (a • ⨍ x in t, f x ∂μ + b • ⨍ x in tᶜ, f x ∂μ)
      < a * g (⨍ x in t, f x ∂μ) + b * g (⨍ x in tᶜ, f x ∂μ) :
    hg.2 (this h₀).1 (this h₀').1 hne ha hb hab
  ... ≤ a * ⨍ x in t, g (f x) ∂μ + b * ⨍ x in tᶜ, g (f x) ∂μ :
    add_le_add (mul_le_mul_of_nonneg_left (this h₀).2 ha.le)
      (mul_le_mul_of_nonneg_left (this h₀').2 hb.le)
end

/-- If the norm of a function `f : α → E` taking values in a strictly convex normed space is
a.e. less than or equal to `C`, then either this function is a constant, or the norm of its integral
is strictly less than `μ univ * C`. -/
lemma strict_convex.ae_eq_const_or_norm_integral_lt_of_norm_le_const [is_finite_measure μ]
  {f : α → E} {C : ℝ} (h_convex : strict_convex ℝ (closed_ball (0 : E) C))
  (h_le : ∀ᵐ x ∂μ, ∥f x∥ ≤ C) :
  (f =ᵐ[μ] const α ⨍ x, f x ∂μ) ∨ ∥∫ x, f x ∂μ∥ < (μ univ).to_real * C :=
begin
  cases le_or_lt C 0 with hC0 hC0,
  { have : f =ᵐ[μ] 0, from h_le.mono (λ x hx, norm_le_zero_iff.1 (hx.trans hC0)),
    simp only [average_congr this, pi.zero_apply, average_zero],
    exact or.inl this },
  cases eq_or_ne μ 0 with hμ hμ,
  { rw hμ, exact or.inl rfl },
  by_cases hfi : integrable f μ, swap,
  { right,
    simpa [integral_undef hfi, hC0, measure_lt_top, ennreal.to_real_pos_iff, pos_iff_ne_zero]
      using hμ },
  replace h_le : ∀ᵐ x ∂μ, f x ∈ closed_ball (0 : E) C, by simpa only [mem_closed_ball_zero_iff],
  have hμ' : 0 < (μ univ).to_real,
    from ennreal.to_real_pos (mt measure_univ_eq_zero.1 hμ) (measure_ne_top _ _),
  simpa only [interior_closed_ball _ hC0, mem_ball_zero_iff, average, norm_smul,
    real.norm_eq_abs, abs_inv, abs_of_pos hμ', ← div_eq_inv_mul, div_lt_iff' hμ']
    using h_convex.ae_eq_const_or_average_mem_interior is_closed_ball h_le hfi,
end
