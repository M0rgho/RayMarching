#pragma once

#include <string>
#include <unordered_map>
#include <glm/mat4x4.hpp>

struct ShaderSource {
	std::string vertexSource;
	std::string fragmentSource;
};


class Shader
{
private:
	std::string m_FilePath;
	unsigned int m_RendererID;
	std::unordered_map<std::string, int> m_Uniform_Location_Cache;
public:
	Shader(const std::string& filepath);
	~Shader();

	void Bind() const;
	void Unbind() const;

	void SetUniform4f(const std::string& name, float v0, float v1, float v2, float v3);
	void SetMat4(const std::string& name, glm::mat4& mat);
	void SetUniform3f(const std::string& name, glm::vec3 vec);
	void SetUniformf(const std::string& name, float v);
	void SetUniformI(const std::string& name, int v);

	inline unsigned int getID() const { return m_RendererID; }

private:
	ShaderSource ParseShader(const std::string& filepath);
	unsigned int CreateShader(ShaderSource shaderSource);
	unsigned int CompileShader(unsigned int type, const std::string source);
	int GetUniformLocation(const std::string& name);
};