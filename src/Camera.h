#pragma once


#include <glm/glm.hpp>
#include <glm/gtc/matrix_transform.hpp>

enum Camera_Movement {
    FORWARD,
    BACKWARD,
    LEFT,
    RIGHT
};

const float MovementSpeed = 2.5f;
const float MouseSensitivity = 0.1f;

class Camera {

    glm::vec3 position;
    glm::vec3 front;
    glm::vec3 up;
    glm::vec3 right;
    glm::vec3 worldUp;
    float yaw;
    float pitch;

    float boostSpeed = 5.0f;

public:

    Camera(glm::vec3 position, float yaw = -90.0f,float pitch = -40.0f) : position(position), yaw(yaw), pitch(pitch) {
        worldUp = glm::vec3(0.0f, 1.0f, 0.0f);
        front = glm::vec3(0.0f, 0.0f, 1.0f);
        updateCameraVectors();
    }

    glm::vec3 GetPosition() { return position; }

    glm::vec3 GetFrontVector() { return front; }

    glm::vec3 getUpVector() { return up;}

    glm::vec3 getRightVector() { return right; }

    void BoostSpeed(bool boost) {
        boostSpeed = boost ? 5.0f : 1.0f;
    }


    void ProcessMovement(Camera_Movement direction, float deltaTime);

    void ProcessMouse(float xoffset, float yoffset);

private:
    void updateCameraVectors();

};