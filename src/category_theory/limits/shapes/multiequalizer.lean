/-
Copyright (c) 2021 Adam Topaz. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Adam Topaz
-/
import category_theory.limits.has_limits

/-!

# Multi-(co)equalizers

A *multiequalizer* is an equalizer of two morphisms between two products.
Since both products and equalizers are limits, such an object is again a limit.
This file provides the diagram whose limit is indeed such an object.
In fact, it is well-known that any limit can be obtained as a multiequalizer.
The dual construction (multicoequalizers) is also provided.

## Projects

Prove that the limit of any diagram is a multiequalizer (and similarly for colimits).

-/

namespace category_theory.limits

open category_theory

universes v u

/-- The type underlying the multiequalizer diagram. -/
@[nolint unused_arguments]
inductive walking_multicospan {α β : Type v} (fst snd : β → α) : Type v
| left : α → walking_multicospan
| right : β → walking_multicospan

/-- The type underlying the multiecoqualizer diagram. -/
@[nolint unused_arguments]
inductive walking_multispan {α β : Type v} (fst snd : α → β) : Type v
| left : α → walking_multispan
| right : β → walking_multispan

namespace walking_multicospan

variables {α β : Type v} {fst snd : β → α}

instance [inhabited α] : inhabited (walking_multicospan fst snd) :=
⟨left (default _)⟩

/-- Morphisms for `walking_multicospan`. -/
inductive hom : Π (a b : walking_multicospan fst snd), Type v
| id (A)  : hom A A
| fst (b) : hom (left (fst b)) (right b)
| snd (b) : hom (left (snd b)) (right b)

instance {a : walking_multicospan fst snd} : inhabited (hom a a) :=
⟨hom.id _⟩

/-- Composition of morphisms for `walking_multicospan`. -/
def hom.comp : Π {A B C : walking_multicospan fst snd} (f : hom A B) (g : hom B C),
  hom A C
| _ _ _ (hom.id X) f := f
| _ _ _ (hom.fst b) (hom.id X) := hom.fst b
| _ _ _ (hom.snd b) (hom.id X) := hom.snd b

instance : small_category (walking_multicospan fst snd) :=
{ hom := hom,
  id := hom.id,
  comp := λ X Y Z, hom.comp,
  id_comp' := begin
    rintro (_|_) (_|_) (_|_|_),
    tidy
  end,
  comp_id' := begin
    rintro (_|_) (_|_) (_|_|_),
    tidy
  end,
  assoc' := begin
    rintro (_|_) (_|_) (_|_) (_|_) (_|_|_) (_|_|_) (_|_|_),
    tidy,
  end }

end walking_multicospan

namespace walking_multispan

variables {α β : Type v} {fst snd : α → β}

instance [inhabited α] : inhabited (walking_multispan fst snd) :=
⟨left (default _)⟩

/-- Morphisms for `walking_multispan`. -/
inductive hom : Π (a b : walking_multispan fst snd), Type v
| id (A)  : hom A A
| fst (a) : hom (left a) (right (fst a))
| snd (a) : hom (left a) (right (snd a))

instance {a : walking_multispan fst snd} : inhabited (hom a a) :=
⟨hom.id _⟩

/-- Composition of morphisms for `walking_multispan`. -/
def hom.comp : Π {A B C : walking_multispan fst snd} (f : hom A B) (g : hom B C),
  hom A C
| _ _ _ (hom.id X) f := f
| _ _ _ (hom.fst a) (hom.id X) := hom.fst a
| _ _ _ (hom.snd a) (hom.id X) := hom.snd a

instance : small_category (walking_multispan fst snd) :=
{ hom := hom,
  id := hom.id,
  comp := λ X Y Z, hom.comp,
  id_comp' := begin
    rintro (_|_) (_|_) (_|_|_),
    tidy
  end,
  comp_id' := begin
    rintro (_|_) (_|_) (_|_|_),
    tidy
  end,
  assoc' := begin
    rintro (_|_) (_|_) (_|_) (_|_) (_|_|_) (_|_|_) (_|_|_),
    tidy,
  end }

end walking_multispan

