///|
/// Dense observation occupancy matrix for view-track diagnostics.
pub(all) struct ObservationMatrix {
  views : Int
  tracks : Int
  cells : Array[Bool]
}

///|
pub fn ObservationMatrix::new(views~ : Int, tracks~ : Int) -> ObservationMatrix {
  {
    views: views.max(0),
    tracks: tracks.max(0),
    cells: Array::make(views.max(0) * tracks.max(0), false),
  }
}

///|
pub fn ObservationMatrix::contains(
  matrix : ObservationMatrix,
  view : Int,
  track : Int,
) -> Bool {
  view >= 0 && track >= 0 && view < matrix.views && track < matrix.tracks
}

///|
pub fn ObservationMatrix::set(
  matrix : ObservationMatrix,
  view : Int,
  track : Int,
  present : Bool,
) -> Bool {
  if !matrix.contains(view, track) {
    return false
  }
  matrix.cells[track * matrix.views + view] = present
  true
}

///|
pub fn ObservationMatrix::get(
  matrix : ObservationMatrix,
  view : Int,
  track : Int,
) -> Bool {
  if matrix.contains(view, track) {
    matrix.cells[track * matrix.views + view]
  } else {
    false
  }
}

///|
pub fn ObservationMatrix::view_degree(
  matrix : ObservationMatrix,
  view : Int,
) -> Int {
  let mut count = 0
  for track in 0..<matrix.tracks {
    if matrix.get(view, track) {
      count += 1
    }
  }
  count
}

///|
pub fn ObservationMatrix::track_degree(
  matrix : ObservationMatrix,
  track : Int,
) -> Int {
  let mut count = 0
  for view in 0..<matrix.views {
    if matrix.get(view, track) {
      count += 1
    }
  }
  count
}

///|
pub fn ObservationMatrix::density(matrix : ObservationMatrix) -> Double {
  if matrix.cells.length() == 0 {
    0.0
  } else {
    let mut count = 0
    for cell in matrix.cells {
      if cell {
        count += 1
      }
    }
    count.to_double() / matrix.cells.length().to_double()
  }
}

///|
pub fn tracks_with_minimum_views(
  matrix : ObservationMatrix,
  minimum : Int,
) -> Array[Int] {
  let result : Array[Int] = []
  for track in 0..<matrix.tracks {
    if matrix.track_degree(track) >= minimum {
      result.push(track)
    }
  }
  result
}

///|
pub fn views_with_minimum_tracks(
  matrix : ObservationMatrix,
  minimum : Int,
) -> Array[Int] {
  let result : Array[Int] = []
  for view in 0..<matrix.views {
    if matrix.view_degree(view) >= minimum {
      result.push(view)
    }
  }
  result
}
