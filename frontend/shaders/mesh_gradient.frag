#version 460 core

uniform vec2 uSize;
uniform float uTime;
uniform float uState; // -1.0 = отрицательно (красный), 0.0 = бездействие (ч/б), 1.0 = положительно (зеленый)

out vec4 fragColor;

// ==== Цвета ====
// Верх (Светлый)
const vec3 colorTopNeutral = vec3(0.9, 0.9, 0.92);
const vec3 colorTopNeg     = vec3(0.9, 0.2, 0.25);
const vec3 colorTopPos     = vec3(0.2, 0.9, 0.4);

// Низ (Темный)
const vec3 colorBotNeutral = vec3(0.04, 0.04, 0.05);
const vec3 colorBotNeg     = vec3(0.15, 0.02, 0.03);
const vec3 colorBotPos     = vec3(0.02, 0.15, 0.05);

const float grainAmount    = 0.10;

float hash21(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

// Интерполяция трех состояний по uState (-1..0..1)
vec3 mixState(vec3 neg, vec3 neutral, vec3 pos, float s) {
    float negW = clamp(-s, 0.0, 1.0);
    float posW = clamp(s, 0.0, 1.0);
    vec3 col = neutral;
    col = mix(col, neg, negW);
    col = mix(col, pos, posW);
    return col;
}

void main() {
    vec2 res = uSize;
    // В Flutter 0.0 - это верхний левый угол
    vec2 uv = gl_FragCoord.xy / res;

    // Цвета текущего состояния
    vec3 topCol = mixState(colorTopNeg, colorTopNeutral, colorTopPos, uState);
    vec3 botCol = mixState(colorBotNeg, colorBotNeutral, colorBotPos, uState);

    // Скорость движения чуть растет при "активном" состоянии
    float activity = abs(uState);
    float speedMul = mix(1.0, 1.5, activity);
    float t = uTime * 0.4 * speedMul;

    // Небольшое волнообразное движение
    // Создаем несколько плавных волн, которые смешиваются друг с другом
    float wave1 = sin(uv.x * 3.0 + t) * 0.15;
    float wave2 = cos(uv.x * 1.5 - t * 0.8) * 0.1;
    float wave3 = sin(uv.x * 5.0 + t * 1.2) * 0.05;
    
    float totalWave = wave1 + wave2 + wave3;

    // Вертикальный градиент: 0.0 (верх) -> 1.0 (низ)
    // Добавляем к нему волну, чтобы граница слегка "дышала"
    float mixFactor = uv.y + totalWave;
    
    // Делаем переход очень плавным
    mixFactor = smoothstep(0.1, 0.9, mixFactor);

    // Смешиваем верхний и нижний цвет
    // uv.y = 0 (верх), поэтому при mixFactor = 0 берем topCol
    vec3 col = mix(topCol, botCol, mixFactor);

    // Статичное мелкое зерно для фактуры (как на референсе)
    float grain = fract(sin(dot(gl_FragCoord.xy, vec2(12.9898, 78.233))) * 43758.5453) - 0.5;
    col += grain * grainAmount;

    fragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}
