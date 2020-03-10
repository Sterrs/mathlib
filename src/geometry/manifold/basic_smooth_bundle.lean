/-
Copyright (c) 2019 Sébastien Gouëzel. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Sébastien Gouëzel
-/

import topology.topological_fiber_bundle geometry.manifold.smooth_manifold_with_corners
/-!
# Basic smooth bundles

In general, a smooth bundle is a bundle over a smooth manifold, whose fiber is a manifold, and
for which the coordinate changes are smooth. In this definition, there are charts involved at
several places: in the manifold structure of the base, in the manifold structure of the fibers, and
in the local trivializations. This makes it a complicated object in general. There is however a
specific situation where things are much simpler: when the fiber is a vector space (no need for
charts for the fibers), and when the local trivializations of the bundle and the charts of the base
coincide. Then everything is expressed in terms of the charts of the base, making for a much
simpler overall structure, which is easier to manipulate formally.

Most vector bundles that naturally occur in differential geometry are of this form:
the tangent bundle, the cotangent bundle, differential forms (used to define de Rham cohomology)
and the bundle of Riemannian metrics. Therefore, it is worth defining a specific constructor for
this kind of bundle, that we call basic smooth bundles.

A basic smooth bundle is thus a smooth bundle over a smooth manifold whose fiber is a vector space,
and which is trivial in the coordinate charts of the base. (We recall that in our notion of manifold
there is a distinguished atlas, which does not need to be maximal: we require the triviality above
this specific atlas). It can be constructed from a basic smooth bundled core, defined below,
specifying the changes in the fiber when one goes from one coordinate chart to another one. We do
not require that this changes in fiber are linear, but only diffeomorphisms.

## Main definitions

* `basic_smooth_bundle_core I M F`: assuming that `M` is a smooth manifold over the model with
  corners `I` on `(𝕜, E, H)`, and `F` is a normed vector space over `𝕜`, this structure registers,
  for each pair of charts of `M`, a smooth change of coordinates on `F`. This is the core structure
  from which one will build a smooth bundle with fiber `F` over `M`.

Let `Z` be a basic smooth bundle core over `M` with fiber `F`. We define
`Z.to_topological_fiber_bundle_core`, the (topological) fiber bundle core associated to `Z`. From it,
we get a space `Z.to_topological_fiber_bundle_core.total_space` (which as a Type is just `M × F`),
with the fiber bundle topology. It inherits a manifold structure (where the charts are in bijection
with the charts of the basis). We show that this manifold is smooth.

Then we use this machinery to construct the tangent bundle of a smooth manifold.

* `tangent_bundle_core I M`: the basic smooth bundle core associated to a smooth manifold `M` over a
  model with corners `I`.
* `tangent_bundle I M`     : the total space of `tangent_bundle_core I M`. It is itself a
  smooth manifold over the model with corners `I.tangent`, the product of `I` and the trivial model
  with corners on `E`.
* `tangent_space I x`      : the tangent space to `M` at `x`
* `tangent_bundle.proj I M`: the projection from the tangent bundle to the base manifold

## Implementation notes

In the definition of a basic smooth bundle core, we do not require that the coordinate changes of
the fibers are linear map, only that they are diffeomorphisms. Therefore, the fibers of the
resulting fiber bundle do not inherit a vector space structure (as an algebraic object) in general.
As the fiber, as a type, is just `F`, one can still always register the vector space structure, but
it does not make sense to do so (i.e., it will not lead to any useful theorem) unless this structure
is canonical, i.e., the coordinate changes are linear maps.

For instance, we register the vector space structure on the fibers of the tangent bundle. However,
we do not register the normed space structure coming from that of `F` (as it is not canonical, and
we also want to keep the possibility to add a Riemannian structure on the manifold later on without
having two competing normed space instances on the tangent spaces).

We require `F` to be a normed space, and not just a topological vector space, as we want to talk
about smooth functions on `F`. The notion of derivative requires a norm to be defined.

## TODO
construct the cotangent bundle, and the bundles of differential forms. They should follow
functorially from the description of the tangent bundle as a basic smooth bundle.

## Tags
Smooth fiber bundle, vector bundle, tangent space, tangent bundle
-/

noncomputable theory

universe u

open topological_space set

/-- Core structure used to create a smooth bundle above `M` (a manifold over the model with
corner `I`) with fiber the normed vector space `F` over `𝕜`, which is trivial in the chart domains
of `M`. This structure registers the changes in the fibers when one changes coordinate charts in the
base. We do not require the change of coordinates of the fibers to be linear, only smooth.
Therefore, the fibers of the resulting bundle will not inherit a canonical vector space structure
in general. -/
structure basic_smooth_bundle_core {𝕜 : Type*} [nondiscrete_normed_field 𝕜]
{E : Type*} [normed_group E] [normed_space 𝕜 E]
{H : Type*} [topological_space H] (I : model_with_corners 𝕜 E H)
(M : Type*) [topological_space M] [manifold H M] [smooth_manifold_with_corners I M]
(F : Type*) [normed_group F] [normed_space 𝕜 F] :=
(coord_change      : atlas H M → atlas H M → H → F → F)
(coord_change_self :
  ∀ i : atlas H M, ∀ x ∈ i.1.target, ∀ v, coord_change i i x v = v)
