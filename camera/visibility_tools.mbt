///|
/// Visibility masks for image-space and depth-space filtering.
pub fn visible_pixels(
  size : ImageSize,
  pixels : ArrayView[@core.Point2],
) -> Array[Bool] {
  let result : Array[Bool] = []
  for pixel in pixels {
    result.push(
      pixel.x >= 0.0 &&
      pixel.y >= 0.0 &&
      pixel.x < size.width.to_double() &&
      pixel.y < size.height.to_double(),
    )
  }
  result
}

///|
pub fn visible_depths(
  depths : ArrayView[Double],
  minimum : Double,
  maximum : Double,
) -> Array[Bool] {
  let result : Array[Bool] = []
  for depth in depths {
    result.push(depth == depth && depth >= minimum && depth <= maximum)
  }
  result
}

///|
pub fn valid_projection_count(points : ArrayView[@core.Point3]) -> Int {
  let mut count = 0
  for point in points {
    if point.z > 0.000000000001 {
      count += 1
    }
  }
  count
}

///|
pub fn front_facing_ratio(points : ArrayView[@core.Point3]) -> Double {
  if points.length() == 0 {
    0.0
  } else {
    valid_projection_count(points).to_double() / points.length().to_double()
  }
}

///|
pub fn crop_pixels(
  pixels : ArrayView[@core.Point2],
  size : ImageSize,
) -> Array[@core.Point2] {
  let result : Array[@core.Point2] = []
  for pixel in pixels {
    if pixel.x >= 0.0 &&
      pixel.y >= 0.0 &&
      pixel.x < size.width.to_double() &&
      pixel.y < size.height.to_double() {
      result.push(pixel)
    }
  }
  result
}

///|
pub fn clamp_visible_pixel(
  pixel : @core.Point2,
  size : ImageSize,
) -> @core.Point2 {
  @core.Point2::new(
    x=pixel.x.max(0.0).min(size.width.to_double() - 1.0),
    y=pixel.y.max(0.0).min(size.height.to_double() - 1.0),
  )
}

///|
pub fn image_margin(pixel : @core.Point2, size : ImageSize) -> Double {
  pixel.x
  .min(pixel.y)
  .min(size.width.to_double() - 1.0 - pixel.x)
  .min(size.height.to_double() - 1.0 - pixel.y)
}
