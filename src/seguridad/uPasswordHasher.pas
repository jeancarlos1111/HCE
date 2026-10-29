unit uPasswordHasher;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, uSha256;

type
  IPasswordHasher = interface
    ['{B989D30B-18FD-4B07-B713-33BF41539E11}']
    function HashClave(const AClave: string): string;
    function VerificarClave(const AClave, AHashAlmacenado: string): Boolean;
    function HashPin(const APin: string): string;
    function VerificarPin(const APin, AHashAlmacenado: string): Boolean;
  end;

  { Hasher criptográfico estándar con PBKDF2-HMAC-SHA256 }
  TPBKDF2PasswordHasher = class(TInterfacedObject, IPasswordHasher)
  private
    FIteraciones: Cardinal;
    function GenerarSalHex(ABytes: Integer = 16): string;
    function PBKDF2_SHA256(const APassword, ASalt: string; AIterations, AKeyLen: Cardinal): string;
    function ComparacionTiempoConstante(const A, B: string): Boolean;
  public
    constructor Create(AIteraciones: Cardinal = 100000);
    function HashClave(const AClave: string): string;
    function VerificarClave(const AClave, AHashAlmacenado: string): Boolean;
    function HashPin(const APin: string): string;
    function VerificarPin(const APin, AHashAlmacenado: string): Boolean;
  end;

implementation

{ HMAC-SHA256 helper }
procedure HmacSha256(const Key; KeyLen: Cardinal; const Msg; MsgLen: Cardinal; out Digest: array of Byte);
var
  K0: array[0..63] of Byte;
  Ipad, Opad: array[0..63] of Byte;
  Ctx: TSha256Context;
  InnerDigest: array[0..31] of Byte;
  i: Integer;
begin
  FillChar(K0, SizeOf(K0), 0);
  if KeyLen > 64 then
  begin
    Sha256Init(Ctx);
    Sha256Update(Ctx, Key, KeyLen);
    Sha256Final(Ctx, InnerDigest);
    Move(InnerDigest[0], K0[0], 32);
  end
  else if KeyLen > 0 then
    Move(Key, K0[0], KeyLen);

  for i := 0 to 63 do
  begin
    Ipad[i] := K0[i] xor $36;
    Opad[i] := K0[i] xor $5c;
  end;

  Sha256Init(Ctx);
  Sha256Update(Ctx, Ipad, 64);
  Sha256Update(Ctx, Msg, MsgLen);
  Sha256Final(Ctx, InnerDigest);

  Sha256Init(Ctx);
  Sha256Update(Ctx, Opad, 64);
  Sha256Update(Ctx, InnerDigest, 32);
  Sha256Final(Ctx, Digest);
end;

constructor TPBKDF2PasswordHasher.Create(AIteraciones: Cardinal);
begin
  inherited Create;
  FIteraciones := AIteraciones;
end;

function TPBKDF2PasswordHasher.GenerarSalHex(ABytes: Integer): string;
var
  Buffer: array of Byte;
  i: Integer;
begin
  SetLength(Buffer, ABytes);
  Randomize;
  for i := 0 to ABytes - 1 do
    Buffer[i] := Byte(Random(256));

  Result := '';
  for i := 0 to ABytes - 1 do
    Result := Result + LowerCase(IntToHex(Buffer[i], 2));
end;

function HexToBytes(const HexStr: string): TBytes;
var
  i, Len: Integer;
begin
  Len := Length(HexStr) div 2;
  SetLength(Result, Len);
  for i := 0 to Len - 1 do
    Result[i] := StrToInt('$' + Copy(HexStr, i * 2 + 1, 2));
end;

function BytesToHex(const B: array of Byte; Len: Integer): string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to Len - 1 do
    Result := Result + LowerCase(IntToHex(B[i], 2));
end;

function TPBKDF2PasswordHasher.PBKDF2_SHA256(const APassword, ASalt: string; AIterations, AKeyLen: Cardinal): string;
var
  PassBytes, SaltBytes: TBytes;
  BlockIndex: Cardinal;
  TotalBlocks: Cardinal;
  U, T, SaltBlock: array of Byte;
  ResultKey: array of Byte;
  i, j, k, CurrentBlockLen: Integer;
