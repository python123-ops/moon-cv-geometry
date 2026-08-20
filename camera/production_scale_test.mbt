///|
test "calibration pipeline aggregates reprojection residuals" {
  let size = ImageSize::new(width=640, height=480)
  let intrinsics = CameraIntrinsics::for_centered_image(focal=500.0, size)
  let points = [
    @core.Point3::new(x=0.0, y=0.0, z=5.0),
    @core.Point3::new(x=1.0, y=0.0, z=5.0),
  ]
  let pixels = project_points(points, intrinsics)
  let report = calibration_batch_report(points, pixels, intrinsics)
  assert_eq(report.count, 2)
  assert_true(report.rms < 0.000001)
}

///|
test "image metrics classify depth and image support" {
  let size = ImageSize::new(width=4, height=4)
  let mask = image_support_mask(size, [
    @core.Point2::new(x=0.0, y=0.0),
    @core.Point2::new(x=9.0, y=9.0),
  ])
  assert_eq(mask.valid_count, 1)
  let histogram = depth_histogram(
    [1.0, 1.0, 2.0, 4.0],
    bins=3,
    minimum=1.0,
    maximum=4.0,
  )
  assert_eq(histogram.total, 4)
}

///|
test "pose interpolation preserves endpoints and trajectory support" {
  let first = CameraPose::identity()
  let second = CameraPose::from_rotation_translation(
    @core.identity3(),
    @core.Vec3::new(x=2.0, y=0.0, z=0.0),
  )
  let path = sample_camera_poses([first, second], 5)
  assert_eq(path.length(), 5)
  assert_true(path[0].camera_center().x == first.camera_center().x)
}

///|
test "distortion field and stereo metrics stay bounded" {
  let distortion = Distortion::brown_conrady(k1=0.01, k2=-0.001)
  let points = [
    @core.Point2::new(x=-0.2, y=0.1),
    @core.Point2::new(x=0.0, y=0.0),
    @core.Point2::new(x=0.2, y=-0.1),
  ]
  let field = distortion_displacement_field(points, distortion)
  assert_eq(field.length(), 3)
  assert_true(field[1].norm() < 0.000001)
  let stereo = stereo_depth_report(
    [2.0, 4.0, 0.0, -1.0],
    baseline=0.1,
    focal=500.0,
  )
  assert_eq(stereo.valid_count, 2)
}

///|
test "calibration schedule decreases step sizes" {
  let schedule = calibration_step_schedule(initial=1.0, decay=0.5, count=4)
  assert_eq(schedule.length(), 4)
  assert_true(schedule[3] < schedule[0])
}

///|
test "intrinsic constraints and stereo scan produce valid ranges" {
  let size = ImageSize::new(width=640, height=480)
  let intrinsics = CameraIntrinsics::for_centered_image(focal=500.0, size)
  assert_true(intrinsics_is_valid(intrinsics, size))
  let scan = disparity_scan(minimum=1.0, maximum=4.0, steps=4)
  assert_eq(scan.length(), 4)
  assert_true(scan[0] < scan[3])
}

///|
test "ray fields and image feature grids have predictable support" {
  let size = ImageSize::new(width=8, height=6)
  let intrinsics = CameraIntrinsics::for_centered_image(focal=4.0, size)
  let field = camera_ray_field(size, intrinsics, columns=4, rows=3)
  assert_eq(field.length(), 12)
  let grid = image_feature_grid(size, step=2)
  assert_true(grid.length() > 0)
}