/-- This is a structure encapsulating the data necessary to define a `multicospan`. -/
@[nolint has_inhabited_instance]
structure multicospan_index (C : Type u) [category.{v} C] :=
(α β : Type v)
(f s : β → α)
(left : α → C)
(right : β → C)
(fst : Π b, left (f b) ⟶ right b)
(snd : Π b, left (s b) ⟶ right b)

/-- This is a structure encapsulating the data necessary to define a `multispan`. -/
@[nolint has_inhabited_instance]
structure multispan_index (C : Type u) [category.{v} C] :=
(α β : Type v)
(f s : α → β)
(left : α → C)
(right : β → C)
(fst : Π a, left a ⟶ right (f a))
(snd : Π a, left a ⟶ right (s a))

namespace multicospan_index

variables {C : Type u} [category.{v} C] (I : multicospan_index C)

/-- The multicospan associated to `I : multicospan_index`. -/
def multicospan : walking_multicospan I.f I.s ⥤ C :=
{ obj := λ x,
  match x with
  | walking_multicospan.left a := I.left a
  | walking_multicospan.right b := I.right b
  end,
  map := λ x y f,
  match x, y, f with
  | _, _, walking_multicospan.hom.id x := 𝟙 _
  | _, _, walking_multicospan.hom.fst b := I.fst _
  | _, _, walking_multicospan.hom.snd b := I.snd _
  end,
  map_id' := begin
    rintros (_|_),
    tidy
  end,
  map_comp' := begin
    rintros (_|_) (_|_) (_|_) (_|_|_) (_|_|_),
    tidy
  end }

@[simp] lemma multicospan_obj_left (a) :
  I.multicospan.obj (walking_multicospan.left a) = I.left a := rfl

@[simp] lemma multicospan_obj_right (b) :
  I.multicospan.obj (walking_multicospan.right b) = I.right b := rfl

@[simp] lemma multicospan_map_fst (b) :
  I.multicospan.map (walking_multicospan.hom.fst b) = I.fst b := rfl

@[simp] lemma multicospan_map_snd (b) :
  I.multicospan.map (walking_multicospan.hom.snd b) = I.snd b := rfl

end multicospan_index

namespace multispan_index

variables {C : Type u} [category.{v} C] (I : multispan_index C)

/-- The multispan associated to `I : multispan_index`. -/
def multispan : walking_multispan I.f I.s ⥤ C :=
{ obj := λ x,
  match x with
  | walking_multispan.left a := I.left a
  | walking_multispan.right b := I.right b
  end,
  map := λ x y f,
  match x, y, f with
  | _, _, walking_multispan.hom.id x := 𝟙 _
  | _, _, walking_multispan.hom.fst b := I.fst _
  | _, _, walking_multispan.hom.snd b := I.snd _
  end,
  map_id' := begin
    rintros (_|_),
    tidy
  end,
  map_comp' := begin
    rintros (_|_) (_|_) (_|_) (_|_|_) (_|_|_),
    tidy
  end }

@[simp] lemma multispan_obj_left (a) :
  I.multispan.obj (walking_multispan.left a) = I.left a := rfl

@[simp] lemma multispan_obj_right (b) :
  I.multispan.obj (walking_multispan.right b) = I.right b := rfl

@[simp] lemma multispan_map_fst (a) :
  I.multispan.map (walking_multispan.hom.fst a) = I.fst a := rfl

@[simp] lemma multispan_map_snd (a) :
  I.multispan.map (walking_multispan.hom.snd a) = I.snd a := rfl

end multispan_index

variables {C : Type u} [category.{v} C]

/-- A multifork is a cone over a multicospan. -/
@[nolint has_inhabited_instance]
def multifork (I : multicospan_index C) := cone I.multicospan

/-- A multicofork is a cocone over a multispan. -/
@[nolint has_inhabited_instance]
def multicofork (I : multispan_index C) := cocone I.multispan

namespace multifork

variables {I : multicospan_index C} (K : multifork I)

/-- The maps from the cone point of a multifork to the objects on the left. -/
def ι (a : I.α) : K.X ⟶ I.left a :=
K.π.app (walking_multicospan.left _)

@[simp] lemma ι_eq_app_left (a) : K.ι a = K.π.app (walking_multicospan.left _) := rfl

