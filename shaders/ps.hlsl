cbuffer Constants : register(b0)
{
    float iTime;
    float iResolutionX;
    float iResolutionY;
    float iMouseX;
    float iMouseY;
    float3 padding;
};

float hash(float seed)
{
    return frac(seed * 0.1031 - floor(seed * 0.1031));
}

float4 main(float4 position : SV_POSITION, float2 texCoord : TexCoord) : SV_Target
{
    float4 fragColor;
    float2 fragCoord = texCoord * float2(iResolutionX, iResolutionY);
    float2 uv = fragCoord / float2(iResolutionX, iResolutionY);
    
    float sandDensity;
    
    float L = 2.0;
    float x = (uv.x - 0.5) * L;
    float y = (uv.y - 0.5) * L;
    
    float PI = 3.14159;
    
    float cycleLength = 4.0;
    float cycleIndex = floor(iTime / cycleLength);
    float cycleProgress = frac(iTime / cycleLength);
    
    float transitionDuration = 1.0;
    float transitionStart = 1.0 - transitionDuration / cycleLength;
    float transitionFactor = 0.0;
    
    if (cycleProgress > transitionStart)
    {
        transitionFactor = (cycleProgress - transitionStart) / (transitionDuration / cycleLength);
        transitionFactor = smoothstep(0.0, 1.0, transitionFactor);
    }

    float seed1 = hash(cycleIndex * 73.0);
    float seed2 = hash(cycleIndex * 127.0 + 17.0);
    
    int n = int(seed1 * 10.0) + 1;
    int m = int(seed2 * 10.0) + 1;
    

    if (n == m)
    {
        m = (m % 10) + 1;
        if (m == n)
            m = (m % 10) + 1;
    }
    
    
    float fn = float(n);
    float fm = float(m);
    
    float term1 = cos(fn * PI * x / L) * cos(fm * PI * y / L);
    float term2 = cos(fm * PI * x / L) * cos(fn * PI * y / L);
    
    float chladni = term1 - term2;
    
    if (cycleProgress > transitionStart)
    {
        
        float nextCycleIndex = cycleIndex + 1.0;
        float nextSeed1 = hash(nextCycleIndex * 73.0);
        float nextSeed2 = hash(nextCycleIndex * 127.0 + 17.0);
        
        int nextN = int(nextSeed1 * 10.0) + 1;
        int nextM = int(nextSeed2 * 10.0) + 1;
        
        if (nextN == nextM)
        {
            nextM = (nextM % 10) + 1;
            if (nextM == nextN)
                nextM = (nextM % 10) + 1;
        }
        
        float nextFn = float(nextN);
        float nextFm = float(nextM);
        
        float nextTerm1 = cos(nextFn * PI * x / L) * cos(nextFm * PI * y / L);
        float nextTerm2 = cos(nextFm * PI * x / L) * cos(nextFn * PI * y / L);
        float nextChladni = nextTerm1 - nextTerm2;
        
        chladni = lerp(chladni, nextChladni, transitionFactor);
    }
    
    float amplitudeAbs = abs(chladni);
    float threshold = 0.08;
    float nodeConcentration = 1.0 - smoothstep(0.0, threshold, amplitudeAbs);
    
    float timeOffset = iTime * 0.005;
    
    float2 uvNoise = fragCoord / float2(iResolutionX, iResolutionY);
    
    float noise1 = frac(sin(dot(uvNoise + timeOffset, float2(12.9898, 78.233))) * 43758.5453 * (cycleIndex + 1));
    float noise2 = frac(sin(dot(uvNoise * 0.5, float2(63.7264, 10.873))) * 43758.5453 * (cycleIndex + 1));
    float clumping = noise1 * noise2;
    
    float stuckGrainHash = frac(sin(dot(uvNoise, float2(54.321, 91.654))) * 22578.1459 * (cycleIndex + 1));
    float stuckGrains = step(0.97, stuckGrainHash) * smoothstep(0.2, 0.8, clumping);
    
    if (cycleProgress > transitionStart)
    {
        float nextNoise1 = frac(sin(dot(uvNoise + timeOffset, float2(12.9898, 78.233))) * 43758.5453 * (cycleIndex + 2));
        float nextNoise2 = frac(sin(dot(uvNoise * 0.5 + timeOffset, float2(63.7264, 10.873))) * 43758.5453 * (cycleIndex + 2));
        float nextClumping = nextNoise1 * nextNoise2;
        
        float nextStuckGrainHash = frac(sin(dot(uvNoise, float2(54.321, 91.654))) * 22578.1459 * (cycleIndex + 2));
        float nextStuckGrains = step(0.97, nextStuckGrainHash) * smoothstep(0.2, 0.8, nextClumping);
        
        clumping = lerp(clumping, nextClumping, transitionFactor);
        stuckGrains = lerp(stuckGrains, nextStuckGrains, transitionFactor);
    }

    // Main pattern sand
    sandDensity = nodeConcentration * smoothstep(0.2, 0.8, clumping);

    // Combine: pattern sand + random stuck grains
    sandDensity = max(sandDensity, stuckGrains * 0.8);

    float centerDist = length(float2(x, y));
    float centerClamp = smoothstep(0.0, 0.03, centerDist);
    
    float edgeX = 1.0 - smoothstep(0.9, 1.0, abs(x / (L / 2.0)));
    float edgeY = 1.0 - smoothstep(0.9, 1.0, abs(y / (L / 2.0)));
    float plateBoundary = edgeX * edgeY;
    
    sandDensity *= centerClamp * plateBoundary;
    
    float3 plateColor = float3(0.05, 0.05, 0.08);
    float3 sandColor = float3(0.95, 0.9, 0.8);
    
    float3 centerColor = float3(0.2, 0.15, 0.1);
    float centerInfluence = 1.0 - smoothstep(0.0, 0.05, centerDist);
    plateColor = lerp(plateColor, centerColor, centerInfluence);
    
    float3 color = lerp(plateColor, sandColor, sandDensity);
    
    fragColor = float4(color, 1.0);
    return fragColor;
}