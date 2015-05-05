unit uNamedValuesImpl;

interface

uses
  Variants,
  Classes,
  Generics.Collections,
  uStorageIntf;

type

  TVariantPair = TPair<string, Variant>;
  TVariantDictionary = TDictionary<string, Variant>;
  TRecords = TList<INamedValues>;

  TNamedValues = class(TInterfacedObject, INamedValues)
    private
      FPairs: TVariantDictionary;
    protected
      function GetValue(Name: string): Variant;
      procedure SetValue(Name: string; const Value: Variant);
      function GetText: string;
      procedure SetText(const Value: string);

      function ValueExists(const Name: string): Boolean;
      function ValueAsString(const Name: string; const ADefault: string = ''): string;
      function ValueAsInteger(const Name: string; const ADefault: Integer = 0): Integer;
      function ValueAsDouble(const Name: string; const ADefault: Double = 0.0): Double;
      function ValueAsDateTime(const Name: string; const ADefault: TDateTime = 0.0): TDateTime;
      function ValueAsBoolean(const Name: string; const ADefault: Boolean = False): Boolean;
    public
      constructor Create;
      destructor Destroy; override;
  end;

implementation

uses
  SysUtils;

{ TNamedValues }

constructor TNamedValues.Create;
begin
  FPairs := TVariantDictionary.Create;
end;

destructor TNamedValues.Destroy;
begin
  FPairs.Free;
  inherited;
end;

function TNamedValues.GetText: string;
var
  list: TStringList;
  pair: TVariantPair;
begin
  list := TStringList.Create;
  try
    for pair in FPairs do
      case TVarData(pair.Value).VType of
        varNull, varUnknown, varEmpty:
          list.Values[pair.Key] := '';
        varInteger, varInt64, varSmallint, varShortInt, varByte, varWord, varLongWord:
          list.Values[pair.Key] := IntToStr(pair.Value);
        varBoolean:
          list.Values[pair.Key] := BoolToStr(pair.Value);
        varDouble, varSingle, varDate:
          list.Values[pair.Key] := FloatToStr(pair.Value);
        varString, varUString, varOleStr:
          list.Values[pair.Key] := string(pair.Value);
        varCurrency:
          list.Values[pair.Key] := CurrToStrF(pair.Value, ffCurrency, 0);
        varVariant:
          list.Values[pair.Key] := string(pair.Value);
      end;
    Result := list.Text;
  finally
    FreeAndNil(list);
  end;
end;

function TNamedValues.GetValue(Name: string): Variant;
begin
  if FPairs.ContainsKey(Name) then
    Result := FPairs.Items[Name]
  else if FPairs.ContainsKey(LowerCase(Name)) then
    Result := FPairs.Items[LowerCase(Name)]
  else if FPairs.ContainsKey(UpperCase(Name)) then
    Result := FPairs.Items[UpperCase(Name)]
  else
    Result := Null;
end;

procedure TNamedValues.SetText(const Value: string);
var
  list: TStringList;
  i: Integer;
begin
  FPairs.Clear;
  if Value = '' then
    Exit;

  list := TStringList.Create;
  try
    list.Text := Value;
    for i := 0 to list.Count - 1 do
      SetValue(list.Names[i], list.ValueFromIndex[i]);
  finally
    FreeAndNil(list);
  end;
end;

procedure TNamedValues.SetValue(Name: string; const Value: Variant);
begin
  if FPairs.ContainsKey(Name) then
    FPairs.Items[Name] := Value
  else
    FPairs.Add(Name, Value);
end;

function TNamedValues.ValueAsBoolean(const Name: string; const ADefault: Boolean): Boolean;
var
  val: Variant;
begin
  val := GetValue(Name);
  if val = Null then
    Result := ADefault
  else
    Result := val;
end;

function TNamedValues.ValueAsDateTime(const Name: string; const ADefault: TDateTime): TDateTime;
var
  val: Variant;
begin
  val := GetValue(Name);
  if val = Null then
    Result := ADefault
  else
    Result := val;
end;

function TNamedValues.ValueAsDouble(const Name: string; const ADefault: Double): Double;
var
  val: Variant;
begin
  val := GetValue(Name);
  if val = Null then
    Result := ADefault
  else
    Result := val;
end;

function TNamedValues.ValueAsInteger(const Name: string; const ADefault: Integer): Integer;
var
  val: Variant;
begin
  val := GetValue(Name);
  if val = Null then
    Result := ADefault
  else
    Result := val;
end;

function TNamedValues.ValueAsString(const Name, ADefault: string): string;
var
  val: Variant;
begin
  val := GetValue(Name);
  if val = Null then
    Result := ADefault
  else
    Result := val;
end;

function TNamedValues.ValueExists(const Name: string): Boolean;
var
  value: Variant;
begin
  value := GetValue(Name);
  Result := not (VarIsNull(value) or VarIsEmpty(value));
end;

end.
