unit uSha256;

{$mode objfpc}{$H+}

interface

uses
  SysUtils;

type
  TSha256Context = record
    State: array[0..7] of Cardinal;
    Count: QWord;
    Buffer: array[0..63] of Byte;
  end;

procedure Sha256Init(var Ctx: TSha256Context);
procedure Sha256Update(var Ctx: TSha256Context; const Data; Len: Cardinal);
procedure Sha256Final(var Ctx: TSha256Context; out Digest: array of Byte);
function Sha256Hex(const Texto: string): string;
function Sha256HexBytes(const Data; Len: Cardinal): string;

implementation

const
  K256: array[0..63] of Cardinal = (
    $428a2f98, $71374491, $b5c0fbcf, $e9b5dba5, $3956c25b, $59f111f1, $923f82a4, $ab1c5ed5,
    $d807aa98, $12835b01, $243185be, $550c7dc3, $72be5d74, $80deb1fe, $9bdc06a7, $c19bf174,
    $e49b69c1, $efbe4786, $0fc19dc6, $240ca1cc, $2de92c6f, $4a7484aa, $5cb0a9dc, $76f988da,
    $983e5152, $a831c66d, $b00327c8, $bf597fc7, $c6e00bf3, $d5a79147, $06ca6351, $14292967,
    $27b70a85, $2e1b2138, $4d2c6dfc, $53380d13, $650a7354, $766a0abb, $81c2c92e, $92722c85,
    $a2bfe8a1, $a81a664b, $c24b8b70, $c76c51a3, $d192e819, $d6990624, $f40e3585, $106aa070,
    $19a4c116, $1e376c08, $2748774c, $34b0bcb5, $391c0cb3, $4ed8aa4a, $5b9cca4f, $682e6ff3,
    $748f82ee, $78a5636f, $84c87814, $8cc70208, $90befffa, $a4506ceb, $bef9a3f7, $c67178f2
  );

function ROR(X: Cardinal; N: Byte): Cardinal; inline;
begin
  Result := (X shr N) or (X shl (32 - N));
end;

function Ch(X, Y, Z: Cardinal): Cardinal; inline;
begin
  Result := (X and Y) xor ((not X) and Z);
end;

function Maj(X, Y, Z: Cardinal): Cardinal; inline;
begin
  Result := (X and Y) xor (X and Z) xor (Y and Z);
end;

function Sigma0(X: Cardinal): Cardinal; inline;
begin
  Result := ROR(X, 2) xor ROR(X, 13) xor ROR(X, 22);
end;

function Sigma1(X: Cardinal): Cardinal; inline;
begin
  Result := ROR(X, 6) xor ROR(X, 11) xor ROR(X, 25);
end;

function Gamma0(X: Cardinal): Cardinal; inline;
begin
  Result := ROR(X, 7) xor ROR(X, 18) xor (X shr 3);
end;

function Gamma1(X: Cardinal): Cardinal; inline;
begin
  Result := ROR(X, 17) xor ROR(X, 19) xor (X shr 10);
end;

procedure Transform(var State: array of Cardinal; const Buffer: array of Byte);
var
  W: array[0..63] of Cardinal;
  A, B, C, D, E, F, G, H, T1, T2: Cardinal;
  i: Integer;
begin
  for i := 0 to 15 do
    W[i] := (Cardinal(Buffer[i * 4]) shl 24) or
            (Cardinal(Buffer[i * 4 + 1]) shl 16) or
            (Cardinal(Buffer[i * 4 + 2]) shl 8) or
            Cardinal(Buffer[i * 4 + 3]);

  for i := 16 to 63 do
    W[i] := Gamma1(W[i - 2]) + W[i - 7] + Gamma0(W[i - 15]) + W[i - 16];

  A := State[0];
  B := State[1];
  C := State[2];
  D := State[3];
  E := State[4];
  F := State[5];
  G := State[6];
  H := State[7];

  for i := 0 to 63 do
  begin
    T1 := H + Sigma1(E) + Ch(E, F, G) + K256[i] + W[i];
    T2 := Sigma0(A) + Maj(A, B, C);
    H := G;
    G := F;
    F := E;
    E := D + T1;
    D := C;
    C := B;
    B := A;
    A := T1 + T2;
  end;

  Inc(State[0], A);
  Inc(State[1], B);
  Inc(State[2], C);
  Inc(State[3], D);
  Inc(State[4], E);
  Inc(State[5], F);
  Inc(State[6], G);
  Inc(State[7], H);