@[simp] lemma app_left_fst (b) :
  K.π.app (walking_multicospan.left (I.f b)) ≫ I.fst b =
    K.π.app (walking_multicospan.right b) :=
by { rw ← K.w (walking_multicospan.hom.fst b), refl }

@[simp] lemma app_left_snd (b) :
  K.π.app (walking_multicospan.left (I.s b)) ≫ I.snd b =
    K.π.app (walking_multicospan.right b) :=
by { rw ← K.w (walking_multicospan.hom.snd b), refl }

/-- Construct a multifork using a collection `ι` of morphisms. -/
@[simps]
def of_ι (I : multicospan_index C) (P : C) (ι : Π a, P ⟶ I.left a)
  (w : ∀ b, ι (I.f b) ≫ I.fst b = ι (I.s b) ≫ I.snd b) :
  multifork I :=
{ X := P,
  π :=
  { app := λ x,
    match x with
    | walking_multicospan.left a := ι _
    | walking_multicospan.right b := ι (I.f b) ≫ I.fst b
    end,
    naturality' := begin
      rintros (_|_) (_|_) (_|_|_),
      any_goals { symmetry, dsimp, rw category.id_comp, apply category.comp_id },
      { dsimp, rw category.id_comp, refl },
      { dsimp, rw category.id_comp, apply w }
    end } }

@[reassoc]
lemma condition (b) :
  K.ι (I.f b) ≫ I.fst b = K.ι (I.s b) ≫ I.snd b := by simp

end multifork

namespace multicofork

variables {I : multispan_index C} (K : multicofork I)

/-- The maps to the cocone point of a multicofork from the objects on the right. -/
def π (b : I.β) : I.right b ⟶ K.X :=
K.ι.app (walking_multispan.right _)

@[simp] lemma π_eq_app_right (b) : K.π b = K.ι.app (walking_multispan.right _) := rfl

@[simp] lemma fst_app_right (a) :
  I.fst a ≫ K.ι.app (walking_multispan.right (I.f a)) =
    K.ι.app (walking_multispan.left a) :=
by { rw ← K.w (walking_multispan.hom.fst a), refl }

@[simp] lemma snd_app_right (a) :
  I.snd a ≫ K.ι.app (walking_multispan.right (I.s a)) =
    K.ι.app (walking_multispan.left a) :=
by { rw ← K.w (walking_multispan.hom.snd a), refl }

/-- Construct a multicofork using a collection `π` of morphisms. -/
@[simps]
def of_π (I : multispan_index C) (P : C) (π : Π b, I.right b ⟶ P)
  (w : ∀ a, I.fst a ≫ π (I.f a) = I.snd a ≫ π (I.s a)) :
  multicofork I :=
{ X := P,
  ι :=
  { app := λ x,
    match x with
    | walking_multispan.left a := I.fst a ≫ π _
    | walking_multispan.right b := π _
    end,
    naturality' := begin
      rintros (_|_) (_|_) (_|_|_),
      any_goals { dsimp, rw category.comp_id, apply category.id_comp },
      { dsimp, rw category.comp_id, refl },
      { dsimp, rw category.comp_id, apply (w _).symm }
    end } }

@[reassoc]
lemma condition (a) :
  I.fst a ≫ K.π (I.f a) = I.snd a ≫ K.π (I.s a) := by simp

end multicofork

/-- For `I : multicospan_index C`, we say that it has a multiequalizer if the associated
  multicospan has a limit. -/
abbreviation has_multiequalizer (I : multicospan_index C) :=
  has_limit I.multicospan

noncomputable theory

/-- The multiequalizer of `I : multicospan_index C`. -/
abbreviation multiequalizer (I : multicospan_index C) [has_multiequalizer I] : C :=
  limit I.multicospan

/-- For `I : multispan_index C`, we say that it has a multicoequalizer if
  the associated multicospan has a limit. -/
abbreviation has_multicoequalizer (I : multispan_index C) :=
  has_colimit I.multispan

/-- The multiecoqualizer of `I : multispan_index C`. -/
abbreviation multicoequalizer (I : multispan_index C) [has_multicoequalizer I] : C :=
  colimit I.multispan

namespace multiequalizer

variables (I : multicospan_index C) [has_multiequalizer I]

