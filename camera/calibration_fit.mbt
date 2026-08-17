///|
pub(all) struct CalibrationReport {
  observations : Int
  cost : Double
  rms : Double
  max_error : Double
  valid : Bool
} derive(Debug, Eq)

///|
pub fn calibration_report(
  observations : ArrayView[CalibrationObservation],
  intrinsics : CameraIntrinsics,
  pose : CameraPose,
  distortion? : Distortion = Distortion::none(),
) -> CalibrationReport raise @core.GeometryError {
  let errors : Array[Double] = []
  for observation in observations {
    errors.push(observation.residual(intrinsics, pose, distortion~).norm())
  }
  let cost = if errors.length() == 0 {
    0.0
  } else {
    let mut sum = 0.0
    for e in errors {
      sum += e * e
    }
    sum / Double::from_int(errors.length())
  }
  let rms = if errors.length() == 0 { 0.0 } else { @core.rms_error(errors) }
  let maximum = if errors.length() == 0 { 0.0 } else { @core.max_error(errors) }
  {
    observations: observations.length(),
    cost,
    rms,
    max_error: maximum,
    valid: observations.length() > 0 && rms < 5.0,
  }
}

///|
pub fn estimate_focal_from_depth(
  points : ArrayView[@core.Point3],
  pixels : ArrayView[@core.Point2],
  principal : @core.Point2,
) -> CameraIntrinsics raise @core.GeometryError {
  if points.length() != pixels.length() || points.length() == 0 {
    raise @core.GeometryError::NotEnoughPoints(
      "focal estimate needs paired points",
    )
  }
  let mut numerator_x = 0.0
  let mut denominator_x = 0.0
  let mut numerator_y = 0.0
  let mut denominator_y = 0.0
  for i in 0..<points.length() {
    if points[i].z <= 0.000001 {
      raise @core.GeometryError::DegenerateInput(
        "focal estimate point is behind camera",
      )
    }
    let nx = points[i].x / points[i].z
    let ny = points[i].y / points[i].z
    numerator_x += nx * (pixels[i].x - principal.x)
    denominator_x += nx * nx
    numerator_y += ny * (pixels[i].y - principal.y)
    denominator_y += ny * ny
  }
  let fx = @core.safe_divide(numerator_x, denominator_x)
  let fy = @core.safe_divide(numerator_y, denominator_y)
  CameraIntrinsics::new(fx~, fy~, cx=principal.x, cy=principal.y)
}

///|
pub fn observation_in_bounds(
  observation : CalibrationObservation,
  size : ImageSize,
) -> Bool {
  pixel_in_bounds(size, observation.pixel)
}

///|
pub fn valid_observations(
  observations : ArrayView[CalibrationObservation],
  size : ImageSize,
) -> Array[CalibrationObservation] {
  let result : Array[CalibrationObservation] = []
  for observation in observations {
    if observation_in_bounds(observation, size) && observation.weight > 0.0 {
      result.push(observation)
    }
  }
  result
}

///|
pub fn weighted_reprojection_cost(
  observations : ArrayView[CalibrationObservation],
  intrinsics : CameraIntrinsics,
  pose : CameraPose,
) -> Double raise @core.GeometryError {
  let mut cost = 0.0
  let mut weights = 0.0
  for observation in observations {
    let r = observation.residual(intrinsics, pose)
    cost += observation.weight * r.norm2()
    weights += observation.weight
  }
  if weights <= 0.0 {
    raise @core.GeometryError::DegenerateInput("weights must be positive")
  }
  cost / weights
}

///|
pub fn calibration_is_usable(
  report : CalibrationReport,
  max_rms? : Double = 2.0,
) -> Bool {
  report.valid && report.rms <= max_rms
}
