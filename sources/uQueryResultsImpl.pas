unit uQueryResultsImpl;

interface

uses
  Variants,
  Classes,
  SysUtils,
  Generics.Collections,
  SQLiteTable3,
  DB,
  uStorageIntf;

type

  TRecords = TList<INamedValues>;

  TQueryResults = class(TInterfacedObject, IQueryResults)
    private
      FRecords: TRecords;
      FIndex: Integer;
    protected
      procedure Next;
      procedure First;
      function Eof: Boolean;
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
      constructor Create(Records: TRecords);
      destructor Destroy; override;
  end;

implementation

constructor TQueryResults.Create(Records: TRecords);
var
  i: Integer;
begin
  FRecords := TRecords.Create;
  if Assigned(Records) then
  begin
    for i := 0 to Records.Count - 1 do
      FRecords.Add(Records.Items[i]);
  end;
end;

destructor TQueryResults.Destroy;
begin
  FRecords.Clear;
  FRecords.Free;
  inherited;
end;

function TQueryResults.Eof: Boolean;
begin
  Result := FIndex >= FRecords.Count;
end;

procedure TQueryResults.First;
begin
  FIndex := 0;
end;

function TQueryResults.GetText: string;
begin
  raise Exception.Create('Not implemented');
end;

function TQueryResults.GetValue(Name: string): Variant;
begin
  if Eof then
    Exit(Null);
  Result := FRecords.Items[FIndex].Value[name];
  if VarIsNull(Result) then
    Result := 0;
end;

procedure TQueryResults.Next;
begin
  FIndex := FIndex + 1;
end;

procedure TQueryResults.SetText(const Value: string);
begin
  raise Exception.Create('Not implemented');
end;

procedure TQueryResults.SetValue(Name: string; const Value: Variant);
begin
  raise Exception.Create('Not implemented');
end;

function TQueryResults.ValueAsBoolean(const Name: string; const ADefault: Boolean): Boolean;
begin
  if ValueExists(Name) then
    Result := GetValue(Name)
  else
    Result := ADefault;
end;

function TQueryResults.ValueAsDateTime(const Name: string; const ADefault: TDateTime): TDateTime;
begin
  if ValueExists(Name) then
    Result := GetValue(Name)
  else
    Result := ADefault;
end;

function TQueryResults.ValueAsDouble(const Name: string; const ADefault: Double): Double;
begin
  if ValueExists(Name) then
    Result := GetValue(Name)
  else
    Result := ADefault;
end;

function TQueryResults.ValueAsInteger(const Name: string; const ADefault: Integer): Integer;
begin
  if ValueExists(Name) then
    Result := GetValue(Name)
  else
    Result := ADefault;
end;

function TQueryResults.ValueAsString(const Name, ADefault: string): string;
begin
  if ValueExists(Name) then
    Result := GetValue(Name)
  else
    Result := ADefault;
end;

function TQueryResults.ValueExists(const Name: string): Boolean;
var
  value: Variant;
begin
  value := GetValue(Name);
  Result := not (VarIsNull(value) or VarIsEmpty(value));
end;

end.