/-- The canonical map from the multiequalizer to the objects on the left. -/
abbreviation ι (a : I.α) : multiequalizer I ⟶ I.left a :=
limit.π _ (walking_multicospan.left a)

/-- The multifork associated to the multiequalizer. -/
abbreviation multifork : multifork I :=
limit.cone _

@[simp]
lemma multifork_ι (a) :
  (multiequalizer.multifork I).ι a = multiequalizer.ι I a := rfl

@[simp]
lemma multifork_π_app_zero (a) :
  (multiequalizer.multifork I).π.app (walking_multicospan.left a) =
  multiequalizer.ι I a := rfl

@[reassoc]
lemma condition (b) :
  multiequalizer.ι I (I.f b) ≫ I.fst b =
  multiequalizer.ι I (I.s b) ≫ I.snd b :=
multifork.condition _ _

/-- Construct a morphism to the multiequalizer from its universal property. -/
abbreviation lift (W : C) (k : Π a, W ⟶ I.left a)
  (h : ∀ b, k (I.f b) ≫ I.fst b = k (I.s b) ≫ I.snd b) :
  W ⟶ multiequalizer I :=
limit.lift _ (multifork.of_ι I _ k h)

@[simp, reassoc]
lemma lift_ι (W : C) (k : Π a, W ⟶ I.left a)
  (h : ∀ b, k (I.f b) ≫ I.fst b = k (I.s b) ≫ I.snd b) (a) :
  multiequalizer.lift I _ k h ≫ multiequalizer.ι I a = k _ :=
limit.lift_π _ _

@[ext]
lemma hom_ext {W : C} (i j : W ⟶ multiequalizer I)
  (h : ∀ a, i ≫ multiequalizer.ι I a =
  j ≫ multiequalizer.ι I a) :
  i = j :=
limit.hom_ext
begin
  rintro (a|b),
  { apply h },
  simp_rw [← limit.w I.multicospan (walking_multicospan.hom.fst b),
    ← category.assoc, h],
end

end multiequalizer

namespace multicoequalizer

variables (I : multispan_index C) [has_multicoequalizer I]

/-- The canonical map from the multiequalizer to the objects on the left. -/
abbreviation π (b : I.β) : I.right b ⟶ multicoequalizer I :=
colimit.ι I.multispan (walking_multispan.right _)

/-- The multicofork associated to the multicoequalizer. -/
abbreviation multicofork : multicofork I :=
colimit.cocone _

@[simp]
lemma multicofork_π (b) :
  (multicoequalizer.multicofork I).π b = multicoequalizer.π I b := rfl

@[simp]
lemma multicofork_π_app_right (b) :
  (multicoequalizer.multicofork I).ι.app (walking_multispan.right b) =
  multicoequalizer.π I b := rfl
@[reassoc]
lemma condition (a) :
  I.fst a ≫ multicoequalizer.π I (I.f a) =
  I.snd a ≫ multicoequalizer.π I (I.s a) :=
multicofork.condition _ _

/-- Construct a morphism from the multicoequalizer from its universal property. -/
abbreviation desc (W : C) (k : Π b, I.right b ⟶ W)
  (h : ∀ a, I.fst a ≫  k (I.f a) = I.snd a ≫ k (I.s a)) :
  multicoequalizer I ⟶ W :=
colimit.desc _ (multicofork.of_π I _ k h)

@[simp, reassoc]
lemma lift_ι (W : C) (k : Π b, I.right b ⟶ W)
  (h : ∀ a, I.fst a ≫  k (I.f a) = I.snd a ≫ k (I.s a)) (b) :
  multicoequalizer.π I b ≫ multicoequalizer.desc I _ k h = k _ :=
colimit.ι_desc _ _

@[ext]
lemma hom_ext {W : C} (i j : multicoequalizer I ⟶ W)
  (h : ∀ b, multicoequalizer.π I b ≫ i = multicoequalizer.π I b ≫ j) :
  i = j :=
colimit.hom_ext
begin
  rintro (a|b),
  { simp_rw [← colimit.w I.multispan (walking_multispan.hom.fst a),
    category.assoc, h] },
  { apply h },
end

end multicoequalizer

end category_theory.limits
