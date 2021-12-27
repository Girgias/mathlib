/-
Copyright (c) 2021 Kalle Kytölä. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Kalle Kytölä
-/
import topology.algebra.weak_dual_topology
import analysis.normed_space.dual
import analysis.normed_space.operator_norm

/-!
# Weak dual of normed space

Let `E` be a normed space over a field `𝕜`. This file is concerned with properties of the weak-*
topology on the dual of `E`. By the dual, we mean either of the type synonyms
`normed_space.dual 𝕜 E` or `weak_dual 𝕜 E`, depending on whether it is viewed as equipped with its
usual operator norm topology or the weak-* topology.

It is shown that the canonical mapping `normed_space.dual 𝕜 E → weak_dual 𝕜 E` is continuous, and
as a consequence the weak-* topology is coarser than the topology obtained from the operator norm
(dual norm).

In this file, we also establish the Banach-Alaoglu theorem about the compactness of closed balls
in the dual of `E` (as well as sets of somewhat more general form) with respect to the weak-*
topology.

## Main definitions

The main definitions concern the canonical mapping `dual 𝕜 E → weak_dual 𝕜 E`.

* `normed_space.dual.to_weak_dual` and `weak_dual.to_normed_dual`: Linear equivalences from
  `dual 𝕜 E` to `weak_dual 𝕜 E` and in the converse direction.
* `normed_space.dual.continuous_linear_map_to_weak_dual`: A continuous linear mapping from
  `dual 𝕜 E` to `weak_dual 𝕜 E` (same as `normed_space.dual.to_weak_dual` but different bundled
  data).

## Main results

The first main result concerns the comparison of the operator norm topology on `dual 𝕜 E` and the
weak-* topology on (its type synonym) `weak_dual 𝕜 E`:
* `dual_norm_topology_le_weak_dual_topology`: The weak-* topology on the dual of a normed space is
  coarser (not necessarily strictly) than the operator norm topology.
* `weak_dual.is_compact_polar` (a version of the Banach-Alaoglu theorem): The polar set of a
  neighborhood of the origin in a normed space `E` over `𝕜` is compact in `weak_dual _ E`, if the
  nondiscrete normed field `𝕜` is proper as a topological space.
* `weak_dual.is_compact_closed_ball` (the most common special case of the Banach-Alaoglu theorem):
  Closed balls in the dual of a normed space `E` over `ℝ` or `ℂ` are compact in the weak-star
  topology.

TODOs:
* Add that in finite dimensions, the weak-* topology and the dual norm topology coincide.
* Add that in infinite dimensions, the weak-* topology is strictly coarser than the dual norm
  topology.
* Add metrizability of the dual unit ball (more generally weak-star compact subsets) of
  `weak_dual 𝕜 E` under the assumption of separability of `E`.
* Add the sequential Banach-Alaoglu theorem: the dual unit ball of a separable normed space `E`
  is sequentially compact in the weak-star topology. (Would follow from the metrizability above.)

## Notations

No new notation is introduced.

## Implementation notes

Weak-* topology is defined generally in the file `topology.algebra.weak_dual_topology`.

When `E` is a normed space, the duals `dual 𝕜 E` and `weak_dual 𝕜 E` are type synonyms with
different topology instances.

For the proof of Banach-Alaoglu theorem, the weak dual of `E` is embedded in the space of
functions `E → 𝕜` with the topology of pointwise convergence. The fact that this is an embedding
is `weak_dual.to_Pi_embedding`.

The polar set `polar 𝕜 s` of a subset `s` of `E` is originally defined as a subset of the dual
`dual 𝕜 E`. We care about properties of these w.r.t. weak-* topology, and for this purpose give
the definition `weak_dual.polar 𝕜 s` for the "same" subset viewed as a subset of `weak_dual 𝕜 E`
(a type synonym of the dual but with a different topology instance).

## References

* https://en.wikipedia.org/wiki/Weak_topology#Weak-*_topology
* https://en.wikipedia.org/wiki/Banach%E2%80%93Alaoglu_theorem

## Tags

