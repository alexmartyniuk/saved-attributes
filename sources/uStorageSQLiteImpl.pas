unit uStorageSQLiteImpl;

interface

uses
  Windows,
  Variants,
  Classes,
  Generics.Collections,
  SQLiteTable3,
  DB,
  uStorageIntf;

type

  TStorageSQLite = class(TInterfacedObject, IStorage, ISqlDriver)
  private
    FFilePath: string;
    FDatabase: TSQLiteDatabase;
    FTimeOut: Integer;
  private
    function IsDatabaseOpened: Boolean;
    procedure CheckDatabaseOpened;
  private
    function BlobRead(const Table, Field: string; Id: Integer; Value: TStream): Boolean; overload;
    function BlobWrite(const Table, Field: string; Id: Integer; Value: TStream): Boolean; overload;
  protected // ISqlDriver
    procedure Exec(const SQL: string; Params: array of const);
    function Select(const SQL: string; Params: array of const): IQueryResults;
    function BlobRead(const SQL: string; Value: TStream): Boolean; overload;
    function BlobWrite(const SQL: string; Value: TStream): Boolean; overload;
    procedure TransactionStart;
    procedure TransactionCommit;
    procedure TransactionRollback;
  protected // IStorage
    function FilePath: string;
    function IsAccessible: Boolean;
    function Open: Boolean;
    function Close: Boolean;
    procedure Backup(const AFileName: string);
    function Table(const AName: string): ITable;
    function Tables: IList<ITable>;
    function IsTableExists(const AName: string): Boolean;
  public
    constructor Create(const AFilePath: string);
    destructor Destroy; override;
  end;

implementation

uses
  SysUtils,
  SQLite3,
  uQueryResultsImpl,
  uTableImpl,
  uNamedValuesImpl,
  uListImpl;

function TStorageSQLite.BlobRead(const Table, Field: string; Id: Integer; Value: TStream): Boolean;
var
  tbl: TSQLiteTable;
  Stream: TMemoryStream;
begin
  CheckDatabaseOpened;
  tbl := FDatabase.GetTable(Format('select %s from %s where id=?', [Field, Table]), [Id]);
  try
    if FDatabase.LastErrorCode in [SQLITE_BUSY, SQLITE_LOCKED] then
      raise Exception.Create(Format('File "%s" blocked by another process.', [FFilePath]));

    Stream := tbl.FieldAsBlob(tbl.FieldIndex[Field]);
    // note that the memory stream is freed when the TSqliteTable is destroyed.

    if (Stream = nil) then
      Exit(False);

    Stream.Position := 0;
    Value.CopyFrom(Stream, Stream.Size);
    Value.Position := 0;

    Result := Value.Size > 0;
  finally
    tbl.Free;
  end;
end;

procedure TStorageSQLite.Backup(const AFileName: string);
var
  temp: TSQLiteDatabase;
begin
  temp := TSQLiteDatabase.Create(AFileName);
  try
    FDatabase.Backup(temp);
  finally
    FreeAndNil(temp);
  end;
end;

function TStorageSQLite.BlobRead(const SQL: string; Value: TStream): Boolean;
var
  tbl: TSQLiteTable;
  Stream: TMemoryStream;
begin
  CheckDatabaseOpened;
  tbl := FDatabase.GetTable(SQL);
  try
    if FDatabase.LastErrorCode in [SQLITE_BUSY, SQLITE_LOCKED] then
      raise Exception.Create(Format('File "%s" blocked by another process.', [FFilePath]));

    Stream := tbl.FieldAsBlob(0);
    if (Stream = nil) then
      Exit(False);

    Stream.Position := 0;
    Value.CopyFrom(Stream, Stream.Size);
    Value.Position := 0;

    Result := Value.Size > 0;
  finally
    tbl.Free;
  end;
end;

function TStorageSQLite.BlobWrite(const Table, Field: string; Id: Integer; Value: TStream): Boolean;
var
  memory: TMemoryStream;
  buffer: AnsiString;
begin
  CheckDatabaseOpened;

  if Assigned(Value) and (Value.Size > 0) then
  begin
    memory := TMemoryStream.Create();
    try
      SetLength(buffer, Value.Size);
      Value.Position := 0;
      Value.ReadBuffer(Pointer(buffer)^, Length(buffer));
      memory.Size := 0;
      memory.Write(Pointer(buffer)^, Length(buffer));
      SetLength(buffer, 0);
      FDatabase.UpdateBlob(Format('UPDATE %s set %s = ? WHERE ID = %d', [Table, Field, Id]), memory);

      if FDatabase.LastErrorCode in [SQLITE_BUSY, SQLITE_LOCKED] then
        raise Exception.Create(Format('File "%s" blocked by another process.', [FFilePath]));
    finally
      memory.Free;
    end;
  end
  else
    Exec(Format('UPDATE %s set %s = NULL WHERE ID = %d', [Table, Field, Id]), []);
end;

function TStorageSQLite.BlobWrite(const SQL: string; Value: TStream): Boolean;
var
  memory: TMemoryStream;
  buffer: AnsiString;
