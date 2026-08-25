---
layout: post
title: Smarter Assembly Lines - Leveraging STEP Files for Worker Assistance Systems
date: 2023-03-01 00:00:00 +0000
tags: usecase ui
image: /assets/2026-09-21/title.png
image_header: /assets/2026-09-21/title.png
bg_alternative: true
read_more_links:
  - name: Welcome to the Future - Introducing Peakboard 4.4
    url: /Welcome-to-the-Future-Introducing-Peakboard-4.4.html
  - name: Use case articles
    url: /category/usecase
downloads:
  - name: AssemblyAssistant.pbmx
    url: /assets/2026-09-21/AssemblyAssistant.pbmx
  - name: BearingUnit.step
    url: /assets/2026-09-21/BearingUnit.step
---
Every manufacturing company has the same treasure lying around unused: a CAD system full of 3D models that describe every single part in the plant down to the last chamfer. And every manufacturing company has the same problem at the assembly station: the worker gets a printed sheet with a grainy screenshot of that model, taken from whatever angle the technical writer happened to pick two years ago.

With the Step control introduced in [Peakboard 4.4](/Welcome-to-the-Future-Introducing-Peakboard-4.4.html), that detour disappears. We drop the actual STEP file into a Peakboard application, and the model appears on the shop floor screen, rotatable, zoomable, and, most importantly, addressable from a script. In this article we build a complete worker assistance system around it: a five step assembly instruction where each work step shows exactly the parts that are already mounted and highlights the one that has to go on next.

Here is what we cover:

1. What the Step control actually does
1. Loading a model into the application
1. The parts list, or how CAD geometry becomes data
1. Driving the model from a work plan
1. Interactive mode and performance mode
1. The finished assembly assistant

## What the Step Control Actually Does

STEP (ISO 10303) is the neutral exchange format that every serious CAD system can write. It carries the exact mathematical description of a solid, a boundary representation made of trimmed surfaces, plus the assembly structure and the names of the products inside it. That is far more than a screen can draw directly, so the control does two jobs.

First, when we assign a model file, the Designer runs the STEP file through a geometry kernel and turns those surfaces into a triangle mesh. That result is stored inside the pbmx file as a mesh cache, which means the Peakboard Box never has to do the expensive tessellation work; it just receives the finished mesh. Second, at runtime the control renders that mesh in a WebGL scene, which is what gives us the smooth rotation and zoom without any extra hardware requirements.

The practical consequence is worth remembering: a big STEP file makes the pbmx file bigger and slows down the Designer once, when we assign it, and not the Box every time the application starts.

We find the control in the toolbar under "Others".

![Peakboard Designer toolbar showing the Step control in the Others category](/assets/2026-09-21/peakboard-designer-step-control-in-others-toolbar.png)

## Loading a Model into the Application

Dragging the control onto the canvas immediately asks us for the model file. STEP files are handled like any other resource in Peakboard, which means the file is embedded in the project and travels with it to the Box. No network share, no file path that breaks when IT reorganises the server.

![Select resource dialog for adding a STEP file to a Peakboard project](/assets/2026-09-21/peakboard-designer-step-viewer-select-resource.png)

For this article we use a small bearing unit assembly: a base plate, a support bracket, a bearing housing, a drive shaft, an end cover, and four hex bolts. Nine parts, each one a named product inside the STEP file. The names matter more than we might expect, and we come back to that in a moment.

Once the resource is assigned, the model shows up directly in the Designer canvas, with the colours that were stored in the CAD data.

![Peakboard Designer property panel of the Step control with model file, parts list and appearance settings](/assets/2026-09-21/peakboard-designer-step-viewer-properties.png)

## The Parts List, or How CAD Geometry Becomes Data

This is the part that turns a nice 3D viewer into an actual assistance system. The control does not just draw the model, it exposes every part of it as a row in a normal Peakboard list. One click on "Create parts list" and the Designer walks the assembly structure of the STEP file and generates a variable list with four columns.

![Generated parts list with one row per part of the STEP model](/assets/2026-09-21/peakboard-designer-step-viewer-generated-parts-list.png)

- **Name** is the product name from the STEP file. This is the key that connects the geometry to everything else.
- **Assembly** (stored in the Group column) is the node the part sits in. In a properly structured CAD assembly this lets us address a whole sub-assembly at once.
- **Visible** decides whether the part is drawn at all.
- **Active** highlights the part in the colour we configure as "Active color".

The last two are the interesting ones, because they work in both directions of our data flow. When our script sets `Visible` to false, the part disappears from the scene. When it sets `Active` to true, the part is rendered in the highlight colour while everything else stays in its CAD colour.

