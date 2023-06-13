#include "Shader.h"

#include <fstream>
#include <string>
#include <sstream>
#include <iostream>
#include <glm/gtc/type_ptr.hpp>

#include "Renderer.h"

Shader::Shader(const std::string& filepath)
    :m_FilePath(filepath), m_RendererID(0)
{
    ShaderSource source = ParseShader(filepath);
    m_RendererID = CreateShader(source);
}

Shader::~Shader()
{
    GLCall(glDeleteProgram(m_RendererID));
}

void Shader::Bind() const
{
    GLCall(glUseProgram(m_RendererID));

}

void Shader::Unbind() const
{
    GLCall(glUseProgram(0));

}

void Shader::SetUniform4f(const std::string& name, float v0, float v1, float v2, float v3)
{
    GLCall(glUniform4f(GetUniformLocation(name), v0, v1, v2, v3));

}

void Shader::SetUniform3f(const std::string& name, glm::vec3 vec)
{
    GLCall(glUniform3fv(GetUniformLocation(name), 1, glm::value_ptr(vec)));

}

void Shader::SetUniformf(const std::string& name, float v)
{
    GLCall(glUniform1f(GetUniformLocation(name), v));

}

void Shader::SetMat4(const std::string& name, glm::mat4& mat)
{
    GLCall(glUniformMatrix4fv(GetUniformLocation(name), 1, GL_FALSE, glm::value_ptr(mat)));

} 
void Shader::SetUniformI(const std::string& name, int v) {
    GLCall(glUniform1i(GetUniformLocation(name), v));
}


ShaderSource Shader::ParseShader(const std::string& filepath) {
    std::ifstream stream(filepath);

    enum class ShaderType {
        NONE = -1, VERTEX = 0, FRAGMENT = 1
    };

    std::string line;
    std::stringstream ss[2];
    ShaderType type = ShaderType::NONE;
    while (getline(stream, line)) {
        if (line.find("#shader") != std::string::npos) {
            if (line.find("vertex") != std::string::npos) {
                type = ShaderType::VERTEX;
            }
            else if (line.find("fragment") != std::string::npos) {
                type = ShaderType::FRAGMENT;
            }
        }
        else {
            ss[(int)type] << line << '\n';
        }
    }
    return { ss[0].str(), ss[1].str() };
}

int Shader::GetUniformLocation(const std::string& name)
{
    if (m_Uniform_Location_Cache.find(name) != m_Uniform_Location_Cache.end())
        return m_Uniform_Location_Cache[name];
    GLCall(unsigned int location = glGetUniformLocation(m_RendererID, name.c_str()));
    if (location == -1)
        std::cout << "Warning uniform " << name << " doesn't exists!" << std::endl;
    m_Uniform_Location_Cache[name] = location;
    return location;
}

unsigned int Shader::CompileShader(unsigned int type, const std::string source) {
    unsigned int shader = glCreateShader(type);
    const char* src = source.c_str();
    glShaderSource(shader, 1, &src, nullptr);
    glCompileShader(shader);

    int  success;
    char infoLog[512];
    glGetShaderiv(shader, GL_COMPILE_STATUS, &success);

    if (success == GL_FALSE)
    {
        glGetShaderInfoLog(shader, 512, NULL, infoLog);
        std::cout << "ERROR::SHADER::COMPILATION_FAILED\n" << infoLog << std::endl;
        return 0;
    }
    return shader;
}

unsigned int Shader::CreateShader(ShaderSource shaderSource) {

    unsigned int vertexShader = CompileShader(GL_VERTEX_SHADER, shaderSource.vertexSource);
    unsigned int fragmentShader = CompileShader(GL_FRAGMENT_SHADER, shaderSource.fragmentSource);


    unsigned int shaderProgram = glCreateProgram();

    glAttachShader(shaderProgram, vertexShader);
    glAttachShader(shaderProgram, fragmentShader);
    glLinkProgram(shaderProgram);

    glValidateProgram(shaderProgram);

    int  success;
    char infoLog[512];
    glGetProgramiv(shaderProgram, GL_LINK_STATUS, &success);
    if (!success) {
        glGetProgramInfoLog(shaderProgram, 512, nullptr, infoLog);
        std::cout << "ERROR::SHADER::PROGRAM::LINKING_FAILED\n" << infoLog << std::endl;
    }

    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);

    return shaderProgram;
}
