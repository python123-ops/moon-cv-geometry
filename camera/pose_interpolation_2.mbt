///|
/// Interpolate camera poses with endpoint clamping.
pub fn interpolate_camera_pose_clamped(
  a : CameraPose,
  b : CameraPose,
  amount : Double,
) -> CameraPose {
  CameraPose::interpolate(a, b, amount.max(0.0).min(1.0))
}

///|
pub fn sample_camera_poses(
  poses : ArrayView[CameraPose],
  count : Int,
) -> Array[CameraPose] {
  let result : Array[CameraPose] = []
  if poses.length() == 0 || count <= 0 {
    return result
  }
  if poses.length() == 1 {
    for _ in 0..<count {
      result.push(poses[0])
    }
    return result
  }
  for i in 0..<count {
    let amount = if count == 1 {
      0.0
    } else {
      i.to_double() / (count - 1).to_double()
    }
    result.push(sample_camera_pose(poses, amount))
  }
  result
}

///|
pub fn sample_camera_pose(
  poses : ArrayView[CameraPose],
  amount : Double,
) -> CameraPose {
  if poses.length() == 0 {
    return CameraPose::identity()
  }
  if poses.length() == 1 {
    return poses[0]
  }
  let position = amount.max(0.0).min(1.0) * (poses.length() - 1).to_double()
  let lower = position.floor().to_int().min(poses.length() - 1)
  let upper = position.ceil().to_int().min(poses.length() - 1)
  if lower == upper {
    poses[lower]
  } else {
    CameraPose::interpolate(
      poses[lower],
      poses[upper],
      position - lower.to_double(),
    )
  }
}

///|
pub fn pose_translation_distance(a : CameraPose, b : CameraPose) -> Double {
  a.camera_center().minus(b.camera_center()).norm()
}

///|
pub fn pose_path_distances(poses : ArrayView[CameraPose]) -> Array[Double] {
  let result : Array[Double] = []
  if poses.length() < 2 {
    return result
  }
  for i in 0..<(poses.length() - 1) {
    result.push(pose_translation_distance(poses[i], poses[i + 1]))
  }
  result
}

///|
pub fn pose_path_length2(poses : ArrayView[CameraPose]) -> Double {
  let mut result = 0.0
  for distance in pose_path_distances(poses) {
    result += distance
  }
  result
}

///|
pub fn pose_speed_estimates(
  poses : ArrayView[CameraPose],
  timestamps : ArrayView[Double],
) -> Array[Double] {
  let result : Array[Double] = []
  let distances = pose_path_distances(poses)
  let count = distances.length().min((timestamps.length() - 1).max(0))
  for i in 0..<count {
    let duration = timestamps[i + 1] - timestamps[i]
    result.push(if duration <= 0.0 { 0.0 } else { distances[i] / duration })
  }
  result
}

///|
pub fn pose_is_stationary(
  poses : ArrayView[CameraPose],
  tolerance : Double,
) -> Bool {
  for distance in pose_path_distances(poses) {
    if distance > tolerance {
      return false
    }
  }
  true
}

///|
pub fn pose_subsequence(
  poses : ArrayView[CameraPose],
  start : Int,
  end : Int,
) -> Array[CameraPose] {
  let result : Array[CameraPose] = []
  let lower = start.max(0).min(poses.length())
  let upper = end.max(lower).min(poses.length())
  for i in lower..<upper {
    result.push(poses[i])
  }
  result
}

///|
pub fn reverse_pose_sequence(
  poses : ArrayView[CameraPose],
) -> Array[CameraPose] {
  let result : Array[CameraPose] = []
  for i in 0..<poses.length() {
    result.push(poses[poses.length() - i - 1])
  }
  result
}

///|
pub fn duplicate_pose_sequence(
  poses : ArrayView[CameraPose],
  repetitions : Int,
) -> Array[CameraPose] {
  let result : Array[CameraPose] = []
  for _ in 0..<repetitions.max(0) {
    for pose in poses {
      result.push(pose)
    }
  }
  result
}
