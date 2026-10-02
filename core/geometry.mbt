///|
pub(all) struct Line2 {
  normal : Vec2
  offset : Double
} derive(Debug, Eq)

///|
pub fn Line2::from_points(a : Point2, b : Point2) -> Line2 raise GeometryError {
  let direction = a.minus(b)
  let normal = Vec2::new(x=-direction.y, y=direction.x).normalize()
  { normal, offset: -(normal.x * a.x + normal.y * a.y), }
}

///|
pub fn Line2::signed_distance(line : Line2, point : Point2) -> Double {
  line.normal.x * point.x + line.normal.y * point.y + line.offset
}

///|
pub fn Line2::project(line : Line2, point : Point2) -> Point2 {
  point.translate(line.normal.scale(-line.signed_distance(point)))
}

///|
pub fn Line2::intersect(a : Line2, b : Line2) -> Point2? {
  let det = a.normal.x * b.normal.y - a.normal.y * b.normal.x
  if abs(det) <= 0.000000000001 {
    None
  } else {
    Some(
      Point2::new(
        x=(a.normal.y * b.offset - b.normal.y * a.offset) / det,
        y=(b.normal.x * a.offset - a.normal.x * b.offset) / det,
      ),
    )
  }
}

///|
pub(all) struct Plane3 {
  normal : Vec3
  offset : Double
} derive(Debug, Eq)

///|
pub fn Plane3::from_points(
  a : Point3,
  b : Point3,
  c : Point3,
) -> Plane3 raise GeometryError {
  let normal = b.minus(a).cross(c.minus(a)).normalize()
  { normal, offset: -normal.dot(a.to_vec()), }
}

///|
pub fn Plane3::signed_distance(plane : Plane3, point : Point3) -> Double {
  plane.normal.dot(point.to_vec()) + plane.offset
}

///|
pub fn Plane3::project(plane : Plane3, point : Point3) -> Point3 {
  point.translate(plane.normal.scale(-plane.signed_distance(point)))
}

///|
pub fn Plane3::ray_hit(plane : Plane3, ray : Ray3) -> Double? {
  let denominator = plane.normal.dot(ray.direction)
  if abs(denominator) <= 0.000000000001 {
    None
  } else {
    Some(-(plane.normal.dot(ray.origin.to_vec()) + plane.offset) / denominator)
  }
}

///|
pub(all) struct Circle2 {
  center : Point2
  radius : Double
} derive(Debug, Eq)

///|
pub fn Circle2::new(
  center~ : Point2,
  radius~ : Double,
) -> Circle2 raise GeometryError {
  if radius < 0.0 {
    raise GeometryError::DegenerateInput("circle radius must be non-negative")
  }
  { center, radius, }
}

///|
pub fn Circle2::contains(circle : Circle2, point : Point2) -> Bool {
  circle.center.minus(point).norm2() <= circle.radius * circle.radius
}

///|
pub fn Circle2::signed_distance(circle : Circle2, point : Point2) -> Double {
  circle.center.minus(point).norm() - circle.radius
}

///|
pub fn polygon_signed_area(
  points : ArrayView[Point2],
) -> Double raise GeometryError {
  if points.length() < 3 {
    raise GeometryError::NotEnoughPoints("polygon needs at least three points")
  }
  let mut total = 0.0
  for i in 0..<points.length() {
    let next = (i + 1) % points.length()
    total += points[i].x * points[next].y - points[next].x * points[i].y
  }
  total / 2.0
}

///|
pub fn polygon_centroid(
  points : ArrayView[Point2],
) -> Point2 raise GeometryError {
  let area = polygon_signed_area(points)
  if abs(area) <= 0.000000000001 {
    raise GeometryError::DegenerateInput("polygon area must be non-zero")
  }
  let mut x = 0.0
  let mut y = 0.0
  for i in 0..<points.length() {
    let next = (i + 1) % points.length()
    let cross = points[i].x * points[next].y - points[next].x * points[i].y
    x += (points[i].x + points[next].x) * cross
    y += (points[i].y + points[next].y) * cross
  }
  Point2::new(x=x / (6.0 * area), y=y / (6.0 * area))
}

///|
pub fn polyline_length(points : ArrayView[Point2]) -> Double {
  let mut result = 0.0
  if points.length() > 1 {
    for i in 1..<points.length() {
      result += distance3(
        Point3::new(x=points[i].x, y=points[i].y, z=0.0),
        Point3::new(x=points[i - 1].x, y=points[i - 1].y, z=0.0),
      )
    }
  }
  result
}

///|
pub fn closest_point_on_segment(
  a : Point2,
  b : Point2,
  point : Point2,
) -> Point2 {
  let direction = b.minus(a)
  let denominator = direction.norm2()
  if denominator <= 0.000000000001 {
    a
  } else {
    let t = clamp(direction.dot(point.minus(a)), lo=0.0, hi=denominator) /
      denominator
    a.translate(direction.scale(t))
  }
}

///|
pub fn segment_distance(a : Point2, b : Point2, point : Point2) -> Double {
  point.minus(closest_point_on_segment(a, b, point)).norm()
}

///|
pub fn barycentric_2d(
  a : Point2,
  b : Point2,
  c : Point2,
  p : Point2,
) -> (Double, Double, Double) raise GeometryError {
  let v0 = b.minus(a)
  let v1 = c.minus(a)
  let v2 = p.minus(a)
  let denominator = v0.x * v1.y - v1.x * v0.y
  if abs(denominator) <= 0.000000000001 {
    raise GeometryError::DegenerateInput("triangle is degenerate")
  }
  let v = (v2.x * v1.y - v1.x * v2.y) / denominator
  let w = (v0.x * v2.y - v2.x * v0.y) / denominator
  (1.0 - v - w, v, w)
}

///|
pub fn barycentric_contains(
  weights : (Double, Double, Double),
  tolerance? : Double = 0.000000001,
) -> Bool {
  let (a, b, c) = weights
  a >= -tolerance &&
  b >= -tolerance &&
  c >= -tolerance &&
  a <= 1.0 + tolerance &&
  b <= 1.0 + tolerance &&
  c <= 1.0 + tolerance
}
