unit SQLiteTable3;

{
  Simple classes for using SQLite's exec and get_table.

  TSQLiteDatabase wraps the calls to open and close an SQLite database.
  It also wraps SQLite_exec for queries that do not return a result set

  TSQLiteTable wraps execution of SQL query.
  It run query and read all returned rows to internal buffer.
  It allows accessing fields by name as well as index and can move through a
  result set forward and backwards, or randomly to any row.

  TSQLiteUniTable wraps execution of SQL query.
  It run query as TSQLiteTable, but reading just first row only!
  You can step to next row (until not EOF) by 'Next' method.
  You cannot step backwards! (So, it is called as UniDirectional result set.)
  It not using any internal buffering, this class is very close to Sqlite API.
  It allows accessing fields by name as well as index on actual row only.
  Very good and fast for sequentional scanning of large result sets with minimal
  memory footprint.

  Warning! Do not close TSQLiteDatabase before any TSQLiteUniTable,
  because query is closed on TSQLiteUniTable destructor and database connection
  is used during TSQLiteUniTable live!

  SQL parameter usage:
  You can add named parameter values by call set of AddParam* methods.
  Parameters will be used for first next SQL statement only.
  Parameter name must be prefixed by ':', '$' or '@' and same prefix must be
  used in SQL statement!
  Sample:
  table.AddParamText(':str', 'some value');
  s := table.GetTableString('SELECT value FROM sometable WHERE id=:str');

  Notes from Andrew Retmanski on prepared queries
  The changes are as follows:

  SQLiteTable3.pas
  - Added new boolean property Synchronised (this controls the SYNCHRONOUS pragma as I found that turning this OFF increased the write performance in my application)
  - Added new type TSQLiteQuery (this is just a simple record wrapper around the SQL string and a TSQLiteStmt pointer)
  - Added PrepareSQL method to prepare SQL query - returns TSQLiteQuery
  - Added ReleaseSQL method to release previously prepared query
  - Added overloaded BindSQL methods for Integer and String types - these set new values for the prepared query parameters
  - Added overloaded ExecSQL method to execute a prepared TSQLiteQuery

  Usage of the new methods should be self explanatory but the process is in essence:

  1. Call PrepareSQL to return TSQLiteQuery 2. Call BindSQL for each parameter in the prepared query 3. Call ExecSQL to run the prepared query 4. Repeat steps 2 & 3 as required 5. Call ReleaseSQL to free SQLite resources

  One other point - the Synchronised property throws an error if used inside a transaction.

  Acknowledments
  Adapted by Tim Anderson (tim@itwriting.com)
  Originally created by Pablo Pissanetzky (pablo@myhtpc.net)
  Modified and enhanced by Lukas Gebauer
  Modified and enhanced by Tobias Gunkel
}

interface

{$IFDEF FPC}
{$MODE Delphi}{$H+}
{$ENDIF}

uses
{$IFDEF WIN32}
  Windows,
{$ENDIF}
  SQLite3,
  Classes,
  SysUtils;

const

  dtInt = 1;
  dtNumeric = 2;
  dtStr = 3;
  dtBlob = 4;
  dtNull = 5;

