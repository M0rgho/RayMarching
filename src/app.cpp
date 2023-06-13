#include <GL/glew.h>
#include <GLFW/glfw3.h>

#include <iostream>
#include <cmath>
#include <glm/vec3.hpp>
#include <glm/mat4x4.hpp>
#include <glm/gtc/matrix_transform.hpp>
#include <glm/gtx/string_cast.hpp>

#include "Renderer.h"
#include "VertexBuffer.h"
#include "IndexBuffer.h"
#include "VertexBufferLayout.h"
#include "VertexArray.h"
#include "Shader.h"
#include "Camera.h"
#include "DemoController.h"

extern int windowWidth = 1400;
extern int windowHeight = 900;

int main(void)
{
    GLFWwindow* window;

    /* Initialize the library */
    if (!glfwInit())
        return -1;

    /* Create a windowed mode window and its OpenGL context */
    window = glfwCreateWindow(windowWidth, windowHeight, "Raymarching", nullptr, nullptr);
    if (!window)
    {
        std::cout << "Failed to create a window" << std::endl;
        glfwTerminate();
        return -1;
    }

    
    /* Make the window's context current */
    glfwMakeContextCurrent(window);

    if (GLEW_OK != glewInit())
    {
        /* Problem: glewInit failed, something is seriously wrong. */
        fprintf(stderr, "glewInit error!\n");
    }
    

    float vertices[] = {
         1.0f, 1.0f, 0.0f,  // top right
         1.0f, -1.0f, 0.0f,  // bottom right
         -1.0f, -1.0f, 0.0f,  // bottom left
         -1.0f, 1.0f, 0.0f   // top left 
    };
    unsigned int indices[] = {
        0, 1, 3,
        1, 2, 3
    };

    //new Shader("src/shaders/donuts.shader");
    //new Shader("src/shaders/frame.shader");
    //new Shader("src/shaders/menger_fractal.shader");

    {
        DemoController controller;
        VertexArray va;
        VertexBuffer vb(vertices, sizeof(vertices));

        VertexBufferLayout layout;
        layout.Push<float>(3);
        va.AddBuffer(vb, layout);


        IndexBuffer ib(indices, sizeof(indices));

        glfwSwapInterval(1);

        Renderer renderer;


        glfwSetInputMode(window, GLFW_CURSOR, GLFW_CURSOR_DISABLED);



        /* Loop until the user closes the window */
        while (!glfwWindowShouldClose(window))
        {
            controller.processInput(window);

            controller.BindVariables();

            renderer.Clear();


            Shader& shader = controller.getShader();


            renderer.Draw(va, ib, shader);

            glfwSwapBuffers(window);


            /* Poll for and process events */
            glfwPollEvents();

        }
    }
    glfwTerminate();
    return 0;
}

