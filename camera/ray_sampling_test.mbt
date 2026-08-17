///|
test "image ray grid covers corners and center" {
  let size = ImageSize::new(width=5, height=5)
  let k = CameraIntrinsics::for_centered_image(focal=2.0, size)
  let rays = image_ray_grid(size, k, 3, 3)
  assert_eq(rays.length(), 9)
  assert_true(rays[4].direction.z > 0.9)
  assert_true(rays[0].direction.x < 0.0)
}

///|
test "ray sampling rejects invalid dimensions and clips pixels" {
  let size = ImageSize::new(width=4, height=3)
  let k = CameraIntrinsics::for_centered_image(focal=3.0, size)
  let rays = sample_pixels(size, k, [
    @core.Point2::new(x=-4.0, y=99.0),
    @core.Point2::new(x=1.0, y=1.0),
  ])
  assert_eq(rays.length(), 1)
  assert_true(rays[0].origin.z == 0.0)
}

///|
test "ray bundle statistics are finite" {
  let size = ImageSize::new(width=8, height=6)
  let k = CameraIntrinsics::for_centered_image(focal=4.0, size)
  let rays = image_ray_grid(size, k, 4, 3)
  let report = ray_bundle_report(rays)
  assert_eq(report.count, 12)
  assert_true(report.mean_direction_norm > 0.9)
}
