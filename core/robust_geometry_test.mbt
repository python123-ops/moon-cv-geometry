///|
test "weighted centroid and covariance handle ordinary clouds" {
  let points = [
    @core.Point3::new(x=0.0, y=0.0, z=1.0),
    @core.Point3::new(x=2.0, y=0.0, z=1.0),
    @core.Point3::new(x=0.0, y=2.0, z=1.0),
  ]
  let weights = [1.0, 2.0, 1.0]
  let c = @core.robust_weighted_centroid3(points, weights)
  assert_true(@core.abs(c.x - 1.0) < 0.000001)
  let cov = @core.robust_weighted_covariance3(points, weights)
  assert_true(cov.trace() > 0.0)
}

///|
test "robust range and finite filters reject invalid observations" {
  let values = [1.0, 2.0, 100.0, -1.0]
  let range = @core.percentile_range(values, 0.25, 0.75)
  assert_true(range.min >= -1.0 && range.max <= 100.0)
  let finite = @core.finite_points3([
    @core.Point3::new(x=0.0, y=0.0, z=1.0),
    @core.Point3::new(x=0.0 / 0.0, y=0.0, z=1.0),
  ])
  assert_eq(finite.length(), 1)
}
