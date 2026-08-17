///|
/// Sample a continuous camera trajectory at normalized timestamps.
pub fn sample_pose_trajectory(
  poses : ArrayView[CameraPose],
  timestamps : ArrayView[Double],
  query : Double,
) -> CameraPose raise @core.GeometryError {
  if poses.length() == 0 || poses.length() != timestamps.length() {
    raise @core.GeometryError::NotEnoughPoints("trajectory samples are invalid")
  }
  if query <= timestamps[0] {
    return poses[0]
  }
  if query >= timestamps[timestamps.length() - 1] {
    return poses[poses.length() - 1]
  }
  for i in 0..<(timestamps.length() - 1) {
    if query >= timestamps[i] && query <= timestamps[i + 1] {
      let span = timestamps[i + 1] - timestamps[i]
      let amount = if span <= 0.0 {
        0.0
      } else {
        (query - timestamps[i]) / span
      }
      return CameraPose::interpolate(poses[i], poses[i + 1], amount)
    }
  }
  poses[0]
}

///|
pub fn trajectory_duration(timestamps : ArrayView[Double]) -> Double {
  if timestamps.length() < 2 {
    0.0
  } else {
    timestamps[timestamps.length() - 1] - timestamps[0]
  }
}

///|
pub fn trajectory_is_monotonic(timestamps : ArrayView[Double]) -> Bool {
  for i in 1..<timestamps.length() {
    if timestamps[i] < timestamps[i - 1] {
      return false
    }
  }
  true
}

///|
pub fn resample_timestamps(
  start : Double,
  end : Double,
  count : Int,
) -> Array[Double] {
  let result : Array[Double] = []
  if count <= 0 {
    return result
  }
  if count == 1 {
    result.push(start)
    return result
  }
  for i in 0..<count {
    result.push(start + (end - start) * i.to_double() / (count - 1).to_double())
  }
  result
}

///|
pub fn camera_center_path(poses : ArrayView[CameraPose]) -> Array[@core.Point3] {
  let result : Array[@core.Point3] = []
  for pose in poses {
    result.push(pose.camera_center())
  }
  result
}

///|
pub fn path_length(poses : ArrayView[CameraPose]) -> Double {
  let mut length = 0.0
  if poses.length() < 2 {
    return length
  }
  for i in 0..<(poses.length() - 1) {
    length += poses[i]
      .camera_center()
      .minus(poses[i + 1].camera_center())
      .norm()
  }
  length
}
