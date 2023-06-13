# RayMarching Demo
Display of 3d rendering using ray marching. It renders complex scenes in real time on gpu thanks to openGL.
## What is ray marching?
It's a rendering technique using math functions and transformation to display objects.
Each object is described by a function SDF(x, y, z) describing the distance from it's surface to a point (x, y, z). It allows for scenes that are impossible or very costly to render using other techniques. \
Great materials: https://iquilezles.org/articles/distfunctions/

## Project Content
Project contains three example scenes showcasing the posibilities of ray marching.
It uses rendering effects:
- ambient, directional and specular lighting
- fog
- spacial repetition and distorsion
- fractals


## Rendering examples
### Donuts Scene
![Donuts](https://github.com/M0rgho/RayMarching/assets/95372995/f57188bc-9210-49f1-92f9-3a66599e13d8)
### Table Scene
![Table](https://github.com/M0rgho/RayMarching/assets/95372995/78b48ea7-f1a1-42e1-b3b2-aca89483b330)
### Menger sponge Scene
![Menger Sponge](https://github.com/M0rgho/RayMarching/assets/95372995/e8c27881-2d73-463e-aa0b-917fab112c1f)
![Menger Sponges](https://github.com/M0rgho/RayMarching/assets/95372995/c457c1a2-5ca0-4e66-b359-8e00f7251441)

## How to use

### Controls
- move camera with WASD and rotate it with a mouse
- t - toggle repeating space 
- f - disable fog 
- 1, 2, 3 - select scene / reset camera position 
- SHIFT - increases movement speed of the camera 

### Performace
It runs above 60FPS on dedicated GPUs. 
In case of bad performace:
 - decrease the number of ray iteration can be  in *.shader files in vec2 intersect(in Ray ray); function.
 - decrease window size.

## How to install
Open the RayMarching.sln project in Visual Studio 2022 and compile it.

### Dependencies
- GLEW
- GLFW
- GLM

All dependencies are included in /Dependencies folder (only a version for visual studio 2022).

_The code is platform independent, only dependencies must be changed for the platform_

---
Made by Mikołaj Maślak 
