unit configuration;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils
  ;

type

  { TConfig }

  TConfig = class
  private
    FAccountEmail: String;
    FAPIKey: String;
  published
    property APIKey: String read FAPIKey write FAPIKey;
    property AccountEmail: String read FAccountEmail write FAccountEmail;
  end;

var
  Config: TConfig;

implementation

uses
  FileUtil, fpjsonrtti
  ;

procedure LoadFromJSON(const aFileName: String; aConfig: TConfig);
var
  aDeStreamer: TJSONDeStreamer;
  aStrings: TStringList;
begin
  aDeStreamer := TJSONDeStreamer.Create(nil);
  aStrings:=TStringList.Create;
  try
    aStrings.LoadFromFile(aFileName);
    aDeStreamer.JSONToObject(aStrings.Text, aConfig);
  finally
    aStrings.Free;
    aDeStreamer.Free;
  end;
end;

procedure SaveToJSON(const aFileName: String; aConfig: TConfig);
var
  aStreamer: TJSONStreamer;
  aStrings: TStringList;
begin
  aStreamer := TJSONStreamer.Create(nil);
  aStrings:=TStringList.Create;
  try
    aStreamer.Options:=aStreamer.Options+[jsoUseFormatString];
    aStrings.Text:=aStreamer.ObjectToJSONString(aConfig);
    aStrings.SaveToFile(aFileName);
  finally
    aStrings.Free;
    aStreamer.Free;
  end;
end;

initialization
  Config:=TConfig.Create;
  LoadFromJSON('config.json', Config);

finalization
  SaveToJSON('config_template.json', Config);
  Config.Free;

end.

