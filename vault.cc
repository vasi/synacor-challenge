#include <cstdlib>
#include <string>
#include <unordered_map>
#include <vector>
using std::string;
using std::unordered_map;
using std::vector;

enum Room {
  Invalid,
  Antechamber,
  A3,
  B2,
  B4,
  C1,
  C3,
  D2,
  Door,
};

enum Op {
  Add,
  Subtract,
  Multiply,
};

struct Path {
  Room source;
  string name;
  Op op;
  int operand;
};

// For each room, how can we get there going forwards?
unordered_map<Room, vector<Path>> all_paths = {
  {Antechamber, {}}, // can't get here, orb disappears
  {A3, {
    {Antechamber, "A2-A3", Add, 4},
    {B2, "A2-A3", Add, 4},
    {B2, "B3-A3", Multiply, 4},
    {B4, "A4-A3", Multiply, 4},
    // no dup from B3
    {C3, "B3-A3", Multiply, 4},
  }},
  {B2, {
    {Antechamber, "A2-B2", Add, 4},
    {Antechamber, "B1-B2", Subtract, 4},
    {A3, "A2-B2", Add, 4},
    {A3, "B3-B2", Multiply, 4},
    {B4, "B3-B2", Multiply, 4},
    {C1, "B1-B2", Subtract, 4},
    // no dup from C1
    {C3, "B3-B2", Multiply, 4},
    {C3, "C2-B2", Subtract, 4},
    {D2, "C2-B2", Subtract, 4},
  }},
  {B4, {
    {A3, "A4-B4", Multiply, 8},
    // no dup from A3
    {B2, "B3-B4", Multiply, 8},
    {C3, "B3-B4", Multiply, 8},
    {C3, "C4-B4", Subtract, 8},
    // door kills the orb
  }},
  {C1, {
    {Antechamber, "B1-C1", Subtract, 9},
    {B2, "B1-C1", Subtract, 9},
    // no dup from B2
    {C3, "C2-C1", Subtract, 9},
    {D2, "C2-C1", Subtract, 9},
    {D2, "D1-C1", Multiply, 9},
  }},
  {C3, {
    {A3, "B3-C3", Multiply, 11},
    {B2, "B3-C3", Multiply, 11},
    {B2, "C2-C3", Subtract, 11},
    {B4, "B3-C3", Multiply, 11},
    {B4, "C4-C3", Subtract, 11},
    {C1, "C2-C3", Subtract, 11},
    {D2, "C2-C3", Subtract, 11},
    {D2, "D3-C3", Multiply, 11},
    // door kills the orb
  }},
  {D2, {
    {B2, "C2-D2", Subtract, 18},
    {C1, "C2-D2", Subtract, 18},
    {C1, "D1-D2", Multiply, 18},
    {C3, "C2-D2", Subtract, 18},
    {C3, "D3-D2", Multiply, 18},
  }},
  {Door, {
    {B4, "C4-Door", Subtract, 1},
    {C3, "C4-Door", Subtract, 1},
    {C3, "D3-Door", Multiply, 1},
    {D2, "D3-Door", Multiply, 1},
  }},
};

struct State {
  Room room;
  int value;

  bool operator==(const State&) const = default;

  bool valid() const { return room != Invalid; }

  static State invalid() { return State(Invalid, 0); }
};

namespace std {
  template <> struct hash<State> {
    size_t operator()(const State& s) const {
      return ((size_t)s.room << 40) ^ s.value;
    }
  };
}

struct Breadcrumb {
  State state;
  const Path *path;
};

struct Finder {
  int curstep;
  State start;
  // each value seen, and how we go from there to the target
  vector<State> current;
  unordered_map<State, Breadcrumb> seen;

  Finder(State _target, State _start)
    : curstep(0), start(_start), current{_target},
      seen{{_target, {State::invalid(), nullptr}}} {}

  State follow_back(State s, const Path& p) const {
    // op is inverted, because we're going backwards!
    // backwards is better, since we can eliminate more multiplications
    if (p.op == Add) {
      if (s.value <= p.operand)
        return State::invalid();
      return State(p.source, s.value - p.operand);
    } else if (p.op == Subtract) {
      return State(p.source, s.value + p.operand);
    } else if (p.op == Multiply) {
      if (s.value % p.operand != 0)
        return State::invalid();
      return State(p.source, s.value / p.operand);
    }
    abort();
  }

  void print_path() const {
    printf("Start");
    State cur = start;
    while (true) {
      const Breadcrumb& b = seen.at(cur);
      if (!b.state.valid()) {
        printf("\n");
        return;
      }
      printf("-%s", b.path->name.c_str());
      cur = b.state;
    }
  }

  // return if finisheed
  bool step() {
    vector<State> prev;
    prev.swap(current);

    for (State state : prev) {
      for (const Path &path : all_paths[state.room]) {
        State next = follow_back(state, path);
        if (!next.valid())
          continue;
        
        if (seen.contains(next)) {
          continue;
        }
        seen[next] = Breadcrumb(state, &path);
        current.push_back(next);

        if (next == start) {
          print_path();
          return true;
        }
      }
    }

    printf("Done with step %d, current items: %ld\n", curstep, current.size());
    ++curstep;
    return false;
  }

  void find() {
    while (!step()) {
      // try again
    }
  }
};

int main() {
  Finder finder{{Door, 30}, {Antechamber, 22}};
  finder.find();
  return 0; 
}
