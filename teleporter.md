# Base data

Starting registers:

```
r0:   4
r1:   1
r2:   3
r3:  10
r4: 101
r5:   0
r6:   0
r7: ???
```

PCs used with counts:
```
6027:  1486
6035:   830
6048:   821
6050:   821
6054:   821
6038:     9
6042:     9
6045:     9
6030:   656
6034:   656
6047:     7
6056:   656
6059:   655
6061:   655
6065:   655
6067:   654
```

Disassembly:
```
6027   jt   r0 6035
6030   add  r0 r1 1
6034   ret  
6035   jt   r1 6048
6038   add  r0 r0 32767
6042   set  r1 r7
6045   call 6027
6047   ret  
6048   push r0
6050   add  r1 r1 32767
6054   call 6027
6056   set  r1 r0
6059   pop  r0
6061   add  r0 r0 32767
6065   call 6027
6067   ret  
```
# Decompilations

## V0

```
start:
  goto 6035 if r0 != 0
  r0 = r1 + 1
  return
6035:
  goto 6048 if r1 != 0
  r0 += 32767
  r1 = r7
  call start
  return
6048:
  push r0
  r1 += 32767
  call start
  r1 = r0
  r0 = pop
  r0 += 32767
  call start
  return
```

## V1

```
void start() {
  if (r0 == 0) {
    r0 = r1 + 1;
    return;
  }
  if (r1 == 0) {
    r0--;
    r1 = r7;
    start();
    return;
  }
  push(r0);
  r1--;
  start();
  r1 = r0;
  r0 = pop() - 1;
  start();
  return;
}
```

## V2

```
void start() {
  if (a == 0) {
    a = b + 1;
    return;
  }
  if (b == 0) {
    a--;
    b = r7;
    start();
    return;
  }
  c = a;
  b--;
  start();
  b = a;
  a = c - 1;
  start();
  return;
}

a = 4;
b = 1;
start();
```

## V3

```
int f(a, b) {
  if (a == 0) {
    return b + 1;
  } else if (b == 0) {
    return f(a - 1, r7);
  } else {
    c = f(a, b - 1)
    return f(a - 1, c);
  }
}

f(4, 1);
```

## V4

```
f(0, y) = y + 1
f(x, 0) = f(x - 1, r7)
f(x, y) = f(x - 1, f(x, y - 1))
f(4, 1)
```

# Tests

## Induction

let r7 = 1

f(0, b) = b + 1
f(1, 0) = f(0, 1) = 2
f(1, 1) = f(0, 2) = 3
f(1, b) = b + 2
f(2, 0) = f(1, 1) = 3
f(2, 1) = f(1, 3) = 5
f(2, 2) = f(1, 5) = 7
f(2, b) = 2b + 3
f(3, 0) = f(2, 1) = 5
f(3, 1) = f(2, 5) = 13
f(3, 2) = f(2, 13) = 29
f(3, 3) = f(2, 29) = 61
f(3, b) = 2^(b+3) - 3
f(4, 0) = f(3, 1) = 13
f(4, 1) = f(3, 13) = 65533 ~ 32765

Can't calculate analytically, cuz we quickly hit intmax!