(coord_change_comp : ∀ i j k : atlas H M,
  ∀ x ∈ ((i.1.symm.trans j.1).trans (j.1.symm.trans k.1)).source, ∀ v,
  (coord_change j k ((i.1.symm.trans j.1).to_fun x)) (coord_change i j x v) = coord_change i k x v)
(coord_change_smooth : ∀ i j : atlas H M,
  times_cont_diff_on 𝕜 ⊤ (λp : E × F, coord_change i j (I.inv_fun p.1) p.2)
  ((I.to_fun '' (i.1.symm.trans j.1).source).prod (univ : set F)))

namespace basic_smooth_bundle_core

variables {𝕜 : Type*} [nondiscrete_normed_field 𝕜]
{E : Type*} [normed_group E] [normed_space 𝕜 E]
{H : Type*} [topological_space H] {I : model_with_corners 𝕜 E H}
{M : Type*} [topological_space M] [manifold H M] [smooth_manifold_with_corners I M]
{F : Type*} [normed_group F] [normed_space 𝕜 F]
(Z : basic_smooth_bundle_core I M F)

/-- Fiber bundle core associated to a basic smooth bundle core -/
def to_topological_fiber_bundle_core : topological_fiber_bundle_core (atlas H M) M F :=
{ base_set := λi, i.1.source,
  is_open_base_set := λi, i.1.open_source,
  index_at := λx, ⟨chart_at H x, chart_mem_atlas H x⟩,
  mem_base_set_at := λx, mem_chart_source H x,
  coord_change := λi j x v, Z.coord_change i j (i.1.to_fun x) v,
  coord_change_self := λi x hx v, Z.coord_change_self i (i.1.to_fun x) (i.1.map_source hx) v,
  coord_change_comp := λi j k x ⟨⟨hx1, hx2⟩, hx3⟩ v, begin
    have := Z.coord_change_comp i j k (i.1.to_fun x) _ v,
    convert this using 2,
    { simp [hx1] },
    { simp [local_equiv.trans_source, hx1, hx2, hx3, i.1.map_source, j.1.map_source] }
  end,
  coord_change_continuous := λi j, begin
    have A : continuous_on (λp : E × F, Z.coord_change i j (I.inv_fun p.1) p.2)
      ((I.to_fun '' (i.1.symm.trans j.1).source).prod (univ : set F)) :=
      (Z.coord_change_smooth i j).continuous_on,
    have B : continuous_on (λx : M, I.to_fun (i.1.to_fun x)) i.1.source :=
      I.continuous_to_fun.comp_continuous_on i.1.continuous_to_fun,
    have C : continuous_on (λp : M × F, (⟨I.to_fun (i.1.to_fun p.1), p.2⟩ : E × F))
             (i.1.source.prod univ),
    { apply continuous_on.prod _ continuous_snd.continuous_on,
      exact B.comp continuous_fst.continuous_on (prod_subset_preimage_fst _ _) },
    have C' : continuous_on (λp : M × F, (⟨I.to_fun (i.1.to_fun p.1), p.2⟩ : E × F))
              ((i.1.source ∩ j.1.source).prod univ) :=
      continuous_on.mono C (prod_mono (inter_subset_left _ _) (subset.refl _)),
    have D : (i.1.source ∩ j.1.source).prod univ ⊆ (λ (p : M × F),
      (I.to_fun (i.1.to_fun p.1), p.2)) ⁻¹' ((I.to_fun '' (i.1.symm.trans j.1).source).prod univ),
    { rintros ⟨x, v⟩ hx,
      simp at hx,
      simp [mem_image_of_mem, local_equiv.trans_source, hx] },
    convert continuous_on.comp A C' D,
    ext p,
    simp
  end }

@[simp] lemma base_set (i : atlas H M) :
  Z.to_topological_fiber_bundle_core.base_set i = i.1.source := rfl

/-- Local chart for the total space of a basic smooth bundle -/
def chart {e : local_homeomorph M H} (he : e ∈ atlas H M) :
  local_homeomorph (Z.to_topological_fiber_bundle_core.total_space) (H × F) :=
(Z.to_topological_fiber_bundle_core.local_triv ⟨e, he⟩).trans
  (local_homeomorph.prod e (local_homeomorph.refl F))

@[simp] lemma chart_source (e : local_homeomorph M H) (he : e ∈ atlas H M) :
  (Z.chart he).source = Z.to_topological_fiber_bundle_core.proj ⁻¹' e.source :=
by { ext p, simp [chart, local_equiv.trans_source] }

@[simp] lemma chart_target (e : local_homeomorph M H) (he : e ∈ atlas H M) :
  (Z.chart he).target = e.target.prod univ :=
