///|
/// In-memory index for feature-to-view incidence queries.
pub(all) struct TrackIndex {
  mut entries : Array[(Int, Int)]
}

///|
pub fn TrackIndex::new() -> TrackIndex {
  { entries: [], }
}

///|
pub fn TrackIndex::insert(index : TrackIndex, track : Int, view : Int) -> Unit {
  let entry = (track, view)
  if !index.entries.contains(entry) {
    index.entries.push(entry)
  }
}

///|
pub fn TrackIndex::remove(index : TrackIndex, track : Int, view : Int) -> Bool {
  let mut position = -1
  for i in 0..<index.entries.length() {
    let current = index.entries[i]
    if current.0 == track && current.1 == view {
      position = i
    }
  }
  if position >= 0 {
    let _ = index.entries.remove(position)
    true
  } else {
    false
  }
}

///|
pub fn TrackIndex::contains(
  index : TrackIndex,
  track : Int,
  view : Int,
) -> Bool {
  index.entries.contains((track, view))
}

///|
pub fn TrackIndex::track_count(index : TrackIndex) -> Int {
  let result : Array[Int] = []
  for entry in index.entries {
    if !result.contains(entry.0) {
      result.push(entry.0)
    }
  }
  result.length()
}

///|
pub fn TrackIndex::view_count(index : TrackIndex) -> Int {
  let result : Array[Int] = []
  for entry in index.entries {
    if !result.contains(entry.1) {
      result.push(entry.1)
    }
  }
  result.length()
}

///|
pub fn TrackIndex::views_for(index : TrackIndex, track : Int) -> Array[Int] {
  let result : Array[Int] = []
  for entry in index.entries {
    if entry.0 == track {
      result.push(entry.1)
    }
  }
  result
}

///|
pub fn TrackIndex::tracks_for(index : TrackIndex, view : Int) -> Array[Int] {
  let result : Array[Int] = []
  for entry in index.entries {
    if entry.1 == view {
      result.push(entry.0)
    }
  }
  result
}

///|
pub fn TrackIndex::pair_count(
  index : TrackIndex,
  left : Int,
  right : Int,
) -> Int {
  let left_tracks = index.tracks_for(left)
  let mut count = 0
  for track in left_tracks {
    if index.contains(track, right) {
      count += 1
    }
  }
  count
}

///|
pub fn TrackIndex::total_observations(index : TrackIndex) -> Int {
  index.entries.length()
}

///|
pub fn TrackIndex::track_degree_histogram(index : TrackIndex) -> Array[Int] {
  let tracks : Array[Int] = []
  let result : Array[Int] = []
  for entry in index.entries {
    let track = entry.0
    let mut position = -1
    for i in 0..<tracks.length() {
      if tracks[i] == track {
        position = i
      }
    }
    if position < 0 {
      tracks.push(track)
      result.push(1)
    } else {
      result[position] += 1
    }
  }
  result
}

///|
pub fn TrackIndex::view_degree_histogram(index : TrackIndex) -> Array[Int] {
  let views : Array[Int] = []
  let result : Array[Int] = []
  for entry in index.entries {
    let view = entry.1
    let mut position = -1
    for i in 0..<views.length() {
      if views[i] == view {
        position = i
      }
    }
    if position < 0 {
      views.push(view)
      result.push(1)
    } else {
      result[position] += 1
    }
  }
  result
}

///|
pub fn TrackIndex::shared_tracks(
  index : TrackIndex,
  views : ArrayView[Int],
) -> Array[Int] {
  let result : Array[Int] = []
  if views.length() == 0 {
    return result
  }
  for track in index.tracks_for(views[0]) {
    let mut present = true
    for view in views[1:] {
      if !index.contains(track, view) {
        present = false
      }
    }
    if present {
      result.push(track)
    }
  }
  result
}

///|
pub fn TrackIndex::clear(index : TrackIndex) -> Unit {
  index.entries.clear()
}
