///|
test "camera center and pose round trip" {
  let pose = CameraPose::from_rotation_translation(
    @core.identity3(),
    @core.Vec3::new(x=-1.0, y=-2.0, z=-3.0),
  )
  let center = pose.camera_center()
  assert_true(@core.almost_equal(center.x, 1.0))
  assert_true(@core.almost_equal(center.z, 3.0))
  let p = @core.Point3::new(x=4.0, y=5.0, z=6.0)
  assert_true(
    @core.distance3(pose.inverse_transform_point(pose.transform_point(p)), p) <
    0.000001,
  )
}

///|
test "projection Jacobian has expected signs" {
  let j = projection_jacobian(
    @core.Point3::new(x=2.0, y=1.0, z=4.0),
    CameraIntrinsics::new(fx=400.0, fy=500.0, cx=0.0, cy=0.0),
  )
  assert_true(j.du_dx > 0.0)
  assert_true(j.du_dz < 0.0)
  assert_true(j.dv_dy > 0.0)
}

///|
test "pyramid stops at one pixel" {
  let size = ImageSize::new(width=8, height=4)
  let k = CameraIntrinsics::for_centered_image(focal=4.0, size)
  let levels = image_pyramid(size, k, levels=8)
  assert_true(levels.length() >= 3)
  assert_true(levels[0].level == 0)
}

///|
test "frustum and pixel boundaries" {
  let size = ImageSize::new(width=640, height=480)
  let k = CameraIntrinsics::for_centered_image(focal=500.0, size)
  let f = Frustum::from_intrinsics(k, size, near=0.1, far=10.0)
  assert_true(f.contains(@core.Point3::new(x=0.0, y=0.0, z=1.0)))
  assert_false(f.contains(@core.Point3::new(x=0.0, y=0.0, z=11.0)))
  assert_true(pixel_in_bounds(size, @core.Point2::new(x=0.0, y=0.0)))
  assert_false(pixel_in_bounds(size, @core.Point2::new(x=640.0, y=0.0)))
}

///|
test "calibration report and focal estimate" {
  let k = CameraIntrinsics::new(fx=400.0, fy=400.0, cx=320.0, cy=240.0)
  let pose = CameraPose::identity()
  let world = [
    @core.Point3::new(x=1.0, y=0.0, z=2.0),
    @core.Point3::new(x=-1.0, y=0.0, z=2.0),
    @core.Point3::new(x=0.0, y=1.0, z=2.0),
    @core.Point3::new(x=0.0, y=-1.0, z=2.0),
  ]
  let pixels = project_points(world, k)
  let estimate = estimate_focal_from_depth(
    world,
    pixels,
    @core.Point2::new(x=320.0, y=240.0),
  )
  assert_true(@core.almost_equal(estimate.fx, 400.0))
  let observations = [
    CalibrationObservation::new(world=world[0], pixel=pixels[0]),
  ]
  assert_true(calibration_report(observations, k, pose).valid)
}

///|
test "invalid camera inputs are explicit" {
  try ImageSize::new(width=0, height=2) catch {
    @core.GeometryError::DegenerateInput(_) => ()
    _ => fail("wrong error")
  } noraise {
    _ => fail("expected error")
  }
  assert_false(CameraIntrinsics::new(fx=0.0, fy=1.0, cx=0.0, cy=0.0).valid())
}
