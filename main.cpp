#define T_PGE_APPLICATION
#include "tPixelGameEngine.h"

class ShaderProgrammer : public tDX::PixelGameEngine
{
public:
  ShaderProgrammer()
  {
    sAppName = "Shader Programmer";
  }

public:
  bool OnUserCreate() override
  {
    // Called once at the start, so create things here
    return true;
  }

  bool OnUserUpdate(float fElapsedTime) override
  {

    return true;
  }
};


int main()
{
  ShaderProgrammer demo;
  if (demo.Construct(800, 800, 1, 1))
    demo.Start();

  return 0;
}
