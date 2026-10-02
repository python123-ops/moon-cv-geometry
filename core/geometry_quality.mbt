///|
/// Test whether a 2D sample is collinear within a metric tolerance.
pub fn is_collinear2(points : ArrayView[Point2], tolerance~ : Double) -> Bool {
  if points.length() < 3 {
    return true
  }
  let origin = points[0]
  let direction = points[1].minus(origin)
  for point in points[2:] {
    let delta = point.minus(origin)
    if abs(direction.x * delta.y - direction.y * delta.x) > tolerance {
      return false
    }
  }
  true
}

///|
pub fn is_collinear3(points : ArrayView[Point3], tolerance~ : Double) -> Bool {
  if points.length() < 3 {
    return true
  }
  let origin = points[0]
  let direction = points[1].minus(origin)
  for point in points[2:] {
    if direction.cross(point.minus(origin)).norm() > tolerance {
      return false
    }
  }
  true
}

///|
pub fn duplicate_count2(points : ArrayView[Point2], tolerance~ : Double) -> Int {
  let mut count = 0
  for i in 0..<points.length() {
    for j in 0..<i {
      if points[i].minus(points[j]).norm() <= tolerance {
        count += 1
        break
      }
    }
  }
  count
}

///|
pub fn duplicate_count3(points : ArrayView[Point3], tolerance~ : Double) -> Int {
  let mut count = 0
  for i in 0..<points.length() {
    for j in 0..<i {
      if points[i].minus(points[j]).norm() <= tolerance {
        count += 1
        break
      }
    }
  }
  count
}

///|
pub fn spread2(points : ArrayView[Point2]) -> Double raise GeometryError {
  if points.length() == 0 {
    raise GeometryError::NotEnoughPoints("spread needs points")
  }
  let center = polygon_centroid(points)
  let mut sum = 0.0
  for point in points {
    let d = point.minus(center).norm()
    sum += d * d
  }
  (sum / points.length().to_double()).sqrt()
}

///|
pub fn spread3(points : ArrayView[Point3]) -> Double raise GeometryError {
  let cloud = PointCloud::from_points(points)
  cloud.rms_radius()
}

///|
pub fn support_ratio2(points : ArrayView[Point2], tolerance : Double) -> Double {
  if points.length() == 0 {
    0.0
  } else {
    (points.length() - duplicate_count2(points, tolerance~)).to_double() /
    points.length().to_double()
  }
}

///|
pub fn support_ratio3(points : ArrayView[Point3], tolerance : Double) -> Double {
  if points.length() == 0 {
    0.0
  } else {
    (points.length() - duplicate_count3(points, tolerance~)).to_double() /
    points.length().to_double()
  }
}

///|
pub fn condition_proxy2(
  points : ArrayView[Point2],
) -> Double raise GeometryError {
  let extent = coordinate_extent2(points)
  if extent <= 0.0 {
    raise GeometryError::DegenerateInput("zero 2D extent")
  }
  let spread = spread2(points)
  spread / extent
}

///|
pub fn condition_proxy3(
  points : ArrayView[Point3],
) -> Double raise GeometryError {
  let extent = coordinate_extent3(points)
  if extent <= 0.0 {
    raise GeometryError::DegenerateInput("zero 3D extent")
  }
  let spread = spread3(points)
  spread / extent
}

///|
pub fn has_area2(points : ArrayView[Point2], minimum_area : Double) -> Bool {
  if points.length() < 3 {
    false
  } else {
    let rect = rect2_from_points(points) catch {
      _ => { min: Point2::new(x=0.0, y=0.0), max: Point2::new(x=0.0, y=0.0), }
    }
    rect.area() >= minimum_area
  }
}

///|
pub fn has_volume3(points : ArrayView[Point3], minimum_volume : Double) -> Bool {
  let box = Aabb3::from_points(points) catch {
    _ =>
      {
        min: Point3::new(x=0.0, y=0.0, z=0.0),
        max: Point3::new(x=0.0, y=0.0, z=0.0),
      }
  }
  box.volume() >= minimum_volume
}

///|
pub fn normalize_quality_score(
  value : Double,
  lower : Double,
  upper : Double,
) -> Double {
  if upper <= lower {
    0.0
  } else {
    ((value - lower) / (upper - lower)).max(0.0).min(1.0)
  }
}

///|
pub fn combine_quality_scores(
  scores : ArrayView[Double],
  weights : ArrayView[Double],
) -> Double raise GeometryError {
  weighted_mean2(scores, weights)
}
