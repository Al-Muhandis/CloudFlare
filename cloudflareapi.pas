unit cloudflareapi;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fphttpclient, fpjson, openssl, opensslsockets
  ;

type

  { TCloudFlareAPI }

  TCloudFlareAPI = class
  private
    FHTTPClient: TFPHTTPClient;
    FJSON: TJSONObject;
    FParameters: TStringList;
    FResponse: String;
    function GetAccountEmail: String;
    function GetAPIKey: String;
    function GetJSONResponse: TJSONObject;
    function GetParameters(const aName: String): String;
    function JSONStringFromObject(aObject: TObject): String;
    function RouteURL(const aObject, aObjectID, aPath: String): String;
    procedure SetAccountEmail(const AValue: String);
    procedure SetAPIKey(const AValue: String);
    procedure SetParameters(aName: String; AValue: String);
  public
    constructor Create;
    procedure ClearParameters;
    destructor Destroy; override;
    procedure ListZones;
    procedure UniversalSSLSettingsDetails(const aZoneID: String);
    procedure EditUniversalSSLSettings(const aZoneID: String; aEnabled: Boolean);
    procedure RawSendMethod(const aMethod, aObject: String; const aObjectID: String = ''; const aPath: String = '');
    property APIKey: String read GetAPIKey write SetAPIKey;
    property AccountEmail: String read GetAccountEmail write SetAccountEmail;
    property Response: String read FResponse;
    property JSONResponse: TJSONObject read GetJSONResponse;
    property Parameters[aName: String]: String read GetParameters write SetParameters;
  end;


implementation

uses
  fpjsonrtti
  ;

const
  _api_endpoint='https://api.cloudflare.com/client/v4/';
  _GET='GET';
  _PATCH='PATCH';
  _zones='zones';
  _pth_UnvrslSSLStngs='ssl/universal/settings';

  _AuthEmail='X-Auth-Email';
  _APIKey='X-Auth-Key';

type
  { TUniversalSetting }

  TUniversalSetting = class
  private
    FEnabled: Boolean;
  published
    property enabled: Boolean read FEnabled write FEnabled;
  end;

{ TCloudFlareAPI }

procedure TCloudFlareAPI.SetAPIKey(const AValue: String);
begin
  FHTTPClient.AddHeader(_APIKey, AValue);
end;

procedure TCloudFlareAPI.SetParameters(aName: String; AValue: String);
begin
  FParameters.Values[aName]:=AValue;
end;

procedure TCloudFlareAPI.SetAccountEmail(const AValue: String);
begin
  FHTTPClient.AddHeader(_AuthEmail, AValue);
end;

function TCloudFlareAPI.GetJSONResponse: TJSONObject;
begin
  FJSON.Free;
  FJSON:=GetJSON(Response) as TJSONObject;
  Result:=FJSON;
end;

function TCloudFlareAPI.GetAPIKey: String;
begin
  Result:=FHTTPClient.GetHeader(_APIKey);
end;

function TCloudFlareAPI.GetAccountEmail: String;
begin
  Result:=FHTTPClient.GetHeader(_AuthEmail);
end;

function TCloudFlareAPI.GetParameters(const aName: String): String;
begin
  Result:=FParameters.Values[aName];
end;

function TCloudFlareAPI.RouteURL(const aObject, aObjectID, aPath: String): String;
begin
  Result:=_api_endpoint;
  if aObject.IsEmpty then
    Exit;
  Result+=aObject+'/';
  if aObjectID.IsEmpty then
    Exit;
  Result+=aObjectID+'/'+aPath;
end;

function TCloudFlareAPI.JSONStringFromObject(aObject: TObject): String;
var
  aStreamer: TJSONStreamer;
begin
  aStreamer := TJSONStreamer.Create(nil);
  try
    Result:=aStreamer.ObjectToJSONString(aObject);
  finally
    aStreamer.Free;
  end;
end;

constructor TCloudFlareAPI.Create;
begin
  FHTTPClient:=TFPHTTPClient.Create(nil);              
  FHTTPClient.AddHeader('Content-Type', 'application/json');
  FParameters:=TStringList.Create;
  FParameters.Delimiter:='&';
  FParameters.StrictDelimiter:=True;
end;

procedure TCloudFlareAPI.ClearParameters;
begin
  FParameters.Text:=EmptyStr;
  FParameters.Delimiter:='&'; 
  FParameters.StrictDelimiter:=True;
end;

destructor TCloudFlareAPI.Destroy;
begin
  FParameters.Free;
  FJSON.Free;
  FHTTPClient.Free;
  inherited Destroy;
end;

procedure TCloudFlareAPI.ListZones;
begin
  RawSendMethod(_GET, _zones);
end;

procedure TCloudFlareAPI.UniversalSSLSettingsDetails(const aZoneID: String);
begin
  RawSendMethod(_GET, _zones, aZoneID, _pth_UnvrslSSLStngs);
end;

procedure TCloudFlareAPI.EditUniversalSSLSettings(const aZoneID: String; aEnabled: Boolean);
var
  aData: TUniversalSetting;
begin
  aData:=TUniversalSetting.Create;
  aData.enabled:=aEnabled;
  try
    FHTTPClient.RequestBody:=TRawByteStringStream.Create(JSONStringFromObject(aData));
    try
      RawSendMethod(_PATCH, _zones, aZoneID, _pth_UnvrslSSLStngs);
    finally
      FHTTPClient.RequestBody.Free; 
      FHTTPClient.RequestBody:=nil;
    end;
  finally
    aData.Free;
  end;
end;

procedure TCloudFlareAPI.RawSendMethod(const aMethod, aObject: String; const aObjectID: String; const aPath: String);
var
  SS: TRawByteStringStream;
  aParameters: String;
begin
  SS:=TRawByteStringStream.Create(EmptyStr);
  try
    FResponse:=EmptyStr;
    if FParameters.Count>0 then
      aParameters:='?'+FParameters.DelimitedText;
    FHTTPClient.HTTPMethod(aMethod, RouteURL(aObject, aObjectID, aPath)+aParameters, SS, [200]);
    FResponse:=SS.DataString;
  finally
    SS.Free;
  end;
end;

end.

