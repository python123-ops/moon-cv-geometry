///|
/// Regular scalar grid used for masks, heatmaps, and calibration residuals.
pub(all) struct ScalarGrid {
  width : Int
  height : Int
  values : Array[Double]
}

///|
pub fn ScalarGrid::new(
  width~ : Int,
  height~ : Int,
  fill~ : Double,
) -> ScalarGrid {
  let values : Array[Double] = []
  for _ in 0..<(width.max(0) * height.max(0)) {
    values.push(fill)
  }
  { width: width.max(0), height: height.max(0), values }
}

///|
pub fn ScalarGrid::width(grid : ScalarGrid) -> Int {
  grid.width
}

///|
pub fn ScalarGrid::height(grid : ScalarGrid) -> Int {
  grid.height
}

///|
pub fn ScalarGrid::length(grid : ScalarGrid) -> Int {
  grid.values.length()
}

///|
pub fn ScalarGrid::contains(grid : ScalarGrid, x : Int, y : Int) -> Bool {
  x >= 0 && y >= 0 && x < grid.width && y < grid.height
}

///|
pub fn ScalarGrid::get(grid : ScalarGrid, x : Int, y : Int) -> Double? {
  if grid.contains(x, y) {
    Some(grid.values[y * grid.width + x])
  } else {
    None
  }
}

///|
pub fn ScalarGrid::set(
  grid : ScalarGrid,
  x : Int,
  y : Int,
  value : Double,
) -> Bool {
  if !grid.contains(x, y) {
    return false
  }
  grid.values[y * grid.width + x] = value
  true
}

///|
pub fn ScalarGrid::map(grid : ScalarGrid, f : (Double) -> Double) -> ScalarGrid {
  let result = ScalarGrid::new(width=grid.width, height=grid.height, fill=0.0)
  for i in 0..<grid.values.length() {
    result.values[i] = f(grid.values[i])
  }
  result
}

///|
pub fn ScalarGrid::sum(grid : ScalarGrid) -> Double {
  let mut total = 0.0
  for value in grid.values {
    total += value
  }
  total
}

///|
pub fn ScalarGrid::mean(grid : ScalarGrid) -> Double {
  if grid.values.length() == 0 {
    0.0
  } else {
    grid.sum() / grid.values.length().to_double()
  }
}

///|
pub fn ScalarGrid::min_max(grid : ScalarGrid) -> (Double, Double)? {
  if grid.values.length() == 0 {
    return None
  }
  let mut minimum = grid.values[0]
  let mut maximum = grid.values[0]
  for value in grid.values {
    minimum = minimum.min(value)
    maximum = maximum.max(value)
  }
  Some((minimum, maximum))
}

///|
pub fn ScalarGrid::bilinear(
  grid : ScalarGrid,
  x : Double,
  y : Double,
) -> Double? {
  let x0 = x.floor().to_int()
  let y0 = y.floor().to_int()
  if !grid.contains(x0, y0) || !grid.contains(x0 + 1, y0 + 1) {
    return None
  }
  let tx = x - x0.to_double()
  let ty = y - y0.to_double()
  let a = grid.values[y0 * grid.width + x0]
  let b = grid.values[y0 * grid.width + x0 + 1]
  let c = grid.values[(y0 + 1) * grid.width + x0]
  let d = grid.values[(y0 + 1) * grid.width + x0 + 1]
  Some(
    a * (1.0 - tx) * (1.0 - ty) +
    b * tx * (1.0 - ty) +
    c * (1.0 - tx) * ty +
    d * tx * ty,
  )
}

///|
pub fn downsample_grid(grid : ScalarGrid, factor : Int) -> ScalarGrid {
  if factor <= 1 {
    return grid
  }
  let width = (grid.width / factor).max(1)
  let height = (grid.height / factor).max(1)
  let result = ScalarGrid::new(width~, height~, fill=0.0)
  for y in 0..<height {
    for x in 0..<width {
      let mut sum = 0.0
      let mut count = 0
      for dy in 0..<factor {
        for dx in 0..<factor {
          let sx = x * factor + dx
          let sy = y * factor + dy
          if grid.contains(sx, sy) {
            sum += grid.values[sy * grid.width + sx]
            count += 1
          }
        }
      }
      let _ = result.set(
        x,
        y,
        if count == 0 {
          0.0
        } else {
          sum / count.to_double()
        },
      )
    }
  }
  result
}