begin
  simp only [chart, local_equiv.trans_target, local_homeomorph.prod_to_local_equiv, id.def,
        local_equiv.refl_inv_fun, local_homeomorph.trans_to_local_equiv, local_equiv.refl_target,
        local_homeomorph.refl_local_equiv, local_equiv.prod_target, local_homeomorph.prod_inv_fun],
  ext p,
  split;
  simp [e.map_target] {contextual := tt}
end

/-- The total space of a basic smooth bundle is endowed with a manifold structure, where the charts
are in bijection with the charts of the basis. -/
instance to_manifold : manifold (H × F) Z.to_topological_fiber_bundle_core.total_space :=
{ atlas := ⋃(e : local_homeomorph M H) (he : e ∈ atlas H M), {Z.chart he},
  chart_at := λp, Z.chart (chart_mem_atlas H p.1),
  mem_chart_source := λp, by simp [mem_chart_source],
  chart_mem_atlas := λp, begin
    simp only [mem_Union, mem_singleton_iff, chart_mem_atlas],
    exact ⟨chart_at H p.1, chart_mem_atlas H p.1, rfl⟩
  end }

lemma mem_atlas_iff (f : local_homeomorph Z.to_topological_fiber_bundle_core.total_space (H × F)) :
  f ∈ atlas (H × F) Z.to_topological_fiber_bundle_core.total_space ↔
  ∃(e : local_homeomorph M H) (he : e ∈ atlas H M), f = Z.chart he :=
by simp [atlas, manifold.atlas]

@[simp] lemma mem_chart_source_iff (p q : Z.to_topological_fiber_bundle_core.total_space) :
  p ∈ (chart_at (H × F) q).source ↔ p.1 ∈ (chart_at H q.1).source :=
by simp [chart_at, manifold.chart_at]

@[simp] lemma mem_chart_target_iff (p : H × F) (q : Z.to_topological_fiber_bundle_core.total_space) :
  p ∈ (chart_at (H × F) q).target ↔ p.1 ∈ (chart_at H q.1).target :=
by simp [chart_at, manifold.chart_at]

@[simp] lemma chart_at_to_fun_fst (p q : Z.to_topological_fiber_bundle_core.total_space) :
  ((chart_at (H × F) q).to_fun p).1 = (chart_at H q.1).to_fun p.1 := rfl

@[simp] lemma chart_at_inv_fun_fst (p : H × F) (q : Z.to_topological_fiber_bundle_core.total_space) :
  ((chart_at (H × F) q).inv_fun p).1 = (chart_at H q.1).inv_fun p.1 := rfl

/-- Smooth manifold structure on the total space of a basic smooth bundle -/
instance to_smooth_manifold :
  smooth_manifold_with_corners (I.prod (model_with_corners_self 𝕜 F))
  Z.to_topological_fiber_bundle_core.total_space :=
