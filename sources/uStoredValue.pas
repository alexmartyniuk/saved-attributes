unit uStoredValue;

interface

uses
  Classes,
  SysUtils,
  Variants,
  Math,
  Generics.Defaults,
  Generics.Collections;

type

  Float = Extended;

implementation

uses
  uStorageIntf;

type

  TStoredValue = record
  private
    _raw: string;
    _name: string;
    _type: TAttributeType;
  private
    class function Normalize(const Value: Float): Float; static;
  public
    class operator Equal(a: TStoredValue; b: string): Boolean;
    class operator Equal(a: string; b: TStoredValue): Boolean;
    class operator Equal(a, b: TStoredValue): Boolean;
    class operator Equal(a: TStoredValue; b: Float): Boolean;
    class operator Equal(a: Float; b: TStoredValue): Boolean;

    class operator NotEqual(a: TStoredValue; b: string): Boolean;
    class operator NotEqual(a: string; b: TStoredValue): Boolean;
    class operator NotEqual(a, b: TStoredValue): Boolean;
    class operator NotEqual(a: TStoredValue; b: Float): Boolean;
    class operator NotEqual(a: Float; b: TStoredValue): Boolean;

    class operator Implicit(a: TStoredValue): string;
    class operator Implicit(a: string): TStoredValue;
    class operator Implicit(a: TStoredValue): Float;
    class operator Implicit(a: Float): TStoredValue;
    class operator Implicit(a: TStoredValue): Integer;
    class operator Implicit(a: Integer): TStoredValue;
  public
    function GetName: string;
    procedure SetName(const AValue: string);
    function GetType: TAttributeType;
  end;

  { TStoredValue }

class operator TStoredValue.Equal(a: TStoredValue; b: Float): Boolean;
begin

end;

class operator TStoredValue.Equal(a: Float; b: TStoredValue): Boolean;
begin

end;

function TStoredValue.GetName: string;
begin
  Result := _name;
end;

function TStoredValue.GetType: TAttributeType;
begin
  Result := _type;
end;

class operator TStoredValue.Equal(a, b: TStoredValue): Boolean;
begin

end;

class operator TStoredValue.Equal(a: TStoredValue; b: string): Boolean;
begin

end;

class operator TStoredValue.Equal(a: string; b: TStoredValue): Boolean;
begin

end;

class operator TStoredValue.Implicit(a: Float): TStoredValue;
begin
  Result._raw := FloatToStr(Normalize(a));
end;

class operator TStoredValue.Implicit(a: TStoredValue): Integer;
begin
  Result := StrToIntDef(a._raw, 0);
end;

class operator TStoredValue.Implicit(a: Integer): TStoredValue;
begin
  Result._raw := IntToStr(a);
end;

class operator TStoredValue.Implicit(a: TStoredValue): Float;
begin
  Result := Normalize(StrToFloatDef(a._raw, 0));
end;

class operator TStoredValue.Implicit(a: TStoredValue): string;
begin
  Result := a._raw;
end;

class operator TStoredValue.Implicit(a: string): TStoredValue;
begin
  Result._raw := a;
end;

class function TStoredValue.Normalize(const Value: Float): Float;
begin
  Result := RoundTo(Value, -12);
end;

class operator TStoredValue.NotEqual(a: string; b: TStoredValue): Boolean;
begin

end;

class operator TStoredValue.NotEqual(a: TStoredValue; b: string): Boolean;
begin

end;

class operator TStoredValue.NotEqual(a, b: TStoredValue): Boolean;
begin

end;

class operator TStoredValue.NotEqual(a: Float; b: TStoredValue): Boolean;
begin

end;

procedure TStoredValue.SetName(const AValue: string);
begin
  _name := AValue;
end;

class operator TStoredValue.NotEqual(a: TStoredValue; b: Float): Boolean;
begin

end;

end.
