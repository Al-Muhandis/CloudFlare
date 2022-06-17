unit cloudflareapi;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, fphttpclient, fpjson
  ;

type

  { TCloudFlareAPI }

  TCloudFlareAPI = class
  private
    FHTTPClient: TFPHTTPClient;
    FJSON: TJSONObject;
    FParameters: TStringList;
    FResponse: String;
    function GetJSONResponse: TJSONObject;
    function GetParameters(const aName: String): String;
    function RouteURL(const aObject, aObjectID, aPath: String): String;
    procedure SetAccountEmail(const AValue: String);
    procedure SetAPIKey(const AValue: String);
    procedure SetParameters(aName: String; AValue: String);
  public
    constructor Create;
    destructor Destroy; override;
    procedure ListZones;
    procedure UniversalSSLSettingsDetails(const aZoneID: String);
    procedure RawSendMethod(const aMethod, aObject: String; const aObjectID: String = ''; const aPath: String = '');
    property APIKey: String write SetAPIKey;
    property AccountEmail: String write SetAccountEmail;
    property Response: String read FResponse;
    property JSONResponse: TJSONObject read GetJSONResponse;
    property Parameters[aName: String]: String read GetParameters write SetParameters;
  end;


implementation

uses
  opensslsockets
  ;

const
  _api_endpoint='https://api.cloudflare.com/client/v4/';
  _GET='GET';
  _PATCH='PATCH';
  _zones='zones';

{ TCloudFlareAPI }

procedure TCloudFlareAPI.SetAPIKey(const AValue: String);
begin
  FHTTPClient.AddHeader('X-Auth-Key', AValue);
end;

procedure TCloudFlareAPI.SetParameters(aName: String; AValue: String);
begin
  FParameters.Values[aName]:=AValue;
end;

procedure TCloudFlareAPI.SetAccountEmail(const AValue: String);
begin
  FHTTPClient.AddHeader('X-Auth-Email', AValue);
end;

function TCloudFlareAPI.GetJSONResponse: TJSONObject;
begin
  FJSON.Free;
  FJSON:=GetJSON(Response) as TJSONObject;
  Result:=FJSON;
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

constructor TCloudFlareAPI.Create;
begin
  FHTTPClient:=TFPHTTPClient.Create(nil);              
  FHTTPClient.AddHeader('Content-Type', 'application/json');
  FParameters:=TStringList.Create;
  FParameters.Delimiter:='&';
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
  RawSendMethod(_GET, _zones, aZoneID, 'ssl/universal/settings');
end;

procedure TCloudFlareAPI.RawSendMethod(const aMethod, aObject: String; const aObjectID: String; const aPath: String);
var
  SS: TRawByteStringStream;
  aParameters: String;
begin
  SS:=TRawByteStringStream.Create(EmptyStr);
  try
    if FParameters.Count>0 then
      aParameters:='?'+FParameters.DelimitedText;
    FHTTPClient.HTTPMethod(aMethod, RouteURL(aObject, aObjectID, aPath)+aParameters, SS, []);
    FResponse:=SS.DataString;
  finally
    SS.Free;
  end;
end;

end.