begin
  if Assigned(Value) and (Value.Size > 0) then
  begin
    memory := TMemoryStream.Create();
    try
      SetLength(buffer, Value.Size);
      Value.Position := 0;
      Value.ReadBuffer(Pointer(buffer)^, Length(buffer));
      memory.Size := 0;
      memory.Write(Pointer(buffer)^, Length(buffer));
      SetLength(buffer, 0);
      FDatabase.UpdateBlob(SQL, memory);

      if FDatabase.LastErrorCode in [SQLITE_BUSY, SQLITE_LOCKED] then
        raise Exception.Create(Format('File "%s" blocked by another process.', [FFilePath]));
    finally
      memory.Free;
    end;
  end;
end;

procedure TStorageSQLite.CheckDatabaseOpened;
begin
  if not IsDatabaseOpened then
    if not Open() then
      raise Exception.Create('Cannot open database: ' + FFilePath);
end;

function TStorageSQLite.Close: Boolean;
begin
  try
    if Assigned(FDatabase) then
    begin
      if FDatabase.IsTransactionOpen then
        FDatabase.Rollback;
      FreeAndNil(FDatabase);
    end;
    Result := True;
  except
    Result := False;
  end;
end;

constructor TStorageSQLite.Create(const AFilePath: string);
begin
  FFilePath := AFilePath;
  FTimeOut := 5000;
end;

destructor TStorageSQLite.Destroy;
begin
  Close;
end;

procedure TStorageSQLite.Exec(const SQL: string; Params: array of const);
begin
  CheckDatabaseOpened;
  FDatabase.ExecSQL(SQL, Params);
  if FDatabase.LastErrorCode in [SQLITE_BUSY, SQLITE_LOCKED] then
    raise Exception.Create(Format('File "%s" blocked by another process.', [FFilePath]));
end;

function TStorageSQLite.FilePath: string;
begin
  Result := FFilePath;
end;

function TStorageSQLite.IsAccessible: Boolean;
begin
  Result := FileExists(FFilePath);
end;

function TStorageSQLite.IsDatabaseOpened: Boolean;
begin
  Result := Assigned(FDatabase);
end;

function TStorageSQLite.IsTableExists(const AName: string): Boolean;
begin
  CheckDatabaseOpened;
  Result := FDatabase.TableExists(AName);
end;

function TStorageSQLite.Open: Boolean;
begin
  if Assigned(FDatabase) then
  begin
    if FDatabase.IsTransactionOpen then
      FDatabase.Commit();
    FreeAndNil(FDatabase);
  end;
  try
    FDatabase := TSQLiteDatabase.Create(FFilePath);
    FDatabase.SetTimeout(FTimeOut);
    FDatabase.RaiseExceptions := True;
    Result := True;
  except
    Result := False;
    FDatabase := nil;
  end;
end;

function TStorageSQLite.Select(const SQL: string; Params: array of const): IQueryResults;
var
  i: Integer;
  namedValues: INamedValues;
  Records: TRecords;
  Table: TSQLiteTable;
begin
  CheckDatabaseOpened;

  Result := nil;
  Table := FDatabase.GetTable(SQL, Params);
  try
    if FDatabase.LastErrorCode in [SQLITE_BUSY, SQLITE_LOCKED] then
      raise Exception.Create(Format('File "%s" blocked by another process.', [FFilePath]));

    Records := TRecords.Create;
    try
      while not Table.Eof do
      begin
        namedValues := TNamedValues.Create;
        for i := 0 to Table.ColCount - 1 do
          namedValues.Value[Table.Columns[i]] := Table.FieldAsVariant[i];
        Records.Add(namedValues);
        Table.Next;
      end;
      if Records.Count > 0 then
        Result := TQueryResults.Create(Records);
    finally
      Records.Free;
    end;
  finally
    Table.Free;
  end;
end;

function TStorageSQLite.Table(const AName: string): ITable;
begin
  Result := TTable.Create(Self, AName);
end;

function TStorageSQLite.Tables: IList<ITable>;
var
  res: IQueryResults;
begin
  Result := TInterfacedList<ITable>.Create;

  res := Select('SELECT name FROM sqlite_master WHERE type="table" ORDER BY name', []);
  if not Assigned(res) then
    Exit;

  while not res.Eof do
  begin
    Result.Add(Table(res.Value['name']));
    res.Next;
  end;
end;

procedure TStorageSQLite.TransactionCommit;
begin
  CheckDatabaseOpened;
  if FDatabase.IsTransactionOpen then
    FDatabase.Commit;
end;

procedure TStorageSQLite.TransactionRollback;
begin
  CheckDatabaseOpened;
  if FDatabase.IsTransactionOpen then
    FDatabase.Rollback;
end;

procedure TStorageSQLite.TransactionStart;
begin
  CheckDatabaseOpened;
  if FDatabase.IsTransactionOpen then
    FDatabase.Commit;
  FDatabase.BeginTransaction;
end;

end.
