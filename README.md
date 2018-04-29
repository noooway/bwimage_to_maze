### Overview

This prototype was inspired by [Matthew's Mazes](https://www.matthewsmazes.com/) art.

<p align="center">
<a href="https://www.redbubble.com/people/matthewsmazes/works/26386240-the-lane-cafe-maze-galway-ireland?c=698690-galway-mazes"><img src="https://ih0.redbubble.net/image.369354728.6240/flat,1000x1000,075,f.jpg" width="300"/></a>
</p>

Much to my surprise, there haven't been any interactive versions of these mazes - nor mobile, nor web - so I've decided to prototype one.

[screenshots]

The problem arises immediately: how to use the existing drawings of mazes to specify walls on a level?
Originally I thought that it would be necessary to find and extract different line segments from the image and then implement collision detection. 
It might have been doable for a vector image, but for a raster formats some kind of line extraction algorithm would be necessary (such as [Line Segment Detector](http://www.ipol.im/pub/art/2012/gjmr-lsd/), e.g. http://docs.opencv.org/3.0-beta/modules/line_descriptor/doc/LSDDetector.html or https://github.com/primetang/pylsd).

That would have been too much work for a prototype, so a different approach has been taken.
The [Matthew's Mazes](https://www.matthewsmazes.com/) images are black-and-white,
so the idea was to extract all the black pixels from the image
and treat them as obstacles for the player. 

Regarding the collision detection, an approach similar to CCD has been adopted.
Each update cycle, new possible player's position is calculated. 
If the possible player position doesn't overlap with black pixels,
the player is moved in that position at the end of the cycle.
If there are overlaps - the player doesn't move in that position. 
Such simple approach works surprisingly well. At least, it is sufficient for a prototype. 

### Installation

Obtain [LÖVE](https://love2d.org/) interpreter, clone the repository, run the program:
```bash
sudo apt-get install love2d
git clone https://github.com/noooway/bwimage_to_maze
love bwimage_to_maze
```

I haven't asked for permission to distribute any actual
[Matthew's Mazes](https://www.matthewsmazes.com/)
with this prototype, but it is possible to use them.
You have to download the maze you like, save it into the program folder,
and add it's filename into
```lua
levels.sequence = { "test_maze.png", "test_maze_circular.png" }
```
line in `main.lua`.