///|
/// Deterministic image-window operations for feature scoring and calibration.
pub(all) struct ImageWindowStats {
  count : Int
  minimum : Double
  maximum : Double
  mean : Double
  variance : Double
  energy : Double
} derive(Debug, Eq)

///|
pub fn image_window_index(width : Int, x : Int, y : Int) -> Int {
  y * width + x
}

///|
pub fn image_window_valid(width : Int, height : Int, x : Int, y : Int) -> Bool {
  width > 0 && height > 0 && x >= 0 && x < width && y >= 0 && y < height
}

///|
pub fn image_window_clamp(
  value : Double,
  minimum : Double,
  maximum : Double,
) -> Double {
  value.max(minimum).min(maximum)
}

///|
pub fn image_window_stats(values : ArrayView[Double]) -> ImageWindowStats {
  if values.length() == 0 {
    return {
      count: 0,
      minimum: 0.0,
      maximum: 0.0,
      mean: 0.0,
      variance: 0.0,
      energy: 0.0,
    }
  }
  let mut minimum = values[0]
  let mut maximum = values[0]
  let mut sum = 0.0
  let mut energy = 0.0
  for value in values {
    minimum = minimum.min(value)
    maximum = maximum.max(value)
    sum += value
    energy += value * value
  }
  let mean = sum / values.length().to_double()
  let mut square_error = 0.0
  for value in values {
    let error = value - mean
    square_error += error * error
  }
  {
    count: values.length(),
    minimum,
    maximum,
    mean,
    variance: square_error / values.length().to_double(),
    energy,
  }
}

///|
pub fn image_window_normalize(values : ArrayView[Double]) -> Array[Double] {
  let stats = image_window_stats(values)
  let result : Array[Double] = []
  let scale = if stats.maximum - stats.minimum <= 0.0 {
    1.0
  } else {
    1.0 / (stats.maximum - stats.minimum)
  }
  for value in values {
    result.push((value - stats.minimum) * scale)
  }
  result
}

///|
pub fn image_window_standardize(values : ArrayView[Double]) -> Array[Double] {
  let stats = image_window_stats(values)
  let scale = if stats.variance <= 0.0 {
    1.0
  } else {
    1.0 / stats.variance.sqrt()
  }
  let result : Array[Double] = []
  for value in values {
    result.push((value - stats.mean) * scale)
  }
  result
}

///|
pub fn image_window_clip(
  values : ArrayView[Double],
  minimum : Double,
  maximum : Double,
) -> Array[Double] {
  let result : Array[Double] = []
  for value in values {
    result.push(image_window_clamp(value, minimum, maximum))
  }
  result
}

///|
pub fn image_window_threshold(
  values : ArrayView[Double],
  threshold : Double,
) -> Array[Bool] {
  let result : Array[Bool] = []
  for value in values {
    result.push(value >= threshold)
  }
  result
}

///|
pub fn image_window_binary_count(
  values : ArrayView[Double],
  threshold : Double,
) -> Int {
  let mut count = 0
  for value in values {
    if value >= threshold {
      count += 1
    }
  }
  count
}

///|
pub fn image_window_mean_abs_difference(
  left : ArrayView[Double],
  right : ArrayView[Double],
) -> Double {
  let count = left.length().min(right.length())
  if count == 0 {
    return 0.0
  }
  let mut total = 0.0
  for i in 0..<count {
    total += (left[i] - right[i]).abs()
  }
  total / count.to_double()
}

///|
pub fn image_window_mean_squared_difference(
  left : ArrayView[Double],
  right : ArrayView[Double],
) -> Double {
  let count = left.length().min(right.length())
  if count == 0 {
    return 0.0
  }
  let mut total = 0.0
  for i in 0..<count {
    let d = left[i] - right[i]
    total += d * d
  }
  total / count.to_double()
}

///|
pub fn image_window_normalized_cross_correlation(
  left : ArrayView[Double],
  right : ArrayView[Double],
) -> Double {
  let count = left.length().min(right.length())
  if count == 0 {
    return 0.0
  }
  let left_stats = image_window_stats(left[:count])
  let right_stats = image_window_stats(right[:count])
  let mut numerator = 0.0
  let mut left_energy = 0.0
  let mut right_energy = 0.0
  for i in 0..<count {
    let a = left[i] - left_stats.mean
    let b = right[i] - right_stats.mean
    numerator += a * b
    left_energy += a * a
    right_energy += b * b
  }
  let denominator = (left_energy * right_energy).sqrt()
  if denominator <= 0.0 {
    0.0
  } else {
    numerator / denominator
  }
}

