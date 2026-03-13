#pragma once
#include <memory>
#include <string>
#include <utility>
#include <vector>

namespace ticker {

struct SmokeObj {
  std::string name;
  int value;
  SmokeObj(std::string n, int v) : name(std::move(n)), value(v) {}
};

inline std::string cxx14_smoke() {
  auto p = std::make_unique<SmokeObj>("cxx14", 0b1010);
  auto add = [](auto a, auto b) { return a + b; }; // C++14 generic lambda
  std::vector<int> v;
  v.push_back(add(p->value, 2));
  return p->name + ":" + std::to_string(v.front());
}

} // namespace ticker
