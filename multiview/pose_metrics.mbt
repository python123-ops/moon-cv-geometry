///|
pub fn pose_rotation_error(a : @core.Mat3, b : @core.Mat3) -> Double {
  let relative = a.mul(b.transpose())
  let trace = relative.m00 + relative.m11 + relative.m22
  let cosine = (trace - 1.0) / 2.0
  @math.acos(@core.clamp_unit(cosine))
}

///|
pub fn pose_translation_error(
  a : @camera.CameraPose,
  b : @camera.CameraPose,
) -> Double {
  a.camera_center().minus(b.camera_center()).norm()
}

///|
pub fn pose_error(
  a : @camera.CameraPose,
  b : @camera.CameraPose,
) -> (Double, Double) {
  (
    pose_rotation_error(a.rotation(), b.rotation()),
    pose_translation_error(a, b),
  )
}

///|
pub fn baseline_length(
  left : @camera.CameraPose,
  right : @camera.CameraPose,
) -> Double {
  left.camera_center().minus(right.camera_center()).norm()
}

///|
pub fn baseline_is_usable(
  left : @camera.CameraPose,
  right : @camera.CameraPose,
  minimum? : Double = 0.000001,
) -> Bool {
  baseline_length(left, right) >= minimum
}

///|
pub fn depth_statistics(
  points : ArrayView[@core.Point3],
) -> (@core.Point3, Double) raise @core.GeometryError {
  if points.length() == 0 {
    raise @core.GeometryError::NotEnoughPoints("depth statistics need points")
  }
  let values : Array[Double] = []
  for p in points {
    if p.z <= 0.0 {
      raise @core.GeometryError::DegenerateInput("point depth is not positive")
    }
    values.push(p.z)
  }
  (
    @core.Point3::new(
      x=@core.mean(values),
      y=@core.median(values),
      z=@core.max_error(values),
    ),
    @core.variance(values),
  )
}

///|
pub fn positive_depth_mask(points : ArrayView[@core.Point3]) -> Array[Bool] {
  let result : Array[Bool] = []
  for p in points {
    result.push(p.z > 0.0)
  }
  result
}
