unit testcloudflareapi;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpcunit, testregistry, cloudflareapi
  ;

type

  { TTestCloudFlare }

  TTestCloudFlare= class(TTestCase)
  private
    FCloudFlare: TCloudFlareAPI;
    procedure ListZonesByName(const aDomainName: String);
  protected
    procedure SetUp; override;
    procedure TearDown; override;
  published
    procedure ReadUniversalSSL;                                                                        
    procedure ListZones;
    procedure EditUniversalSSLSettings;
  end;

implementation

uses
  FileUtil, fpjson, configuration
  ;

procedure TTestCloudFlare.ReadUniversalSSL;
var
  aID: String;
begin
  ListZones;
  with FCloudFlare.JSONResponse do
  begin
    if Booleans['success'] then
      if Arrays['result'].Count>0 then
      begin
        aID:=(Arrays['result'][0] as TJSONObject).Strings['id'];
        FCloudFlare.UniversalSSLSettingsDetails(aID);
      end;
  end;
end;

procedure TTestCloudFlare.ListZones;
begin
  FCloudFlare.Parameters['page']:='2';
  FCloudFlare.ListZones;
end;

procedure TTestCloudFlare.EditUniversalSSLSettings;
var
  aID: String;
begin
  FCloudFlare.Parameters['name']:='sample.com';
  ListZones;
  with FCloudFlare.JSONResponse do
  begin
    if Booleans['success'] then
      if Arrays['result'].Count>0 then
      begin
        aID:=(Arrays['result'][0] as TJSONObject).Strings['id'];
        FCloudFlare.UniversalSSLSettingsDetails(aID);
      end;
  end;
  FCloudFlare.EditUniversalSSLSettings(aID, True);
end;

procedure TTestCloudFlare.ListZonesByName(const aDomainName: String);
begin
  FCloudFlare.Parameters['name']:=aDomainName;
  FCloudFlare.ListZones;
end;

procedure TTestCloudFlare.SetUp;
begin
  FCloudFlare:=TCloudFlareAPI.Create;
  FCloudFlare.APIKey:=Config.APIKey;
  FCloudFlare.AccountEmail:=Config.AccountEmail;
end;

procedure TTestCloudFlare.TearDown; 
var
  aStrings: TStringList;
begin
  aStrings:=TStringList.Create;
  try
    aStrings.Text:=FCloudFlare.JSONResponse.FormatJSON();
    aStrings.SaveToFile('~jsonresponse.json');
  finally
    aStrings.Free;
  end;
  FCloudFlare.Free;
end;

initialization

  RegisterTest(TTestCloudFlare);
end.

