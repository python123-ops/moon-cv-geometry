///|
pub fn principal_point_error(k : CameraIntrinsics, size : ImageSize) -> Double {
  let expected_x = Double::from_int(size.width) / 2.0
  let expected_y = Double::from_int(size.height) / 2.0
  @core.Vec2::new(x=k.cx - expected_x, y=k.cy - expected_y).norm()
}

///|
pub fn focal_consistency(k : CameraIntrinsics) -> Double {
  @core.relative_error(k.fx, k.fy)
}

///|
pub fn camera_model_score(k : CameraIntrinsics, size : ImageSize) -> Double {
  if !k.valid() {
    0.0
  } else {
    1.0 / (1.0 + principal_point_error(k, size) + focal_consistency(k))
  }
}

///|
pub fn residual_histogram(
  residuals : ArrayView[Double],
  bins~ : Int,
  maximum~ : Double,
) -> Array[Int] raise @core.GeometryError {
  if bins <= 0 || maximum <= 0.0 {
    raise @core.GeometryError::DegenerateInput(
      "histogram parameters are invalid",
    )
  }
  let result : Array[Int] = []
  for _ in 0..<bins {
    result.push(0)
  }
  for residual in residuals {
    let raw = (residual / maximum * Double::from_int(bins)).to_int()
    let index = if raw < 0 { 0 } else if raw >= bins { bins - 1 } else { raw }
    result[index] += 1
  }
  result
}

///|
pub fn coverage_fraction(
  observations : ArrayView[CalibrationObservation],
  size : ImageSize,
) -> Double {
  if observations.length() == 0 {
    0.0
  } else {
    let valid = valid_observations(observations, size)
    Double::from_int(valid.length()) / Double::from_int(observations.length())
  }
}

///|
pub fn calibration_acceptance(
  report : CalibrationReport,
  coverage : Double,
  minimum_coverage? : Double = 0.8,
) -> Bool {
  report.valid && coverage >= minimum_coverage && report.rms <= 2.0
}