begin
  PassBytes := TEncoding.UTF8.GetBytes(APassword);
  SaltBytes := HexToBytes(ASalt);

  TotalBlocks := (AKeyLen + 31) div 32;
  SetLength(ResultKey, AKeyLen);
  SetLength(U, 32);
  SetLength(T, 32);

  for BlockIndex := 1 to TotalBlocks do
  begin
    // Salt + BigEndian(BlockIndex)
    SetLength(SaltBlock, Length(SaltBytes) + 4);
    Move(SaltBytes[0], SaltBlock[0], Length(SaltBytes));
    SaltBlock[Length(SaltBytes)] := Byte(BlockIndex shr 24);
    SaltBlock[Length(SaltBytes) + 1] := Byte(BlockIndex shr 16);
    SaltBlock[Length(SaltBytes) + 2] := Byte(BlockIndex shr 8);
    SaltBlock[Length(SaltBytes) + 3] := Byte(BlockIndex);

    // U_1 = PRF(Password, SaltBlock)
    HmacSha256(PassBytes[0], Length(PassBytes), SaltBlock[0], Length(SaltBlock), U[0]);
    Move(U[0], T[0], 32);

    for j := 2 to AIterations do
    begin
      HmacSha256(PassBytes[0], Length(PassBytes), U[0], 32, U[0]);
      for k := 0 to 31 do
        T[k] := T[k] xor U[k];
    end;

    if BlockIndex * 32 <= AKeyLen then
      CurrentBlockLen := 32
    else
      CurrentBlockLen := AKeyLen - (BlockIndex - 1) * 32;

    Move(T[0], ResultKey[(BlockIndex - 1) * 32], CurrentBlockLen);
  end;

  Result := BytesToHex(ResultKey, AKeyLen);
end;

function TPBKDF2PasswordHasher.ComparacionTiempoConstante(const A, B: string): Boolean;
var
  Diff: Integer;
  i: Integer;
begin
  if Length(A) <> Length(B) then
    Exit(False);

  Diff := 0;
  for i := 1 to Length(A) do
    Diff := Diff or (Ord(A[i]) xor Ord(B[i]));

  Result := (Diff = 0);
end;

function TPBKDF2PasswordHasher.HashClave(const AClave: string): string;
var
  Sal: string;
  Hash: string;
begin
  Sal := GenerarSalHex(16);
  Hash := PBKDF2_SHA256(AClave, Sal, FIteraciones, 32);
  // Formato estándar: $pbkdf2-sha256$i=100000$<sal>$<hash>
  Result := Format('$pbkdf2-sha256$i=%d$%s$%s', [FIteraciones, Sal, Hash]);
end;

function TPBKDF2PasswordHasher.VerificarClave(const AClave, AHashAlmacenado: string): Boolean;
var
  Partes: TStringArray;
  Iter: Cardinal;
  Sal, HashEsperado, HashCalculado: string;
begin
  Result := False;
  if AHashAlmacenado = '' then Exit;

  Partes := AHashAlmacenado.Split(['$']);
  // Espera: ['', 'pbkdf2-sha256', 'i=100000', '<sal>', '<hash>']
  if (Length(Partes) < 5) or (Partes[1] <> 'pbkdf2-sha256') then
    Exit(False);

  if not TryStrToUInt(Copy(Partes[2], 3, Length(Partes[2])), Iter) then
    Exit(False);

  Sal := Partes[3];
  HashEsperado := Partes[4];

  HashCalculado := PBKDF2_SHA256(AClave, Sal, Iter, 32);
  Result := ComparacionTiempoConstante(HashCalculado, HashEsperado);
end;

function TPBKDF2PasswordHasher.HashPin(const APin: string): string;
begin
  Result := HashClave(APin);
end;

function TPBKDF2PasswordHasher.VerificarPin(const APin, AHashAlmacenado: string): Boolean;
begin
  Result := VerificarClave(APin, AHashAlmacenado);
end;

end.

