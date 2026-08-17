///|
test "weighted centroid and covariance handle ordinary clouds" {
  let points = [
    Point3::new(x=0.0, y=0.0, z=1.0),
    Point3::new(x=2.0, y=0.0, z=1.0),
    Point3::new(x=0.0, y=2.0, z=1.0),
  ]
  let weights = [1.0, 2.0, 1.0]
  let c = robust_weighted_centroid3(points, weights)
  assert_true(abs(c.x - 1.0) < 0.000001)
  let cov = robust_weighted_covariance3(points, weights)
  assert_true(cov.trace() > 0.0)
}

///|
test "robust range and finite filters reject invalid observations" {
  let values = [1.0, 2.0, 100.0, -1.0]
  let range = percentile_range(values, 0.25, 0.75)
  assert_true(range.min >= -1.0 && range.max <= 100.0)
  let finite = finite_points3([
    Point3::new(x=0.0, y=0.0, z=1.0),
    Point3::new(x=0.0 / 0.0, y=0.0, z=1.0),
  ])
  assert_eq(finite.length(), 1)
}