begin
  /- We have to check that the charts belong to the smooth groupoid, i.e., they are smooth on their
  source, and their inverses are smooth on the target. Since both objects are of the same kind, it
  suffices to prove the first statement in A below, and then glue back the pieces at the end. -/
  let J := model_with_corners.to_local_equiv (I.prod (model_with_corners_self 𝕜 F)),
  have A : ∀ (e e' : local_homeomorph M H) (he : e ∈ atlas H M) (he' : e' ∈ atlas H M),
    times_cont_diff_on 𝕜 ⊤
    (J.to_fun ∘ ((Z.chart he).symm.trans (Z.chart he')).to_fun ∘ J.inv_fun)
    (J.inv_fun ⁻¹' ((Z.chart he).symm.trans (Z.chart he')).source ∩ range J.to_fun),
  { assume e e' he he',
    have : J.inv_fun ⁻¹' ((chart Z he).symm.trans (chart Z he')).source ∩ range J.to_fun =
      (I.inv_fun ⁻¹' (e.symm.trans e').source ∩ range I.to_fun).prod univ,
    { have : range (λ (p : H × F), (I.to_fun (p.fst), id p.snd)) =
             (range I.to_fun).prod (range (id : F → F)) := prod_range_range_eq.symm,
      simp at this,
      ext p,
      simp [-mem_range, J, local_equiv.trans_source, chart, model_with_corners.prod,
            local_equiv.trans_target, this],
      split,
      { tauto },
      { exact λ⟨⟨hx1, hx2⟩, hx3⟩, ⟨⟨⟨hx1, e.map_target hx1⟩, hx2⟩, hx3⟩ } },
    rw this,
    -- check separately that the two components of the coordinate change are smooth
    apply times_cont_diff_on.prod,
    show times_cont_diff_on 𝕜 ⊤ (λ (p : E × F), (I.to_fun ∘ e'.to_fun ∘ e.inv_fun ∘ I.inv_fun) p.1)
         ((I.inv_fun ⁻¹' (e.symm.trans e').source ∩ range I.to_fun).prod (univ : set F)),
    { -- the coordinate change on the base is just a coordinate change for `M`, smooth since
      -- `M` is smooth
      have A : times_cont_diff_on 𝕜 ⊤
        (I.to_fun ∘ (e.symm.trans e').to_fun ∘ I.inv_fun)
        (I.inv_fun ⁻¹' (e.symm.trans e').source ∩ range I.to_fun) :=
        (has_groupoid.compatible (times_cont_diff_groupoid ⊤ I) he he').1,
      have B : times_cont_diff_on 𝕜 ⊤ (λp : E × F, p.1)
        ((I.inv_fun ⁻¹' (e.symm.trans e').source ∩ range I.to_fun).prod univ) :=
      times_cont_diff_fst.times_cont_diff_on,
      exact times_cont_diff_on.comp A B (prod_subset_preimage_fst _ _) },
    show times_cont_diff_on 𝕜 ⊤ (λ (p : E × F),
      Z.coord_change ⟨chart_at H (e.inv_fun (I.inv_fun p.1)), _⟩ ⟨e', he'⟩
         ((chart_at H (e.inv_fun (I.inv_fun p.1))).to_fun (e.inv_fun (I.inv_fun p.1)))
      (Z.coord_change ⟨e, he⟩ ⟨chart_at H (e.inv_fun (I.inv_fun p.1)), _⟩
        (e.to_fun (e.inv_fun (I.inv_fun p.1))) p.2))
      ((I.inv_fun ⁻¹' (e.symm.trans e').source ∩ range I.to_fun).prod (univ : set F)),
    { /- The coordinate change in the fiber is more complicated as its definition involves the
      reference chart chosen at each point. However, it appears with its inverse, so using the
      cocycle property one can get rid of it, and then conclude using the smoothness of the
      cocycle as given in the definition of basic smooth bundles. -/
      have := Z.coord_change_smooth ⟨e, he⟩ ⟨e', he'⟩,
      rw model_with_corners.image at this,
      apply times_cont_diff_on.congr this,
      rintros ⟨x, v⟩ hx,
      simp [local_equiv.trans_source] at hx,
      let f := chart_at H (e.inv_fun (I.inv_fun x)),
      have A : I.inv_fun x ∈ ((e.symm.trans f).trans (f.symm.trans e')).source,
        by simp [local_equiv.trans_source, hx.1.1, hx.1.2, mem_chart_source, f.map_source],
      rw e.right_inv hx.1.1,
      have := Z.coord_change_comp ⟨e, he⟩ ⟨f, chart_mem_atlas _ _⟩ ⟨e', he'⟩ (I.inv_fun x) A v,
      simpa using this } },
  haveI : has_groupoid Z.to_topological_fiber_bundle_core.total_space
         (times_cont_diff_groupoid ⊤ (I.prod (model_with_corners_self 𝕜 F))) :=
  begin
    split,
    assume e₀ e₀' he₀ he₀',
    rcases (Z.mem_atlas_iff _).1 he₀ with ⟨e, he, rfl⟩,
    rcases (Z.mem_atlas_iff _).1 he₀' with ⟨e', he', rfl⟩,
    rw [times_cont_diff_groupoid, mem_groupoid_of_pregroupoid],
    exact ⟨A e e' he he', A e' e he' he⟩
  end,
  constructor
end

end basic_smooth_bundle_core

section tangent_bundle

variables {𝕜 : Type*} [nondiscrete_normed_field 𝕜]
{E : Type*} [normed_group E] [normed_space 𝕜 E]
{H : Type*} [topological_space H] (I : model_with_corners 𝕜 E H)
(M : Type*) [topological_space M] [manifold H M] [smooth_manifold_with_corners I M]

set_option class.instance_max_depth 50

/-- Basic smooth bundle core version of the tangent bundle of a smooth manifold `M` modelled over a
model with corners `I` on `(E, H)`. The fibers are equal to `E`, and the coordinate change in the
fiber corresponds to the derivative of the coordinate change in `M`. -/
def tangent_bundle_core : basic_smooth_bundle_core I M E :=
{ coord_change := λi j x v, (fderiv_within 𝕜 (I.to_fun ∘ j.1.to_fun ∘ i.1.inv_fun ∘ I.inv_fun)
                            (range I.to_fun) (I.to_fun x) : E → E) v,
  coord_change_smooth := λi j, begin
    /- To check that the coordinate change of the bundle is smooth, one should just use the
    smoothness of the charts, and thus the smoothness of their derivatives. -/
    rw model_with_corners.image,
    have A : times_cont_diff_on 𝕜 ⊤
      (I.to_fun ∘ (i.1.symm.trans j.1).to_fun ∘ I.inv_fun)
      (I.inv_fun ⁻¹' (i.1.symm.trans j.1).source ∩ range I.to_fun) :=
      (has_groupoid.compatible (times_cont_diff_groupoid ⊤ I) i.2 j.2).1,
    have B : unique_diff_on 𝕜 (I.inv_fun ⁻¹' (i.1.symm.trans j.1).source ∩ range I.to_fun),
    { rw inter_comm,
      apply I.unique_diff.inter (I.continuous_inv_fun _ (local_homeomorph.open_source _)) },
    have C : times_cont_diff_on 𝕜 ⊤
      (λ (p : E × E), (fderiv_within 𝕜 (I.to_fun ∘ j.1.to_fun ∘ i.1.inv_fun ∘ I.inv_fun)
            (I.inv_fun ⁻¹' (i.1.symm.trans j.1).source ∩ range I.to_fun) p.1 : E → E) p.2)
      ((I.inv_fun ⁻¹' (i.1.symm.trans j.1).source ∩ range I.to_fun).prod univ) :=
      times_cont_diff_on_fderiv_within_apply A B lattice.le_top,
    have D : ∀ x ∈ (I.inv_fun ⁻¹' (i.1.symm.trans j.1).source ∩ range I.to_fun),
      fderiv_within 𝕜 (I.to_fun ∘ j.1.to_fun ∘ i.1.inv_fun ∘ I.inv_fun)
            (range I.to_fun) x =
      fderiv_within 𝕜 (I.to_fun ∘ j.1.to_fun ∘ i.1.inv_fun ∘ I.inv_fun)
            (I.inv_fun ⁻¹' (i.1.symm.trans j.1).source ∩ range I.to_fun) x,
    { assume x hx,
      have N : I.inv_fun ⁻¹' (i.1.symm.trans j.1).source ∈ nhds x :=
        I.continuous_inv_fun.continuous_at.preimage_mem_nhds
          (mem_nhds_sets (local_homeomorph.open_source _) hx.1),
      symmetry,
      rw inter_comm,
      exact fderiv_within_inter N (I.unique_diff _ hx.2) },
    apply times_cont_diff_on.congr C,
    rintros ⟨x, v⟩ hx,
    have E : x ∈ I.inv_fun ⁻¹' (i.1.symm.trans j.1).source ∩ range I.to_fun,
      by simpa using hx,
    have : I.to_fun (I.inv_fun x) = x, by simp [E.2],
    dsimp,
    rw [this, D x E],
    refl
  end,
  coord_change_self := λi x hx v, begin
    /- Locally, a self-change of coordinate is just the identity, thus its derivative is the
    identity. One just needs to write this carefully, paying attention to the sets where the
    functions are defined. -/
    have A : I.inv_fun ⁻¹' (i.1.symm.trans i.1).source ∩ range I.to_fun ∈
      nhds_within (I.to_fun x) (range I.to_fun),
    { rw inter_comm,
      apply inter_mem_nhds_within,
      apply I.continuous_inv_fun.continuous_at.preimage_mem_nhds
        (mem_nhds_sets (local_homeomorph.open_source _) _),
      simp [hx, local_equiv.trans_source, i.1.map_target] },
    have B : ∀ᶠ y in nhds_within (I.to_fun x) (range I.to_fun),
      (I.to_fun ∘ i.1.to_fun ∘ i.1.inv_fun ∘ I.inv_fun) y = (id : E → E) y,
    { apply filter.mem_sets_of_superset A,
      assume y hy,
      rw ← model_with_corners.image at hy,
      rcases hy with ⟨z, hz⟩,
      simp [local_equiv.trans_source] at hz,
      simp [hz.2.symm, hz.1] },
    have C : fderiv_within 𝕜 (I.to_fun ∘ i.1.to_fun ∘ i.1.inv_fun ∘ I.inv_fun)
               (range I.to_fun) (I.to_fun x) =
             fderiv_within 𝕜 (id : E → E) (range I.to_fun) (I.to_fun x) :=
      fderiv_within_congr_of_mem_nhds_within (I.unique_diff _ (mem_range_self _)) B (by simp [hx]),
    rw fderiv_within_id (I.unique_diff _ (mem_range_self _)) at C,
    rw C,
    refl
  end,
  coord_change_comp := λi j u x hx, begin
    /- The cocycle property is just the fact that the derivative of a composition is the product of
    the derivatives. One needs however to check that all the functions one considers are smooth, and
    to pay attention to the domains where these functions are defined, making this proof a little
    bit cumbersome although there is nothing complicated here. -/
    have M : I.to_fun x ∈
      (I.inv_fun ⁻¹' ((i.1.symm.trans j.1).trans (j.1.symm.trans u.1)).source ∩ range I.to_fun) :=
    ⟨by simpa using hx, mem_range_self _⟩,
    have U : unique_diff_within_at 𝕜
      (I.inv_fun ⁻¹' ((i.1.symm.trans j.1).trans (j.1.symm.trans u.1)).source ∩ range I.to_fun)
      (I.to_fun x),
    { have : unique_diff_on 𝕜
        (I.inv_fun ⁻¹' ((i.1.symm.trans j.1).trans (j.1.symm.trans u.1)).source ∩ range I.to_fun),
      { rw inter_comm,
        exact I.unique_diff.inter (I.continuous_inv_fun _ (local_homeomorph.open_source _)) },
      exact this _ M },
    have A : fderiv_within 𝕜 ((I.to_fun ∘ u.1.to_fun ∘ j.1.inv_fun ∘ I.inv_fun)
                          ∘ (I.to_fun ∘ j.1.to_fun ∘ i.1.inv_fun ∘ I.inv_fun))
             (I.inv_fun ⁻¹' ((i.1.symm.trans j.1).trans (j.1.symm.trans u.1)).source ∩ range I.to_fun)
             (I.to_fun x)
      = (fderiv_within 𝕜 (I.to_fun ∘ u.1.to_fun ∘ j.1.inv_fun ∘ I.inv_fun)
             (I.inv_fun ⁻¹' (j.1.symm.trans u.1).source ∩ range I.to_fun)
             ((I.to_fun ∘ j.1.to_fun ∘ i.1.inv_fun ∘ I.inv_fun) (I.to_fun x))).comp
        (fderiv_within 𝕜 (I.to_fun ∘ j.1.to_fun ∘ i.1.inv_fun ∘ I.inv_fun)
             (I.inv_fun ⁻¹' ((i.1.symm.trans j.1).trans (j.1.symm.trans u.1)).source ∩ range I.to_fun)
             (I.to_fun x)),
    { apply fderiv_within.comp _ _ _ _ U,
      show differentiable_within_at 𝕜 (I.to_fun ∘ j.1.to_fun ∘ i.1.inv_fun ∘ I.inv_fun)
        (I.inv_fun ⁻¹' ((i.1.symm.trans j.1).trans (j.1.symm.trans u.1)).source ∩ range I.to_fun)
        (I.to_fun x),
      { have A : times_cont_diff_on 𝕜 ⊤
          (I.to_fun ∘ (i.1.symm.trans j.1).to_fun ∘ I.inv_fun)
          (I.inv_fun ⁻¹' (i.1.symm.trans j.1).source ∩ range I.to_fun) :=
        (has_groupoid.compatible (times_cont_diff_groupoid ⊤ I) i.2 j.2).1,
        have B : differentiable_on 𝕜 (I.to_fun ∘ j.1.to_fun ∘ i.1.inv_fun ∘ I.inv_fun)
          (I.inv_fun ⁻¹' ((i.1.symm.trans j.1).trans (j.1.symm.trans u.1)).source ∩ range I.to_fun),
        { apply (A.differentiable_on (lattice.le_top)).mono,
          have : ((i.1.symm.trans j.1).trans (j.1.symm.trans u.1)).source ⊆ (i.1.symm.trans j.1).source :=
            inter_subset_left _ _,
          exact inter_subset_inter (preimage_mono this) (subset.refl (range I.to_fun)) },
        apply B,
        simpa [mem_inter_iff, -mem_image, -mem_range, mem_range_self] using hx },
      show differentiable_within_at 𝕜 (I.to_fun ∘ u.1.to_fun ∘ j.1.inv_fun ∘ I.inv_fun)
        (I.inv_fun ⁻¹' (j.1.symm.trans u.1).source ∩ range I.to_fun)
        ((I.to_fun ∘ j.1.to_fun ∘ i.1.inv_fun ∘ I.inv_fun) (I.to_fun x)),
      { have A : times_cont_diff_on 𝕜 ⊤
          (I.to_fun ∘ (j.1.symm.trans u.1).to_fun ∘ I.inv_fun)
          (I.inv_fun ⁻¹' (j.1.symm.trans u.1).source ∩ range I.to_fun) :=
        (has_groupoid.compatible (times_cont_diff_groupoid ⊤ I) j.2 u.2).1,
        apply A.differentiable_on (lattice.le_top),
        rw [local_homeomorph.trans_source] at hx,
        simp [mem_inter_iff, -mem_image, -mem_range, mem_range_self],
        exact hx.2 },
      show (I.inv_fun ⁻¹' ((i.1.symm.trans j.1).trans (j.1.symm.trans u.1)).source ∩ range I.to_fun)
        ⊆ (I.to_fun ∘ j.1.to_fun ∘ i.1.inv_fun ∘ I.inv_fun) ⁻¹'
          (I.inv_fun ⁻¹' (j.1.symm.trans u.1).source ∩ range I.to_fun),
      { assume y hy,
        simp [-mem_range, local_equiv.trans_source] at hy,
        rw [local_equiv.left_inv] at hy,
        { simp [-mem_range, mem_range_self, hy, local_equiv.trans_source] },
        { exact hy.1.1.2 } } },
    have B : fderiv_within 𝕜 ((I.to_fun ∘ u.1.to_fun ∘ j.1.inv_fun ∘ I.inv_fun)
                          ∘ (I.to_fun ∘ j.1.to_fun ∘ i.1.inv_fun ∘ I.inv_fun))
             (I.inv_fun ⁻¹' ((i.1.symm.trans j.1).trans (j.1.symm.trans u.1)).source ∩ range I.to_fun)
             (I.to_fun x)
             = fderiv_within 𝕜 (I.to_fun ∘ u.1.to_fun ∘ i.1.inv_fun ∘ I.inv_fun)
             (I.inv_fun ⁻¹' ((i.1.symm.trans j.1).trans (j.1.symm.trans u.1)).source ∩ range I.to_fun)
             (I.to_fun x),
    { have E : ∀ y ∈ (I.inv_fun ⁻¹' ((i.1.symm.trans j.1).trans (j.1.symm.trans u.1)).source ∩ range I.to_fun),
        ((I.to_fun ∘ u.1.to_fun ∘ j.1.inv_fun ∘ I.inv_fun)
                          ∘ (I.to_fun ∘ j.1.to_fun ∘ i.1.inv_fun ∘ I.inv_fun)) y =
        (I.to_fun ∘ u.1.to_fun ∘ i.1.inv_fun ∘ I.inv_fun) y,
      { assume y hy,
        simp only [function.comp_app, model_with_corners_left_inv],
        rw [j.1.left_inv],
        exact hy.1.1.2 },
      exact fderiv_within_congr U E (E _ M) },
    have C : fderiv_within 𝕜 (I.to_fun ∘ u.1.to_fun ∘ i.1.inv_fun ∘ I.inv_fun)
             (I.inv_fun ⁻¹' ((i.1.symm.trans j.1).trans (j.1.symm.trans u.1)).source ∩ range I.to_fun)
             (I.to_fun x) =
             fderiv_within 𝕜 (I.to_fun ∘ u.1.to_fun ∘ i.1.inv_fun ∘ I.inv_fun)
             (range I.to_fun) (I.to_fun x),
    { rw inter_comm,
      apply fderiv_within_inter _ (I.unique_diff _ (mem_range_self _)),
      apply I.continuous_inv_fun.continuous_at.preimage_mem_nhds
        (mem_nhds_sets (local_homeomorph.open_source _) _),
      simpa using hx },
    have D : fderiv_within 𝕜 (I.to_fun ∘ u.1.to_fun ∘ j.1.inv_fun ∘ I.inv_fun)
               (I.inv_fun ⁻¹' (j.1.symm.trans u.1).source ∩ range I.to_fun)
               ((I.to_fun ∘ j.1.to_fun ∘ i.1.inv_fun ∘ I.inv_fun) (I.to_fun x)) =
             fderiv_within 𝕜 (I.to_fun ∘ u.1.to_fun ∘ j.1.inv_fun ∘ I.inv_fun)
               (range I.to_fun)
               ((I.to_fun ∘ j.1.to_fun ∘ i.1.inv_fun ∘ I.inv_fun) (I.to_fun x)),
    { rw inter_comm,
      apply fderiv_within_inter _ (I.unique_diff _ (mem_range_self _)),
      apply I.continuous_inv_fun.continuous_at.preimage_mem_nhds
        (mem_nhds_sets (local_homeomorph.open_source _) _),
      rw [local_homeomorph.trans_source] at hx,
      simp [mem_inter_iff, -mem_image, -mem_range, mem_range_self],
      exact hx.2 },
    have E : fderiv_within 𝕜 (I.to_fun ∘ j.1.to_fun ∘ i.1.inv_fun ∘ I.inv_fun)
               (I.inv_fun ⁻¹' ((i.1.symm.trans j.1).trans (j.1.symm.trans u.1)).source ∩ range I.to_fun)
               (I.to_fun x) =
             (fderiv_within 𝕜 (I.to_fun ∘ j.1.to_fun ∘ i.1.inv_fun ∘ I.inv_fun)
               (range I.to_fun)
               (I.to_fun x)),
    { rw inter_comm,
      apply fderiv_within_inter _ (I.unique_diff _ (mem_range_self _)),
      apply I.continuous_inv_fun.continuous_at.preimage_mem_nhds
        (mem_nhds_sets (local_homeomorph.open_source _) _),
      simpa using hx },
    rw [B, C, D, E] at A,
    rw A,
    assume v,
    simp,
    unfold_coes,
    simp
  end }

/-- The tangent bundle to a smooth manifold, as a plain type. -/
def tangent_bundle := (tangent_bundle_core I M).to_topological_fiber_bundle_core.total_space

/-- The projection from the tangent bundle of a smooth manifold to the manifold. As the tangent
bundle is represented internally as a product type, the notation `p.1` also works for the projection
of the point `p`. -/
def tangent_bundle.proj : tangent_bundle I M → M :=
(tangent_bundle_core I M).to_topological_fiber_bundle_core.proj

variable {M}

/-- The tangent space at a point of the manifold `M`. It is just `E`. -/
def tangent_space (x : M) : Type* :=
(tangent_bundle_core I M).to_topological_fiber_bundle_core.fiber x

section tangent_bundle_instances

/- In general, the definition of tangent_bundle and tangent_space are not reducible, so that type
class inference does not pick wrong instances. In this section, we record the right instances for
them, noting in particular that the tangent bundle is a smooth manifold. -/
variable (M)
local attribute [reducible] tangent_bundle

instance : topological_space (tangent_bundle I M) := by apply_instance
instance : manifold (H × E) (tangent_bundle I M) := by apply_instance
instance : smooth_manifold_with_corners I.tangent (tangent_bundle I M) := by apply_instance

local attribute [reducible] tangent_space topological_fiber_bundle_core.fiber
/- When `topological_fiber_bundle_core.fiber` is reducible, then
`topological_fiber_bundle_core.topological_space_fiber` can be applied to prove that any space is
a topological space, with several unknown metavariables. This is a bad instance, that we disable.-/
local attribute [instance, priority 0] topological_fiber_bundle_core.topological_space_fiber

variables {M} (x : M)

instance : topological_module 𝕜 (tangent_space I x) := by apply_instance
instance : topological_space (tangent_space I x) := by apply_instance
instance : add_comm_group (tangent_space I x) := by apply_instance
instance : topological_add_group (tangent_space I x) := by apply_instance
instance : vector_space 𝕜 (tangent_space I x) := by apply_instance

end tangent_bundle_instances

variable (M)

/-- The tangent bundle projection on the basis is a continuous map. -/
lemma tangent_bundle_proj_continuous : continuous (tangent_bundle.proj I M) :=
topological_fiber_bundle_core.continuous_proj _

/-- The tangent bundle projection on the basis is an open map. -/
lemma tangent_bundle_proj_open : is_open_map (tangent_bundle.proj I M) :=
topological_fiber_bundle_core.is_open_map_proj _

/-- In the tangent bundle to the model space, the charts are just the identity-/
@[simp] lemma tangent_bundle_model_space_chart_at (p : tangent_bundle I H) :
  (chart_at (H × E) p).to_local_equiv = local_equiv.refl (H × E) :=
begin
  have A : ∀ x_fst, fderiv_within 𝕜 (I.to_fun ∘ I.inv_fun) (range I.to_fun) (I.to_fun x_fst)
           = continuous_linear_map.id,
  { assume x_fst,
    have : fderiv_within 𝕜 (I.to_fun ∘ I.inv_fun) (range I.to_fun) (I.to_fun x_fst)
         = fderiv_within 𝕜 id (range I.to_fun) (I.to_fun x_fst),
    { refine fderiv_within_congr (I.unique_diff _ (mem_range_self _)) (λy hy, _) (by simp),
      exact model_with_corners_right_inv _ hy },
    rwa fderiv_within_id (I.unique_diff _ (mem_range_self _)) at this },
  ext x : 1,
  show (chart_at (H × E) p).to_fun x = (local_equiv.refl (H × E)).to_fun x,
  { cases x,
    simp [chart_at, manifold.chart_at, basic_smooth_bundle_core.chart,
          topological_fiber_bundle_core.local_triv, topological_fiber_bundle_core.local_triv',
          basic_smooth_bundle_core.to_topological_fiber_bundle_core, tangent_bundle_core],
    erw [local_equiv.refl_to_fun, local_equiv.refl_inv_fun, A],
    refl },
  show ∀ x, ((chart_at (H × E) p).to_local_equiv).inv_fun x = (local_equiv.refl (H × E)).inv_fun x,
  { rintros ⟨x_fst, x_snd⟩,
    simp [chart_at, manifold.chart_at, basic_smooth_bundle_core.chart,
          topological_fiber_bundle_core.local_triv, topological_fiber_bundle_core.local_triv',
          basic_smooth_bundle_core.to_topological_fiber_bundle_core, tangent_bundle_core],
    erw [local_equiv.refl_to_fun, local_equiv.refl_inv_fun, A],
    refl },
  show ((chart_at (H × E) p).to_local_equiv).source = (local_equiv.refl (H × E)).source,
  by simp [chart_at, manifold.chart_at, basic_smooth_bundle_core.chart,
           topological_fiber_bundle_core.local_triv, topological_fiber_bundle_core.local_triv',
           basic_smooth_bundle_core.to_topological_fiber_bundle_core, tangent_bundle_core,
           local_equiv.trans_source]
end

variable (H)
/-- In the tangent bundle to the model space, the topology is the product topology, i.e., the bundle
is trivial -/
lemma tangent_bundle_model_space_topology_eq_prod :
  tangent_bundle.topological_space I H = prod.topological_space :=
begin
  ext o,
  let x : tangent_bundle I H := (I.inv_fun (0 : E), (0 : E)),
  let e := chart_at (H × E) x,
  have e_source : e.source = univ, by { simp [e], refl },
  have e_target : e.target = univ, by { simp [e], refl },
  let e' := e.to_homeomorph_of_source_eq_univ_target_eq_univ e_source e_target,
  split,
  { assume ho,
    have := e'.continuous_inv_fun o ho,
    simpa [e', tangent_bundle_model_space_chart_at] },
  { assume ho,
    have := e'.continuous_to_fun o ho,
    simpa [e', tangent_bundle_model_space_chart_at] }
end

end tangent_bundle