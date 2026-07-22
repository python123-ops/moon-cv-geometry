///|
pub fn Rect2::new(min~ : Point2, max~ : Point2) -> Rect2 raise GeometryError {
  if max.x < min.x || max.y < min.y {
    raise GeometryError::DegenerateInput(
      "Rect2 max corner must not be smaller than min corner",
    )
  }
  { min, max }
}

///|
pub fn Rect2::from_center_size(
  center~ : Point2,
  width~ : Double,
  height~ : Double,
) -> Rect2 raise GeometryError {
  if width < 0.0 || height < 0.0 {
    raise GeometryError::DegenerateInput("Rect2 size must be non-negative")
  }
  let half_w = width / 2.0
  let half_h = height / 2.0
  Rect2::new(
    min=Point2::new(x=center.x - half_w, y=center.y - half_h),
    max=Point2::new(x=center.x + half_w, y=center.y + half_h),
  )
}

///|
pub fn rect2_from_points(
  points : ArrayView[Point2],
) -> Rect2 raise GeometryError {
  if points.length() == 0 {
    raise GeometryError::NotEnoughPoints("Rect2 needs at least one point")
  }
  let first = points[0]
  let mut min_x = first.x
  let mut min_y = first.y
  let mut max_x = first.x
  let mut max_y = first.y
  for i in 1..<points.length() {
    let p = points[i]
    if p.x < min_x {
      min_x = p.x
    }
    if p.y < min_y {
      min_y = p.y
    }
    if p.x > max_x {
      max_x = p.x
    }
    if p.y > max_y {
      max_y = p.y
    }
  }
  Rect2::new(
    min=Point2::new(x=min_x, y=min_y),
    max=Point2::new(x=max_x, y=max_y),
  )
}

///|
pub fn Rect2::width(rect : Rect2) -> Double {
  rect.max.x - rect.min.x
}

///|
pub fn Rect2::height(rect : Rect2) -> Double {
  rect.max.y - rect.min.y
}

///|
pub fn Rect2::area(rect : Rect2) -> Double {
  rect.width() * rect.height()
}

///|
pub fn Rect2::center(rect : Rect2) -> Point2 {
  Point2::new(
    x=(rect.min.x + rect.max.x) / 2.0,
    y=(rect.min.y + rect.max.y) / 2.0,
  )
}

///|
pub fn Rect2::contains(rect : Rect2, p : Point2) -> Bool {
  p.x >= rect.min.x &&
  p.x <= rect.max.x &&
  p.y >= rect.min.y &&
  p.y <= rect.max.y
}

///|
pub fn Rect2::expand(
  rect : Rect2,
  margin : Double,
) -> Rect2 raise GeometryError {
  Rect2::new(
    min=Point2::new(x=rect.min.x - margin, y=rect.min.y - margin),
    max=Point2::new(x=rect.max.x + margin, y=rect.max.y + margin),
  )
}

///|
pub fn Rect2::union(a : Rect2, b : Rect2) -> Rect2 {
  Rect2::{
    min: Point2::new(
      x=if a.min.x < b.min.x { a.min.x } else { b.min.x },
      y=if a.min.y < b.min.y { a.min.y } else { b.min.y },
    ),
    max: Point2::new(
      x=if a.max.x > b.max.x { a.max.x } else { b.max.x },
      y=if a.max.y > b.max.y { a.max.y } else { b.max.y },
    ),
  }
}

///|
pub fn Rect2::intersection(a : Rect2, b : Rect2) -> Rect2? {
  let min_x = if a.min.x > b.min.x { a.min.x } else { b.min.x }
  let min_y = if a.min.y > b.min.y { a.min.y } else { b.min.y }
  let max_x = if a.max.x < b.max.x { a.max.x } else { b.max.x }
  let max_y = if a.max.y < b.max.y { a.max.y } else { b.max.y }
  if max_x < min_x || max_y < min_y {
    None
  } else {
    Some(Rect2::{
      min: Point2::new(x=min_x, y=min_y),
      max: Point2::new(x=max_x, y=max_y),
    })
  }
}
