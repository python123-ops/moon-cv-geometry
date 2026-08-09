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
  assert_true(triangulated_point_is_in_front(result, left, right))
  assert_true(triangulation_angle(left, right) > 0.4)
}

///|
test "homography uses all correspondences" {
  let src = [
    @core.Point2::new(x=0.0, y=0.0),
    @core.Point2::new(x=1.0, y=0.0),
    @core.Point2::new(x=0.0, y=1.0),
    @core.Point2::new(x=1.0, y=1.0),
    @core.Point2::new(x=2.0, y=1.0),
    @core.Point2::new(x=-1.0, y=2.0),
  ]
  let dst = [
    @core.Point2::new(x=10.0, y=20.0),
    @core.Point2::new(x=12.0, y=20.0),
    @core.Point2::new(x=10.0, y=23.0),
    @core.Point2::new(x=12.0, y=23.0),
    @core.Point2::new(x=14.0, y=23.0),
    @core.Point2::new(x=8.0, y=26.0),
  ]
  let h = estimate_homography(src, dst)
  for i in 0..<src.length() {
    assert_true(homography_reprojection_error(h, src[i], dst[i]) < 0.000001)
  }
}

///|
test "eight point fundamental estimate satisfies epipolar constraints" {
  let left = [
    @core.Point2::new(x=0.1, y=0.2),
    @core.Point2::new(x=0.4, y=-0.3),
    @core.Point2::new(x=-0.2, y=0.5),
    @core.Point2::new(x=0.7, y=0.1),
    @core.Point2::new(x=-0.6, y=-0.4),
    @core.Point2::new(x=0.2, y=0.8),
    @core.Point2::new(x=-0.8, y=0.3),
    @core.Point2::new(x=0.9, y=-0.7),
  ]
  let right = [
    @core.Point2::new(x=0.3, y=-0.1666666667),
    @core.Point2::new(x=-0.4, y=0.0),
    @core.Point2::new(x=0.2, y=-0.2083333333),
    @core.Point2::new(x=-0.1, y=0.15),
    @core.Point2::new(x=0.5, y=-0.2333333333),
    @core.Point2::new(x=-0.3, y=0.1833333333),
    @core.Point2::new(x=0.6, y=-0.2666666667),
    @core.Point2::new(x=-0.2, y=0.2166666667),
  ]
  let f = estimate_fundamental(left, right)
  for i in 0..<left.length() {
    assert_true(@core.abs(epipolar_residual(f, left[i], right[i])) < 0.00001)
  }
}
