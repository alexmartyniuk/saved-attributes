program PropertyStorageDemo;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  System.SysUtils,
  Classes,
  System.Generics.Collections,
  uFilterImpl in '..\sources\uFilterImpl.pas',
  uListImpl in '..\sources\uListImpl.pas',
  uNamedValuesImpl in '..\sources\uNamedValuesImpl.pas',
  uQueryResultsImpl in '..\sources\uQueryResultsImpl.pas',
  uRecordImpl in '..\sources\uRecordImpl.pas',
  uStorageIntf in '..\sources\uStorageIntf.pas',
  uStorageSQLiteImpl in '..\sources\uStorageSQLiteImpl.pas',
  uStoredValue in '..\sources\uStoredValue.pas',
  uTableImpl in '..\sources\uTableImpl.pas';

const
  SCHOOL_DB_NAME = 'school.db';

var
  school: IStorage;
  students: ITable;
  student: IRecord;
  list: IList<IRecord>;
  stream: TStream;

begin
  try
    school := TStorageSQLite.Create(SCHOOL_DB_NAME);
    school.Open();
    try
      students := school.Table('students');

      student := students.NewRecord();
      student.Attribute['name'] := 'Alexander Martinyuk';
      student.Attribute['age'] := 25;

      student := students.NewRecord();
      student.Attribute['name'] := 'Боб Марлі';
      student.Attribute['age'] := 59;
      student.Attribute['date_of_entry'] := EncodeDate(2000, 12, 06);

      stream := TFileStream.Create('d:\Маршрут.png', fmOpenRead);
      student.Attribute['photo'].SetStream(stream);
      stream.Free;
    finally
      school.Close();
    end;
    school := TStorageSQLite.Create(SCHOOL_DB_NAME);
    school.Open();
    try
      students := school.Table('students');

      list := students.ReadMany(Where('age', CONDITION_MORE, 40));
      for student in list do
      begin
        Writeln('Day of birth: ' + DateToStr(student.Attribute['date_of_entry']));
        Writeln(string(student.Attribute['name']));

        stream := TmemoryStream.Create;
        student.Attribute['photo'].GetStream(stream);
        Writeln(IntToStr(stream.Size));
        stream.Free;
      end;
      Readln;
    finally
      school.Close();
    end;
  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;

end.
