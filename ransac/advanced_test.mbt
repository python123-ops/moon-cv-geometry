///|
test "config validation and adaptive bound" {
  let config = RansacConfig::new(iterations=10, threshold=1.0, min_inliers=2)
  assert_true(config.validated(data_size=4).iterations == 10)
  assert_true(adaptive_iteration_bound(inlier_ratio=0.8, sample_size=4) > 0)
}

///|
test "residual diagnostics classify consensus" {
  let report = report_from_residuals([0.1, 0.2, 4.0, 0.3], threshold=1.0)
  assert_true(report.inliers == 3)
  assert_true(report.ratio > 0.7)
  assert_true(report.acceptable(minimum_ratio=0.5, maximum_mean_error=0.5))
  assert_true(weighted_consensus([0.0, 0.5, 2.0], threshold=1.0) > 1.0)
}

///|
test "sampler is deterministic and unique" {
  let a = deterministic_indices(length=10, count=5, seed=42U)
  let b = deterministic_indices(length=10, count=5, seed=42U)
  assert_true(a == b)
  for i in 0..<a.length() {
    for j in (i + 1)..<a.length() {
      assert_true(a[i] != a[j])
    }
  }
}

///|
test "robust losses downweight outliers" {
  assert_true(tukey_weight(residual=0.0, cutoff=1.0) == 1.0)
  assert_true(tukey_weight(residual=2.0, cutoff=1.0) == 0.0)
  assert_true(huber_loss(residual=10.0, delta=1.0) < 50.0)
  assert_true(
    consensus_ratio(InlierMask::{ values: [true, false, true] }) > 0.5,
  )
}

///|
test "mask bounds are checked" {
  let mask = InlierMask::{ values: [true, false] }
  assert_true(mask.count() == 1)
  assert_true(mask.indices() == [0])
  assert_true(validate_mask(mask, expected_length=2))
  try mask.is_inlier(4) catch {
    @core.GeometryError::DegenerateInput(_) => ()
    _ => fail("wrong error")
  } noraise {
    _ => fail("expected error")
  }
}
