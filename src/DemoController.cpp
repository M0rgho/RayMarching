#include "DemoController.h"

void DemoController::processInput(GLFWwindow* window)
{
    GLdouble xPos, yPos;
    glfwGetCursorPos(window, &xPos, &yPos);
    processMouse(window, xPos, yPos);

    float currentFrame = glfwGetTime();
    deltaTime = currentFrame - lastFrame;
    lastFrame = currentFrame;


    if (glfwGetKey(window, GLFW_KEY_ESCAPE) == GLFW_PRESS)
        glfwSetWindowShouldClose(window, true);

    if (!pressed) {
        if (glfwGetKey(window, GLFW_KEY_T) == GLFW_PRESS) {
            mod = 1 - mod;
        }
        if (glfwGetKey(window, GLFW_KEY_F) == GLFW_PRESS) {
            fog = 1 - fog;
        }
        if (glfwGetKey(window, GLFW_KEY_1) == GLFW_PRESS) {
            selectedShader = shaders[0];
            camera = default_cameras[0];
        }
        else if (glfwGetKey(window, GLFW_KEY_2) == GLFW_PRESS) {
            selectedShader = shaders[1];
            camera = default_cameras[1];
        }
        else if (glfwGetKey(window, GLFW_KEY_3) == GLFW_PRESS) {
            selectedShader = shaders[2];
            camera = default_cameras[2];
        }
    }

    if (glfwGetKey(window, GLFW_KEY_W) == GLFW_PRESS)
        camera.ProcessMovement(FORWARD, deltaTime);
    if (glfwGetKey(window, GLFW_KEY_S) == GLFW_PRESS)
        camera.ProcessMovement(BACKWARD, deltaTime);
    if (glfwGetKey(window, GLFW_KEY_A) == GLFW_PRESS)
        camera.ProcessMovement(LEFT, deltaTime);
    if (glfwGetKey(window, GLFW_KEY_D) == GLFW_PRESS)
        camera.ProcessMovement(RIGHT, deltaTime);
    if (glfwGetKey(window, GLFW_KEY_LEFT_SHIFT) == GLFW_PRESS)
        camera.BoostSpeed(true);
    else if (glfwGetKey(window, GLFW_KEY_LEFT_SHIFT) == GLFW_RELEASE)
        camera.BoostSpeed(false);

    if (glfwGetKey(window, GLFW_KEY_T) == GLFW_PRESS || glfwGetKey(window, GLFW_KEY_1) == GLFW_PRESS ||
        glfwGetKey(window, GLFW_KEY_2) == GLFW_PRESS || glfwGetKey(window, GLFW_KEY_3) == GLFW_PRESS || glfwGetKey(window, GLFW_KEY_F) == GLFW_PRESS)
        pressed = true;
    else {
        pressed = false;
    }



    glfwGetFramebufferSize(window, &screenWidth, &screenHeight);
    selectedShader->Bind();
    GLCall(unsigned int location = glGetUniformLocation(selectedShader->getID(), WINDOW_SIZE));
    GLCall(glUniform2ui(location, screenWidth, screenHeight));

}


void DemoController::processMouse(GLFWwindow* window, double xposIn, double yposIn)
{
    static float lastX, lastY;
    static bool firstMouse = true;
    float xpos = static_cast<float>(xposIn);
    float ypos = static_cast<float>(yposIn);

    if (firstMouse)
    {
        lastX = xpos;
        lastY = ypos;
        firstMouse = false;
    }

    float xoffset = xpos - lastX;
    float yoffset = lastY - ypos;

    lastX = xpos;
    lastY = ypos;

    camera.ProcessMouse(xoffset, yoffset);
}

void DemoController::BindVariables() {
    DemoController::selectedShader->Bind();
    selectedShader->SetUniform3f("position", camera.GetPosition());
    selectedShader->SetUniform3f("front", camera.GetFrontVector());
    selectedShader->SetUniform3f("up", camera.getUpVector());
    selectedShader->SetUniform3f("right", camera.getRightVector());
    selectedShader->SetUniform4f("fov", tan(PI / 8), tan(PI / 8) * screenHeight / screenWidth, 0, 0);
    selectedShader->SetUniformf("time", glfwGetTime());
    selectedShader->SetUniformI("do_mod", mod);
    selectedShader->SetUniformI("fog", fog);

}

Shader& DemoController::getShader() {
    return *selectedShader;
}