///|
test "projection rejects invalid coordinates intrinsics and overflow" {
  let infinity = 1.0e308 * 1.0e308
  let nan = infinity - infinity
  let k = @camera.CameraIntrinsics::new(fx=500.0, fy=500.0, cx=320.0, cy=240.0)
  for
    point in [
      @core.Point3::new(x=nan, y=0.0, z=1.0),
      @core.Point3::new(x=0.0, y=0.0, z=infinity),
      @core.Point3::new(x=1.0e308, y=0.0, z=1.0),
    ] {
    try @camera.project_point(point, k) catch {
      @core.GeometryError::DegenerateInput(_) => ()
      _ => fail("unexpected error")
    } noraise {
      _ => fail("expected invalid projection")
    }
  }
  for
    intrinsics in [
      @camera.CameraIntrinsics::new(fx=0.0, fy=1.0, cx=0.0, cy=0.0),
      @camera.CameraIntrinsics::new(fx=1.0, fy=-1.0, cx=0.0, cy=0.0),
      @camera.CameraIntrinsics::new(fx=1.0, fy=1.0, cx=nan, cy=0.0),
    ] {
    try
      @camera.project_point(@core.Point3::new(x=0.0, y=0.0, z=1.0), intrinsics)
    catch {
      @core.GeometryError::DegenerateInput(_) => ()
      _ => fail("unexpected error")
    } noraise {
      _ => fail("expected invalid intrinsics")
    }
  }
}

///|
test "field of view rejects non-physical angles and non-finite extents" {
  let infinity = 1.0e308 * 1.0e308
  for
    angle in [0.0, -1.0, 3.141592653589793, 4.0, infinity, infinity - infinity] {
    try @camera.focal_from_fov(sensor_extent=640.0, fov_radians=angle) catch {
      @core.GeometryError::DegenerateInput(_) => ()
      _ => fail("unexpected error")
    } noraise {
      _ => fail("expected invalid FOV")
    }
  }
  let k = @camera.CameraIntrinsics::new(fx=500.0, fy=500.0, cx=320.0, cy=240.0)
  let angle = @camera.horizontal_fov(k, width=640.0)
  assert_true(
    @core.almost_equal(
      @camera.focal_from_fov(sensor_extent=640.0, fov_radians=angle),
      500.0,
    ),
  )
  try @camera.vertical_fov(k, height=infinity) catch {
    @core.GeometryError::DegenerateInput(_) => ()
    _ => fail("unexpected error")
  } noraise {
    _ => fail("expected non-finite extent error")
  }
  let large = @camera.CameraIntrinsics::new(
    fx=1.0e308,
    fy=1.0e308,
    cx=0.0,
    cy=0.0,
  )
  assert_true(@camera.horizontal_fov(large, width=1.0e308) > 0.9)
  assert_true(@camera.vertical_fov(large, height=1.0e308) > 0.9)
  try
    @camera.focal_from_fov(sensor_extent=1.0e308, fov_radians=1.0e-300)
  catch {
    @core.GeometryError::DegenerateInput(_) => ()
    _ => fail("unexpected error")
  } noraise {
    _ => fail("expected focal overflow error")
  }
}