One detail is easy to trip over, so let us be explicit about it: the control **writes** the Name and Assembly columns itself whenever it loads the model. We should treat those two columns as read only and never abuse them to store our own information; it will be overwritten. Visible and Active are ours.

## Driving the Model from a Work Plan

Now we can build the actual logic. The application holds three lists:

- `StepViewerParts` is the generated parts list, owned by the control.
- `WorkSteps` holds the five work steps with number, title, and instruction text. In a real installation this comes from the ERP routing rather than from a hard-coded list.
- `StepParts` maps each part name to the work step it belongs to. This is the piece that a real system would take from the bill of materials.

A single shared function, `ApplyStep`, does all the work. For every part in the model it looks up which step the part belongs to, then decides two things: parts of earlier steps stay visible so the worker sees what has already been built, and the part of the current step gets highlighted.

![The ApplyStep function in the Peakboard script editor](/assets/2026-09-21/peakboard-designer-applystep-script.png)

```lua
local i = 0
local j = 0
local s = data.CurrentStep

for i = 0, data.StepViewerParts.count - 1 do
   local partStep = 0
   for j = 0, data.StepParts.count - 1 do
      if data.StepParts[j].Part == data.StepViewerParts[i].Name then
         partStep = data.StepParts[j].StepNo
      end
   end

   -- everything up to the current step stays on screen
   local visible = partStep <= s
   if data.StepViewerParts[i].Visible ~= visible then
      data.StepViewerParts[i].Visible = visible
   end

   -- only the part of the current step is highlighted
   local active = partStep == s
   if data.StepViewerParts[i].Active ~= active then
      data.StepViewerParts[i].Active = active
   end
end
```

Two things in this snippet deserve a comment. The write is guarded by a comparison, so we only touch a property when the value really changes and the scene is not repainted for nothing. And the whole function is called from a one second timer rather than only from the buttons, because the control rebuilds its parts list when the model finishes loading and would otherwise reset our carefully set visibility flags right after start.

The two buttons are then almost embarrassingly simple:

```lua
if data.CurrentStep < data.WorkSteps.count then
   data.CurrentStep = data.CurrentStep + 1
   ApplyStep()
end
```

![Explorer view of the finished project with lists, timer and function](/assets/2026-09-21/peakboard-designer-assembly-assistant-project.png)

## Interactive Mode and Performance Mode

Two checkboxes on the control are worth knowing about.

**Interactive** decides whether the worker may rotate, pan, and zoom the model with touch or mouse. For an assembly station this is exactly what we want, because being able to turn a part and look at the mounting point from the other side is the whole reason for showing 3D instead of a photo. For a pure information display that just rotates through screens, we switch it off so nobody leaves the model at a useless angle and walks away.

**Performance mode**, hidden in the Advanced section, trades rendering quality for frame rate. On a Peakboard Box that also has to serve a couple of data sources and a video wall, it is the switch to reach for when the model starts to feel sluggish.

The **Active color** completes the picture. We set it to the same accent colour the rest of the application uses, so the highlighted part reads as "this is your task now" rather than as a random colour change.

## The Finished Assembly Assistant

Here is the result. Step one, only the base plate exists, highlighted, with the instruction and the torque value next to it.

![Assembly assistant at step one showing only the highlighted base plate](/assets/2026-09-21/peakboard-runtime-assembly-step-1-base-plate.png)

At step three the plate and the bracket are already in place and shown in their normal colour, while the bearing housing that has to go on now is highlighted.

![Assembly assistant at step three with the bearing housing highlighted](/assets/2026-09-21/peakboard-runtime-assembly-step-3-bearing-housing.png)

And at step five the unit is complete, with the hex bolts marked as the remaining task.

![Assembly assistant at step five with the complete unit and the bolts highlighted](/assets/2026-09-21/peakboard-runtime-assembly-step-5-end-cover.png)

The worker can rotate the model at any point to look at a mounting point from a different angle, and the whole thing runs on a Peakboard Box without a CAD licence, a viewer installation, or a browser plugin.

## What This Changes

The honest value here is not the 3D rendering; plenty of tools can draw a CAD model. The value is that the model has become a data source like any other. The parts of the geometry are rows in a list, the list is driven by a script, and the script is fed by the same ERP data that drives the rest of our shop floor applications. When engineering changes the part, we exchange one resource in the project instead of re-shooting a series of screenshots. When the routing changes, the assistance system follows automatically.

That is what makes it worth wiring up properly rather than just dropping a pretty model on a screen.

The complete application and the STEP file we used are available for download above. Open the pbmx file in Peakboard Designer 4.4 or later, hit Preview, and click through the steps.
