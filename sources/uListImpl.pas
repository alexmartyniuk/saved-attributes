unit uListImpl;

interface

uses
  SysUtils,
  Classes,
  Masks,
  Generics.Defaults,
  Generics.Collections,
  uStorageIntf;

type

  TInterfacedList<T> = class(TInterfacedObject, IList<T>)
    private
      FList: TList<T>;
      function GetEnumerator: TList<T>.TEnumerator;
    protected
      function Add(const Value: T): Integer; overload;
      function Add(const Values: IList<T>): Integer; overload;
      function Count: Integer;
      procedure Clear;
      procedure Delete(AIndex: Integer);
      procedure DeleteItem(AItem: T);
      procedure Insert(AIndex: Integer; const AValue: T);
      function GetItem(AIndex: Integer): T;
      procedure SetItem(AIndex: Integer; const AValue: T);
      function GetIndex(AValue: T): Integer; virtual;
      procedure Sort(const AComparer: IComparer<T>); overload;
    public
      constructor Create;
      destructor Destroy; override;
  end;

implementation

{ TInterfacedList<T> }

function TInterfacedList<T>.Add(const Value: T): Integer;
begin
  Result := FList.Add(Value);
end;

function TInterfacedList<T>.Add(const Values: IList<T>): Integer;
var
  item: T;
begin
  for item in Values do
    Add(item);
end;

procedure TInterfacedList<T>.Clear;
begin
  FList.Clear;
end;

function TInterfacedList<T>.Count: Integer;
begin
  Result := FList.Count;
end;

constructor TInterfacedList<T>.Create;
begin
  inherited;
  FList := TList<T>.Create;
end;

procedure TInterfacedList<T>.Delete(AIndex: Integer);
begin
  FList.Delete(AIndex);
end;

procedure TInterfacedList<T>.DeleteItem(AItem: T);
var
  index: Integer;
begin
  index := FList.IndexOf(AItem);
  if (index >= 0) and (index < FList.Count) then
    FList.Delete(index);
end;

destructor TInterfacedList<T>.Destroy;
begin
  FList.Clear;
  FreeAndNil(FList);
  inherited;
end;

function TInterfacedList<T>.GetEnumerator: TList<T>.TEnumerator;
begin
  Result := FList.GetEnumerator;
end;

function TInterfacedList<T>.GetIndex(AValue: T): Integer;
begin
  Result := FList.IndexOf(AValue);
end;

function TInterfacedList<T>.GetItem(AIndex: Integer): T;
begin
  if (AIndex >= Count) or (AIndex < 0) then
    Exit;
  Result := FList.Items[AIndex];
end;

procedure TInterfacedList<T>.Insert(AIndex: Integer; const AValue: T);
begin
  FList.Insert(AIndex, AValue);
end;

procedure TInterfacedList<T>.SetItem(AIndex: Integer; const AValue: T);
begin
  FList.Items[AIndex] := AValue;
end;

procedure TInterfacedList<T>.Sort(const AComparer: IComparer<T>);
begin
  if not Assigned(AComparer) then
    Exit;
  FList.Sort(AComparer);
end;

end.
