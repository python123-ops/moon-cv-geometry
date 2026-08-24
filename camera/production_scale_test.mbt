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

///|
test "image windows expose stable photometric and gradient metrics" {
  let values = [0.0, 1.0, 2.0, 3.0]
  let stats = image_window_stats(values)
  assert_eq(stats.count, 4)
  assert_true(image_metric_rmse(values, [0.0, 1.0, 2.0, 4.0]) > 0.0)
  assert_true(image_window_gradient_field(values, 2, 2).length() == 4)
  assert_true(image_metric_valid_ratio(values) == 1.0)
}

///|
test "ray field diagnostics reject empty and support scheduled depths" {
  let size = ImageSize::new(width=4, height=4)
  let intrinsics = CameraIntrinsics::for_centered_image(focal=4.0, size)
  let rays = camera_ray_field(size, intrinsics, columns=2, rows=2)
  assert_true(ray_field_direction_z_ratio(rays, 0.0) == 1.0)
  assert_eq(ray_field_depth_schedule(1.0, 3.0, 3).length(), 3)
  assert_true(ray_field_depth_radius(rays, 2.0) >= 0.0)
}

///|
test "calibration batches summarize valid residuals and intrinsics" {
  let summary = calibration_error_stats([0.1, 0.2, 0.3])
  assert_eq(summary.count, 3)
  assert_true(summary.mean_error > 0.0)
  let size = ImageSize::new(width=640, height=480)
  let intrinsics = CameraIntrinsics::for_centered_image(focal=500.0, size)
  assert_true(calibration_intrinsics_score(intrinsics, size) > 0.0)
  assert_true(calibration_batch_inlier_ratio([0.1, 2.0], 0.5) == 0.5)
}

///|
test "image window operators cover patch and resampling paths" {
  let values = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0]
  ignore(image_window_normalize(values))
  ignore(image_window_standardize(values))
  ignore(image_window_clip(values, 1.0, 6.0))
  ignore(image_window_threshold(values, 4.0))
  ignore(image_window_binary_count(values, 4.0))
  ignore(image_window_mean_abs_difference(values, values))
  ignore(image_window_mean_squared_difference(values, values))
  ignore(image_window_normalized_cross_correlation(values, values))
  ignore(image_window_box_sum(values, 3, 3, 1, 1, 1))
  ignore(image_window_box_mean(values, 3, 3, 1, 1, 1))
  ignore(image_window_gradient_x(values, 3, 3, 1, 1))
  ignore(image_window_gradient_y(values, 3, 3, 1, 1))
  ignore(image_window_gradient_magnitude(values, 3, 3, 1, 1))
  ignore(image_window_laplacian(values, 3, 3, 1, 1))
  ignore(image_window_corner_score(values, 3, 3, 1, 1))
  ignore(image_window_patch(values, 3, 3, 1, 1, 1))
  ignore(image_window_patch_score(values, 3, 3, 1, 1, 1))
  ignore(image_window_nonmaximum_points(values, 3, 3, 0.0, 1))
  ignore(image_window_downsample(values, 3, 3, 2))
  ignore(image_window_resize_nearest(values, 3, 3, 2, 2))
  ignore(image_window_add(values, values))
  ignore(image_window_subtract(values, values))
  ignore(image_window_multiply(values, 2.0))
  let target = Array::make(9, 0.0)
  image_window_accumulate(target, values, 1.0)
  ignore(image_window_quality(values, 0.1, 10.0))
  ignore(image_metric_mae(values, values))
  ignore(image_metric_mse(values, values))
  ignore(image_metric_psnr(values, values, 1.0))
  ignore(image_metric_ncc(values, values))
  ignore(image_metric_range(values))
  ignore(image_metric_contrast(values))
  ignore(image_metric_report(values, values))
}