type

  ESQLiteException = class(Exception)
  end;

  TSQliteParam = class
    public
      name: string;
      valuetype: integer;
      valueinteger: int64;
      valuefloat: double;
      valuedata: string;
  end;

  THookQuery = procedure(Sender: TObject; SQL: String) of object;

  TSQLiteQuery = record
    SQL: String;
    Statement: TSQLiteStmt;
  end;

  TSQLiteTable = class;
  TSQLiteUniTable = class;

  TSQLiteDatabase = class
    private
      fDB: TSQLiteDB;
      fInTrans: boolean;
      fSync: boolean;
      fParams: TList;
      FOnQuery: THookQuery;
      FLastErrorCode: Integer;
      FRaiseExceptions: Boolean;
    private
      function GetLastError: string;
      function GetLastErrorCode: Integer;
    private
      procedure RaiseError(s: string; SQL: string);
      procedure SetParams(Stmt: TSQLiteStmt);
      procedure BindData(Stmt: TSQLiteStmt; const Bindings: array of const );
      function GetRowsChanged: integer;
      function GetRaiseExceptions: Boolean;
      procedure SetRaiseExceptions(const Value: Boolean);
    protected
      procedure SetSynchronised(Value: boolean);
      procedure DoQuery(Value: string);
    public
      constructor Create(const FileName: string);
      destructor Destroy; override;
      function GetTable(const SQL: Ansistring): TSQLiteTable; overload;
      function GetTable(const SQL: Ansistring; const Bindings: array of const ): TSQLiteTable; overload;
      procedure ExecSQL(const SQL: Ansistring); overload;
      procedure ExecSQL(const SQL: Ansistring; const Bindings: array of const ); overload;
      procedure ExecSQL(Query: TSQLiteQuery); overload;
      function PrepareSQL(const SQL: Ansistring): TSQLiteQuery;
      procedure BindSQL(Query: TSQLiteQuery; const Index: integer; const Value: integer); overload;
      procedure BindSQL(Query: TSQLiteQuery; const Index: integer; const Value: String); overload;
      procedure ReleaseSQL(Query: TSQLiteQuery);
      function GetUniTable(const SQL: Ansistring): TSQLiteUniTable; overload;
      function GetUniTable(const SQL: Ansistring; const Bindings: array of const ): TSQLiteUniTable; overload;
      function GetTableValue(const SQL: Ansistring): int64; overload;
      function GetTableValue(const SQL: Ansistring; const Bindings: array of const ): int64; overload;
      function GetTableString(const SQL: Ansistring): string; overload;
      function GetTableString(const SQL: Ansistring; const Bindings: array of const ): string; overload;
      procedure GetTableStrings(const SQL: Ansistring; const Value: TStrings);
      procedure UpdateBlob(const SQL: Ansistring; BlobData: TStream);
      procedure BeginTransaction;
      procedure Commit;
      procedure Rollback;
      function TableExists(TableName: string): boolean;
      function GetLastInsertRowID: int64;
      function GetLastChangedRows: int64;
      procedure SetTimeout(Value: integer);
      function Backup(TargetDB: TSQLiteDatabase): integer; Overload;
      function Backup(TargetDB: TSQLiteDatabase; targetName: Ansistring; sourceName: Ansistring): integer; Overload;
      function Version: string;
      procedure AddCustomCollate(name: string; xCompare: TCollateXCompare);
      // adds collate named SYSTEM for correct data sorting by user's locale
      Procedure AddSystemCollate;
      procedure ParamsClear;
      procedure AddParamInt(name: string; Value: int64);
      procedure AddParamFloat(name: string; Value: double);
      procedure AddParamText(name: string; Value: string);
      procedure AddParamNull(name: string);

      property DB: TSQLiteDB read fDB;
      property RaiseExceptions: Boolean read GetRaiseExceptions write SetRaiseExceptions;
      property LastError: string read GetLastError;
      property LastErrorCode: Integer read GetLastErrorCode;
    published
      property IsTransactionOpen: boolean read fInTrans;
      // database rows that were changed (or inserted or deleted) by the most recent SQL statement
      property RowsChanged: integer read GetRowsChanged;
      property Synchronised: boolean read fSync write SetSynchronised;
      property OnQuery: THookQuery read FOnQuery write FOnQuery;
  end;

  TSQLiteTable = class
    private
      fResults: TList;
      fRowCount: cardinal;
      fColCount: cardinal;
      fCols: TStringList;
      fColTypes: TList;
      fRow: cardinal;
      function GetFields(I: cardinal): string;
      function GetEOF: boolean;
      function GetBOF: boolean;
      function GetColumns(I: integer): string;
      function GetFieldByName(FieldName: string): string;
      function GetFieldIndex(FieldName: string): integer;
      function GetCount: integer;
      function GetCountResult: integer;
    public
      constructor Create(DB: TSQLiteDatabase; const SQL: Ansistring); overload;
      constructor Create(DB: TSQLiteDatabase; const SQL: Ansistring; const Bindings: array of const ); overload;
      destructor Destroy; override;
      function FieldAsInteger(I: cardinal): int64;
      function FieldAsBlob(I: cardinal): TMemoryStream;
      function FieldAsBlobText(I: cardinal): string;
      function FieldIsNull(I: cardinal): boolean;
      function FieldAsString(I: cardinal): string;
      function FieldAsDouble(I: cardinal): double;
      function Next: boolean;
      function Previous: boolean;
      property EOF: boolean read GetEOF;
      property BOF: boolean read GetBOF;
      property Fields[I: cardinal]: string read GetFields;
      property FieldByName[FieldName: string]: string read GetFieldByName;
      property FieldIndex[FieldName: string]: integer read GetFieldIndex;
      property Columns[I: integer]: string read GetColumns;
      property ColCount: cardinal read fColCount;
      property RowCount: cardinal read fRowCount;
      property Row: cardinal read fRow;
      function MoveFirst: boolean;
      function MoveLast: boolean;
      function MoveTo(position: cardinal): boolean;
      property Count: integer read GetCount;
      // The property CountResult is used when you execute count(*) queries.
      // It returns 0 if the result set is empty or the value of the
      // first field as an integer.
      property CountResult: integer read GetCountResult;
  end;

  TSQLiteTableHelper = class helper for TSQLiteTable
    protected
      function GetFieldType(I: cardinal): integer;
      function GetFieldAsVariant(I: cardinal): Variant;
    public
      property FieldType[I: cardinal]: integer read GetFieldType;
      property FieldAsVariant[I: cardinal]: Variant read GetFieldAsVariant;
  end;

  TSQLiteUniTable = class
    private
      fColCount: cardinal;
      fCols: TStringList;
      fRow: cardinal;
      fEOF: boolean;
      fStmt: TSQLiteStmt;
      fDB: TSQLiteDatabase;
      fSQL: string;
      function GetFields(I: cardinal): string;
      function GetColumns(I: integer): string;
      function GetFieldByName(FieldName: string): string;
      function GetFieldIndex(FieldName: string): integer;
    public
      constructor Create(DB: TSQLiteDatabase; const SQL: Ansistring); overload;
      constructor Create(DB: TSQLiteDatabase; const SQL: Ansistring; const Bindings: array of const ); overload;
      destructor Destroy; override;
      function FieldAsInteger(I: cardinal): int64;
      function FieldAsBlob(I: cardinal): TMemoryStream;
      function FieldAsBlobPtr(I: cardinal; out iNumBytes: integer): Pointer;
      function FieldAsBlobText(I: cardinal): string;
      function FieldIsNull(I: cardinal): boolean;
      function FieldAsString(I: cardinal): string;
      function FieldAsDouble(I: cardinal): double;
      function Next: boolean;
      property EOF: boolean read fEOF;
      property Fields[I: cardinal]: string read GetFields;
      property FieldByName[FieldName: string]: string read GetFieldByName;
      property FieldIndex[FieldName: string]: integer read GetFieldIndex;
      property Columns[I: integer]: string read GetColumns;
      property ColCount: cardinal read fColCount;
      property Row: cardinal read fRow;
  end;

procedure DisposePointer(ptr: Pointer); cdecl;

{$IFDEF WIN32}
function SystemCollate(Userdta: Pointer; Buf1Len: integer; Buf1: Pointer; Buf2Len: integer; Buf2: Pointer): integer; cdecl;
{$ENDIF}

implementation

procedure DisposePointer(ptr: Pointer); cdecl;
begin
  if assigned(ptr) then
    freemem(ptr);
end;

{$IFDEF WIN32}

function SystemCollate(Userdta: Pointer; Buf1Len: integer; Buf1: Pointer; Buf2Len: integer; Buf2: Pointer): integer; cdecl;
begin
  Result := CompareStringW(LOCALE_USER_DEFAULT, 0, PWideChar(Buf1), Buf1Len, PWideChar(Buf2), Buf2Len) - 2;
end;
{$ENDIF}
// ------------------------------------------------------------------------------
// TSQLiteDatabase
// ------------------------------------------------------------------------------

constructor TSQLiteDatabase.Create(const FileName: string);
var
  Msg: PAnsiChar;
  iResult: integer;
  utf8FileName: UTF8string;
begin
  inherited Create;

  FRaiseExceptions := True;
  fParams := TList.Create;

  self.fInTrans := False;

  Msg := nil;
  try
    utf8FileName := UTF8string(FileName);
    iResult := SQLite3_Open(PAnsiChar(utf8FileName), fDB);

    if iResult <> SQLITE_OK then
      if assigned(fDB) then
      begin
        Msg := Sqlite3_ErrMsg(fDB);
        raise ESQLiteException.CreateFmt('Failed to open database "%s" : %s', [FileName, Msg]);
      end
      else
        raise ESQLiteException.CreateFmt('Failed to open database "%s" : unknown error', [FileName]);

    // set a few configs
    // L.G. Do not call it here. Because busy handler is not setted here,
    // any share violation causing exception!

    // self.ExecSQL('PRAGMA SYNCHRONOUS=NORMAL;');
    // self.ExecSQL('PRAGMA temp_store = MEMORY;');

  finally
    if assigned(Msg) then
      SQLite3_Free(Msg);
  end;

end;

// ..............................................................................

destructor TSQLiteDatabase.Destroy;
begin
  if self.fInTrans then
    self.Rollback; // assume rollback
  if assigned(fDB) then
    SQLite3_Close(fDB);
  ParamsClear;
  fParams.Free;
  inherited;