weak-star, weak dual

-/

noncomputable theory
open filter
open_locale topological_space

section weak_star_topology_for_duals_of_normed_spaces
/-!
### Weak star topology on duals of normed spaces
In this section, we prove properties about the weak-* topology on duals of normed spaces.
We prove in particular that the canonical mapping `dual 𝕜 E → weak_dual 𝕜 E` is continuous,
i.e., that the weak-* topology is coarser (not necessarily strictly) than the topology given
by the dual-norm (i.e. the operator-norm).
-/

open normed_space

variables {𝕜 : Type*} [nondiscrete_normed_field 𝕜]
variables {E : Type*} [normed_group E] [normed_space 𝕜 E]

/-- For normed spaces `E`, there is a canonical map `dual 𝕜 E → weak_dual 𝕜 E` (the "identity"
mapping). It is a linear equivalence. -/
def normed_space.dual.to_weak_dual : dual 𝕜 E ≃ₗ[𝕜] weak_dual 𝕜 E :=
linear_equiv.refl 𝕜 (E →L[𝕜] 𝕜)

/-- For normed spaces `E`, there is a canonical map `weak_dual 𝕜 E → dual 𝕜 E` (the "identity"
mapping). It is a linear equivalence. Here it is implemented as the inverse of the linear
equivalence `normed_space.dual.to_weak_dual` in the other direction. -/
def weak_dual.to_normed_dual : weak_dual 𝕜 E ≃ₗ[𝕜] dual 𝕜 E :=
normed_space.dual.to_weak_dual.symm

