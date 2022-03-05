#include <vector>
#include <cstdio>

typedef unsigned uint;

const int mod = (1<<15);

std::vector<uint> v(5 * mod, 0);

// get from cache
uint ca(uint r0, uint r1) {
  return v[r0 * mod + r1];
}

// calculate
uint f(uint r0, uint r1, uint r7) {
  if (r0 == 0) {
    return (r1 + 1) % mod;
  } else if (r1 == 0) {
    return ca(r0 - 1, r7);
  } else {
    int t = ca(r0, (r1 - 1) % mod);
    return ca(r0 - 1, t);
  }
}

int main() {
  for (uint r7 = 0; r7 < mod; r7++) {
    for (uint r0 = 0; r0 <= 4; r0++) {
      for (uint r1 = 0; r1 < mod; r1++) {
        v[r0 * mod + r1] = f(r0, r1, r7);
      }
    }
    uint r = ca(4, 1);
    printf("f6027(%5u) = %5u\n", r7, r);
    if (r == 6) {
      break;
    }
  }
}
