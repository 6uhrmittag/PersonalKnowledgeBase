# Editing videos in Davinci Resolve

Random Settings to remember

## Default Settings for Timelines in Project

Set the resolution and frame rate you're using to record in OBS as default settings:

- Files > Project settings > Master settings
    - Timeline resolution: 2560x1440
    - Timeline frame rate: 60fps

## Settings

### User

Menu > Settings > User

- Editing
    - Start timecode: 00:00:00:00 (Not decided if thats better)
    - Number of Video Tracks: 2

## FAQ

### Why are Timelines starting at 01:00:00:00?

> DaVinci Resolve timeline starts at 1 hour because it gives headroom (a bit of a lead time) to include any test signals, bars, tones, etc., before the actual start of your edit at the starting timecode of 1 hour (01:00:00:00).

- Source: https://beginnersapproach.com/davinci-resolve-start-timecode/

- Note: it does actually make it easy to cut away the first seconds of a recording
