///|
test "project and back-project normalized pinhole coordinates" {
  let k = CameraIntrinsics::new(fx=500.0, fy=500.0, cx=320.0, cy=240.0)
  let p = @core.Point3::new(x=1.0, y=2.0, z=4.0)
  let pixel = project_point(p, k)
  assert_true(@core.almost_equal(pixel.x, 445.0))
  assert_true(@core.almost_equal(pixel.y, 490.0))
  let ray = bearing_from_pixel(pixel, k)
  assert_true(ray.z > 0.85)
}

///|
test "distortion iterative inverse returns near original coordinate" {
  let d = Distortion::brown_conrady(k1=0.1, k2=-0.02, p1=0.001, p2=-0.001)
  let p = @core.Point2::new(x=0.2, y=-0.1)
  let distorted = distort_point(p, d)
  let recovered = undistort_point_iterative(distorted, d, iterations=8)
  assert_true(@core.reprojection_error(p, recovered) < 0.000001)
}

///|
test "field-of-view helpers round trip focal length" {
  let k = CameraIntrinsics::new(fx=500.0, fy=400.0, cx=320.0, cy=240.0)
  let hfov = horizontal_fov(k, width=1000.0)
  let vfov = vertical_fov(k, height=800.0)
  assert_true(
    @core.almost_equal(
      focal_from_fov(sensor_extent=1000.0, fov_radians=hfov),
      500.0,
    ),
  )
  assert_true(
    @core.almost_equal(
      focal_from_fov(sensor_extent=800.0, fov_radians=vfov),
      400.0,
    ),
  )
}

///|
test "viewport helpers expose image bounds and scaled intrinsics" {
  let size = ImageSize::new(width=640, height=480)
  let rect = size.as_rect()
  assert_true(rect.contains(@core.Point2::new(x=320.0, y=240.0)))
  assert_false(rect.contains(@core.Point2::new(x=641.0, y=240.0)))
  let k = CameraIntrinsics::for_centered_image(focal=600.0, size)
  assert_true(@core.almost_equal(k.cx, 320.0))
  assert_true(@core.almost_equal(k.cy, 240.0))
  let half = k.scaled(scale_x=0.5, scale_y=0.5)
  assert_true(@core.almost_equal(half.fx, 300.0))
  assert_true(@core.almost_equal(half.cx, 160.0))
  let m = half.as_matrix()
  assert_true(@core.almost_equal(m.m00, 300.0))
  assert_true(@core.almost_equal(m.m22, 1.0))
}
