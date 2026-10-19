///|
test "confidence and model selection helpers" {
  assert_true(
    @ransac.confidence_from_success(iterations=10, success_probability=0.5) >
    0.9,
  )
  assert_true(@ransac.required_iterations(success_probability=0.5) > 1)
  assert_true(@ransac.minimum_consensus_count(total=10, ratio=0.8) == 8)
  assert_true(@ransac.residual_is_inlier(residual=0.1, threshold=1.0))
  assert_true(
    @ransac.sample_probability(inlier_ratio=0.5, sample_size=2) == 0.25,
  )
  let mask = @ransac.InlierMask::{ values: [true, true, false], }
  assert_true(@ransac.inlier_ratio_from_mask(mask) > 0.6)
}
