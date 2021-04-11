/-
Copyright (c) 2021 Scott Morrison. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Scott Morrison
-/
import algebra.homology2.homotopy
import algebra.category.Module.abelian
import algebra.category.Module.epi_mono

/-!
# Complexes of modules

We provide some additional API to work with homological complexes in `Module R`.
-/

universes v u

open_locale classical
noncomputable theory

open category_theory category_theory.limits homological_complex

variables {R : Type v} [comm_ring R]

-- Generalize to any concrete category.
@[ext]
lemma cokernel_funext {M N K : Module R} {f : M ⟶ N} {g h : cokernel f ⟶ K}
  (w : ∀ (n : N), g (cokernel.π f n) = h (cokernel.π f n)) : g = h :=
begin
  apply coequalizer.hom_ext,
  ext,
  exact w x,
end

@[ext]
lemma cokernel_π_ext {M N : Module.{v} R} (f : M ⟶ N) {x y : N} (m : M) (w : f m + x = y) :
  cokernel.π f x = cokernel.π f y :=
by { subst w, simp, }

@[ext]
lemma cokernel_π_image_subobject_ext {L M N : Module.{v} R}
  (f : L ⟶ M) (g : (image_subobject f : Module.{v} R) ⟶ N)
  {x y : N} (l : L) (w : g (factor_thru_image_subobject f l) + x = y) :
  cokernel.π g x = cokernel.π g y :=
begin
  subst w,
  simp,
end

def to_kernel {M N : Module R} {f : M ⟶ N} (m : M) (w : f m = 0) : (kernel f : Module R) :=
(Module.kernel_iso_ker f).symm.to_linear_equiv.to_equiv ⟨m, w⟩

@[simp] lemma to_kernel_kernel_ι {M N : Module R} {f : M ⟶ N} (m : M) (w : f m = 0) :
  (kernel.ι f) (to_kernel m w) = m :=
by simp [to_kernel]

def to_kernel_subobject {M N : Module R} {f : M ⟶ N} (m : M) (w : f m = 0) : kernel_subobject f :=
(kernel_subobject_iso f ≪≫ Module.kernel_iso_ker f).inv ⟨m, w⟩

attribute [elementwise] kernel_subobject_arrow'

@[simp] lemma to_kernel_subobject_arrow {M N : Module R} {f : M ⟶ N} (m : M) (w : f m = 0) :
  (kernel_subobject f).arrow (to_kernel_subobject m w) = m :=
by simp [to_kernel_subobject]

/--
To prove that two maps out of a homology group are equal,
it suffices to check they are equal on the images of cycles.
-/
@[ext]
lemma homology_ext {L M N K : Module R} {f : L ⟶ M} {g : M ⟶ N} (w : f ≫ g = 0)
  {h k : homology f g w ⟶ K}
  (w : ∀ (m : M) (p : g m = 0),
    h (cokernel.π (image_to_kernel _ _ w) (to_kernel_subobject m p)) =
      k (cokernel.π (image_to_kernel _ _ w) (to_kernel_subobject m p))) : h = k :=
begin
  ext n,
  -- Gosh it would be nice if `equiv_rw` could directly use an isomorphism, or an enriched `≃`.
  equiv_rw (kernel_subobject_iso g ≪≫ Module.kernel_iso_ker g).to_linear_equiv.to_equiv at n,
  convert w n.1 n.2; simp [to_kernel_subobject],
end

variables {ι : Type*} {c : complex_shape ι} {C D : homological_complex (Module.{v} R) c}

namespace homological_complex

def to_cycles (C : homological_complex (Module.{v} R) c)
  {i : ι} (x : C.X i) (p : C.d_from i x = 0) : C.cycles i :=
to_kernel_subobject x p

@[simp] lemma to_cycles_arrow {C : homological_complex (Module.{v} R) c} {i : ι}
  (x : C.X i) (p : C.d_from i x = 0) : (C.cycles i).arrow (C.to_cycles x p) = x :=
begin
  simp [to_cycles],
  dsimp [to_kernel_subobject, cycles, kernel_subobject_iso],
  simp,
end

@[ext] lemma cycles_ext {C : homological_complex (Module.{v} R) c} {i : ι}
  {x y : C.cycles i} (w : (C.cycles i).arrow x = (C.cycles i).arrow y) : x = y :=
begin
  apply_fun (C.cycles i).arrow,
  exact w,
  apply (Module.mono_iff_injective _).mp,
  exact (cycles C i).arrow_mono,
end

end homological_complex

@[simp] lemma cycles_map_to_cycles (f : C ⟶ D) {i : ι} {x : C.X i} (p : C.d_from i x = 0) :
  (cycles_map f i) (C.to_cycles x p) = D.to_cycles (f.f i x) (by simp [p]) :=
by { ext, simp, }

def homological_complex.to_homology
  (C : homological_complex (Module.{v} R) c) {i : ι} (x : C.X i) (p : C.d_from i x = 0) :
  C.homology i :=
cokernel.π (C.boundaries_to_cycles i) (C.to_cycles x p)

@[ext]
lemma homological_complex.ext {M : Module R} (i : ι) {h k : C.homology i ⟶ M}
  (w : ∀ (x : C.X i) (p : C.d_from i x = 0), h (C.to_homology x p) = k (C.to_homology x p)) :
  h = k :=
homology_ext _ w

variables (f g : C ⟶ D)

attribute [elementwise] cokernel.π_desc
open category_theory.limits

@[simp]
lemma add_left_eq_self_assoc {M : Type*} [add_right_cancel_monoid M] {a b c : M} :
  a + (b + c) = c ↔ a + b = 0 :=
by rw [←add_assoc, add_left_eq_self]

attribute [elementwise] image_subobject_arrow_comp -- rename this?

theorem homology_map_eq_of_homotopy' (h : homotopy f g) (i : ι) :
  (homology_functor (Module.{v} R) c i).map f = (homology_functor (Module.{v} R) c i).map g :=
begin
  -- To check two morphisms out of a homology group agree, it suffices to check on cycles:
  ext,
  dsimp [homology_functor, homological_complex.to_homology],
  simp only [cokernel.π_desc_apply, coe_comp],
  -- To check that two elements are equal mod coboundaries, it suffices to exhibit a coboundary:
  ext1,
  swap, exact -(h.to_prev i i) x,
  -- Moreover, to check that two cycles are equal, it suffices to check their underlying elements:
  ext1,
  simp [h.comm i, p],
end
