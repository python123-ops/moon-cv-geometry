///|
pub fn Ray3::new(
  origin~ : Point3,
  direction~ : Vec3,
) -> Ray3 raise GeometryError {
  { origin, direction: direction.normalize(), }
}

///|
pub fn Ray3::point_at(ray : Ray3, depth : Double) -> Point3 {
  ray.origin.translate(ray.direction.scale(depth))
}

///|
pub fn Ray3::closest_midpoint(a : Ray3, b : Ray3) -> Point3 raise GeometryError {
  let w0 = a.origin.minus(b.origin)
  let aa = a.direction.dot(a.direction)
  let bb = a.direction.dot(b.direction)
  let cc = b.direction.dot(b.direction)
  let dd = a.direction.dot(w0)
  let ee = b.direction.dot(w0)
  let denom = aa * cc - bb * bb
  if abs(denom) <= 0.000000000001 {
    raise GeometryError::DegenerateInput("rays are parallel or nearly parallel")
  }
  let depth_a = (bb * ee - cc * dd) / denom
  let depth_b = (aa * ee - bb * dd) / denom
  let pa = a.point_at(depth_a)
  let pb = b.point_at(depth_b)
  Point3::new(
    x=(pa.x + pb.x) / 2.0,
    y=(pa.y + pb.y) / 2.0,
    z=(pa.z + pb.z) / 2.0,
  )
}

///|
pub fn Ray3::closest_separation(
  a : Ray3,
  b : Ray3,
) -> Double raise GeometryError {
  let p = a.closest_midpoint(b)
  let da = p.minus(a.origin).dot(a.direction)
  let db = p.minus(b.origin).dot(b.direction)
  distance3(a.point_at(da), b.point_at(db))
}
