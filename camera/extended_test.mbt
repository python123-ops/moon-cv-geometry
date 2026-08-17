///|
test "stereo depth round trip and rolling shutter" {
  let k = CameraIntrinsics::new(fx=400.0, fy=400.0, cx=320.0, cy=240.0)
  let stereo = StereoPair::new(left=k, right=k, baseline=0.1)
  let disparity = stereo.disparity(4.0)
  assert_true(@core.almost_equal(stereo.depth(disparity), 4.0))
  assert_true(stereo.valid_disparity(disparity))
  let model = RollingShutter::new(readout_seconds=0.02, image_height=480)
  assert_true(model.row_time(240.0) > 0.0)
  assert_true(model.midpoint_time() > 0.0)
  assert_true(radial_distortion_monotone(0.2, Distortion::none()))
  assert_true(
    @core.almost_equal(
      depth_uncertainty(
        focal=400.0,
        baseline=0.1,
        disparity=10.0,
        disparity_error=1.0,
      ),
      0.4,
    ),
  )
}

///|
test "calibration quality helpers" {
  let size = ImageSize::new(width=640, height=480)
  let k = CameraIntrinsics::for_centered_image(focal=500.0, size)
  assert_true(principal_point_error(k, size) == 0.0)
  assert_true(camera_model_score(k, size) > 0.9)
  let hist = residual_histogram([0.1, 0.5, 1.2], bins=4, maximum=1.0)
  assert_true(hist.length() == 4)
  assert_true(coverage_fraction([], size) == 0.0)
}
