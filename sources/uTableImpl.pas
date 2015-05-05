unit uTableImpl;

interface

uses
  SysUtils,
  Classes,
  Windows,
  Variants,
  System.Generics.Collections,
  uStorageIntf;

type

  TTable = class(TInterfacedObject, ITable)
  private
    FName: string;
    FStorage: IStorage;
  protected
    function GetName: string;
    function GetStorage: IStorage;
    function NewRecord: IRecord;
    function DelRecord(const ARecord: IRecord): Boolean;
    function ReadOne(const AFilter: IFilter): IRecord; overload;
    function ReadOne(const AGuid: string): IRecord; overload;
    function ReadMany(const AFilter: IFilter = nil): IList<IRecord>;
  public
    constructor Create(const AStorage: IStorage; const AName: string);
    destructor Destroy; override;
  end;

implementation

uses
  StrUtils,
  SQLiteTable3,
  uRecordImpl,
  uFilterImpl,
  uListImpl;

constructor TTable.Create(const AStorage: IStorage; const AName: string);
begin
  FStorage := AStorage;
  FName := AName;

  if not GetStorage.IsTableExists(FName) then
    with GetStorage as ISqlDriver do
    begin
      Exec(Format('CREATE TABLE "%s" (RECORD TEXT NOT NULL, NAME TEXT, VALUE TEXT, TYPE INTEGER);', [FName]), []);
      Exec(Format('CREATE UNIQUE INDEX %s_IDX ON "%s" (RECORD, NAME);', [FName, FName]), []);
    end;
end;

function TTable.DelRecord(const ARecord: IRecord): Boolean;
begin
  with GetStorage as ISqlDriver do
    Exec('delete from "' + GetName + '" where RECORD=?', [ARecord.Guid]);
  Result := True;
end;

destructor TTable.Destroy;
begin
  FStorage := nil;
  inherited;
end;

function TTable.GetName: string;
begin
  Result := FName;
end;

function TTable.GetStorage: IStorage;
begin
  Result := FStorage;
end;

function TTable.NewRecord: IRecord;
begin
  Result := TRecord.Create(Self);
end;

function TTable.ReadMany(const AFilter: IFilter = nil): IList<IRecord>;
var
  filter: IFilter;
  sql: string;
  res: IQueryResults;
  item: IRecord;
  buffer: TStringList;
  i: Integer;
  paramsArray: array of TVarRec;
  paramsList: TList<Variant>;
begin
  Result := TInterfacedList<IRecord>.Create;

  if Assigned(AFilter) then
    filter := AFilter
  else
    filter := Where();

  paramsList := TList<Variant>.Create;
  try
    filter.GetParams(paramsList);
    SetLength(paramsArray, paramsList.Count);
    for i := 0 to paramsList.Count - 1 do
      paramsArray[i] := VariantToVarRec(paramsList.Items[i]);
  finally
    FreeAndNil(paramsList);
  end;

  sql := StringReplace(filter.Text, '%TABLE%', FName, [rfReplaceAll]);

  with GetStorage as ISqlDriver do
    res := Select(sql, paramsArray);
  SetLength(paramsArray, 0);

  if not Assigned(res) then
    Exit;

  buffer := TStringList.Create;
  try
    buffer.Sorted := True;
    buffer.Duplicates := dupIgnore;
    buffer.BeginUpdate;
    while not res.Eof do
    begin
      buffer.Add(res.Value['GUID']);
      res.Next;
    end;
    buffer.EndUpdate;
    res := nil;
    for i := 0 to buffer.Count - 1 do
    begin
      item := TRecord.Create(Self, buffer.Strings[i]);
      Result.Add(item);
    end;
  finally
    buffer.Free;
  end;
end;

function TTable.ReadOne(const AGuid: string): IRecord;
var
  sql: string;
  res: IQueryResults;
begin
  sql := Format('select * from "%s" where RECORD=?', [FName]);
  res := (GetStorage as ISqlDriver).Select(sql, [AGuid]);
  if not Assigned(res) then
    Exit(nil);

  Result := TRecord.Create(Self, AGuid);
end;

function TTable.ReadOne(const AFilter: IFilter): IRecord;
var
  records: IList<IRecord>;
begin
  records := ReadMany(AFilter);
  if records.Count > 0 then
    Result := records.Items[0]
  else
    Result := nil;
end;

end.
