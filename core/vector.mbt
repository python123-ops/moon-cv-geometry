///|
pub fn Point2::to_vec(p : Point2) -> Vec2 {
  Vec2::new(x=p.x, y=p.y)
}

///|
pub fn Point2::translate(p : Point2, v : Vec2) -> Point2 {
  Point2::new(x=p.x + v.x, y=p.y + v.y)
}

///|
pub fn Point2::minus(a : Point2, b : Point2) -> Vec2 {
  Vec2::new(x=a.x - b.x, y=a.y - b.y)
}

///|
pub fn Point3::to_vec(p : Point3) -> Vec3 {
  Vec3::new(x=p.x, y=p.y, z=p.z)
}

///|
pub fn Vec2::add(a : Vec2, b : Vec2) -> Vec2 {
  Vec2::new(x=a.x + b.x, y=a.y + b.y)
}

///|
pub fn Vec2::sub(a : Vec2, b : Vec2) -> Vec2 {
  Vec2::new(x=a.x - b.x, y=a.y - b.y)
}

///|
pub fn Vec2::scale(v : Vec2, s : Double) -> Vec2 {
  Vec2::new(x=v.x * s, y=v.y * s)
}

///|
pub fn Vec2::dot(a : Vec2, b : Vec2) -> Double {
  a.x * b.x + a.y * b.y
}

///|
pub fn Vec2::norm2(v : Vec2) -> Double {
  v.dot(v)
}

///|
pub fn Vec2::norm(v : Vec2) -> Double {
  v.norm2().sqrt()
}

///|
pub fn Vec2::normalize(v : Vec2) -> Vec2 raise GeometryError {
  let n = v.norm()
  if n <= 0.000000000001 {
    raise GeometryError::DegenerateInput("cannot normalize a zero-length Vec2")
  }
  v.scale(1.0 / n)
}

///|
pub fn Vec3::add(a : Vec3, b : Vec3) -> Vec3 {
  Vec3::new(x=a.x + b.x, y=a.y + b.y, z=a.z + b.z)
}

///|
pub fn Vec3::sub(a : Vec3, b : Vec3) -> Vec3 {
  Vec3::new(x=a.x - b.x, y=a.y - b.y, z=a.z - b.z)
}

///|
pub fn Vec3::scale(v : Vec3, s : Double) -> Vec3 {
  Vec3::new(x=v.x * s, y=v.y * s, z=v.z * s)
}

///|
pub fn Vec3::dot(a : Vec3, b : Vec3) -> Double {
  a.x * b.x + a.y * b.y + a.z * b.z
}

///|
pub fn Vec3::cross(a : Vec3, b : Vec3) -> Vec3 {
  Vec3::new(
    x=a.y * b.z - a.z * b.y,
    y=a.z * b.x - a.x * b.z,
    z=a.x * b.y - a.y * b.x,
  )
}

///|
pub fn Vec3::norm2(v : Vec3) -> Double {
  v.dot(v)
}

///|
pub fn Vec3::norm(v : Vec3) -> Double {
  v.norm2().sqrt()
}

///|
pub fn Vec3::normalize(v : Vec3) -> Vec3 raise GeometryError {
  let n = v.norm()
  if n <= 0.000000000001 {
    raise GeometryError::DegenerateInput("cannot normalize a zero-length Vec3")
  }
  v.scale(1.0 / n)
}

///|
pub fn distance2(a : Point2, b : Point2) -> Double {
  a.minus(b).norm()
}

///|
pub fn reprojection_error(a : Point2, b : Point2) -> Double {
  distance2(a, b)
}
