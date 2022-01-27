/-
Copyright (c) 2020 Johan Commelin. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Johan Commelin
-/
import category_theory.concrete_category.bundled_hom
import algebra.punit_instances
import order.hom.basic

/-! # Category of preorders -/

namespace order_iso
open order_dual

/-- The order isomorphism between a type and its double dual. -/
def dual_dual (α : Type*) [preorder α] : α ≃o order_dual (order_dual α) := refl α

@[simp] lemma coe_dual_dual (α : Type*) [preorder α] : ⇑(dual_dual α) = to_dual ∘ to_dual := rfl
@[simp] lemma coe_dual_dual_symm (α : Type*) [preorder α] :
  ⇑(dual_dual α).symm = of_dual ∘ of_dual := rfl

@[simp] lemma dual_dual_apply {α : Type*} [preorder α] (a : α) :
  dual_dual α a = to_dual (to_dual a) := rfl

@[simp] lemma dual_dual_symm_apply {α : Type*} [preorder α] (a : order_dual (order_dual α)) :
  (dual_dual α).symm a = of_dual (of_dual a) := rfl

end order_iso

open category_theory

/-- The category of preorders. -/
def Preorder := bundled preorder

namespace Preorder

instance : bundled_hom @order_hom :=
{ to_fun := @order_hom.to_fun,
  id := @order_hom.id,
  comp := @order_hom.comp,
  hom_ext := @order_hom.ext }

attribute [derive [large_category, concrete_category]] Preorder

instance : has_coe_to_sort Preorder Type* := bundled.has_coe_to_sort

/-- Construct a bundled Preorder from the underlying type and typeclass. -/
def of (α : Type*) [preorder α] : Preorder := bundled.of α

instance : inhabited Preorder := ⟨of punit⟩

instance (α : Preorder) : preorder α := α.str

/-- `order_dual` as a functor. -/
@[simps] def to_dual : Preorder ⥤ Preorder :=
{ obj := λ X, of (order_dual X), map := λ X Y, order_hom.dual }

/-- Constructs an equivalence between preorders from an order isomorphism between them. -/
@[simps] def iso_of_order_iso {α β : Preorder} (e : α ≃o β) : α ≅ β :=
{ hom := e,
  inv := e.symm,
  hom_inv_id' := by { ext, exact e.symm_apply_apply x },
  inv_hom_id' := by { ext, exact e.apply_symm_apply x } }

/-- The equivalence between `Preorder` and itself induced by `order_dual` both ways. -/
@[simps] def dual_equiv : Preorder ≌ Preorder :=
equivalence.mk to_dual to_dual
  (nat_iso.of_components (λ X, iso_of_order_iso $ order_iso.dual_dual X) $ λ X Y f, rfl)
  (nat_iso.of_components (λ X, iso_of_order_iso $ order_iso.dual_dual X) $ λ X Y f, rfl)

end Preorder
