#pragma once


#include <GL/glew.h>
#include <GLFW/glfw3.h>
#include <vector>
#include <iostream>

#include "Camera.h"
#include "Shader.h"
#include "Renderer.h"

// WASD - move camera
// mouse - rotate camera
// t - toggle repeating space
// f - disable fog
// 1, 2, 3 - select scene / reset camera position
// shift - increases movement speed of the camera

#define PI 3.1415926538
#define CAMERA "camera"
#define WINDOW_SIZE "window_size"


extern int windowWidth;
extern int windowHeight;



class DemoController {
private:
    Camera camera;
    Shader* selectedShader;
    std::vector<Shader*> shaders;
    Camera default_cameras[3] = {
        Camera(glm::vec3(0.0, 0.0f, 4.0f), -90.0, 0.0),
        Camera(glm::vec3(0.0, 5.0f, 20.0f),-90.0, -25.0),
        Camera(glm::vec3(0.0, 1.0f, 4.0f), -90.0, -20.0),
    };

    float deltaTime = 0.0f;
    float lastFrame = 0.0f;
    int mod = 0;
    int fog = 0;
    int screenHeight = 0, screenWidth = 0;
    bool pressed = false;

public:
    DemoController() : camera(Camera(glm::vec3(0.0, 0.0f, 3.0f), -90.0, 0.0)) {

        shaders.push_back(new Shader("src/shaders/donuts.shader"));
        shaders.push_back(new Shader("src/shaders/table.shader"));
        shaders.push_back(new Shader("src/shaders/menger_fractal.shader"));

        selectedShader = shaders[0];

    }

    ~DemoController() {
        for (Shader* ptr : shaders) delete ptr;
    }

    void processInput(GLFWwindow* window);


    void processMouse(GLFWwindow* window, double xposIn, double yposIn);

    void BindVariables();

    Shader& getShader();
};