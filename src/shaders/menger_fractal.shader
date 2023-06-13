#shader vertex
#version 330 core

layout(location = 0) in vec3 aPos;

void main()
{
    gl_Position = vec4(aPos, 1);
};

#shader fragment
#version 330 core

out vec4 FragColor;

uniform uvec2 window_size;

uniform vec4 fov;
uniform float time;
uniform int do_mod;
uniform int fog;

uniform vec3 position;
uniform vec3 front;
uniform vec3 up;
uniform vec3 right;

struct Ray {
    vec3 ro;
    vec3 rd;
};

Ray getRay(vec4 fragCoord)
{
    float x_screen = (float(gl_FragCoord.x * 2 / window_size.x) - 1);
    float y_screen = (float(gl_FragCoord.y * 2 / window_size.y) - 1);

    vec3 ray = normalize(x_screen * right * fov.x + y_screen * up * fov.y + front);

    return Ray(position, ray);
}

float sdBoxFrame(vec3 p, vec3 b, float e)
{
    p = abs(p) - b;
    vec3 q = abs(p + e) - e;
    return min(min(
        length(max(vec3(p.x, q.y, q.z), 0.0)) + min(max(p.x, max(q.y, q.z)), 0.0),
        length(max(vec3(q.x, p.y, q.z), 0.0)) + min(max(q.x, max(p.y, q.z)), 0.0)),
        length(max(vec3(q.x, q.y, p.z), 0.0)) + min(max(q.x, max(q.y, p.z)), 0.0));
}

float sdBox(vec3 p, vec3 b)
{
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sdTorus(vec3 p, vec2 t)
{
    return length(vec2(length(p.xz) - t.x, p.y)) - t.y;
}
const mat3 ma = mat3( 0.60, 0.00,  0.80,
                      0.00, 1.00,  0.00,
                     -0.80, 0.00,  0.60 );

vec4 getSDF(vec3 p) {
    const float modulo = 5.0;

    if (do_mod != 0)
        p = mod(p + modulo, 2 * modulo) - modulo;
    float d = sdBox(p, vec3(1.0));
    float s = 1.0;
    vec4 res = vec4(d, 1.0, 0.0, 0.0);
    for (int i = 0; i < 5; i++) {
        vec3 a = mod(p * s, 2.0) - 1.0;
        s *= 3.0;
        vec3 r = abs(1.0 - 3.0 * abs(a) - 0.2 + 0.2 * sin(0.5*time));

        float da = max(r.x, r.y);
        float db = max(r.y, r.z);
        float dc = max(r.z, r.x);
        float c = (min(da, min(db, dc)) - 1.0) / s;
        if (c > d)
        {
            d = c;
            res = vec4(d, 0.2 * da * db * dc, 0.1*float(i), 0.0);
        }

    }
    return res;
}


float softshadow(vec3 ro, vec3 rd, float k)
{
    const float mint = 0.01;
    const float maxt = 1000;


    float res = 0.7;
    float t = mint;
    for (int i = 0; i < 64; i++)
    {
        float h = getSDF(ro + rd * t).x;
        res = min(res, k * h / t);
        if (res < 0.0001 * t) break;
        t += clamp(h, 0.005, 0.1);
        if (t > maxt) break;
    }
    return clamp(res, 0.0, 1.0);
}


#define EPS_GRAD 0.001
vec3 computeSDFGrad(in vec3 p)
{
    vec3 p_x_p = p + vec3(EPS_GRAD, 0, 0);
    vec3 p_x_m = p - vec3(EPS_GRAD, 0, 0);
    vec3 p_y_p = p + vec3(0, EPS_GRAD, 0);
    vec3 p_y_m = p - vec3(0, EPS_GRAD, 0);
    vec3 p_z_p = p + vec3(0, 0, EPS_GRAD);
    vec3 p_z_m = p - vec3(0, 0, EPS_GRAD);

    float sdf_x_p = getSDF(p_x_p).x;
    float sdf_x_m = getSDF(p_x_m).x;
    float sdf_y_p = getSDF(p_y_p).x;
    float sdf_y_m = getSDF(p_y_m).x;
    float sdf_z_p = getSDF(p_z_p).x;
    float sdf_z_m = getSDF(p_z_m).x;


    return vec3(sdf_x_p - sdf_x_m,
        sdf_y_p - sdf_y_m,
        sdf_z_p - sdf_z_m) / (2. * EPS_GRAD);
}

vec4 intersect(in Ray ray) {
    const float tmin = 0.01;
    const float tmax = 2000.0;
    const float error = 0.00005;

    float t = tmin;
    vec4 res = vec4(-1.0);
    for (int i = 0; i < 128 && t < tmax; i++)
    {
        vec4 h = getSDF(ray.ro + ray.rd * t);
        if (h.x < t * error) {
            res = vec4(t, h.yzw);
            break;
        }
        t += h.x;
    }
    return res;
}

vec3 render(in Ray ray) {
    const vec3 skyColor = vec3(0.47843, 0.67451, 0.94510);
    const vec3 colorBottom = vec3(0.98431, 0.98824, 1.00000);

    const vec3 lightDir = normalize(vec3(1.0, 0.9, 0.3));
    const vec3 shadowColor = vec3(1.0);
    const vec3 ambientColor = vec3(0.15, 0.17, 0.20);

    const float fog_density = 0.009;
    const vec3 fog_color = vec3(0.9, 0.9, 0.9);


    vec4 data = intersect(ray);

    vec3 matcol = 0.6 + 0.5 * cos(vec3(0.0, 1.0, 2.0) + 2.0 * data.z);
    float occ = data.y;


    float value = ray.rd.y;
    vec3 backgroundColor = mix(colorBottom, skyColor, (value + 1.0) / 2.0);

    if (data.x < 0.0) {
        return backgroundColor;
    }
    vec3 intersectionPoint = ray.ro + data.x * ray.rd;
    vec3 normal = computeSDFGrad(intersectionPoint);
    float dif = dot(normal, lightDir);
    float shadow = 1.0;
    if (dif > 0.0)
        shadow = softshadow(intersectionPoint, lightDir, 64);
    dif = max(dif, 0.0);

    vec3 hal = normalize(lightDir - ray.rd);
    float specular = dif * shadow * pow(clamp(dot(hal, normal), 0.0, 1.0), 128.0)
        * (0.04 + 0.8 * pow(clamp(1.0 - dot(hal, lightDir), 0.0, 1.0), 6.0));

    float sky = 0.5 + 0.5 * normal.y;


    vec3 light = vec3(0.0);
    light += 1.0 * dif * shadowColor * shadow; // directional shadow
    light += 0.5 * sky * skyColor * occ; // sky lightning;
    light += 0.25 * occ * ambientColor; // ambient lightning
    vec3 finalColor = matcol * light + specular * 128;

    float fogFactor = fog != 0 ? 1 : exp(-fog_density * max(length((intersectionPoint - ray.ro)) - 25.0, 0.0));

    return mix(backgroundColor, finalColor, fogFactor);
}


void main()
{
    Ray ray = getRay(gl_FragCoord);

    FragColor = vec4(render(ray), 1.0);
};

