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

uniform int level;


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



float sdPlane(vec3 p, vec3 n, float h)
{
    return dot(p, n) + h;
}

float sdFloor(vec3 p) {
    return sdPlane(p, vec3(0.0, 1.0, 0.0), 9.5);
}

float sdPlatform(vec3 p, float s, float h)
{
    return max(length(p.xz) - s, abs(p.y + 2.0) - h);
}

float sdSphere(vec3 p, float s)
{
    return length(p) - s;
}



float sdBox(vec3 p, vec3 b)
{
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}


float sdBox(vec2 p, vec2 b)
{
    vec2 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0);
}


float sdCross(in vec3 p)
{
    float da = sdBox(p.xy, vec2(0.3));
    float db = sdBox(p.yz, vec2(0.3));
    float dc = sdBox(p.zx, vec2(0.3));
    return min(da, min(db, dc));
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

float sdCappedCylinder(vec3 p, float h, float r)
{
    vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(r, h);
    return min(max(d.x, d.y), 0.0) + length(max(d, 0.0));
}


float sdTorus(vec3 p, vec2 t)
{
    return length(vec2(length(p.xz) - t.x, p.y)) - t.y;
}

float sdOctahedron(vec3 p, float s)
{
    p = abs(p);
    return (p.x + p.y + p.z - s) * 0.57735027;
}

vec3 flatRepetition(vec3 p) {
    vec3 newP = mod(p + 20.0, 40.0) - 20.0;
    newP.y = p.y;
    return newP;
}

vec2 minX(vec2 p1, vec2 p2) {
    return p1.x < p2.x ? p1 : p2;
}

vec2 getSDF(vec3 p) {
    if (do_mod != 0) {
        p = flatRepetition(p);
    }
    vec2 res = vec2(sdFloor(p), -3.0);
    res = minX(res, vec2(sdPlatform(p, 10.0, 0.1), 0.01));
    res = minX(res, vec2(sdCappedCylinder(p - vec3(0.0, -5.5, 0.0), 3.5, 1.0), 0.01));
    res = minX(res, vec2(sdPlatform(p - vec3(0.0, -6.9, 0.0), 3.0, 0.1), 0.01));

    res = minX(res, vec2(sdSphere(p - vec3(0.0, -1.0, 0.0), 1.0), 1.3));
    res = minX(res, vec2(sdBox(p - vec3(4.0, -1.0, 4.0), vec3(1.0)), 2.5));
    res = minX(res, vec2(sdBoxFrame(p - vec3(-4.0, -0.9, -4.0), vec3(1.0), 0.1), 3.5));
    res = minX(res, vec2(sdCappedCylinder(p - vec3(-4.0, -1.0, 4.0), 1.0, 1.0), 7.1));
    res = minX(res, vec2(sdOctahedron(p - vec3(4.0, -0.9, -4.0), 1.0), 6.2));

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
        if (res < 0.001) break;
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

// find the intersection point of the ray
// returns more information about intersection point
vec4 intersect(in Ray ray) {
    const float tmin = 0.01;
    const float tmax = 1000.0;
    const float error = 0.0001;

    float t = tmin;
    vec4 res = vec4(-1.0);
    for (int i = 0; i < 128 && t < tmax; i++)
    {
        vec4 h = vec4(getSDF(ray.ro + ray.rd * t), 0.0, 0.0);
        t += h.x;
        if (h.x < error * t) {
            return vec4(t, h.yzw);
        }
    }
    if (ray.rd.y < 0.0) {
        float floorDist = t + sdFloor(ray.ro + ray.rd * t);
        return vec4(floorDist, -3.0, 0.0, 0.0);
    }
    return res;
}


vec3 render(in Ray ray) {
    const vec3 skyColor = vec3(0.67843, 0.87451, 0.94510);
    const vec3 colorBottom = vec3(0.98431, 0.98824, 1.00000);

    vec3 light = normalize(vec3(cos(0.2*time), 0.6, sin(0.2*time)));
    const vec3 shadowColor = vec3(1.0);
    const vec3 ambientColor = vec3(0.15, 0.17, 0.20);

    const float fog_density = 0.003;
    const vec3 fog_color = vec3(0.9, 0.9, 0.9);


    float occ = 1.0;


    vec4 data = intersect(ray);

    

    if (data.x > 0.0) {

        vec3 intersectionPoint = ray.ro + data.x * ray.rd;

        vec3 matcol = 0.3 + 0.2 * sin(data.y * 1.5 + vec3(0.1, 1.0, 2.0));

        // floor tiling
       if (data.y < 0.0) {
            const float w = 0.01;
            matcol = vec3(0.1, 0.1, 0.9);
            vec2 i = 2.0 * (abs(fract((intersectionPoint.xz - 0.5 * w) * 0.5) - 0.5) - abs(fract((intersectionPoint.xz + 0.5 * w) * 0.5) - 0.5)) / w;
            float val = 0.5 - 0.5 * i.x * i.y;
            matcol = 0.2 + val * vec3(0.1) + vec3(0.001 * data.x);
        }

        vec3 normal = computeSDFGrad(intersectionPoint);
        float dif = dot(normal, light);
        float shadow = 1.0;
        if (dif > 0.0)
            shadow = softshadow(intersectionPoint, light, 64);
        dif = max(dif, 0.0);

        vec3  hal = normalize(light - ray.rd);
        float specular = dif * shadow * pow(clamp(dot(hal, normal), 0.0, 1.0), 128.0) * (0.04 + 0.8 * pow(clamp(1.0 - dot(hal, light), 0.0, 1.0), 6.0));

        float sky = 0.5 + 0.5 * normal.y;


        vec3 light = vec3(0.0);
        light += 1.0 * dif * shadowColor * shadow; // directional shadow
        light += 0.5 * sky * skyColor * occ; // sky lightning;
        light += 0.25 * occ * ambientColor; // ambient lightning
        vec3 finalColor = matcol * light + specular * 128 * (data.y < 0.1 ? 0.05 : 1);


        float fogFactor = fog != 0 ? 1 : exp(-fog_density * max(length((intersectionPoint - ray.ro)) - 125.0, 0.0));
        float value = ray.rd.y;
        return mix(mix(colorBottom, skyColor, (value + 1.0) / 2.0), finalColor, fogFactor);
    }
    else {
        float value = ray.rd.y;
        return mix(colorBottom, skyColor, (value + 1.0) / 2.0);
    }
}


void main()
{
    Ray ray = getRay(gl_FragCoord);

    FragColor = vec4(render(ray), 1.0);
};

