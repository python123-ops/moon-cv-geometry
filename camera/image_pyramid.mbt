///|
/// One level of an image-coordinate pyramid.
pub(all) struct ImageLevel {
  scale : Double
  size : ImageSize
  intrinsics : CameraIntrinsics
}

///|
pub fn ImageLevel::new(
  scale~ : Double,
  size~ : ImageSize,
  intrinsics~ : CameraIntrinsics,
) -> ImageLevel {
  { scale, size, intrinsics, }
}

///|
pub fn ImageLevel::pixel_to_base(
  level : ImageLevel,
  pixel : @core.Point2,
) -> @core.Point2 {
  @core.Point2::new(x=pixel.x / level.scale, y=pixel.y / level.scale)
}

///|
pub fn ImageLevel::base_to_pixel(
  level : ImageLevel,
  pixel : @core.Point2,
) -> @core.Point2 {
  @core.Point2::new(x=pixel.x * level.scale, y=pixel.y * level.scale)
}

///|
pub fn build_image_pyramid(
  base_size : ImageSize,
  base_intrinsics : CameraIntrinsics,
  levels : Int,
  scale_step? : Double = 0.5,
) -> Array[ImageLevel] raise @core.GeometryError {
  let result : Array[ImageLevel] = []
  let mut scale = 1.0
  for _ in 0..<levels.max(0) {
    let width = (base_size.width.to_double() * scale).to_int().max(1)
    let height = (base_size.height.to_double() * scale).to_int().max(1)
    let size = ImageSize::new(width~, height~)
    let intrinsics = CameraIntrinsics::new(
      fx=base_intrinsics.fx * scale,
      fy=base_intrinsics.fy * scale,
      cx=base_intrinsics.cx * scale,
      cy=base_intrinsics.cy * scale,
      skew=base_intrinsics.skew * scale,
    )
    result.push(ImageLevel::new(scale~, size~, intrinsics~))
    scale *= scale_step
  }
  result
}

///|
pub fn pyramid_scale(levels : ArrayView[ImageLevel], index : Int) -> Double {
  if index < 0 || index >= levels.length() {
    0.0
  } else {
    levels[index].scale
  }
}

///|
pub fn pyramid_pixel_radius(base_radius : Double, level : ImageLevel) -> Double {
  base_radius * level.scale
}

///|
pub fn pyramid_levels_covering(size : ImageSize, minimum_width : Int) -> Int {
  let mut width = size.width
  let mut count = 0
  while width >= minimum_width && width > 0 {
    count += 1
    width /= 2
  }
  count
}
