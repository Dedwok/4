unit TourismISAPI;

interface

uses
  System.SysUtils, System.Classes, Web.HTTPApp, Data.DB, Data.SqlExpr,
  Data.FMTBcd, Datasnap.Provider, Datasnap.DBClient;

type
  TWebModule1 = class(TWebModule)
    SQLConnection1: TSQLConnection;
    dsCountries: TSQLDataSet;
    dsTours: TSQLDataSet;
    procedure WebModule1DefaultHandlerAction(Sender: TObject;
      Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
    procedure WebModuleCreate(Sender: TObject);
  private
    { Private declarations }
    function GetCountriesJSON: string;
    function GetToursJSON: string;
    function CreateOrder(const AClientID, ATourID, APersons: Integer): string;
  public
    { Public declarations }
  end;

var
  WebModuleClass: TComponentClass = TWebModule1;

implementation

{$R *.dfm}

uses
  System.JSON, DBXJSON;

procedure TWebModule1.WebModuleCreate(Sender: TObject);
begin
  // Настройка подключения к MS SQL Server
  SQLConnection1.Params.Clear;
  SQLConnection1.DriverName := 'MSSQL';
  SQLConnection1.Params.Add('DriverUnit=Data.DBXMSSQL');
  SQLConnection1.Params.Add('DriverPackageLoader=TDBXDynalinkDriverLoader,DBXCommonDriver250.bpl');
  SQLConnection1.Params.Add('DriverAssemblyLoader=Borland.Data.TDBXDynalinkDriverLoader,Borland.Data.DbxCommonDriver,Version=24.0.0.0,Culture=neutral,PublicKeyToken=91d62ebb5b0d1b1b');
  SQLConnection1.Params.Add('MetaDataPackageLoader=TDBXMsSqlMetaDataCommandFactory,DbxMSSQLDriver250.bpl');
  SQLConnection1.Params.Add('MetaDataAssemblyLoader=Borland.Data.TDBXMsSqlMetaDataCommandFactory,Borland.Data.DbxMSSQLDriver,Version=24.0.0.0,Culture=neutral,PublicKeyToken=91d62ebb5b0d1b1b');
  SQLConnection1.Params.Add('GetDriverFunc=getSQLDriverMSSQL');
  SQLConnection1.Params.Add('LibraryName=dbxmss.dll');
  SQLConnection1.Params.Add('VendorLib=sqlncli10.dll');
  SQLConnection1.Params.Add('HostName=localhost');
  SQLConnection1.Params.Add('Database=TourismManagement');
  SQLConnection1.Params.Add('User_Name=sa');
  SQLConnection1.Params.Add('Password=your_password');
  SQLConnection1.Params.Add('MaxBlobSize=-1');
  SQLConnection1.Params.Add('LocaleCode=0000');
  SQLConnection1.Params.Add('IsolationLevel=ReadCommitted');
  SQLConnection1.Params.Add('OSAuthentication=False');
  SQLConnection1.Params.Add('PrepareSQL=True');
  SQLConnection1.Params.Add('BlobSize=-1');
  SQLConnection1.Params.Add('ErrorResourceFile=');
  SQLConnection1.Connected := True;
end;

function TWebModule1.GetCountriesJSON: string;
var
  JSONArray: TJSONArray;
begin
  JSONArray := TJSONArray.Create;
  try
    dsCountries.Close;
    dsCountries.CommandText := 'SELECT * FROM Countries ORDER BY CountryName';
    dsCountries.Open;
    
    while not dsCountries.Eof do
    begin
      JSONArray.AddElement(
        TJSONObject.Create
          .AddPair('CountryID', TJSONNumber.Create(dsCountries.FieldByName('CountryID').AsInteger))
          .AddPair('CountryName', dsCountries.FieldByName('CountryName').AsString)
          .AddPair('VisaRequired', TJSONBool.Create(dsCountries.FieldByName('VisaRequired').AsBoolean))
      );
      dsCountries.Next;
    end;
    
    Result := JSONArray.ToString;
  finally
    JSONArray.Free;
    dsCountries.Close;
  end;
end;

function TWebModule1.GetToursJSON: string;
var
  JSONArray: TJSONArray;
begin
  JSONArray := TJSONArray.Create;
  try
    dsTours.Close;
    dsTours.CommandText := 'SELECT t.*, c.CountryName FROM Tours t ' +
                          'INNER JOIN Countries c ON t.CountryID = c.CountryID ' +
                          'WHERE t.IsActive = 1 ORDER BY t.StartDate';
    dsTours.Open;
    
    while not dsTours.Eof do
    begin
      JSONArray.AddElement(
        TJSONObject.Create
          .AddPair('TourID', TJSONNumber.Create(dsTours.FieldByName('TourID').AsInteger))
          .AddPair('Title', dsTours.FieldByName('Title').AsString)
          .AddPair('CountryName', dsTours.FieldByName('CountryName').AsString)
          .AddPair('StartDate', FormatDateTime('yyyy-mm-dd', dsTours.FieldByName('StartDate').AsDateTime))
          .AddPair('EndDate', FormatDateTime('yyyy-mm-dd', dsTours.FieldByName('EndDate').AsDateTime))
          .AddPair('Price', TJSONNumber.Create(dsTours.FieldByName('Price').AsFloat))
      );
      dsTours.Next;
    end;
    
    Result := JSONArray.ToString;
  finally
    JSONArray.Free;
    dsTours.Close;
  end;
end;

function TWebModule1.CreateOrder(const AClientID, ATourID, APersons: Integer): string;
var
  Query: TSQLQuery;
  TourPrice: Double;
begin
  Query := TSQLQuery.Create(nil);
  try
    Query.SQLConnection := SQLConnection1;
    
    // Получаем цену тура
    Query.SQL.Text := 'SELECT Price FROM Tours WHERE TourID = :TourID';
    Query.ParamByName('TourID').AsInteger := ATourID;
    Query.Open;
    TourPrice := Query.FieldByName('Price').AsFloat;
    Query.Close;
    
    // Создаем заказ
    Query.SQL.Text := 'INSERT INTO Orders (ClientID, TourID, PersonsCount, TotalPrice) ' +
                     'VALUES (:ClientID, :TourID, :Persons, :TotalPrice); ' +
                     'SELECT SCOPE_IDENTITY() AS NewOrderID;';
    Query.ParamByName('ClientID').AsInteger := AClientID;
    Query.ParamByName('TourID').AsInteger := ATourID;
    Query.ParamByName('Persons').AsInteger := APersons;
    Query.ParamByName('TotalPrice').AsFloat := TourPrice * APersons;
    Query.Open;
    
    Result := '{"status":"success","order_id":' + 
              Query.FieldByName('NewOrderID').AsString + '}';
  finally
    Query.Free;
  end;
end;

procedure TWebModule1.WebModule1DefaultHandlerAction(Sender: TObject;
  Request: TWebRequest; Response: TWebResponse; var Handled: Boolean);
var
  Action: string;
begin
  Action := Request.PathInfo;
  
  if Action = '/countries' then
  begin
    Response.ContentType := 'application/json';
    Response.Content := GetCountriesJSON;
    Handled := True;
  end
  else if Action = '/tours' then
  begin
    Response.ContentType := 'application/json';
    Response.Content := GetToursJSON;
    Handled := True;
  end
  else if Action = '/create_order' then
  begin
    Response.ContentType := 'application/json';
    Response.Content := CreateOrder(
      StrToIntDef(Request.ContentFields.Values['client_id'], 0),
      StrToIntDef(Request.ContentFields.Values['tour_id'], 0),
      StrToIntDef(Request.ContentFields.Values['persons'], 1)
    );
    Handled := True;
  end
  else
  begin
    Response.Content := '<html><body>Tourism Web Service</body></html>';
    Handled := True;
  end;
end;

end.
