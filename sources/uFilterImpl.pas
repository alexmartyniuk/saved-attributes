unit uFilterImpl;

interface

uses
  System.Generics.Collections,
  uStorageIntf;

type
  TFilterImpl = class(TInterfacedObject, IFilter)
  private
    FText: string;
    FParams: TList<Variant>;
  protected
    function And_(const AName: string; AKind: TQueryCondition; const AValue: Variant): IFilter;
    function Or_(const AName: string; AKind: TQueryCondition; const AValue: Variant): IFilter;
    function GetText: string;
    function GetParams(const AListToFill: TList<Variant>): Boolean;
  public
    constructor Create(const AName: string; AKind: TQueryCondition; const AValue: Variant); overload;
    constructor Create; overload;
    constructor Create(const AText: string; AParams: TList<Variant>); overload;
    destructor Destroy; override;
  end;

function VariantToVarRec(const Item: Variant): TVarRec;

implementation

uses
  SysUtils;

function VariantToTypedVarRec(const Item: Variant; VarType: TVarType): TVarRec;
begin
  case VarType of
    varInteger, varSmallint, varShortInt, varByte, varWord, varLongWord:
      begin
        Result.VType := vtInteger;
        Result.VInteger := Item;
      end;
    varNull, varUnknown, varEmpty:
      begin
        Result.VType := vtInteger;
        Result.VInteger := 0;
      end;
    varBoolean:
      begin
        Result.VType := vtBoolean;
        Result.VBoolean := Item;
      end;
    varDouble, varSingle, varDate:
      begin
        Result.VType := vtExtended;
        New(Result.VExtended);
        Result.VExtended^ := Item;
      end;
    varString:
      begin
        Result.VType := vtString;
        New(Result.VString);
        Result.VString^ := ShortString(Item);
      end;
    varCurrency:
      begin
        Result.VType := vtCurrency;
        New(Result.VCurrency);
        Result.VCurrency^ := Item;
      end;
    varVariant:
      begin
        Result.VType := vtVariant;
        New(Result.VVariant);
        Result.VVariant^ := Item;
      end;
    varOleStr:
      begin
        Result.VType := vtWideString;
        Result.VWideString := nil;
        WideString(Result.VWideString) := WideString(Item);
      end;
    varInt64:
      begin
        Result.VType := vtInt64;
        New(Result.VInt64);
        Result.VInt64^ := Item;
      end;
{$IFDEF UNICODE}
    varUString:
      begin
        Result.VType := vtUnicodeString;
        Result.VUnicodeString := nil;
        UnicodeString(Result.VUnicodeString) := UnicodeString(Item);
      end;
{$ENDIF}
  end;
end;

function VariantToVarRec(const Item: Variant): TVarRec;
begin
  Result := VariantToTypedVarRec(Item, TVarData(Item).VType);
end;

{ TFilterImpl }

function TFilterImpl.And_(const AName: string; AKind: TQueryCondition; const AValue: Variant): IFilter;
var
  text: string;
  params: TList<Variant>;
  filter: IFilter;
begin
  filter := TFilterImpl.Create(AName, AKind, AValue);
  text := FText + ' INTERSECT ' + filter.text;
  params := TList<Variant>.Create;
  try
    GetParams(params);
    filter.GetParams(params);
    Result := TFilterImpl.Create(text, params);
  finally
    FreeAndNil(params);
  end;
end;

constructor TFilterImpl.Create(const AName: string; AKind: TQueryCondition; const AValue: Variant);
var
  rec: TVarRec;
begin
  Create;
  rec := VariantToVarRec(AValue);
  case AKind of
    CONDITION_EQUAL:
      FText := 'SELECT DISTINCT RECORD as GUID FROM "%TABLE%" WHERE (NAME="' + AName + '" and VALUE=?)';
    CONDITION_NOT_EQUAL:
      FText := 'SELECT DISTINCT RECORD as GUID FROM "%TABLE%" WHERE (NAME="' + AName + '" and VALUE<>?)';
    CONDITION_MORE:
      FText := 'SELECT DISTINCT RECORD as GUID FROM "%TABLE%" WHERE (NAME="' + AName + '" and VALUE>?)';
    CONDITION_LESS:
      FText := 'SELECT DISTINCT RECORD as GUID FROM "%TABLE%" WHERE (NAME="' + AName + '" and VALUE<?)';
    CONDITION_LIKE:
      FText := 'SELECT DISTINCT RECORD as GUID FROM "%TABLE%" WHERE (NAME="' + AName + '" and VALUE like ?)';
    CONDITION_EXISTS:
      if AValue then
        FText := 'SELECT DISTINCT RECORD as GUID FROM "%TABLE%" WHERE EXISTS (SELECT RECORD as GUID2 FROM "%TABLE%" WHERE NAME="' + AName +
          '" and GUID = GUID2)'
      else
        FText := 'SELECT DISTINCT RECORD as GUID FROM "%TABLE%" WHERE NOT EXISTS (SELECT RECORD as GUID2 FROM "%TABLE%" WHERE NAME="' +
          AName + '" and GUID = GUID2)';
  end;

  if AKind <> CONDITION_EXISTS then
    if rec.VType = vtBoolean then
      FParams.Add(BoolToStr(AValue))
    else
      FParams.Add(AValue);
end;

constructor TFilterImpl.Create;
begin
  FParams := TList<Variant>.Create;
  FText := 'SELECT DISTINCT RECORD as GUID FROM "%TABLE%"';
end;

constructor TFilterImpl.Create(const AText: string; AParams: TList<Variant>);
var
  i: Integer;
begin
  Create;
  FText := AText;
  FParams.Clear;
  for i := 0 to AParams.Count - 1 do
    FParams.Add(AParams.Items[i]);
end;

destructor TFilterImpl.Destroy;
begin
  FParams.Clear;
  FreeAndNil(FParams);
  inherited;
end;

function TFilterImpl.GetParams(const AListToFill: TList<Variant>): Boolean;
var
  i: Integer;
begin
  Result := False;

  if FParams.Count = 0 then
    Exit;

  for i := 0 to FParams.Count - 1 do
    AListToFill.Add(FParams.Items[i]);

  Result := True;
end;

function TFilterImpl.GetText: string;
begin
  Result := FText;
end;

function TFilterImpl.Or_(const AName: string; AKind: TQueryCondition; const AValue: Variant): IFilter;
var
  text: string;
  params: TList<Variant>;
  filter: IFilter;
begin
  filter := TFilterImpl.Create(AName, AKind, AValue);
  text := FText + ' UNION ' + filter.text;
  params := TList<Variant>.Create;
  try
    GetParams(params);
    filter.GetParams(params);
    Result := TFilterImpl.Create(text, params);
  finally
    FreeAndNil(params);
  end;
end;

end.
