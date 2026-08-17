///|
test "matching and reconstruction constraints" {
  let left = [@core.Point2::new(x=0.0, y=0.0), @core.Point2::new(x=1.0, y=1.0)]
  let right = [@core.Point2::new(x=0.1, y=0.0), @core.Point2::new(x=1.1, y=1.0)]
  let matches = mutual_matches(left, right, maximum_distance=0.5)
  assert_true(matches.length() == 2)
  assert_true(match_distance_statistics(matches).0 < 0.2)
  let rays = [
    @core.Ray3::new(
      origin=@core.Point3::new(x=0.0, y=0.0, z=0.0),
      direction=@core.Vec3::new(x=0.0, y=0.0, z=1.0),
    ),
  ]
  let points = [@core.Point3::new(x=0.0, y=0.0, z=2.0)]
  let report = reconstruction_report(points, rays, rays)
  assert_true(report.positive_depth == 1)
  assert_true(depth_clamp(points[0], minimum=1.0, maximum=3.0).z == 2.0)
}

///|
test "fundamental normalization and angular residual" {
  let f = estimate_fundamental_from_translation(
    @core.Vec3::new(x=1.0, y=0.0, z=0.0),
  )
  let n = normalize_fundamental(f)
  assert_true(essential_scale(n) > 0.0)
  let a = normalize_bearing(@core.Point2::new(x=0.0, y=0.0))
  assert_true(bearing_residual(a, a) == 0.0)
  assert_true(
    positive_depth_mask([
      @core.Point3::new(x=0.0, y=0.0, z=1.0),
      @core.Point3::new(x=0.0, y=0.0, z=-1.0),
    ]) ==
    [true, false],
  )
}
