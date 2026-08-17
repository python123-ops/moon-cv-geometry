///|
pub(all) struct CalibrationGrid {
  columns : Int
  rows : Int
  spacing : Double
} derive(Debug, Eq)

///|
pub fn CalibrationGrid::new(
  columns~ : Int,
  rows~ : Int,
  spacing~ : Double,
) -> CalibrationGrid raise @core.GeometryError {
  if columns <= 0 || rows <= 0 || spacing <= 0.0 {
    raise @core.GeometryError::DegenerateInput(
      "calibration grid dimensions are invalid",
    )
  }
  { columns, rows, spacing }
}

///|
pub fn CalibrationGrid::length(grid : CalibrationGrid) -> Int {
  grid.columns * grid.rows
}

///|
pub fn CalibrationGrid::points(grid : CalibrationGrid) -> Array[@core.Point3] {
  let result : Array[@core.Point3] = []
  for row in 0..<grid.rows {
    for column in 0..<grid.columns {
      result.push(
        @core.Point3::new(
          x=Double::from_int(column) * grid.spacing,
          y=Double::from_int(row) * grid.spacing,
          z=0.0,
        ),
      )
    }
  }
  result
}

///|
pub fn CalibrationGrid::bounds(
  grid : CalibrationGrid,
) -> @core.Rect2 raise @core.GeometryError {
  @core.rect2_from_points(
    grid.points().map(fn(p) { @core.Point2::new(x=p.x, y=p.y) }),
  )
}

///|
pub fn CalibrationGrid::coverage(
  grid : CalibrationGrid,
  size : ImageSize,
  intrinsics : CameraIntrinsics,
) -> Double raise @core.GeometryError {
  let bounds = grid.bounds()
  let pixel_min = normalized_to_pixel(bounds.min, intrinsics)
  let pixel_max = normalized_to_pixel(bounds.max, intrinsics)
  let image_area = Double::from_int(size.width * size.height)
  let width = if pixel_max.x > pixel_min.x {
    pixel_max.x - pixel_min.x
  } else {
    pixel_min.x - pixel_max.x
  }
  let height = if pixel_max.y > pixel_min.y {
    pixel_max.y - pixel_min.y
  } else {
    pixel_min.y - pixel_max.y
  }
  let area = width * height
  if image_area <= 0.0 {
    0.0
  } else if area > image_area {
    1.0
  } else {
    area / image_area
  }
}

///|
pub fn CalibrationGrid::world_point(
  grid : CalibrationGrid,
  index : Int,
) -> @core.Point3 raise @core.GeometryError {
  if index < 0 || index >= grid.length() {
    raise @core.GeometryError::DegenerateInput(
      "calibration grid index out of range",
    )
  }
  let row = index / grid.columns
  let column = index % grid.columns
  @core.Point3::new(
    x=Double::from_int(column) * grid.spacing,
    y=Double::from_int(row) * grid.spacing,
    z=0.0,
  )
}

///|
pub fn ray_bundle(
  pixels : ArrayView[@core.Point2],
  intrinsics : CameraIntrinsics,
) -> Array[@core.Vec3] raise @core.GeometryError {
  let result : Array[@core.Vec3] = []
  for pixel in pixels {
    result.push(bearing_from_pixel(pixel, intrinsics))
  }
  result
}
