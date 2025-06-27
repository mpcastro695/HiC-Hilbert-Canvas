# Hi-C: Hilbert Canvas 🎨

##### 🔍 Submitted as a final project for CS50x

A macOS app for visualizing 2D Hilbert curves. Adjust curve parameters such as the spacing between nodes, the width of the connecting paths, and the diameter of your node markers. See stats such as path length, path area, and path volume updated as you build your curve. When finished, export a copy as a vector-based PDF.
#### Demo:  <https://youtu.be/7LzKyFsDkqs>
![Alt text](<Screenshot.png>)

Hilbert curves preserve locality among both 1D (unfolded) and 2D (folded) space, even as the size of curve grows -from a minimum of 16 nodes to a max of 16,384 in *Hi-C*.

*Hi-C* uses an iterative algorithm - detailed [here](/Chwedczuk_Archive.pdf) by Marcin Chwedczuk - for calculating cartesian (i.e., X, Y) coordinates given a node's 'Hilbert' index. It uses bit shifting to apply the appropriate transformation(s) to a 2x2 base curve (e.g., translation, rotation, flipping) based on its position within the larger curve. The original JavaScript code that **HilbertCurve.swift** is based on can be found [here](https://github.com/marcin-chwedczuk/hilbert_curve).

*Hilbert Canvas* has three main components:
* **HilbertCurve.swift**: A *Swift* implementation of Chwedczuck's algorithm that uses bit shifting to find cartesian coordinates for a given 'hilbert' node. 
    * Initialized with an index count (4, 8, 16, 32, 64, or 128) 
    * The `coordinates` property is an array of x, y coordinate tuples.

* **CurveCanvas.swift**: A *SwiftUI* [Canvas](https://developer.apple.com/documentation/swiftui/canvas) view that draws a Hilbert space-filling curve from an array of cartesian coordinates.

    * Includes helper functions for returning the `pathArea` and `pathDistance` based on current parameters

* **ContentView.swift**: The main *SwiftUI* view containing controls for changing the curve's parameters, including:
    * Number of nodes
    * Spacing between each node
    * Width of the connecting paths between nodes
    * Diameter of node markers
    * Depth of the path, markers
    * Scale of the viewport

## Statistics

As you change the curve's parameters, values are calculated for:

* **Edge Length**: The length along the outer edge (in mm) of your curve

* **Curve Area**: total area of your space-filling curve (in mm<sup>2</sup>)

* **Path Length**: total length traveled along the main path connecting all nodes (in mm)

* **Path Area**: total area of the path connecting all nodes (in mm<sup>2</sup>); if the **Markers** option is enabled, the result of `markerArea` is added per below:

![Alt text](<MarkerArea.png>)

* **Path Volume**: total volume to fill the path (in μL), including markers, if applicable. Only calculated if the **Depth** option is enabled.

## PDF Export

With the **DXF** option enabled, you can export a vector-based PDF of your custom curve like the one below: 

![Alt text](<Screenshot_Export.png>)

This can then be imported into a vector graphics editor - e.g., [InkScape](https://inkscape.org/) - and converted to a DXF (*Drawing Exchange Format*) file for use in cutting and/or CAD modeling software. An STL file demonstrating a simple deboss is [included](/Curve%20Deboss.stl).

![Alt text](<Deboss_Render.png>)