@[simp] lemma weak_dual.coe_to_fun_eq_normed_coe_to_fun (x' : dual 𝕜 E) :
  (x'.to_weak_dual : E → 𝕜) = x' := rfl

namespace normed_space.dual

@[simp] lemma to_weak_dual_eq_iff (x' y' : dual 𝕜 E) :
  x'.to_weak_dual = y'.to_weak_dual ↔ x' = y' :=
to_weak_dual.injective.eq_iff

@[simp] lemma _root_.weak_dual.to_normed_dual_eq_iff (x' y' : weak_dual 𝕜 E) :
  x'.to_normed_dual = y'.to_normed_dual ↔ x' = y' :=
weak_dual.to_normed_dual.injective.eq_iff

theorem to_weak_dual_continuous :
  continuous (λ (x' : dual 𝕜 E), x'.to_weak_dual) :=
begin
  apply weak_dual.continuous_of_continuous_eval,
  intros z,
  exact (inclusion_in_double_dual 𝕜 E z).continuous,
end

/-- For a normed space `E`, according to `to_weak_dual_continuous` the "identity mapping"
`dual 𝕜 E → weak_dual 𝕜 E` is continuous. This definition implements it as a continuous linear
map. -/
def continuous_linear_map_to_weak_dual : dual 𝕜 E →L[𝕜] weak_dual 𝕜 E :=
{ cont := to_weak_dual_continuous, .. to_weak_dual, }

/-- The weak-star topology is coarser than the dual-norm topology. -/
theorem dual_norm_topology_le_weak_dual_topology :
  (by apply_instance : topological_space (dual 𝕜 E)) ≤
    (by apply_instance : topological_space (weak_dual 𝕜 E)) :=
begin
  refine continuous.le_induced _,
  apply continuous_pi_iff.mpr,
  intros z,
  exact (inclusion_in_double_dual 𝕜 E z).continuous,
end

end normed_space.dual

namespace weak_dual

variables (𝕜)

/-- The polar set `polar 𝕜 s` of `s : set E` seen as a subset of the dual of `E` with the
weak-star topology is `weak_dual.polar 𝕜 s`. -/
def polar (s : set E) : set (weak_dual 𝕜 E) := to_normed_dual ⁻¹' (polar 𝕜 s)

end weak_dual

end weak_star_topology_for_duals_of_normed_spaces

section polar_sets_in_weak_dual

open metric set normed_space

variables {𝕜 : Type*} [nondiscrete_normed_field 𝕜]
variables {E : Type*} [normed_group E] [normed_space 𝕜 E]

/-- The polar `polar 𝕜 s` of a set `s : E` is a closed subset when the weak star topology
is used, i.e., when `polar 𝕜 s` is interpreted as a subset of `weak_dual 𝕜 E`. -/
lemma weak_dual.is_closed_polar (s : set E) : is_closed (weak_dual.polar 𝕜 s) :=
begin
  rw [weak_dual.polar, polar_eq_Inter, preimage_bInter],
  apply is_closed_bInter,
  intros z hz,
  rw set.preimage_set_of_eq,
  have eq : {x' : weak_dual 𝕜 E | ∥weak_dual.to_normed_dual x' z∥ ≤ 1}
    = (λ (x' : weak_dual 𝕜 E), ∥x' z∥)⁻¹' (Iic 1) := by refl,
  rw eq,
  refine is_closed.preimage _ (is_closed_Iic),
  apply continuous.comp continuous_norm (weak_dual.eval_continuous _ _ z),
end

end polar_sets_in_weak_dual

section embedding_to_Pi

variables {𝕜 : Type*} [nondiscrete_normed_field 𝕜]
variables {E : Type*} [normed_group E] [normed_space 𝕜 E]

open metric set normed_space

/-- The (weak) dual `weak_dual 𝕜 E` of a normed space `E` consists of bounded linear
functionals `E → 𝕜`. Such functionals can be interpreted as elements of the Cartesian
product `E → 𝕜` via the function `weak_dual.to_Pi : weak_dual 𝕜 E → (E → 𝕜)`. -/
def _root_.weak_dual.to_Pi (𝕜 : Type*) [nondiscrete_normed_field 𝕜]
  (E : Type*) [topological_space E] [add_comm_group E] [module 𝕜 E] (x' : weak_dual 𝕜 E) :=
x'.to_fun

lemma _root_.weak_dual.to_Pi_def (𝕜 : Type*) [nondiscrete_normed_field 𝕜]
  (E : Type*) [topological_space E] [add_comm_group E] [module 𝕜 E] :
  weak_dual.to_Pi 𝕜 E = λ x', x'.to_fun :=
rfl

/-- The function `weak_dual.to_Pi : weak_dual 𝕜 E → (E → 𝕜)` is an embedding. -/
lemma weak_dual.to_Pi_embedding (𝕜 : Type*) [nondiscrete_normed_field 𝕜]
  (E : Type*) [topological_space E] [add_comm_group E] [module 𝕜 E] :
  embedding (weak_dual.to_Pi 𝕜 E) :=
{ induced := rfl,
  inj := continuous_linear_map.coe_fn_injective, }

namespace weak_dual.to_Pi_embedding

-- The following lemmas prove the desired `linear_map.is_closed_range_coe`,
-- which was proposed in the PR review.
--
-- I think it is natural to reduce the proof of this desired result to
-- `linear_map.mem_range_to_fun_eq_Inter` using `is_closed_Inter`.
-- However, to prove `linear_map.mem_range_to_fun_eq_Inter` I had to resort to a
-- bit lengthy (but in my opinion still natural and perhaps worthwhile) approach, via
-- `linear_map.mem_range_to_fun_iff` and `linear_map_of_forall_apply_linear_combination_eq`.
-- Or is there a better way?
--
-- In any case, these lemmas or their improved versions should be placed in some
-- appropriate files.

/-- Construct a linear map from a map satisfying the hypothesis of
respecting linear combinations. -/
def _root_.linear_map_of_forall_apply_linear_combination_eq
  {R S : Type*} [semiring R] [semiring S] {σ : R →+* S} {M₁ M₂ : Type*}
  [add_comm_monoid M₁] [add_comm_monoid M₂] [module R M₁] [module S M₂] {f : M₁ → M₂}
  (hf : ∀ (u v : M₁) (a b : R), f (a • u + b • v) = (σ a) • (f u) + (σ b) • (f v)) :
  M₁ →ₛₗ[σ] M₂ :=
{ to_fun := f,
  map_add' := begin
    intros u v,
    have key := hf u v 1 1,
    rwa [map_one σ, one_smul, one_smul, one_smul, one_smul] at key,
  end,
  map_smul' := begin
    intros a u,
    have key := hf u 0 a 0,
    rwa [map_zero σ, zero_smul, zero_smul, add_zero, add_zero] at key,
  end, }

lemma _root_.linear_map.mem_range_to_fun_iff
  {R S : Type*} [semiring R] [semiring S] {σ : R →+* S} {M₁ M₂ : Type*}
  [add_comm_monoid M₁] [add_comm_monoid M₂] [module R M₁] [module S M₂] (f : M₁ → M₂) :
  f ∈ range (λ (ψ : M₁ →ₛₗ[σ] M₂), ψ.to_fun) ↔
  ∀ (u v : M₁) (a b : R), f (a • u + b • v) = (σ a) • (f u) + (σ b) • (f v) :=
begin
  split,
  { intros hf u v a b,
    cases mem_range.mp hf with φ hφf,
    rw [← hφf, linear_map.to_fun_eq_coe],
    simp only [map_add, linear_map.map_smulₛₗ], },
  { intros hf,
    use linear_map_of_forall_apply_linear_combination_eq hf,
    refl, },
end

lemma _root_.linear_map.mem_range_to_fun_eq_Inter
  {R S : Type*} [semiring R] [semiring S] {σ : R →+* S} {M₁ M₂ : Type*}
  [add_comm_monoid M₁] [add_comm_monoid M₂] [module R M₁] [module S M₂] :
  range (λ (ψ : M₁ →ₛₗ[σ] M₂), ψ.to_fun) =
    ⋂ (u v : M₁) (a b : R), { f : M₁ → M₂ | f (a • u + b • v) = (σ a) • (f u) + (σ b) • (f v) } :=
begin
  ext f,
  rw linear_map.mem_range_to_fun_iff,
  simp only [mem_Inter, mem_set_of_eq],
end

lemma _root_.linear_map.is_closed_range_coe {M₁ M₂ R S : Type*}
  [topological_space M₂] [t2_space M₂] [semiring R] [semiring S]
  [add_comm_monoid M₁] [add_comm_monoid M₂] [module R M₁] [module S M₂]
  [topological_space S] [has_continuous_smul S M₂] [has_continuous_add M₂] {σ : R →+* S} :
  is_closed (range (λ (ψ : M₁ →ₛₗ[σ] M₂), ψ.to_fun)) :=
begin
  rw linear_map.mem_range_to_fun_eq_Inter,
  apply is_closed_Inter, intros u,
  apply is_closed_Inter, intros v,
  apply is_closed_Inter, intros a,
  apply is_closed_Inter, intros b,
  have cont₂ : continuous (λ (g : M₁ → M₂), (σ a) • g u + (σ b) • g v),
  { have cnt_add : continuous (λ (μ : M₂ × M₂), μ.fst + μ.snd) := continuous_add,
    have cnt₁ : continuous (λ (g : M₁ → M₂), (σ a) • g u),
    from continuous.comp (continuous_uncurry_left (σ a) continuous_smul) (continuous_apply u),
    have cnt₂ : continuous (λ (g : M₁ → M₂), (σ b) • g v),
    from continuous.comp (continuous_uncurry_left (σ b) continuous_smul) (continuous_apply v),
    exact continuous.add cnt₁ cnt₂, },
  exact is_closed_eq (continuous_apply (a • u + b • v)) cont₂,
end

lemma _root_.continuous_linear_map.range_coe_subset_linear_map_range_coe {M₁ M₂ R S : Type*}
  [topological_space M₂] [topological_space M₁] [semiring R] [semiring S]
  [add_comm_monoid M₁] [add_comm_monoid M₂] [module R M₁] [module S M₂] {σ : R →+* S} :
  (range (λ (ψ : M₁ →SL[σ] M₂), ψ.to_fun)) ⊆ (range (λ (ψ : M₁ →ₛₗ[σ] M₂), ψ.to_fun)) :=
begin
  intros f hf,
  cases mem_range.mp hf with φ hφf,
  use [φ, hφf],
end

/-- Elements of the closure of the range of the embedding
`weak_dual.to_Pi : weak_dual 𝕜 E → (E → 𝕜)` are linear. Here it is stated as the elements
respecting linear combinations. -/
lemma linear_of_mem_closure_range
  (f : E → 𝕜) (hf : f ∈ closure (range (weak_dual.to_Pi 𝕜 E)))
  (z₁ z₂ : E) (c₁ c₂ : 𝕜) : f (c₁ • z₁ + c₂ • z₂) = c₁ • f(z₁) + c₂ • f(z₂) :=
begin
  have hf' : f ∈ closure (range (λ (ψ : E →ₗ[𝕜] 𝕜), ψ.to_fun)),
  { apply closure_mono (continuous_linear_map.range_coe_subset_linear_map_range_coe),
    exact hf, },
  rw is_closed.closure_eq
    (linear_map.is_closed_range_coe : is_closed (range (λ (ψ : E →ₗ[𝕜] 𝕜), ψ.to_fun))) at hf',
  rw _root_.linear_map.mem_range_to_fun_iff at hf',
  exact hf' z₁ z₂ c₁ c₂,
end

/-- Elements of the closure of the range of the embedding
`weak_dual.to_Pi : weak_dual 𝕜 E → (E → 𝕜)` can be viewed as linear maps `E → 𝕜`. -/
def linear_map_of_mem_closure_range
  (f : (E → 𝕜)) (hf : f ∈ closure (range (weak_dual.to_Pi 𝕜 E))) :
  E →ₗ[𝕜] 𝕜 :=
linear_map_of_forall_apply_linear_combination_eq (linear_of_mem_closure_range f hf)

lemma linear_of_mem_closure_range_apply
  (f : E → 𝕜) (hf : f ∈ closure (range (weak_dual.to_Pi 𝕜 E))) (z : E) :
  linear_map_of_mem_closure_range f hf z = f z := rfl

/-- Elements of the closure of the image under `weak_dual.to_Pi : weak_dual 𝕜 E → (E → 𝕜)` of
a subset defined by a non-strict bound on the norm still satisfy the same bound. -/
lemma norm_eval_le_of_mem_closure_norm_eval_le
  (z : E) (c : ℝ) (f : E → 𝕜)
  (hf : f ∈ closure ((weak_dual.to_Pi 𝕜 E) '' {x' : weak_dual 𝕜 E | ∥ x' z ∥ ≤ c})) :
  ∥ f z ∥ ≤ c :=
begin
  suffices : ∀ (ε : ℝ), 0 < ε → ∥ f (z) ∥ ≤ c + ε,
  { exact le_of_forall_pos_le_add this, },
  intros ε ε_pos,
  have nhd : {g : E → 𝕜 | ∥f z - g z∥ < ε} ∈ 𝓝 f,
  { have nhd' := continuous_at_apply z f (ball_mem_nhds (f z) ε_pos),
    rwa [mem_map,
         (_ : (λ (g : E → 𝕜), g z) ⁻¹' (ball (f z) ε) = {g : E → 𝕜 | ∥f z - g z∥ < ε})] at nhd',
    ext g,
    simp only [ball, dist_comm, mem_set_of_eq, preimage_set_of_eq],
    exact mem_ball_iff_norm, },
  cases mem_closure_iff_nhds.mp hf _ nhd with g hg,
  simp only [mem_image, mem_inter_eq, mem_set_of_eq] at hg,
  rcases hg with ⟨tri, ⟨y', ⟨at_z_le, eq_g⟩⟩⟩,
  have eq : weak_dual.to_Pi 𝕜 E y' z = y' z := rfl,
  rw [← eq_g, eq] at tri,
  have key := norm_add_le_of_le tri.le at_z_le,
  rwa [sub_add_cancel, add_comm] at key,
end

/-- Elements of the closure of the image under `weak_dual.to_Pi : weak_dual 𝕜 E → (E → 𝕜)` of
a polar `polar s` of a neighborhood `s` of the origin are continuous (linear) functions. -/
lemma continuous_of_mem_closure_polar
  {s : set E} (s_nhd : s ∈ 𝓝 (0 : E)) (φ : E → 𝕜)
  (hφ : φ ∈ closure ((weak_dual.to_Pi 𝕜 E) '' (weak_dual.polar 𝕜 s))) :
  continuous φ :=
begin
  cases polar_bounded_of_nhds_zero 𝕜 s_nhd with c hc,
  have c_nn : 0 ≤ c := le_trans (norm_nonneg _) (hc 0 (zero_mem_polar 𝕜 s)),
  have hφ' : φ ∈ closure (range (weak_dual.to_Pi 𝕜 E)),
  from closure_mono (image_subset_range _ _) hφ,
  set flin := linear_map_of_mem_closure_range φ hφ' with hflin,
  suffices : continuous flin,
  { assumption, },
  apply linear_map.continuous_of_bound flin c,
  intros z,
  set θ := λ (ψ : E → 𝕜), ∥ ψ z ∥ with hθ,
  have θ_cont : continuous θ,
  { apply continuous.comp continuous_norm,
    exact continuous_apply z, },
  have sin_closed : is_closed (Icc (-c * ∥z∥) (c * ∥z∥) : set ℝ) := is_closed_Icc,
  have preim_cl := is_closed.preimage θ_cont sin_closed,
  suffices : (weak_dual.to_Pi 𝕜 E) '' (weak_dual.polar 𝕜 s) ⊆ θ⁻¹' (Icc (-c * ∥z∥) (c * ∥z∥)),
  { exact ((is_closed.closure_subset_iff preim_cl).mpr this hφ).right, },
  intros ψ hψ,
  rcases hψ with ⟨x', ⟨polar_x', ψ_x'⟩⟩,
  rw ← ψ_x',
  simp only [neg_mul_eq_neg_mul_symm, mem_preimage, mem_Icc, hθ],
  split,
  { apply le_trans _ (norm_nonneg _),
    rw right.neg_nonpos_iff,
    exact mul_nonneg c_nn (norm_nonneg _), },
  apply le_trans (continuous_linear_map.le_op_norm x' z) _,
  apply mul_le_mul (hc x' polar_x') rfl.ge (norm_nonneg z) c_nn,
end

/-- The image under `weak_dual.to_Pi : weak_dual 𝕜 E → (E → 𝕜)` of a polar `polar 𝕜 s` of a
neighborhood `s` of the origin is a closed set. -/
lemma is_closed_image_polar
  {s : set E} (s_nhd : s ∈ 𝓝 (0 : E)) :
  is_closed ((weak_dual.to_Pi 𝕜 E) '' (weak_dual.polar 𝕜 s)) :=
begin
  apply is_closed_iff_cluster_pt.mpr,
  intros f hf,
  simp only [mem_image, mem_set_of_eq],
  have f_in_closure : f ∈ closure ((weak_dual.to_Pi 𝕜 E) '' (weak_dual.polar 𝕜 s)),
  from mem_closure_iff_cluster_pt.mpr hf,
  have f_in_closure₀ : f ∈ closure (range (weak_dual.to_Pi 𝕜 E)),
  { apply closure_mono (image_subset_range _ _),
    exact mem_closure_iff_cluster_pt.mpr hf, },
  set f_lin := linear_map_of_mem_closure_range f f_in_closure₀ with h_f_lin,
  have f_cont := continuous_of_mem_closure_polar s_nhd f f_in_closure,
  set φ : weak_dual 𝕜 E :=
    { to_fun := f,
      map_add' := begin
        intros z₁ z₂,
        have key := f_lin.map_add z₁ z₂,
        rw h_f_lin at key,
        repeat {rwa linear_of_mem_closure_range_apply
          f f_in_closure₀ _ at key, },
      end,
      map_smul' := begin
        intros c z,
        have key := f_lin.map_smul c z,
        rw h_f_lin at key,
        repeat {rwa linear_of_mem_closure_range_apply
          f f_in_closure₀ _ at key, },
      end,
      cont := f_cont, } with hφ,
  refine ⟨φ, ⟨_, rfl⟩⟩,
  rw [weak_dual.polar, polar],
  intros z hz,
  apply norm_eval_le_of_mem_closure_norm_eval_le z 1 f,
  have ss : weak_dual.polar 𝕜 s ⊆ {x' : weak_dual 𝕜 E | ∥x' z∥ ≤ 1},
  { intros x' hx',
    simp only [weak_dual.polar, polar, mem_set_of_eq, preimage_set_of_eq] at hx',
    exact hx' z hz, },
  apply closure_mono (image_subset _ ss),
  exact mem_closure_iff_cluster_pt.mpr hf,
end

/-- The image under `weak_dual.to_Pi : weak_dual 𝕜 E → (E → 𝕜)` of the polar `polar s` of
a neighborhood `s` of the origin is compact if the field `𝕜` is a proper topological space. -/
lemma image_polar_compact [proper_space 𝕜] {s : set E} (s_nhd : s ∈ 𝓝 (0 : E)) :
  is_compact ((weak_dual.to_Pi 𝕜 E) '' (weak_dual.polar 𝕜 s)) :=
begin
  cases polar_bounded_of_nhds_zero 𝕜 s_nhd with c hc,
  have ss : (weak_dual.to_Pi 𝕜 E) '' (weak_dual.polar 𝕜 s) ⊆
    (set.pi (univ : set E) (λ z, (closed_ball (0 : 𝕜) (c * ∥ z ∥)))),
  { intros f hf,
    simp only [mem_image, exists_exists_and_eq_and] at hf,
    rcases hf with ⟨x', hx', f_eq⟩,
    simp only [mem_closed_ball, dist_zero_right, mem_univ_pi],
    intros z,
    have bd : ∥ x' z ∥ ≤ c * ∥ z ∥,
    { apply (continuous_linear_map.le_op_norm x' z).trans
        (mul_le_mul (hc x' hx') (le_refl ∥z∥) (norm_nonneg z) _),
      have c_nn := hc 0 (zero_mem_polar 𝕜 s),
      rwa norm_zero at c_nn, },
    have eq : x' z = f z := congr_fun f_eq z,
    rwa eq at bd, },
  apply compact_of_is_closed_subset _ _ ss,
  { apply is_compact_univ_pi,
    exact λ z, proper_space.is_compact_closed_ball 0 _, },
  exact is_closed_image_polar s_nhd,
end

end weak_dual.to_Pi_embedding

/-- The Banach-Alaoglu theorem: the polar set of a neighborhood `s` of the origin in a
normed space `E` is a compact subset of `weak_dual 𝕜 E`. -/
theorem weak_dual.is_compact_polar [proper_space 𝕜] {s : set E} (s_nhd : s ∈ 𝓝 (0 : E)) :
  is_compact (weak_dual.polar 𝕜 s) :=
begin
  apply (weak_dual.to_Pi_embedding 𝕜 E).is_compact_iff_is_compact_image.mpr,
  exact weak_dual.to_Pi_embedding.image_polar_compact s_nhd,
end

/-- The Banach-Alaoglu theorem: closed balls of the dual of a normed space `E` over `ℝ` or `ℂ`
are compact in the weak-star topology. -/
theorem weak_dual.is_compact_closed_ball
  {𝕜 : Type*} [is_R_or_C 𝕜] {E : Type*} [normed_group E] [normed_space 𝕜 E] (r : ℝ) (hr : 0 < r) :
  is_compact (id (closed_ball 0 r : set (normed_space.dual 𝕜 E)) : set (weak_dual 𝕜 E)) :=
begin
  have as_polar := @polar_closed_ball 𝕜 _ E _ _ r⁻¹ (inv_pos.mpr hr),
  simp only [one_div, inv_inv₀] at as_polar,
  rw ←as_polar,
  exact weak_dual.is_compact_polar (closed_ball_mem_nhds (0 : E) (inv_pos.mpr hr)),
end

end embedding_to_Pi
