unit uStorageIntf;

interface

uses
  Classes,
  SysUtils,
  Variants,
  Math,
  System.Generics.Defaults,
  System.Generics.Collections,
  uStoredValue;

type

  IList<T> = interface(IInterface)
    function GetEnumerator: TList<T>.TEnumerator;
    function Add(const Value: T): Integer; overload;
    function Add(const Values: IList<T>): Integer; overload;
    function Count: Integer;
    procedure Clear;
    procedure Delete(AIndex: Integer);
    procedure DeleteItem(AItem: T);
    procedure Insert(AIndex: Integer; const AValue: T);
    function GetItem(AIndex: Integer): T;
    function GetIndex(AValue: T): Integer;
    procedure SetItem(AIndex: Integer; const AValue: T);

    procedure Sort(const AComparer: IComparer<T>); overload;
    property Items[Index: Integer]: T read GetItem write SetItem; default;
  end;

  TQueryCondition = (CONDITION_EQUAL, CONDITION_NOT_EQUAL, CONDITION_MORE, CONDITION_LESS, CONDITION_LIKE, CONDITION_EXISTS);

  IFilter = interface
    ['{F143D34A-4A4F-4226-BB09-310CA9DE4D5C}']
    function And_(const AName: string; AKind: TQueryCondition; const AValue: Variant): IFilter;
    function Or_(const AName: string; AKind: TQueryCondition; const AValue: Variant): IFilter;
    function GetText: string;
    function GetParams(const AListToFill: TList<Variant>): Boolean;

    property Text: string read GetText;
  end;

  INamedValues = interface
    ['{30D29CC6-B1D3-43F2-AF72-12E002D7EA46}']
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

    property Value[Name: string]: Variant read GetValue write SetValue; default;
    property Text: string read GetText write SetText;
  end;

  IQueryResults = interface(INamedValues)
    ['{B5720A09-CC65-4AC7-995B-78D2346A4F9B}']
    procedure Next;
    procedure First;
    function Eof: Boolean;
  end;

  ITable = interface;

  ISqlDriver = interface
  ['{DDD9B867-BA9F-45BF-89E1-A75AF16B18C9}']
    procedure Exec(const SQL: string; Params: array of const);
    function Select(const SQL: string; Params: array of const): IQueryResults;
    function BlobRead(const SQL: string; Value: TStream): Boolean;
    function BlobWrite(const SQL: string; Value: TStream): Boolean;
  end;

  IStorage = interface
    ['{BC8A7802-6219-4704-8443-F3F9914F494D}']
    function FilePath: string;
    function IsAccessible: Boolean;
    function Open: Boolean;
    function Close: Boolean;
    procedure Backup(const AFileName: string);
    procedure TransactionStart;
    procedure TransactionCommit;
    procedure TransactionRollback;

    function Table(const AName: string): ITable;
    function IsTableExists(const AName: string): Boolean;
    function Tables: IList<ITable>;
  end;

  IRecord = interface;

  ITable = interface
    ['{E3FD6E7C-5406-492D-8811-5D26B4ED6BD6}']
    function NewRecord: IRecord;
    function DelRecord(const ARecord: IRecord): Boolean;
    function ReadOne(const AFilter: IFilter): IRecord; overload;
    function ReadOne(const AGuid: string): IRecord; overload;
    function ReadMany(const AFilter: IFilter = nil): IList<IRecord>;

    function GetName: string;
    function GetStorage: IStorage;

    property Storage: IStorage read GetStorage;
    property Name: string read GetName;
  end;

  TAttributeType = (ATTRIBUTE_NULL, ATTRIBUTE_INTEGER, ATTRIBUTE_BOOLEAN, ATTRIBUTE_DOUBLE, ATTRIBUTE_TEXT, ATTRIBUTE_BLOB,
    ATTRIBUTE_DATETIME, ATTRIBUTE_PROTECTED_TEXT, ATTRIBUTE_PROTECTED_BLOB);

  TAttribute = record
  private
    _raw: string;
    _name: string;
    _type: TAttributeType;
  private
    class function Normalize(const Value: Float): Float; static;
    procedure ConvertToStreamFromBase64(const AStream: TStream; const ABase64Data: UTF8String);
    function ConvertToBase64FromStream(const AStream: TStream): UTF8String;
  public
    class operator Implicit(a: TAttribute): string;
    class operator Implicit(a: string): TAttribute;
    class operator Implicit(a: TAttribute): Float;
    class operator Implicit(a: Float): TAttribute;
    class operator Implicit(a: TAttribute): Integer;
    class operator Implicit(a: Integer): TAttribute;
    class operator Implicit(a: TAttribute): Boolean;
    class operator Implicit(a: Boolean): TAttribute;
  public
    function GetName: string;
    procedure SetName(const AValue: string);
    function GetType: TAttributeType;
    function IsNull: Boolean;
    procedure CopyFrom(const AValue: TAttribute);
    function IsEqual(const AValue: TAttribute): Boolean;

    procedure SetStream(const AValue: TStream);
    function GetStream(AValue: TStream): Int64;
  public
    constructor Create(const AName, AValue: string; AType: TAttributeType);
    constructor CreateNull(const AName: string);
  end;

  IAttribute = interface;

  IRecord = interface
    ['{E064976E-6739-48AB-86A4-F867F3433A39}']
    function GetGuid: string;
    function GetTable: ITable;
    function GetAttributes: IList<TAttribute>;

    procedure SetGuid(const Value: string);
    function GetAttribute(const AName: string): TAttribute;
    procedure SetAttribute(const AName: string; const AValue: TAttribute);

    property Guid: string read GetGuid write SetGuid;
    property Table: ITable read GetTable;
    property Attributes: IList<TAttribute> read GetAttributes;

    property Attribute[const AName: string]: TAttribute read GetAttribute write SetAttribute;
  end;

  IAttribute = interface
    ['{BCB06D36-C7F0-4E9A-97C1-CD847D34A1C5}']
    function GetName: string;
    function GetRecord: IRecord;
    function GetType: TAttributeType;

    function GetDouble: Double;
    function GetDateTime: TDateTime;
    function GetInteger: Integer;
    function GetBoolean: Boolean;
    function GetStream(const AValue: TStream): Integer;
    function GetString: string;
    function GetProtectedStream(const AValue: TStream): Integer;
    function GetProtectedString: string;

    procedure SetName(const AValue: string);
    procedure SetDouble(const AValue: Double);
    procedure SetDateTime(const AValue: TDateTime);
    procedure SetInteger(const AValue: Integer);
    procedure SetBoolean(const AValue: Boolean);
    procedure SetStream(const AValue: TStream);
    procedure SetString(const Value: string);
    procedure SetProtectedStream(const Value: TStream);
    procedure SetProtectedString(const Value: string);

    procedure Remove;

    property Record_: IRecord read GetRecord;
    property Name: string read GetName write SetName;
    property Type_: TAttributeType read GetType;
  end;

