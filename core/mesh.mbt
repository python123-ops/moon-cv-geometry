///|
pub(all) struct Triangle3 {
  a : Point3
  b : Point3
  c : Point3
} derive(Debug, Eq)

///|
pub fn Triangle3::new(a~ : Point3, b~ : Point3, c~ : Point3) -> Triangle3 {
  { a, b, c, }
}

///|
pub fn Triangle3::normal(t : Triangle3) -> Vec3 raise GeometryError {
  t.b.minus(t.a).cross(t.c.minus(t.a)).normalize()
}

///|
pub fn Triangle3::area(t : Triangle3) -> Double {
  t.b.minus(t.a).cross(t.c.minus(t.a)).norm() / 2.0
}

///|
pub fn Triangle3::centroid(t : Triangle3) -> Point3 {
  Point3::new(
    x=(t.a.x + t.b.x + t.c.x) / 3.0,
    y=(t.a.y + t.b.y + t.c.y) / 3.0,
    z=(t.a.z + t.b.z + t.c.z) / 3.0,
  )
}

///|
pub fn Triangle3::barycentric(
  t : Triangle3,
  p : Point3,
) -> (Double, Double, Double) raise GeometryError {
  let n = t.normal()
  let area = t.area()
  if area <= 0.000000000001 {
    raise GeometryError::DegenerateInput("triangle has zero area")
  }
  let a = Triangle3::new(a=p, b=t.b, c=t.c).bary_area(n) / area
  let b = Triangle3::new(a=t.a, b=p, c=t.c).bary_area(n) / area
  let c = Triangle3::new(a=t.a, b=t.b, c=p).bary_area(n) / area
  (a, b, c)
}

///|
fn Triangle3::bary_area(t : Triangle3, normal : Vec3) -> Double {
  t.b.minus(t.a).cross(t.c.minus(t.a)).dot(normal).abs() / 2.0
}

///|
pub fn barycentric3_contains(
  weights : (Double, Double, Double),
  tolerance? : Double = 0.000001,
) -> Bool {
  let (a, b, c) = weights
  a >= -tolerance &&
  b >= -tolerance &&
  c >= -tolerance &&
  a <= 1.0 + tolerance &&
  b <= 1.0 + tolerance &&
  c <= 1.0 + tolerance
}

///|
pub fn triangle_plane_distance(
  t : Triangle3,
  point : Point3,
) -> Double raise GeometryError {
  abs(t.normal().dot(point.minus(t.a)))
}

///|
pub fn closest_point_on_triangle(
  t : Triangle3,
  point : Point3,
) -> Point3 raise GeometryError {
  let weights = t.barycentric(point)
  if barycentric3_contains(weights) {
    point
  } else {
    let p0 = closest_point_on_segment(
      Point2::new(x=t.a.x, y=t.a.y),
      Point2::new(x=t.b.x, y=t.b.y),
      Point2::new(x=point.x, y=point.y),
    )
    let p1 = closest_point_on_segment(
      Point2::new(x=t.b.x, y=t.b.y),
      Point2::new(x=t.c.x, y=t.c.y),
      Point2::new(x=point.x, y=point.y),
    )
    let p2 = closest_point_on_segment(
      Point2::new(x=t.c.x, y=t.c.y),
      Point2::new(x=t.a.x, y=t.a.y),
      Point2::new(x=point.x, y=point.y),
    )
    let d0 = distance3(Point3::new(x=p0.x, y=p0.y, z=point.z), point)
    let d1 = distance3(Point3::new(x=p1.x, y=p1.y, z=point.z), point)
    let d2 = distance3(Point3::new(x=p2.x, y=p2.y, z=point.z), point)
    if d0 < d1 {
      if d0 < d2 {
        Point3::new(x=p0.x, y=p0.y, z=point.z)
      } else {
        Point3::new(x=p2.x, y=p2.y, z=point.z)
      }
    } else if d1 < d2 {
      Point3::new(x=p1.x, y=p1.y, z=point.z)
    } else {
      Point3::new(x=p2.x, y=p2.y, z=point.z)
    }
  }
}

///|
pub(all) struct Aabb3 {
  min : Point3
  max : Point3
} derive(Debug, Eq)

///|
pub fn Aabb3::from_points(
  points : ArrayView[Point3],
) -> Aabb3 raise GeometryError {
  if points.length() == 0 {
    raise GeometryError::NotEnoughPoints("Aabb3 needs points")
  }
  let first = points[0]
  let mut min_x = first.x
  let mut min_y = first.y
  let mut min_z = first.z
  let mut max_x = first.x
  let mut max_y = first.y
  let mut max_z = first.z
  for p in points {
    if p.x < min_x {
      min_x = p.x
    }
    if p.y < min_y {
      min_y = p.y
    }
    if p.z < min_z {
      min_z = p.z
    }
    if p.x > max_x {
      max_x = p.x
    }
    if p.y > max_y {
      max_y = p.y
    }
    if p.z > max_z {
      max_z = p.z
    }
  }
  {
    min: Point3::new(x=min_x, y=min_y, z=min_z),
    max: Point3::new(x=max_x, y=max_y, z=max_z),
  }
}

///|
pub fn Aabb3::contains(box : Aabb3, p : Point3) -> Bool {
  p.x >= box.min.x &&
  p.x <= box.max.x &&
  p.y >= box.min.y &&
  p.y <= box.max.y &&
  p.z >= box.min.z &&
  p.z <= box.max.z
}

///|
pub fn Aabb3::volume(box : Aabb3) -> Double {
  (box.max.x - box.min.x) * (box.max.y - box.min.y) * (box.max.z - box.min.z)
}

///|
pub fn Aabb3::center(box : Aabb3) -> Point3 {
  Point3::new(
    x=(box.min.x + box.max.x) / 2.0,
    y=(box.min.y + box.max.y) / 2.0,
    z=(box.min.z + box.max.z) / 2.0,
  )
}

///|
pub fn Aabb3::expand(box : Aabb3, margin : Double) -> Aabb3 {
  {
    min: Point3::new(
      x=box.min.x - margin,
      y=box.min.y - margin,
      z=box.min.z - margin,
    ),
    max: Point3::new(
      x=box.max.x + margin,
      y=box.max.y + margin,
      z=box.max.z + margin,
    ),
  }
}