end;

procedure Sha256Init(var Ctx: TSha256Context);
begin
  Ctx.State[0] := $6a09e667;
  Ctx.State[1] := $bb67ae85;
  Ctx.State[2] := $3c6ef372;
  Ctx.State[3] := $a54ff53a;
  Ctx.State[4] := $510e527f;
  Ctx.State[5] := $9b05688c;
  Ctx.State[6] := $1f83d9ab;
  Ctx.State[7] := $5be0cd19;
  Ctx.Count := 0;
  FillChar(Ctx.Buffer, SizeOf(Ctx.Buffer), 0);
end;

procedure Sha256Update(var Ctx: TSha256Context; const Data; Len: Cardinal);
var
  P: PByte;
  Left, Fill: Cardinal;
begin
  if Len = 0 then Exit;
  P := PByte(@Data);
  Left := Ctx.Count and 63;
  Fill := 64 - Left;
  Inc(Ctx.Count, Len);

  if (Left > 0) and (Len >= Fill) then
  begin
    Move(P^, Ctx.Buffer[Left], Fill);
    Transform(Ctx.State, Ctx.Buffer);
    Inc(P, Fill);
    Dec(Len, Fill);
    Left := 0;
  end;

  while Len >= 64 do
  begin
    Transform(Ctx.State, PByteArray(P)^);
    Inc(P, 64);
    Dec(Len, 64);
  end;

  if Len > 0 then
    Move(P^, Ctx.Buffer[Left], Len);
end;

procedure Sha256Final(var Ctx: TSha256Context; out Digest: array of Byte);
var
  Bits: QWord;
  PadLen: Cardinal;
  Padding: array[0..63] of Byte;
  i: Integer;
begin
  Bits := Ctx.Count * 8;
  PadLen := (Ctx.Count and 63);
  if PadLen < 56 then
    PadLen := 56 - PadLen
  else
    PadLen := 120 - PadLen;

  FillChar(Padding, SizeOf(Padding), 0);
  Padding[0] := $80;
  Sha256Update(Ctx, Padding, PadLen);

  // Big endian bits count
  Padding[0] := Byte(Bits shr 56);
  Padding[1] := Byte(Bits shr 48);
  Padding[2] := Byte(Bits shr 40);
  Padding[3] := Byte(Bits shr 32);
  Padding[4] := Byte(Bits shr 24);
  Padding[5] := Byte(Bits shr 16);
  Padding[6] := Byte(Bits shr 8);
  Padding[7] := Byte(Bits);
  Sha256Update(Ctx, Padding, 8);

  for i := 0 to 7 do
  begin
    Digest[i * 4] := Byte(Ctx.State[i] shr 24);
    Digest[i * 4 + 1] := Byte(Ctx.State[i] shr 16);
    Digest[i * 4 + 2] := Byte(Ctx.State[i] shr 8);
    Digest[i * 4 + 3] := Byte(Ctx.State[i]);
  end;
end;

function Sha256HexBytes(const Data; Len: Cardinal): string;
var
  Ctx: TSha256Context;
  Digest: array[0..31] of Byte;
  i: Integer;
begin
  Sha256Init(Ctx);
  Sha256Update(Ctx, Data, Len);
  Sha256Final(Ctx, Digest);
  Result := '';
  for i := 0 to 31 do
    Result := Result + LowerCase(IntToHex(Digest[i], 2));
end;

function Sha256Hex(const Texto: string): string;
var
  U: UTF8String;
begin
  U := UTF8Encode(Texto);
  if Length(U) = 0 then
    Result := Sha256HexBytes('', 0)
  else
    Result := Sha256HexBytes(U[1], Length(U));
end;

end.