end;

function TSQLiteDatabase.GetLastInsertRowID: int64;
begin
  Result := Sqlite3_LastInsertRowID(self.fDB);
end;

function TSQLiteDatabase.GetLastChangedRows: int64;
begin
  Result := SQLite3_TotalChanges(self.fDB);
end;

function TSQLiteDatabase.GetLastError: string;
var
  msg: PAnsiChar;
begin
  Result := '';

  if not Assigned(self.fDB) then
    Exit('Database not assigned.');

  if FLastErrorCode in [SQLITE_OK, SQLITE_DONE] then
    Exit();

  msg := Sqlite3_ErrMsg(self.fDB);
  if Assigned(msg) then
    Result := AnsiString(msg);
end;

function TSQLiteDatabase.GetLastErrorCode: Integer;
begin
  Result := FLastErrorCode;
end;

// ..............................................................................

procedure TSQLiteDatabase.RaiseError(s: string; SQL: string);
begin
  FLastErrorCode := sqlite3_errcode(self.fDB);
  if (FLastErrorCode <> SQLITE_OK) and FRaiseExceptions then
    raise ESQLiteException.CreateFmt(s + '.'#13'Error [%d]: %s.'#13'"%s": %s', [FLastErrorCode, SQLiteErrorStr(FLastErrorCode), SQL, GetLastError])
end;

procedure TSQLiteDatabase.SetSynchronised(Value: boolean);
begin
  if Value <> fSync then
  begin
    if Value then
      ExecSQL('PRAGMA synchronous = ON;')
    else
      ExecSQL('PRAGMA synchronous = OFF;');
    fSync := Value;
  end;
end;

procedure TSQLiteDatabase.BindData(Stmt: TSQLiteStmt; const Bindings: array of const );
var
  BlobMemStream: TCustomMemoryStream;
  BlobStdStream: TStream;
  DataPtr: Pointer;
  DataSize: integer;
  AnsiStr: Ansistring;
  AnsiStrPtr: PAnsiString;
  WideStrPtr: PWideString;
  I: integer;
begin
  FLastErrorCode := SQLITE_OK;
  for I := 0 to High(Bindings) do
  begin
    case Bindings[I].VType of
      vtString, vtUnicodeString, vtAnsiString, vtPChar, vtWideString, vtPWideChar, vtChar, vtWideChar:
        begin
          case Bindings[I].VType of
            vtString:
              begin // ShortString
                AnsiStr := Bindings[I].VString^;
                DataPtr := PAnsiChar(AnsiStr);
                DataSize := Length(AnsiStr) + 1;
                if (sqlite3_bind_text(Stmt, I + 1, DataPtr, DataSize, SQLITE_STATIC) <> SQLITE_OK) then
                  RaiseError('Could not bind text', 'BindData');
              end;
            vtPChar:
              begin
                DataPtr := Bindings[I].VPChar;
                DataSize := - 1;
                if (sqlite3_bind_text(Stmt, I + 1, DataPtr, DataSize, SQLITE_STATIC) <> SQLITE_OK) then
                  RaiseError('Could not bind text', 'BindData');
              end;
            vtAnsiString:
              begin
                AnsiStrPtr := PAnsiString(@Bindings[I].VAnsiString);
                DataPtr := PAnsiChar(AnsiStrPtr^);
                DataSize := Length(AnsiStrPtr^) + 1;
                if (sqlite3_bind_text(Stmt, I + 1, DataPtr, DataSize, SQLITE_STATIC) <> SQLITE_OK) then
                  RaiseError('Could not bind text', 'BindData');
              end;
            vtPWideChar:
              begin
                DataPtr := Bindings[I].VPWideChar;
                DataSize := - 1;
                if (sqlite3_bind_text16(Stmt, I + 1, DataPtr, DataSize, SQLITE_STATIC) <> SQLITE_OK) then
                  RaiseError('Could not bind text', 'BindData');
              end;
            vtUnicodeString:
              begin
                WideStrPtr := PWideString(@Bindings[I].VWideString);
                DataPtr := PWideChar(WideStrPtr^);
                DataSize := - 1;
                if (sqlite3_bind_text16(Stmt, I + 1, DataPtr, DataSize, SQLITE_STATIC) <> SQLITE_OK) then
                  RaiseError('Could not bind text', 'BindData');
              end;
            vtWideString:
              begin
                WideStrPtr := PWideString(@Bindings[I].VWideString);
                DataPtr := PWideChar(WideStrPtr^);
                DataSize := - 1;
                if (sqlite3_bind_text16(Stmt, I + 1, DataPtr, DataSize, SQLITE_STATIC) <> SQLITE_OK) then
                  RaiseError('Could not bind text', 'BindData');
              end;
            vtChar:
              begin
                DataPtr := PAnsiChar(String(Bindings[I].VChar));
                DataSize := 2;
                if (sqlite3_bind_text(Stmt, I + 1, DataPtr, DataSize, SQLITE_STATIC) <> SQLITE_OK) then
                  RaiseError('Could not bind text', 'BindData');
              end;
            vtWideChar:
              begin
                DataPtr := PWideChar(WideString(Bindings[I].VWideChar));
                DataSize := - 1;
                if (sqlite3_bind_text16(Stmt, I + 1, DataPtr, DataSize, SQLITE_STATIC) <> SQLITE_OK) then
                  RaiseError('Could not bind text', 'BindData');
              end;
            else
              raise ESQLiteException.Create('Unknown string-type');
            end;
        end;
      vtInteger:
        if (sqlite3_bind_int(Stmt, I + 1, Bindings[I].VInteger) <> SQLITE_OK) then
          RaiseError('Could not bind integer', 'BindData');
      vtInt64:
        if (sqlite3_bind_int64(Stmt, I + 1, Bindings[I].VInt64^) <> SQLITE_OK) then
          RaiseError('Could not bind int64', 'BindData');
      vtExtended:
        if (sqlite3_bind_double(Stmt, I + 1, Bindings[I].VExtended^) <> SQLITE_OK) then
          RaiseError('Could not bind extended', 'BindData');
      vtBoolean:
        if (sqlite3_bind_int(Stmt, I + 1, integer(Bindings[I].VBoolean)) <> SQLITE_OK) then
          RaiseError('Could not bind boolean', 'BindData');
      vtPointer:
        begin
          if (Bindings[I].VPointer = nil) then
          begin
            if (sqlite3_bind_null(Stmt, I + 1) <> SQLITE_OK) then
              RaiseError('Could not bind null', 'BindData');
          end
          else
            raise ESQLiteException.Create('Unhandled pointer (<> nil)');
        end;
      vtObject:
        begin
          if (Bindings[I].VObject is TCustomMemoryStream) then
          begin
            BlobMemStream := TCustomMemoryStream(Bindings[I].VObject);
            if (sqlite3_bind_blob(Stmt, I + 1, @PAnsiChar(BlobMemStream.Memory)[BlobMemStream.position], BlobMemStream.Size - BlobMemStream.position,
              SQLITE_STATIC) <> SQLITE_OK) then
            begin
              RaiseError('Could not bind BLOB', 'BindData');
            end;
          end
          else if (Bindings[I].VObject is TStream) then
          begin
            BlobStdStream := TStream(Bindings[I].VObject);
            DataSize := BlobStdStream.Size;

            GetMem(DataPtr, DataSize);
            if (DataPtr = nil) then
              raise ESQLiteException.Create('Error getting memory to save blob');

            BlobStdStream.position := 0;
            BlobStdStream.Read(DataPtr^, DataSize);

            if (sqlite3_bind_blob(Stmt, I + 1, DataPtr, DataSize, @DisposePointer) <> SQLITE_OK) then
              RaiseError('Could not bind BLOB', 'BindData');
          end
          else
            raise ESQLiteException.Create('Unhandled object-type in binding');
        end
      else
        begin
          raise ESQLiteException.Create('Unhandled binding');
        end;
      end;
  end;
end;

procedure TSQLiteDatabase.ExecSQL(const SQL: Ansistring);
begin
  ExecSQL(SQL, []);
end;

procedure TSQLiteDatabase.ExecSQL(const SQL: Ansistring; const Bindings: array of const );
var
  Stmt: TSQLiteStmt;
  NextSQLStatement: PAnsiChar;
  iStepResult: integer;
begin
  FLastErrorCode := SQLITE_OK;
  try
    if Sqlite3_Prepare_v2(self.fDB, PAnsiChar(SQL), - 1, Stmt, NextSQLStatement) <> SQLITE_OK then
      RaiseError('Error executing SQL', SQL);
    if (Stmt = nil) then
      RaiseError('Could not prepare SQL statement', SQL);
    DoQuery(SQL);
    SetParams(Stmt);
    BindData(Stmt, Bindings);

    iStepResult := Sqlite3_step(Stmt);
    if (iStepResult <> SQLITE_DONE) then
    begin
      SQLite3_reset(Stmt);
      RaiseError('Error executing SQL statement', SQL);
    end;
  finally
    if assigned(Stmt) then
      Sqlite3_Finalize(Stmt);
  end;
end;

{$WARNINGS OFF}

procedure TSQLiteDatabase.ExecSQL(Query: TSQLiteQuery);
var
  iStepResult: integer;
begin
  FLastErrorCode := SQLITE_OK;
  if assigned(Query.Statement) then
  begin
    iStepResult := Sqlite3_step(Query.Statement);

    if (iStepResult <> SQLITE_DONE) then
    begin
      SQLite3_reset(Query.Statement);
      RaiseError('Error executing prepared SQL statement', Query.SQL);
    end;
    SQLite3_reset(Query.Statement);
  end;
end;
{$WARNINGS ON}
{$WARNINGS OFF}

function TSQLiteDatabase.PrepareSQL(const SQL: Ansistring): TSQLiteQuery;
var
  Stmt: TSQLiteStmt;
  NextSQLStatement: PAnsiChar;
begin
  FLastErrorCode := SQLITE_OK;

  Result.SQL := SQL;
  Result.Statement := nil;

  if Sqlite3_Prepare(self.fDB, PAnsiChar(SQL), - 1, Stmt, NextSQLStatement) <> SQLITE_OK then
    RaiseError('Error executing SQL', SQL)
  else
    Result.Statement := Stmt;

  if (Result.Statement = nil) then
    RaiseError('Could not prepare SQL statement', SQL);
  DoQuery(SQL);
end;
{$WARNINGS ON}
{$WARNINGS OFF}

procedure TSQLiteDatabase.BindSQL(Query: TSQLiteQuery; const Index: integer; const Value: integer);
begin
  FLastErrorCode := SQLITE_OK;
  if assigned(Query.Statement) then
    sqlite3_bind_int(Query.Statement, Index, Value)
  else
    RaiseError('Could not bind integer to prepared SQL statement', Query.SQL);
end;
{$WARNINGS ON}
{$WARNINGS OFF}

procedure TSQLiteDatabase.BindSQL(Query: TSQLiteQuery; const Index: integer; const Value: String);
begin
  FLastErrorCode := SQLITE_OK;
  if assigned(Query.Statement) then
    sqlite3_bind_text(Query.Statement, Index, PAnsiChar(Value), Length(Value), Pointer(SQLITE_STATIC))
  else
    RaiseError('Could not bind string to prepared SQL statement', Query.SQL);
end;
{$WARNINGS ON}
{$WARNINGS OFF}

procedure TSQLiteDatabase.ReleaseSQL(Query: TSQLiteQuery);
begin
  FLastErrorCode := SQLITE_OK;
  if assigned(Query.Statement) then
  begin
    Sqlite3_Finalize(Query.Statement);
    Query.Statement := nil;
  end
  else
    RaiseError('Could not release prepared SQL statement', Query.SQL);
end;
{$WARNINGS ON}

procedure TSQLiteDatabase.UpdateBlob(const SQL: Ansistring; BlobData: TStream);
var
  iSize: integer;
  ptr: Pointer;
  Stmt: TSQLiteStmt;
  Msg: PAnsiChar;
  NextSQLStatement: PAnsiChar;
  iStepResult: integer;
  iBindResult: integer;
begin
  FLastErrorCode := SQLITE_OK;
  // expects SQL of the form 'UPDATE MYTABLE SET MYFIELD = ? WHERE MYKEY = 1'
  if pos('?', SQL) = 0 then
    RaiseError('SQL must include a ? parameter', SQL);

  Msg := nil;
  try

    if Sqlite3_Prepare_v2(self.fDB, PAnsiChar(SQL), - 1, Stmt, NextSQLStatement) <> SQLITE_OK then
      RaiseError('Could not prepare SQL statement', SQL);

    if (Stmt = nil) then
      RaiseError('Could not prepare SQL statement', SQL);
    DoQuery(SQL);

    // now bind the blob data
    iSize := BlobData.Size;

    GetMem(ptr, iSize);

    if (ptr = nil) then
      raise ESQLiteException.CreateFmt('Error getting memory to save blob', [SQL, 'Error']);

    BlobData.position := 0;
    BlobData.Read(ptr^, iSize);

    iBindResult := sqlite3_bind_blob(Stmt, 1, ptr, iSize, @DisposePointer);

    if iBindResult <> SQLITE_OK then
      RaiseError('Error binding blob to database', SQL);

    iStepResult := Sqlite3_step(Stmt);

    if (iStepResult <> SQLITE_DONE) then
    begin
      SQLite3_reset(Stmt);
      RaiseError('Error executing SQL statement', SQL);
    end;

  finally

    if assigned(Stmt) then
      Sqlite3_Finalize(Stmt);

    if assigned(Msg) then
      SQLite3_Free(Msg);
  end;

end;

// ..............................................................................

function TSQLiteDatabase.GetTable(const SQL: Ansistring): TSQLiteTable;
begin
  Result := TSQLiteTable.Create(self, SQL);
end;

function TSQLiteDatabase.GetTable(const SQL: Ansistring; const Bindings: array of const ): TSQLiteTable;
begin
  Result := TSQLiteTable.Create(self, SQL, Bindings);
end;

function TSQLiteDatabase.GetUniTable(const SQL: Ansistring): TSQLiteUniTable;
begin
  Result := TSQLiteUniTable.Create(self, SQL);
end;

function TSQLiteDatabase.GetUniTable(const SQL: Ansistring; const Bindings: array of const ): TSQLiteUniTable;
begin
  Result := TSQLiteUniTable.Create(self, SQL, Bindings);
end;

function TSQLiteDatabase.GetTableValue(const SQL: Ansistring): int64;
begin
  Result := GetTableValue(SQL, []);
end;

function TSQLiteDatabase.GetTableValue(const SQL: Ansistring; const Bindings: array of const ): int64;
var
  Table: TSQLiteUniTable;
begin
  Result := 0;
  Table := self.GetUniTable(SQL, Bindings);
  try
    if not Table.EOF then
      Result := Table.FieldAsInteger(0);
  finally
    Table.Free;
  end;
end;

function TSQLiteDatabase.GetTableString(const SQL: Ansistring): String;
begin
  Result := GetTableString(SQL, []);
end;

function TSQLiteDatabase.GetTableString(const SQL: Ansistring; const Bindings: array of const ): String;
var
  Table: TSQLiteUniTable;
begin
  Result := '';
  Table := self.GetUniTable(SQL, Bindings);
  try
    if not Table.EOF then
      Result := Table.FieldAsString(0);
  finally
    Table.Free;
  end;
end;

procedure TSQLiteDatabase.GetTableStrings(const SQL: Ansistring; const Value: TStrings);
var
  Table: TSQLiteUniTable;
begin
  Value.Clear;
  Table := self.GetUniTable(SQL);
  try
    while not Table.EOF do
    begin
      Value.Add(Table.FieldAsString(0));
      Table.Next;
    end;
  finally
    Table.Free;
  end;
end;

procedure TSQLiteDatabase.BeginTransaction;
begin
  if not self.fInTrans then
  begin
    self.ExecSQL('BEGIN EXCLUSIVE TRANSACTION');
    self.fInTrans := True;
  end
  else
    raise ESQLiteException.Create('Transaction already open');
end;

procedure TSQLiteDatabase.Commit;
begin
  self.ExecSQL('COMMIT');
  self.fInTrans := False;
end;

procedure TSQLiteDatabase.Rollback;
begin
  self.ExecSQL('ROLLBACK');
  self.fInTrans := False;
end;

function TSQLiteDatabase.TableExists(TableName: string): boolean;
var
  SQL: string;
  ds: TSQLiteTable;
begin
  // returns true if table exists in the database
  SQL := 'select [sql] from sqlite_master where [type] = ''table'' and lower(name) = ''' + lowercase(TableName) + ''' ';
  ds := self.GetTable(SQL);
  try
    Result := (ds.Count > 0);
  finally
    ds.Free;
  end;
end;

procedure TSQLiteDatabase.SetTimeout(Value: integer);
begin
  SQLite3_BusyTimeout(self.fDB, Value);
end;

function TSQLiteDatabase.Version: string;
begin
  Result := SQLite3_Version;
end;

procedure TSQLiteDatabase.AddCustomCollate(name: string; xCompare: TCollateXCompare);
begin
  sqlite3_create_collation(fDB, PAnsiChar(name), SQLITE_UTF8, nil, xCompare);
end;

procedure TSQLiteDatabase.AddSystemCollate;
begin
{$IFDEF WIN32}
  sqlite3_create_collation(fDB, 'SYSTEM', SQLITE_UTF16LE, nil, @SystemCollate);
{$ENDIF}
end;

procedure TSQLiteDatabase.ParamsClear;
var
  n: integer;
begin
  for n := fParams.Count - 1 downto 0 do
    TSQliteParam(fParams[n]).Free;
  fParams.Clear;
end;

procedure TSQLiteDatabase.AddParamInt(name: string; Value: int64);
var
  par: TSQliteParam;
begin
  par := TSQliteParam.Create;
  par.name := name;
  par.valuetype := SQLITE_INTEGER;
  par.valueinteger := Value;
  fParams.Add(par);
end;

procedure TSQLiteDatabase.AddParamFloat(name: string; Value: double);
var
  par: TSQliteParam;
begin
  par := TSQliteParam.Create;
  par.name := name;
  par.valuetype := SQLITE_FLOAT;
  par.valuefloat := Value;
  fParams.Add(par);
end;

procedure TSQLiteDatabase.AddParamText(name: string; Value: string);
var
  par: TSQliteParam;
begin
  par := TSQliteParam.Create;
  par.name := name;
  par.valuetype := SQLITE_TEXT;
  par.valuedata := Value;
  fParams.Add(par);
end;

procedure TSQLiteDatabase.AddParamNull(name: string);
var
  par: TSQliteParam;
begin
  par := TSQliteParam.Create;
  par.name := name;
  par.valuetype := SQLITE_NULL;
  fParams.Add(par);
end;

procedure TSQLiteDatabase.SetParams(Stmt: TSQLiteStmt);
var
  n: integer;
  I: integer;
  par: TSQliteParam;
begin
  try
    for n := 0 to fParams.Count - 1 do
    begin
      par := TSQliteParam(fParams[n]);
      I := sqlite3_bind_parameter_index(Stmt, PAnsiChar(par.name));
      if I > 0 then
      begin
        case par.valuetype of
          SQLITE_INTEGER:
            sqlite3_bind_int64(Stmt, I, par.valueinteger);
          SQLITE_FLOAT:
            sqlite3_bind_double(Stmt, I, par.valuefloat);
          SQLITE_TEXT:
            sqlite3_bind_text(Stmt, I, PAnsiChar(par.valuedata), Length(par.valuedata), SQLITE_TRANSIENT);
          SQLITE_NULL:
            sqlite3_bind_null(Stmt, I);
        end;
      end;
    end;
  finally
    ParamsClear;
  end;
end;

procedure TSQLiteDatabase.SetRaiseExceptions(const Value: Boolean);
begin
  FRaiseExceptions := Value;
end;

// database rows that were changed (or inserted or deleted) by the most recent SQL statement
function TSQLiteDatabase.GetRaiseExceptions: Boolean;
begin
  Result := FRaiseExceptions;
end;

function TSQLiteDatabase.GetRowsChanged: integer;
begin
  Result := SQLite3_Changes(self.fDB);
end;

procedure TSQLiteDatabase.DoQuery(Value: string);
begin
  if assigned(OnQuery) then
    OnQuery(self, Value);
end;

// returns result of SQLITE3_Backup_Step
function TSQLiteDatabase.Backup(TargetDB: TSQLiteDatabase; targetName: Ansistring; sourceName: Ansistring): integer;
var
  pBackup: TSQLiteBackup;
begin
  pBackup := Sqlite3_backup_init(TargetDB.DB, PAnsiChar(targetName), self.DB, PAnsiChar(sourceName));

  if (pBackup = nil) then
    raise ESQLiteException.Create('Could not initialize backup')
  else
  begin
    try
      Result := SQLITE3_Backup_Step(pBackup, - 1); // copies entire db
    finally
      SQLITE3_backup_finish(pBackup);
    end;
  end;
end;

function TSQLiteDatabase.Backup(TargetDB: TSQLiteDatabase): integer;
begin
  Result := self.Backup(TargetDB, 'main', 'main');
end;

// ------------------------------------------------------------------------------
// TSQLiteTable
// ------------------------------------------------------------------------------

constructor TSQLiteTable.Create(DB: TSQLiteDatabase; const SQL: Ansistring);
begin
  Create(DB, SQL, []);
end;

constructor TSQLiteTable.Create(DB: TSQLiteDatabase; const SQL: Ansistring; const Bindings: array of const );
var
  Stmt: TSQLiteStmt;
  NextSQLStatement: PAnsiChar;
  iStepResult: integer;
  ptr: Pointer;
  iNumBytes: integer;
  thisBlobValue: TMemoryStream;
  thisStringValue: pstring;
  thisDoubleValue: pDouble;
  thisIntValue: pInt64;
  thisColType: pInteger;
  I: integer;
  DeclaredColType: PAnsiChar;
  ActualColType: integer;
  ptrValue: PAnsiChar;
begin
  inherited Create;
  try
    self.fRowCount := 0;
    self.fColCount := 0;
    // if there are several SQL statements in SQL, NextSQLStatment points to the
    // beginning of the next one. Prepare only prepares the first SQL statement.
    if Sqlite3_Prepare_v2(DB.fDB, PAnsiChar(SQL), - 1, Stmt, NextSQLStatement) <> SQLITE_OK then
      DB.RaiseError('Error executing SQL', SQL);
    if (Stmt = nil) then
      DB.RaiseError('Could not prepare SQL statement', SQL);
    DB.DoQuery(SQL);
    DB.SetParams(Stmt);
    DB.BindData(Stmt, Bindings);

    iStepResult := Sqlite3_step(Stmt);
    while (iStepResult <> SQLITE_DONE) do
    begin
      case iStepResult of
        SQLITE_ROW:
          begin
            Inc(fRowCount);
            if (fRowCount = 1) then
            begin
              // get data types
              fCols := TStringList.Create;
              fColTypes := TList.Create;
              fColCount := SQLite3_ColumnCount(Stmt);
              for I := 0 to Pred(fColCount) do
                fCols.Add(AnsiUpperCase(Sqlite3_ColumnName(Stmt, I)));
              for I := 0 to Pred(fColCount) do
              begin
                new(thisColType);
                DeclaredColType := Sqlite3_ColumnDeclType(Stmt, I);
                if DeclaredColType = nil then
                  thisColType^ := Sqlite3_ColumnType(Stmt, I) // use the actual column type instead
                  // seems to be needed for last_insert_rowid
                else if (DeclaredColType = 'INTEGER') or (DeclaredColType = 'BOOLEAN') then
                  thisColType^ := dtInt
                else if (DeclaredColType = 'NUMERIC') or (DeclaredColType = 'FLOAT') or (DeclaredColType = 'DOUBLE') or (DeclaredColType = 'REAL') then
                  thisColType^ := dtNumeric
                else if DeclaredColType = 'BLOB' then
                  thisColType^ := dtBlob
                else
                  thisColType^ := dtStr;
                fColTypes.Add(thisColType);
              end;
              fResults := TList.Create;
            end;

            // get column values
            for I := 0 to Pred(ColCount) do
            begin
              ActualColType := Sqlite3_ColumnType(Stmt, I);
              if (ActualColType = SQLITE_NULL) then
                fResults.Add(nil)
              else if pInteger(fColTypes[I])^ = dtInt then
              begin
                new(thisIntValue);
                thisIntValue^ := Sqlite3_ColumnInt64(Stmt, I);
                fResults.Add(thisIntValue);
              end
              else if pInteger(fColTypes[I])^ = dtNumeric then
              begin
                new(thisDoubleValue);
                thisDoubleValue^ := Sqlite3_ColumnDouble(Stmt, I);
                fResults.Add(thisDoubleValue);
              end
              else if pInteger(fColTypes[I])^ = dtBlob then
              begin
                iNumBytes := Sqlite3_ColumnBytes(Stmt, I);
                if iNumBytes = 0 then
                  thisBlobValue := nil
                else
                begin
                  thisBlobValue := TMemoryStream.Create;
                  thisBlobValue.position := 0;
                  ptr := Sqlite3_ColumnBlob(Stmt, I);
                  thisBlobValue.writebuffer(ptr^, iNumBytes);
                end;
                fResults.Add(thisBlobValue);
              end
              else
              begin
                new(thisStringValue);
                ptrValue := Sqlite3_ColumnText(Stmt, I);
                setstring(thisStringValue^, ptrValue, strlen(ptrValue));
                fResults.Add(thisStringValue);
              end;
            end;
          end;
        SQLITE_BUSY:
          raise ESQLiteException.CreateFmt('Could not prepare SQL statement', [SQL, 'SQLite is Busy']);
        else
          begin
            SQLite3_reset(Stmt);
            DB.RaiseError('Could not retrieve data', SQL);
          end;
        end;
      iStepResult := Sqlite3_step(Stmt);
    end;
    fRow := 0;
  finally
    if assigned(Stmt) then
      Sqlite3_Finalize(Stmt);
  end;
end;

// ..............................................................................

destructor TSQLiteTable.Destroy;
var
  I: cardinal;
  iColNo: integer;
begin
  if assigned(fResults) then
  begin
    for I := 0 to fResults.Count - 1 do
    begin
      // check for blob type
      iColNo := (I mod fColCount);
      case pInteger(self.fColTypes[iColNo])^ of
        dtBlob:
          TMemoryStream(fResults[I]).Free;
        dtStr:
          if fResults[I] <> nil then
          begin
            setstring(string(fResults[I]^), nil, 0);
            dispose(fResults[I]);
          end;
        else
          dispose(fResults[I]);
        end;
    end;
    fResults.Free;
  end;
  if assigned(fCols) then
    fCols.Free;
  if assigned(fColTypes) then
    for I := 0 to fColTypes.Count - 1 do
      dispose(fColTypes[I]);
  fColTypes.Free;
  inherited;
end;

// ..............................................................................

function TSQLiteTable.GetColumns(I: integer): string;
begin
  Result := fCols[I];
end;

// ..............................................................................

function TSQLiteTable.GetCountResult: integer;
begin
  if not EOF then
    Result := StrToInt(Fields[0])
  else
    Result := 0;
end;

function TSQLiteTable.GetCount: integer;
begin
  Result := fRowCount;
end;

// ..............................................................................

function TSQLiteTable.GetEOF: boolean;
begin
  Result := fRow >= fRowCount;
end;

function TSQLiteTable.GetBOF: boolean;
begin
  Result := fRow <= 0;
end;

// ..............................................................................

function TSQLiteTable.GetFieldByName(FieldName: string): string;
begin
  Result := GetFields(self.GetFieldIndex(FieldName));
end;

function TSQLiteTable.GetFieldIndex(FieldName: string): integer;
begin
  if (fCols = nil) then
  begin
    raise ESQLiteException.Create('Field ' + FieldName + ' Not found. Empty dataset');
    exit;
  end;

  if (fCols.Count = 0) then
  begin
    raise ESQLiteException.Create('Field ' + FieldName + ' Not found. Empty dataset');
    exit;
  end;

  Result := fCols.IndexOf(AnsiUpperCase(FieldName));

  if (Result < 0) then
  begin
    raise ESQLiteException.Create('Field not found in dataset: ' + FieldName)
  end;
end;

// ..............................................................................

function TSQLiteTable.GetFields(I: cardinal): string;
var
  thisvalue: pstring;
  thistype: integer;
begin
  Result := '';
  if EOF then
    raise ESQLiteException.Create('Table is at End of File');
  // integer types are not stored in the resultset
  // as strings, so they should be retrieved using the type-specific
  // methods
  thistype := pInteger(self.fColTypes[I])^;

  case thistype of
    dtStr:
      begin
        thisvalue := self.fResults[(self.fRow * self.fColCount) + I];
        if (thisvalue <> nil) then
          Result := thisvalue^
        else
          Result := '';
      end;
    dtInt:
      Result := IntToStr(self.FieldAsInteger(I));
    dtNumeric:
      Result := FloatToStr(self.FieldAsDouble(I));
    dtBlob:
      Result := self.FieldAsBlobText(I);
    else
      Result := '';
    end;
end;

function TSQLiteTable.FieldAsBlob(I: cardinal): TMemoryStream;
begin
  if EOF then
    raise ESQLiteException.Create('Table is at End of File');
  if (self.fResults[(self.fRow * self.fColCount) + I] = nil) then
    Result := nil
  else if pInteger(self.fColTypes[I])^ = dtBlob then
    Result := TMemoryStream(self.fResults[(self.fRow * self.fColCount) + I])
  else
    raise ESQLiteException.Create('Not a Blob field');
end;

function TSQLiteTable.FieldAsBlobText(I: cardinal): string;
var
  MemStream: TMemoryStream;
  Buffer: PAnsiChar;
begin
  Result := '';
  MemStream := self.FieldAsBlob(I);
  if MemStream <> nil then
    if MemStream.Size > 0 then
    begin
      MemStream.position := 0;
{$IFDEF UNICODE}
      Buffer := AnsiStralloc(MemStream.Size + 1);
{$ELSE}
      Buffer := Stralloc(MemStream.Size + 1);
{$ENDIF}
      MemStream.readbuffer(Buffer[0], MemStream.Size);
      (Buffer + MemStream.Size)^ := chr(0);
      setstring(Result, Buffer, MemStream.Size);
      strdispose(Buffer);
    end;
  // do not free the TMemoryStream here; it is freed when
  // TSqliteTable is destroyed

end;

function TSQLiteTable.FieldAsInteger(I: cardinal): int64;
begin
  if EOF then
    raise ESQLiteException.Create('Table is at End of File');
  if (self.fResults[(self.fRow * self.fColCount) + I] = nil) then
    Result := 0
  else if pInteger(self.fColTypes[I])^ = dtInt then
    Result := pInt64(self.fResults[(self.fRow * self.fColCount) + I])^
  else if pInteger(self.fColTypes[I])^ = dtNumeric then
    Result := trunc(strtofloat(pstring(self.fResults[(self.fRow * self.fColCount) + I])^))
  else
    raise ESQLiteException.Create('Not an integer or numeric field');
end;

function TSQLiteTable.FieldAsDouble(I: cardinal): double;
begin
  if EOF then
    raise ESQLiteException.Create('Table is at End of File');
  if (self.fResults[(self.fRow * self.fColCount) + I] = nil) then
    Result := 0
  else if pInteger(self.fColTypes[I])^ = dtInt then
    Result := pInt64(self.fResults[(self.fRow * self.fColCount) + I])^
  else if pInteger(self.fColTypes[I])^ = dtNumeric then
    Result := pDouble(self.fResults[(self.fRow * self.fColCount) + I])^
  else
    raise ESQLiteException.Create('Not an integer or numeric field');
end;

function TSQLiteTable.FieldAsString(I: cardinal): string;
begin
  if EOF then
    raise ESQLiteException.Create('Table is at End of File');
  if (self.fResults[(self.fRow * self.fColCount) + I] = nil) then
    Result := ''
  else
    Result := self.GetFields(I);
end;

function TSQLiteTable.FieldIsNull(I: cardinal): boolean;
var
  thisvalue: Pointer;
begin
  if EOF then
    raise ESQLiteException.Create('Table is at End of File');
  thisvalue := self.fResults[(self.fRow * self.fColCount) + I];
  Result := (thisvalue = nil);
end;

// ..............................................................................

function TSQLiteTable.Next: boolean;
begin
  Result := False;
  if not EOF then
  begin
    Inc(fRow);
    Result := True;
  end;
end;

function TSQLiteTable.Previous: boolean;
begin
  Result := False;
  if not BOF then
  begin
    Dec(fRow);
    Result := True;
  end;
end;

function TSQLiteTable.MoveFirst: boolean;
begin
  Result := False;
  if self.fRowCount > 0 then
  begin
    fRow := 0;
    Result := True;
  end;
end;

function TSQLiteTable.MoveLast: boolean;
begin
  Result := False;
  if self.fRowCount > 0 then
  begin
    fRow := fRowCount - 1;
    Result := True;
  end;
end;

{$WARNINGS OFF}

function TSQLiteTable.MoveTo(position: cardinal): boolean;
begin
  Result := False;
  if (self.fRowCount > 0) and (self.fRowCount > position) then
  begin
    fRow := position;
    Result := True;
  end;
end;
{$WARNINGS ON}
{ TSQLiteUniTable }

constructor TSQLiteUniTable.Create(DB: TSQLiteDatabase; const SQL: Ansistring);
begin
  Create(DB, SQL, []);
end;

constructor TSQLiteUniTable.Create(DB: TSQLiteDatabase; const SQL: Ansistring; const Bindings: array of const );
var
  NextSQLStatement: PAnsiChar;
  I: integer;
begin
  inherited Create;
  self.fDB := DB;
  self.fEOF := False;
  self.fRow := 0;
  self.fColCount := 0;
  self.fSQL := SQL;
  if Sqlite3_Prepare_v2(DB.fDB, PAnsiChar(SQL), - 1, fStmt, NextSQLStatement) <> SQLITE_OK then
    DB.RaiseError('Error executing SQL', SQL);
  if (fStmt = nil) then
    DB.RaiseError('Could not prepare SQL statement', SQL);
  DB.DoQuery(SQL);
  DB.SetParams(fStmt);
  DB.BindData(fStmt, Bindings);

  // get data types
  fCols := TStringList.Create;
  fColCount := SQLite3_ColumnCount(fStmt);
  for I := 0 to Pred(fColCount) do
    fCols.Add(AnsiUpperCase(Sqlite3_ColumnName(fStmt, I)));

  Next;
end;

destructor TSQLiteUniTable.Destroy;
begin
  if assigned(fStmt) then
    Sqlite3_Finalize(fStmt);
  if assigned(fCols) then
    fCols.Free;
  inherited;
end;

function TSQLiteUniTable.FieldAsBlob(I: cardinal): TMemoryStream;
var
  iNumBytes: integer;
  ptr: Pointer;
begin
  Result := TMemoryStream.Create;
  iNumBytes := Sqlite3_ColumnBytes(fStmt, I);
  if iNumBytes > 0 then
  begin
    ptr := Sqlite3_ColumnBlob(fStmt, I);
    Result.writebuffer(ptr^, iNumBytes);
    Result.position := 0;
  end;
end;

function TSQLiteUniTable.FieldAsBlobPtr(I: cardinal; out iNumBytes: integer): Pointer;
begin
  iNumBytes := Sqlite3_ColumnBytes(fStmt, I);
  Result := Sqlite3_ColumnBlob(fStmt, I);
end;

function TSQLiteUniTable.FieldAsBlobText(I: cardinal): string;
var
  MemStream: TMemoryStream;
  Buffer: PAnsiChar;
begin
  Result := '';
  MemStream := self.FieldAsBlob(I);
  if MemStream <> nil then
    try
      if MemStream.Size > 0 then
      begin
        MemStream.position := 0;
{$IFDEF UNICODE}
        Buffer := AnsiStralloc(MemStream.Size + 1);
{$ELSE}
        Buffer := Stralloc(MemStream.Size + 1);
{$ENDIF}
        MemStream.readbuffer(Buffer[0], MemStream.Size);
        (Buffer + MemStream.Size)^ := chr(0);
        setstring(Result, Buffer, MemStream.Size);
        strdispose(Buffer);
      end;
    finally
      MemStream.Free;
    end
end;

function TSQLiteUniTable.FieldAsDouble(I: cardinal): double;
begin
  Result := Sqlite3_ColumnDouble(fStmt, I);
end;

function TSQLiteUniTable.FieldAsInteger(I: cardinal): int64;
begin
  Result := Sqlite3_ColumnInt64(fStmt, I);
end;

function TSQLiteUniTable.FieldAsString(I: cardinal): string;
begin
  Result := self.GetFields(I);
end;

function TSQLiteUniTable.FieldIsNull(I: cardinal): boolean;
begin
  Result := Sqlite3_ColumnText(fStmt, I) = nil;
end;

function TSQLiteUniTable.GetColumns(I: integer): string;
begin
  Result := fCols[I];
end;

function TSQLiteUniTable.GetFieldByName(FieldName: string): string;
begin
  Result := GetFields(self.GetFieldIndex(FieldName));
end;

function TSQLiteUniTable.GetFieldIndex(FieldName: string): integer;
begin
  if (fCols = nil) then
  begin
    raise ESQLiteException.Create('Field ' + FieldName + ' Not found. Empty dataset');
    exit;
  end;

  if (fCols.Count = 0) then
  begin
    raise ESQLiteException.Create('Field ' + FieldName + ' Not found. Empty dataset');
    exit;
  end;

  Result := fCols.IndexOf(AnsiUpperCase(FieldName));

  if (Result < 0) then
  begin
    raise ESQLiteException.Create('Field not found in dataset: ' + FieldName)
  end;
end;

function TSQLiteUniTable.GetFields(I: cardinal): string;
begin
  Result := Sqlite3_ColumnText(fStmt, I);
end;

function TSQLiteUniTable.Next: boolean;
var
  iStepResult: integer;
begin
  fEOF := True;
  iStepResult := Sqlite3_step(fStmt);
  case iStepResult of
    SQLITE_ROW:
      begin
        fEOF := False;
        Inc(fRow);
      end;
    SQLITE_DONE:
      // we are on the end of dataset
      // return EOF=true only
      ;
    else
      begin
        SQLite3_reset(fStmt);
        fDB.RaiseError('Could not retrieve data', fSQL);
      end;
    end;
  Result := not fEOF;
end;

{ TSQLiteTableHelper }

function TSQLiteTableHelper.GetFieldAsVariant(I: cardinal): Variant;
var
  thisvalue: pstring;
  thistype: integer;
  utf8str: Ansistring;
begin
  Result := '';
  if EOF then
    raise ESQLiteException.Create('Table is at End of File');
  // integer types are not stored in the resultset
  // as strings, so they should be retrieved using the type-specific
  // methods
  thistype := pInteger(self.fColTypes[I])^;

  case thistype of
    dtStr:
      begin
        thisvalue := self.fResults[(self.fRow * self.fColCount) + I];
        if (thisvalue <> nil) then
          utf8str := thisvalue^
        else
          utf8str := '';
        Result := UTF8ToString(utf8str);
      end;
    dtInt:
      Result := self.FieldAsInteger(I);
    dtNumeric:
      Result := self.FieldAsDouble(I);
    dtBlob:
      Result := self.FieldAsBlobText(I);
    else
      Result := '';
    end;
end;

function TSQLiteTableHelper.GetFieldType(I: cardinal): integer;
begin
  {
    dtInt = 1;
    dtNumeric = 2;
    dtStr = 3;
    dtBlob = 4;
    dtNull = 5;
  }
  Result := pInteger(self.fColTypes[I])^;
end;

end.
