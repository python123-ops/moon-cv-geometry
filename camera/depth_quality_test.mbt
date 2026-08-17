///|
test "depth quality classifies valid and invalid samples" {
  let samples = [0.0, 1.0, 2.0, -1.0, 4.0]
  let q = depth_quality(samples, minimum=0.1, maximum=3.0)
  assert_eq(q.valid_count, 2)
  assert_true(q.valid_ratio > 0.3)
  assert_true(q.span > 0.0)
}

///|
test "depth normalization preserves invalid markers" {
  let values = normalize_depths([1.0, 2.0, 3.0], invalid_value=-1.0)
  assert_true(@core.abs(values[1] - 0.5) < 0.000001)
  let empty = normalize_depths([], invalid_value=-1.0)
  assert_eq(empty.length(), 0)
}