function Where(const AName: string; AKind: TQueryCondition; const AValue: Variant): IFilter; overload;
function Where(): IFilter; overload;
function Storage(const AFileName: string): IStorage;

implementation

uses
  Soap.EncdDecd,
  uFilterImpl,
  uStorageSQLiteImpl;

function Where(const AName: string; AKind: TQueryCondition; const AValue: Variant): IFilter; overload;
begin
  Result := TFilterImpl.Create(AName, AKind, AValue);
end;

function Where(): IFilter; overload;
begin
  Result := TFilterImpl.Create;
end;

function Storage(const AFileName: string): IStorage;
begin
  Result := TStorageSQLite.Create(AFileName);
end;

{ TAttribute }

function TAttribute.ConvertToBase64FromStream(const AStream: TStream): UTF8String;
var
  inStr, outStr: TStringStream;
begin
  outStr := TStringStream.Create('', TEncoding.UTF8);
  try
    AStream.Position := 0;
    EncodeStream(AStream, outStr);
    Result := outStr.DataString;
  finally
    outStr.Free;
  end;
end;

procedure TAttribute.ConvertToStreamFromBase64(const AStream: TStream; const ABase64Data: UTF8String);
var
  inStr, outStr: TStringStream;
begin
  inStr := TStringStream.Create(ABase64Data, TEncoding.UTF8);
  try
    DecodeStream(inStr, AStream);
    AStream.Position := 0;
  finally
    inStr.Free;
  end;
end;

procedure TAttribute.CopyFrom(const AValue: TAttribute);
begin
  Self._raw := AValue._raw;
  if AValue._name <> '' then
    Self._name := AValue._name;
  Self._type := AValue._type;
end;

constructor TAttribute.Create(const AName, AValue: string; AType: TAttributeType);
begin
  _name := AName;
  _type := AType;
  _raw := AValue;
end;

constructor TAttribute.CreateNull(const AName: string);
begin
  _name := AName;
  _raw := '';
  _type := ATTRIBUTE_NULL;
end;

function TAttribute.GetName: string;
begin
  Result := _name;
end;

function TAttribute.GetStream(AValue: TStream): Int64;
begin
  ConvertToStreamFromBase64(AValue, _raw);
  Result := AValue.Size;
end;

function TAttribute.GetType: TAttributeType;
begin
  Result := _type;
end;

class operator TAttribute.Implicit(a: Integer): TAttribute;
begin
  Result._raw := IntToStr(a);
  Result._type := ATTRIBUTE_INTEGER;
end;

function TAttribute.IsEqual(const AValue: TAttribute): Boolean;
begin
  Result := (Self._raw = AValue._raw) and (Self._name = AValue._name) and (Self._type = AValue._type);
end;

function TAttribute.IsNull: Boolean;
begin
  Result := _type = ATTRIBUTE_NULL;
end;

class operator TAttribute.Implicit(a: string): TAttribute;
begin
  Result._raw := a;
  Result._type := ATTRIBUTE_TEXT;
end;

class operator TAttribute.Implicit(a: TAttribute): Float;
begin
  Result := Normalize(StrToFloatDef(a._raw, 0));
end;

class operator TAttribute.Implicit(a: TAttribute): Integer;
begin
  Result := StrToIntDef(a._raw, 0);
end;

class operator TAttribute.Implicit(a: TAttribute): string;
begin
  Result := a._raw;
end;

class operator TAttribute.Implicit(a: Float): TAttribute;
begin
  Result._raw := FloatToStr(Normalize(a));
  Result._type := ATTRIBUTE_DOUBLE;
end;

class function TAttribute.Normalize(const Value: Float): Float;
begin
  Result := RoundTo(Value, -12);
end;

procedure TAttribute.SetName(const AValue: string);
begin
  _name := AValue;
end;

procedure TAttribute.SetStream(const AValue: TStream);
begin
  _raw := ConvertToBase64FromStream(AValue);
  _type := ATTRIBUTE_BLOB;
end;

class operator TAttribute.Implicit(a: TAttribute): Boolean;
begin
  Result := StrToBoolDef(a, False);
end;

class operator TAttribute.Implicit(a: Boolean): TAttribute;
begin
  Result._raw := BoolToStr(a);
  Result._type := ATTRIBUTE_BOOLEAN;
end;

end.
