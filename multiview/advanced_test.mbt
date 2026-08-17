///|
test "affine estimator recovers translation and scale" {
  let src = [
    @core.Point2::new(x=0.0, y=0.0),
    @core.Point2::new(x=1.0, y=0.0),
    @core.Point2::new(x=0.0, y=1.0),
    @core.Point2::new(x=2.0, y=1.0),
  ]
  let dst = [
    @core.Point2::new(x=3.0, y=4.0),
    @core.Point2::new(x=5.0, y=4.0),
    @core.Point2::new(x=3.0, y=7.0),
    @core.Point2::new(x=7.0, y=7.0),
  ]
  let a = estimate_affine(src, dst)
  let p = a.apply(@core.Point2::new(x=0.25, y=0.5))
  assert_true(@core.almost_equal(p.x, 3.5))
  assert_true(@core.almost_equal(p.y, 5.5))
}

///|
test "affine estimator rejects collinear points" {
  let points = [
    @core.Point2::new(x=0.0, y=0.0),
    @core.Point2::new(x=1.0, y=1.0),
    @core.Point2::new(x=2.0, y=2.0),
  ]
  try estimate_affine(points, points) catch {
    @core.GeometryError::DegenerateInput(_) => ()
    _ => fail("wrong error")
  } noraise {
    _ => fail("expected error")
  }
}

///|
test "track residuals and visibility" {
  let k = @camera.CameraIntrinsics::new(fx=100.0, fy=100.0, cx=0.0, cy=0.0)
  let p = @core.Point3::new(x=1.0, y=0.0, z=2.0)
  let pixel = @camera.project_point(p, k)
  let observation = @camera.CalibrationObservation::new(world=p, pixel~)
  let track = PointTrack::new(world=p, observations=[observation])
  assert_true(observation_count([track]) == 1)
  assert_true(visible_track_count([track], @camera.CameraPose::identity()) == 1)
  assert_true(
    normalized_track_error(track, k, @camera.CameraPose::identity()) < 0.000001,
  )
}

///|
test "epipolar and homography masks preserve length" {
  let f = estimate_fundamental_from_translation(
    @core.Vec3::new(x=1.0, y=0.0, z=0.0),
  )
  let left = [@core.Point2::new(x=0.1, y=0.2)]
  let right = [@core.Point2::new(x=-0.2, y=0.2)]
  let mask = epipolar_inlier_mask(f, left, right, threshold=0.001)
  assert_true(mask.length() == 1)
  assert_true(count_inliers(mask) == 1)
  let h = Homography::new(matrix=@core.identity3())
  let hm = homography_inlier_mask(h, left, left, threshold=0.001)
  assert_true(count_inliers(hm) == 1)
}

///|
test "triangulation quality handles weak baseline" {
  let a = @core.Ray3::new(
    origin=@core.Point3::new(x=0.0, y=0.0, z=0.0),
    direction=@core.Vec3::new(x=0.0, y=0.0, z=1.0),
  )
  let b = @core.Ray3::new(
    origin=@core.Point3::new(x=1.0, y=0.0, z=0.0),
    direction=@core.Vec3::new(x=0.0, y=0.0, z=1.0),
  )
  assert_true(parallax_degrees(a, b) == 0.0)
}
