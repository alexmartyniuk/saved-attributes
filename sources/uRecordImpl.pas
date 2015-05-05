unit uRecordImpl;

interface

uses
  SysUtils,
  Classes,
  Windows,
  Variants,
  System.Generics.Collections,
  uStorageIntf;

type
  TRecord = class(TInterfacedObject, IRecord)
  private
    FGuid: string;
    FTable: ITable;
    FAttributes: IList<TAttribute>;
  private
    function GenerateGuid: string;
    procedure Save(const AValue: TAttribute);
  protected
    function GetGuid: string;
    function GetTable: ITable;
    function GetAttributes: IList<TAttribute>;

    procedure SetGuid(const Value: string);

    function GetAttribute(const AName: string): TAttribute;
    procedure SetAttribute(const AName: string; const AValue: TAttribute);
  public
    constructor Create(const ATable: ITable; const AGuid: string = '');
    destructor Destroy; override;
  end;

implementation

uses
  uListImpl;

destructor TRecord.Destroy;
begin
  FTable := nil;
  FAttributes := nil;
  inherited;
end;

function TRecord.GenerateGuid: string;
var
  guid: TGUID;
begin
  CreateGUID(guid);
  Result := GUIDToString(guid);
end;

function TRecord.GetAttribute(const AName: string): TAttribute;
var
  attr: TAttribute;
begin
  for attr in GetAttributes do
    if SameText(attr.GetName, AName) then
      Exit(attr);
  Result := attr.CreateNull(AName);
end;

function TRecord.GetAttributes: IList<TAttribute>;
var
  res: IQueryResults;
  attr: TAttribute;
begin
  if not Assigned(FAttributes) then
  begin
    FAttributes := TInterfacedList<TAttribute>.Create;
    res := (FTable.Storage as ISqlDriver).Select('select NAME, VALUE, TYPE from "' + FTable.Name + '" where RECORD=?', [GetGuid]);
    if Assigned(res) then
      while not res.Eof do
      begin
        attr := TAttribute.Create(res.Value['NAME'], res.Value['VALUE'], TAttributeType(Integer(res.Value['TYPE'])));
        FAttributes.Add(attr);
        res.Next;
      end;
  end;
  Result := FAttributes;
end;

function TRecord.GetGuid: string;
begin
  Result := FGuid;
end;

function TRecord.GetTable: ITable;
begin
  Result := FTable;
end;

constructor TRecord.Create(const ATable: ITable; const AGuid: string = '');
begin
  FTable := ATable;
  if AGuid = '' then
    FGuid := GenerateGuid
  else
    FGuid := AGuid;
end;

procedure TRecord.Save(const AValue: TAttribute);
begin
  (GetTable.Storage as ISqlDriver).Exec('insert or replace into "' + GetTable.Name + '" (RECORD, NAME, VALUE, TYPE) values (?, ?, ?, ?)',
    [GetGuid, AValue.GetName, string(AValue), Integer(AValue.GetType)]);
end;

procedure TRecord.SetAttribute(const AName: string; const AValue: TAttribute);
var
  attr: TAttribute;
begin
  Assert(AName <> '', 'Empty attribute name');

  for attr in GetAttributes do
    if SameText(attr.GetName, AName) then
      if not attr.IsEqual(AValue) then
      begin
        attr.CopyFrom(AValue);
        Save(attr);
      end;

  attr := TAttribute.CreateNull(AName);
  attr.CopyFrom(AValue);
  FAttributes.Add(attr);
  Save(attr);
end;

procedure TRecord.SetGuid(const Value: string);
begin
  FGuid := Value;
end;

end.
