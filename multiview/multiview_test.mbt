///|
test "homography applies affine point correspondences" {
  let src = [
    @core.Point2::new(x=0.0, y=0.0),
    @core.Point2::new(x=1.0, y=0.0),
    @core.Point2::new(x=0.0, y=1.0),
    @core.Point2::new(x=1.0, y=1.0),
  ]
  let dst = [
    @core.Point2::new(x=10.0, y=20.0),
    @core.Point2::new(x=12.0, y=20.0),
    @core.Point2::new(x=10.0, y=23.0),
    @core.Point2::new(x=12.0, y=23.0),
  ]
  let h = estimate_homography_from_four(src, dst)
  let p = h.apply(@core.Point2::new(x=0.25, y=0.5))
  assert_true(@core.almost_equal(p.x, 10.5))
  assert_true(@core.almost_equal(p.y, 21.5))
}

///|
test "epipolar residual is zero for x-axis stereo translation" {
  let f = estimate_fundamental_from_translation(
    @core.Vec3::new(x=1.0, y=0.0, z=0.0),
  )
  let left = @core.Point2::new(x=0.2, y=0.4)
  let right = @core.Point2::new(x=-0.1, y=0.4)
  assert_true(@core.almost_equal(epipolar_residual(f, left, right), 0.0))
  assert_true(epipolar_distance(f, left, right) < 0.000000001)
  assert_true(sampson_error(f, left, right) < 0.000000001)
}

///|
test "homography handles projective four-point mapping" {
  let src = [
    @core.Point2::new(x=0.0, y=0.0),
    @core.Point2::new(x=1.0, y=0.0),
    @core.Point2::new(x=1.0, y=1.0),
    @core.Point2::new(x=0.0, y=1.0),
  ]
  let dst = [
    @core.Point2::new(x=0.0, y=0.0),
    @core.Point2::new(x=2.0, y=0.0),
    @core.Point2::new(x=1.6, y=1.2),
    @core.Point2::new(x=0.2, y=1.0),
  ]
  let h = estimate_homography_from_four(src, dst)
  for i in 0..<4 {
    assert_true(homography_reprojection_error(h, src[i], dst[i]) < 0.000000001)
  }
}

///|
test "triangulate from two bearing rays" {
  let target = @core.Point3::new(x=0.0, y=0.0, z=2.0)
  let left = @core.Ray3::new(
    origin=@core.Point3::new(x=0.0, y=0.0, z=0.0),
    direction=target.minus(@core.Point3::new(x=0.0, y=0.0, z=0.0)),
  )
  let right_origin = @core.Point3::new(x=1.0, y=0.0, z=0.0)
  let right = @core.Ray3::new(
    origin=right_origin,
    direction=target.minus(right_origin),
  )
  let result = triangulate_from_rays(left, right)
  assert_true(@core.distance3(result.point, target) < 0.000000001)
  assert_true(
    triangulation_is_well_conditioned(result, max_separation=0.000000001),
  )
}
