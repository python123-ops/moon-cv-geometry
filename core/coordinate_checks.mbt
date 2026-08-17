///|
/// Coordinate-system checks shared by camera and multiview entry points.
pub fn finite_vec2(v : Vec2) -> Bool {
  v.x == v.x && v.y == v.y
}

///|
pub fn finite_vec3(v : Vec3) -> Bool {
  v.x == v.x && v.y == v.y && v.z == v.z
}

///|
pub fn coordinate_finite_point2(p : Point2) -> Bool {
  p.x == p.x && p.y == p.y
}

///|
pub fn coordinate_finite_point3(p : Point3) -> Bool {
  p.x == p.x && p.y == p.y && p.z == p.z
}

///|
pub fn points2_are_finite(points : ArrayView[Point2]) -> Bool {
  for point in points {
    if !coordinate_finite_point2(point) {
      return false
    }
  }
  true
}

///|
pub fn points3_are_finite(points : ArrayView[Point3]) -> Bool {
  for point in points {
    if !coordinate_finite_point3(point) {
      return false
    }
  }
  true
}

///|
pub fn vectors3_are_nonzero(
  vectors : ArrayView[Vec3],
  tolerance : Double,
) -> Bool {
  for vector in vectors {
    if vector.norm() <= tolerance {
      return false
    }
  }
  true
}

///|
pub fn normalize_points2(
  points : ArrayView[Point2],
) -> Array[Point2] raise GeometryError {
  if points.length() == 0 {
    raise GeometryError::NotEnoughPoints("normalization needs points")
  }
  let center = polygon_centroid(points)
  let result : Array[Point2] = []
  let mut scale = 0.0
  for point in points {
    scale += point.minus(center).norm()
  }
  let divisor = (scale / points.length().to_double()).max(0.000000000001)
  for point in points {
    result.push(
      Point2::new(
        x=(point.x - center.x) / divisor,
        y=(point.y - center.y) / divisor,
      ),
    )
  }
  result
}

///|
pub fn normalize_points3(
  points : ArrayView[Point3],
) -> Array[Point3] raise GeometryError {
  if points.length() == 0 {
    raise GeometryError::NotEnoughPoints("normalization needs points")
  }
  let center = centroid3(points)
  let result : Array[Point3] = []
  let mut scale = 0.0
  for point in points {
    scale += point.minus(center).norm()
  }
  let divisor = (scale / points.length().to_double()).max(0.000000000001)
  for point in points {
    result.push(
      Point3::new(
        x=(point.x - center.x) / divisor,
        y=(point.y - center.y) / divisor,
        z=(point.z - center.z) / divisor,
      ),
    )
  }
  result
}

///|
pub fn coordinate_extent2(
  points : ArrayView[Point2],
) -> Double raise GeometryError {
  let rect = rect2_from_points(points)
  rect.min.minus(rect.max).norm()
}

///|
pub fn coordinate_extent3(
  points : ArrayView[Point3],
) -> Double raise GeometryError {
  let box = Aabb3::from_points(points)
  box.max.minus(box.min).norm()
}
