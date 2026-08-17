///|
test "camera rig projects through named views" {
  let k = CameraIntrinsics::new(fx=400.0, fy=400.0, cx=320.0, cy=240.0)
  let rig = CameraRig::new([
    CameraView::new(id=7, intrinsics=k, pose=CameraPose::identity()),
  ])
  let observations = rig.project(@core.Point3::new(x=0.0, y=0.0, z=2.0))
  assert_true(observations.length() == 1)
  assert_true(observations[0].view_id == 7)
  assert_true(@core.almost_equal(observations[0].pixel.x, 320.0))
}

///|
test "calibration grid has deterministic planar points" {
  let grid = CalibrationGrid::new(columns=3, rows=2, spacing=0.25)
  let points = grid.points()
  assert_true(points.length() == 6)
  assert_true(points[5].x == 0.5)
  assert_true(points[5].y == 0.25)
  let size = ImageSize::new(width=640, height=480)
  let intrinsics = CameraIntrinsics::for_centered_image(focal=500.0, size)
  assert_true(grid.coverage(size, intrinsics) > 0.0)
}

///|
test "camera ray bundle keeps pixel correspondence" {
  let k = CameraIntrinsics::new(fx=100.0, fy=100.0, cx=0.0, cy=0.0)
  let pixels = [
    @core.Point2::new(x=0.0, y=0.0),
    @core.Point2::new(x=10.0, y=0.0),
  ]
  let rays = ray_bundle(pixels, k)
  assert_true(rays.length() == 2)
  assert_true(rays[1].x > rays[0].x)
}
