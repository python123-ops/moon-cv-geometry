///|
pub(all) struct CameraPair {
  left : @camera.CameraPose
  right : @camera.CameraPose
  intrinsics_left : @camera.CameraIntrinsics
  intrinsics_right : @camera.CameraIntrinsics
} derive(Debug, Eq)

///|
pub fn CameraPair::new(
  left~ : @camera.CameraPose,
  right~ : @camera.CameraPose,
  intrinsics_left~ : @camera.CameraIntrinsics,
  intrinsics_right~ : @camera.CameraIntrinsics,
) -> CameraPair {
  { left, right, intrinsics_left, intrinsics_right, }
}

///|
pub fn CameraPair::bearings(
  pair : CameraPair,
  left_pixel : @core.Point2,
  right_pixel : @core.Point2,
) -> (@core.Ray3, @core.Ray3) raise @core.GeometryError {
  let a = @camera.bearing_from_pixel(left_pixel, pair.intrinsics_left)
  let b = @camera.bearing_from_pixel(right_pixel, pair.intrinsics_right)
  let left_ray = @core.Ray3::new(
    origin=@core.Point3::new(x=0.0, y=0.0, z=0.0),
    direction=a,
  )
  let right_origin = @core.Point3::new(
    x=-pair.right.world_to_camera.m03,
    y=-pair.right.world_to_camera.m13,
    z=-pair.right.world_to_camera.m23,
  )
  let right_direction = @core.Vec3::new(x=b.x, y=b.y, z=b.z)
  (left_ray, @core.Ray3::new(origin=right_origin, direction=right_direction))
}

///|
pub(all) struct TrackObservation {
  point_id : Int
  pixel : @core.Point2
  view_id : Int
} derive(Debug, Eq)

///|
pub fn TrackObservation::new(
  point_id~ : Int,
  pixel~ : @core.Point2,
  view_id~ : Int,
) -> TrackObservation {
  { point_id, pixel, view_id, }
}

///|
pub fn residual_vector(
  predicted : ArrayView[@core.Point2],
  observed : ArrayView[@core.Point2],
) -> Array[Double] raise @core.GeometryError {
  if predicted.length() != observed.length() {
    raise @core.GeometryError::DegenerateInput(
      "residual vectors need paired arrays",
    )
  }
  let result : Array[Double] = []
  for i in 0..<predicted.length() {
    let d = predicted[i].minus(observed[i])
    result.push(d.x)
    result.push(d.y)
  }
  result
}

///|
pub fn total_reprojection_error(
  predicted : ArrayView[@core.Point2],
  observed : ArrayView[@core.Point2],
) -> Double raise @core.GeometryError {
  if predicted.length() != observed.length() {
    raise @core.GeometryError::DegenerateInput("error needs paired arrays")
  }
  if predicted.length() == 0 {
    raise @core.GeometryError::NotEnoughPoints("error needs observations")
  }
  let mut total = 0.0
  for i in 0..<predicted.length() {
    total += predicted[i].minus(observed[i]).norm()
  }
  total / Double::from_int(predicted.length())
}

///|
pub fn homography_condition_indicator(h : Homography) -> Double {
  let a = h.matrix.m00 * h.matrix.m00 +
    h.matrix.m01 * h.matrix.m01 +
    h.matrix.m02 * h.matrix.m02
  let b = h.matrix.m10 * h.matrix.m10 +
    h.matrix.m11 * h.matrix.m11 +
    h.matrix.m12 * h.matrix.m12
  let c = h.matrix.m20 * h.matrix.m20 +
    h.matrix.m21 * h.matrix.m21 +
    h.matrix.m22 * h.matrix.m22
  let largest = if a > b {
    if a > c {
      a
    } else {
      c
    }
  } else if b > c {
    b
  } else {
    c
  }
  let smallest = if a < b {
    if a < c {
      a
    } else {
      c
    }
  } else if b < c {
    b
  } else {
    c
  }
  if smallest <= 0.000000000001 {
    1.0e100
  } else {
    (largest / smallest).sqrt()
  }
}

///|
pub fn epipolar_residuals(
  f : FundamentalMatrix,
  left : ArrayView[@core.Point2],
  right : ArrayView[@core.Point2],
) -> Array[Double] raise @core.GeometryError {
  if left.length() != right.length() {
    raise @core.GeometryError::DegenerateInput(
      "epipolar residuals need paired points",
    )
  }
  let values : Array[Double] = []
  for i in 0..<left.length() {
    values.push(epipolar_residual(f, left[i], right[i]))
  }
  values
}

///|
pub fn sampson_residuals(
  f : FundamentalMatrix,
  left : ArrayView[@core.Point2],
  right : ArrayView[@core.Point2],
) -> Array[Double] raise @core.GeometryError {
  if left.length() != right.length() {
    raise @core.GeometryError::DegenerateInput(
      "Sampson residuals need paired points",
    )
  }
  let values : Array[Double] = []
  for i in 0..<left.length() {
    values.push(sampson_error(f, left[i], right[i]).sqrt())
  }
  values
}

///|
pub fn triangulation_quality(
  result : TriangulatedPoint,
  angle : Double,
  separation_limit : Double,
) -> Double {
  if result.separation > separation_limit || angle <= 0.0 {
    0.0
  } else {
    angle / (angle + result.separation + 0.000000000001)
  }
}

///|
pub fn triangulate_many(
  left : ArrayView[@core.Ray3],
  right : ArrayView[@core.Ray3],
) -> Array[TriangulatedPoint] raise @core.GeometryError {
  if left.length() != right.length() {
    raise @core.GeometryError::DegenerateInput(
      "triangulation needs paired rays",
    )
  }
  let result : Array[TriangulatedPoint] = []
  for i in 0..<left.length() {
    result.push(triangulate_from_rays(left[i], right[i]))
  }
  result
}

///|
pub fn cheirality_mask(
  points : ArrayView[TriangulatedPoint],
  left : ArrayView[@core.Ray3],
  right : ArrayView[@core.Ray3],
) -> Array[Bool] raise @core.GeometryError {
  if points.length() != left.length() || left.length() != right.length() {
    raise @core.GeometryError::DegenerateInput(
      "cheirality inputs must have equal length",
    )
  }
  let mask : Array[Bool] = []
  for i in 0..<points.length() {
    mask.push(triangulated_point_is_in_front(points[i], left[i], right[i]))
  }
  mask
}

///|
pub fn count_true(values : ArrayView[Bool]) -> Int {
  let mut count = 0
  for value in values {
    if value {
      count += 1
    }
  }
  count
}

///|
pub fn pose_depth(point : @core.Point3, pose : @camera.CameraPose) -> Double {
  pose.world_to_camera.m20 * point.x +
  pose.world_to_camera.m21 * point.y +
  pose.world_to_camera.m22 * point.z +
  pose.world_to_camera.m23
}

///|
pub fn is_visible(
  point : @core.Point3,
  pose : @camera.CameraPose,
  near? : Double = 0.000001,
) -> Bool {
  pose_depth(point, pose) > near
}

///|
pub fn visible_points(
  points : ArrayView[@core.Point3],
  pose : @camera.CameraPose,
  near? : Double = 0.000001,
) -> Array[Bool] {
  let mask : Array[Bool] = []
  for point in points {
    mask.push(is_visible(point, pose, near~))
  }
  mask
}
