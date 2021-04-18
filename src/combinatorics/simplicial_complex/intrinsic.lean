import tactic
import data.real.basic
import linear_algebra.affine_space.independent
import linear_algebra.std_basis
import linear_algebra.affine_space.finite_dimensional
import linear_algebra.affine_space.combination
import linear_algebra.finite_dimensional
import algebra.module.linear_map
import analysis.convex.topology
import combinatorics.simplicial_complex.to_move.topology
import combinatorics.simplicial_complex.convex_independence

open_locale classical affine big_operators
open set
--TODO: Generalise to LCTVS
variables {E : Type*} [normed_group E] [normed_space ℝ E] {x : E} {A B : set E}

namespace affine

def intrinsic_frontier (A : set E) :
  set E :=
coe '' (frontier {x : affine_span ℝ A | ↑x ∈ A})

def intrinsic_interior (A : set E) :
  set E :=
coe '' (interior {x : affine_span ℝ A | ↑x ∈ A})

lemma coe_closure_subset_closure_aux (B : set E) :
  coe '' closure {x : affine_span ℝ A | ↑x ∈ B} ⊆ closure B :=
begin
  rintro _ ⟨x, hx, rfl⟩,
  rw mem_closure_iff_seq_limit at ⊢ hx,
  obtain ⟨f, hfB, hflim⟩ := hx,
  exact ⟨λ y, f y, hfB, by rwa ←embedding.tendsto_nhds_iff embedding_subtype_coe⟩,
end

lemma closure_eq_intrinsic_closure :
  closure A = coe '' (closure {x : affine_span ℝ A | ↑x ∈ A}) :=
begin
  refine subset.antisymm _ (coe_closure_subset_closure_aux A),
  rintro x hxA,
  rw mem_closure_iff_seq_limit at hxA,
  obtain ⟨f, hfA, hflim⟩ := hxA,
  simp_rw [mem_image, closure_induced],
  split,
  sorry,
  sorry,
end

lemma closure_eq_intrinsic_interior_union_intrinsic_frontier :
  closure A = intrinsic_interior A ∪ intrinsic_frontier A :=
begin
  ext x,
  rw [closure_eq_intrinsic_closure, closure_eq_interior_union_frontier],
  split,
  { rintro ⟨x', (hx' | hx'), rfl⟩,
    { left,
      exact ⟨x', hx', rfl⟩ },
    right,
    exact ⟨x', hx', rfl⟩ },
  rintro (⟨x', hx', rfl⟩ | ⟨x', hx', rfl⟩),
  exacts [⟨x', by {left, exact hx'}, rfl⟩, ⟨x', by {right, exact hx'}, rfl⟩],
end

lemma intrinsic_interior_subset_closure :
  intrinsic_interior A ⊆ closure A :=
begin
  rw closure_eq_intrinsic_interior_union_intrinsic_frontier,
  exact subset_union_left _ _,
end

lemma intrinsic_frontier_subset_closure :
  intrinsic_frontier A ⊆ closure A :=
begin
  rw closure_eq_intrinsic_interior_union_intrinsic_frontier,
  exact subset_union_right _ _,
end

lemma disjoint_intrinsic_interior_intrinsic_frontier :
  disjoint (intrinsic_interior A) (intrinsic_frontier A) :=
begin
  rintro x ⟨⟨x₁, hx₁, rfl⟩, x₂, hx₂, hx₁x₂⟩,
  rw subtype.ext hx₁x₂ at hx₂,
  exact hx₂.2 hx₁,
end

lemma intrinsic_frontier_eq_closure_diff_intrinsic_interior :
  intrinsic_frontier A = closure A \ intrinsic_interior A :=
by rw [closure_eq_intrinsic_interior_union_intrinsic_frontier,
  set.union_diff_cancel_left disjoint_intrinsic_interior_intrinsic_frontier]

lemma intrinsic_interior_eq_closure_diff_intrinsic_frontier :
  intrinsic_interior A = closure A \ intrinsic_frontier A :=
by rw [intrinsic_frontier_eq_closure_diff_intrinsic_interior, diff_diff_right, diff_self,
  empty_union, inter_eq_self_of_subset_right intrinsic_interior_subset_closure]

lemma intrinsic_frontier_subset_frontier :
  intrinsic_frontier A ⊆ frontier A :=
begin
  rintro x hx,
  unfold intrinsic_frontier at hx,
  rw frontier_eq_closure_inter_closure at ⊢ hx,
  obtain ⟨x', hx', rfl⟩ := hx,
  exact ⟨coe_closure_subset_closure_aux _ ⟨x', hx'.1, rfl⟩, coe_closure_subset_closure_aux Aᶜ
    ⟨x', hx'.2, rfl⟩⟩,
end

lemma interior_subset_intrinsic_interior :
  interior A ⊆ intrinsic_interior A :=
begin
  rw [interior_eq_closure_diff_frontier, intrinsic_interior_eq_closure_diff_intrinsic_frontier],
  exact diff_subset_diff_right intrinsic_frontier_subset_frontier,
end

--rewrite the condition to something about dimension?
lemma intrinsic_frontier_eq_frontier (hA : affine_span ℝ A = ⊤) :
  intrinsic_frontier A = frontier A :=
begin
  apply subset.antisymm intrinsic_frontier_subset_frontier,
  rintro x hx,
  have hxA : x ∈ affine_span ℝ A,
  {
    rw hA,
    sorry,
  },
  refine ⟨⟨x, hxA⟩, _, rfl⟩,
  sorry
end

lemma intrinsic_frontier_convex_hull_eq (hA : convex_independent (λ p, p : A → E)) :
  intrinsic_frontier (convex_hull A) =
  ⋃ (B : set E) (H : affine_span ℝ B < affine_span ℝ A),convex_hull B :=
begin
  sorry --angry hard
end

lemma intrinsic_frontier_convex_hull_eq' (hA : affine_independent ℝ (λ p, p : A → E)) :
  intrinsic_frontier (convex_hull A) = ⋃ B ⊂ A, convex_hull B :=
begin
  sorry --damn hard
end

end affine