///|
pub fn image_window_box_sum(
  values : ArrayView[Double],
  width : Int,
  height : Int,
  x : Int,
  y : Int,
  radius : Int,
) -> Double {
  if width <= 0 || height <= 0 {
    return 0.0
  }
  let mut total = 0.0
  let r = radius.max(0)
  let start_y = (y - r).max(0)
  let end_y = (y + r + 1).min(height)
  let start_x = (x - r).max(0)
  let end_x = (x + r + 1).min(width)
  for yy in start_y..<end_y {
    for xx in start_x..<end_x {
      let index = image_window_index(width, xx, yy)
      if index >= 0 && index < values.length() {
        total += values[index]
      }
    }
  }
  total
}

///|
pub fn image_window_box_mean(
  values : ArrayView[Double],
  width : Int,
  height : Int,
  x : Int,
  y : Int,
  radius : Int,
) -> Double {
  let r = radius.max(0)
  let start_x = (x - r).max(0)
  let end_x = (x + r + 1).min(width)
  let start_y = (y - r).max(0)
  let end_y = (y + r + 1).min(height)
  let count = (end_x - start_x).max(0) * (end_y - start_y).max(0)
  if count <= 0 {
    0.0
  } else {
    image_window_box_sum(values, width, height, x, y, r) / count.to_double()
  }
}

///|
pub fn image_window_gradient_x(
  values : ArrayView[Double],
  width : Int,
  height : Int,
  x : Int,
  y : Int,
) -> Double {
  if !image_window_valid(width, height, x, y) {
    return 0.0
  }
  let left = values[image_window_index(width, (x - 1).max(0), y)]
  let right = values[image_window_index(width, (x + 1).min(width - 1), y)]
  (right - left) * 0.5
}

///|
pub fn image_window_gradient_y(
  values : ArrayView[Double],
  width : Int,
  height : Int,
  x : Int,
  y : Int,
) -> Double {
  if !image_window_valid(width, height, x, y) {
    return 0.0
  }
  let top = values[image_window_index(width, x, (y - 1).max(0))]
  let bottom = values[image_window_index(width, x, (y + 1).min(height - 1))]
  (bottom - top) * 0.5
}

///|
pub fn image_window_gradient_magnitude(
  values : ArrayView[Double],
  width : Int,
  height : Int,
  x : Int,
  y : Int,
) -> Double {
  let dx = image_window_gradient_x(values, width, height, x, y)
  let dy = image_window_gradient_y(values, width, height, x, y)
  (dx * dx + dy * dy).sqrt()
}

///|
pub fn image_window_gradient_field(
  values : ArrayView[Double],
  width : Int,
  height : Int,
) -> Array[Double] {
  let result : Array[Double] = []
  for y in 0..<height.max(0) {
    for x in 0..<width.max(0) {
      result.push(image_window_gradient_magnitude(values, width, height, x, y))
    }
  }
  result
}

///|
pub fn image_window_laplacian(
  values : ArrayView[Double],
  width : Int,
  height : Int,
  x : Int,
  y : Int,
) -> Double {
  if !image_window_valid(width, height, x, y) {
    return 0.0
  }
  let center = values[image_window_index(width, x, y)]
  let left = values[image_window_index(width, (x - 1).max(0), y)]
  let right = values[image_window_index(width, (x + 1).min(width - 1), y)]
  let top = values[image_window_index(width, x, (y - 1).max(0))]
  let bottom = values[image_window_index(width, x, (y + 1).min(height - 1))]
  left + right + top + bottom - 4.0 * center
}

///|
pub fn image_window_corner_score(
  values : ArrayView[Double],
  width : Int,
  height : Int,
  x : Int,
  y : Int,
) -> Double {
  let dx = image_window_gradient_x(values, width, height, x, y)
  let dy = image_window_gradient_y(values, width, height, x, y)
  let laplacian = image_window_laplacian(values, width, height, x, y)
  (dx * dx + dy * dy) / (1.0 + laplacian.abs())
}

