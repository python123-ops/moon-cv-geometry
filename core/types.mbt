///|
pub(all) suberror GeometryError {
  DegenerateInput(String)
  NotEnoughPoints(String)
} derive(Debug, Eq)

///|
pub(all) struct Point2 {
  x : Double
  y : Double
} derive(Debug, Eq)

///|
pub fn Point2::new(x~ : Double, y~ : Double) -> Point2 {
  { x, y, }
}

///|
pub(all) struct Point3 {
  x : Double
  y : Double
  z : Double
} derive(Debug, Eq)

///|
pub fn Point3::new(x~ : Double, y~ : Double, z~ : Double) -> Point3 {
  { x, y, z, }
}

///|
pub(all) struct Vec2 {
  x : Double
  y : Double
} derive(Debug, Eq)

///|
pub fn Vec2::new(x~ : Double, y~ : Double) -> Vec2 {
  { x, y, }
}

///|
pub(all) struct Vec3 {
  x : Double
  y : Double
  z : Double
} derive(Debug, Eq)

///|
pub fn Vec3::new(x~ : Double, y~ : Double, z~ : Double) -> Vec3 {
  { x, y, z, }
}

///|
pub(all) struct Mat3 {
  m00 : Double
  m01 : Double
  m02 : Double
  m10 : Double
  m11 : Double
  m12 : Double
  m20 : Double
  m21 : Double
  m22 : Double
} derive(Debug, Eq)

///|
pub(all) struct Mat34 {
  m00 : Double
  m01 : Double
  m02 : Double
  m03 : Double
  m10 : Double
  m11 : Double
  m12 : Double
  m13 : Double
  m20 : Double
  m21 : Double
  m22 : Double
  m23 : Double
} derive(Debug, Eq)

///|
pub(all) struct Ray3 {
  origin : Point3
  direction : Vec3
} derive(Debug, Eq)

///|
pub(all) struct Rect2 {
  min : Point2
  max : Point2
} derive(Debug, Eq)
