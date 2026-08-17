///|
test "MLESAC score prefers concentrated residuals" {
  let config = MlesacConfig::new(inlier_scale=1.0, outlier_scale=10.0)
  let concentrated = score_mlesac([0.1, 0.2, 0.3], config)
  let spread = score_mlesac([2.0, 3.0, 4.0], config)
  assert_true(concentrated > spread)
}

///|
test "threshold sweep selects best consensus" {
  let result = sweep_thresholds([0.1, 0.2, 0.4, 2.0, 3.0], [0.2, 0.5, 1.0])
  assert_true(result.threshold == 0.5)
  assert_true(result.inliers == 3)
}