///|
pub fn image_window_patch(
  values : ArrayView[Double],
  width : Int,
  height : Int,
  x : Int,
  y : Int,
  radius : Int,
) -> Array[Double] {
  let result : Array[Double] = []
  let r = radius.max(0)
  let start_y = (y - r).max(0)
  let end_y = (y + r + 1).min(height)
  let start_x = (x - r).max(0)
  let end_x = (x + r + 1).min(width)
  for yy in start_y..<end_y {
    for xx in start_x..<end_x {
      let index = image_window_index(width, xx, yy)
      if index >= 0 && index < values.length() {
        result.push(values[index])
      }
    }
  }
  result
}

///|
pub fn image_window_patch_score(
  values : ArrayView[Double],
  width : Int,
  height : Int,
  x : Int,
  y : Int,
  radius : Int,
) -> Double {
  image_window_stats(image_window_patch(values, width, height, x, y, radius)).variance
}

///|
pub fn image_window_nonmaximum_points(
  values : ArrayView[Double],
  width : Int,
  height : Int,
  threshold : Double,
  radius : Int,
) -> Array[@core.Point2] {
  let result : Array[@core.Point2] = []
  for y in 0..<height.max(0) {
    for x in 0..<width.max(0) {
      let score = values[image_window_index(width, x, y)]
      if score >= threshold &&
        score >= image_window_patch_score(values, width, height, x, y, radius) {
        result.push(@core.Point2::new(x=x.to_double(), y=y.to_double()))
      }
    }
  }
  result
}

///|
pub fn image_window_downsample(
  values : ArrayView[Double],
  width : Int,
  height : Int,
  factor : Int,
) -> (Array[Double], Int, Int) {
  let step = factor.max(1)
  let output_width = (width.max(0) + step - 1) / step
  let output_height = (height.max(0) + step - 1) / step
  let result : Array[Double] = []
  for y in 0..<output_height {
    for x in 0..<output_width {
      result.push(
        image_window_box_mean(
          values,
          width,
          height,
          x * step,
          y * step,
          (step - 1) / 2,
        ),
      )
    }
  }
  (result, output_width, output_height)
}

///|
pub fn image_window_resize_nearest(
  values : ArrayView[Double],
  width : Int,
  height : Int,
  output_width : Int,
  output_height : Int,
) -> Array[Double] {
  let result : Array[Double] = []
  if output_width <= 0 || output_height <= 0 {
    return result
  }
  for y in 0..<output_height {
    for x in 0..<output_width {
      let source_x = (x * width.max(1) / output_width).min(width.max(1) - 1)
      let source_y = (y * height.max(1) / output_height).min(height.max(1) - 1)
      let index = image_window_index(width, source_x, source_y)
      result.push(
        if index >= 0 && index < values.length() {
          values[index]
        } else {
          0.0
        },
      )
    }
  }
  result
}

///|
pub fn image_window_add(
  left : ArrayView[Double],
  right : ArrayView[Double],
) -> Array[Double] {
  let result : Array[Double] = []
  let count = left.length().min(right.length())
  for i in 0..<count {
    result.push(left[i] + right[i])
  }
  result
}

///|
pub fn image_window_subtract(
  left : ArrayView[Double],
  right : ArrayView[Double],
) -> Array[Double] {
  let result : Array[Double] = []
  let count = left.length().min(right.length())
  for i in 0..<count {
    result.push(left[i] - right[i])
  }
  result
}

///|
pub fn image_window_multiply(
  values : ArrayView[Double],
  scale : Double,
) -> Array[Double] {
  let result : Array[Double] = []
  for value in values {
    result.push(value * scale)
  }
  result
}

///|
pub fn image_window_accumulate(
  target : Array[Double],
  source : ArrayView[Double],
  scale : Double,
) -> Unit {
  let count = target.length().min(source.length())
  for i in 0..<count {
    target[i] += source[i] * scale
  }
}

///|
pub fn image_window_quality(
  values : ArrayView[Double],
  minimum_variance : Double,
  maximum_mean_abs : Double,
) -> Double {
  let stats = image_window_stats(values)
  let texture = if minimum_variance <= 0.0 {
    1.0
  } else {
    (stats.variance / minimum_variance).min(1.0)
  }
  let brightness = if maximum_mean_abs <= 0.0 {
    0.0
  } else {
    (stats.mean.abs() / maximum_mean_abs).min(1.0)
  }
  texture * (1.0 - brightness)
}
