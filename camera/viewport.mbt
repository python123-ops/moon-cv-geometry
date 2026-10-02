///|
pub(all) struct ImageSize {
  width : Int
  height : Int
} derive(Debug, Eq)

///|
pub fn ImageSize::new(
  width~ : Int,
  height~ : Int,
) -> ImageSize raise @core.GeometryError {
  if width <= 0 || height <= 0 {
    raise @core.GeometryError::DegenerateInput("image size must be positive")
  }
  { width, height, }
}

///|
pub fn ImageSize::as_rect(
  size : ImageSize,
) -> @core.Rect2 raise @core.GeometryError {
  @core.Rect2::new(
    min=@core.Point2::new(x=0.0, y=0.0),
    max=@core.Point2::new(
      x=Double::from_int(size.width),
      y=Double::from_int(size.height),
    ),
  )
}

///|
pub fn CameraIntrinsics::principal_point(k : CameraIntrinsics) -> @core.Point2 {
  @core.Point2::new(x=k.cx, y=k.cy)
}

///|
pub fn CameraIntrinsics::as_matrix(k : CameraIntrinsics) -> @core.Mat3 {
  @core.mat3_from_rows((k.fx, k.skew, k.cx), (0.0, k.fy, k.cy), (0.0, 0.0, 1.0))
}

///|
pub fn CameraIntrinsics::scaled(
  k : CameraIntrinsics,
  scale_x~ : Double,
  scale_y~ : Double,
) -> CameraIntrinsics raise @core.GeometryError {
  if scale_x <= 0.0 || scale_y <= 0.0 {
    raise @core.GeometryError::DegenerateInput(
      "intrinsic scales must be positive",
    )
  }
  CameraIntrinsics::new(
    fx=k.fx * scale_x,
    fy=k.fy * scale_y,
    cx=k.cx * scale_x,
    cy=k.cy * scale_y,
    skew=k.skew * scale_x,
  )
}

///|
pub fn CameraIntrinsics::for_centered_image(
  focal~ : Double,
  size : ImageSize,
  skew? : Double = 0.0,
) -> CameraIntrinsics raise @core.GeometryError {
  if focal <= 0.0 {
    raise @core.GeometryError::DegenerateInput("focal length must be positive")
  }
  CameraIntrinsics::new(
    fx=focal,
    fy=focal,
    cx=Double::from_int(size.width) / 2.0,
    cy=Double::from_int(size.height) / 2.0,
    skew~,
  )
}
