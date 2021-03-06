        ��  ��                  4  (   �� B F A I L       0           <html><head><title>Build failed: [[ProjectName]]</title></head>
<body style="font-family:sans-serif;background-color:white;color:black;margin:0em;">
<h1 style="background-color:#0000CC;color:white;margin:0em;padding:0.2em;">Build failed: [[ProjectName]]</h1>
<xmp style="margin:0.1em;">[[Log]]</xmp>
<p style="background-color:#0000CC;color:white;font-size:0.8em;margin:0em;padding:0.2em;text-align:right;">
<a href="[[URL]]" style="float:left;color:white;">refresh</a>
<a href="http://yoy.be/xxm/" style="color:white;">xxm</a> [[DateTime]]</p></body></html>T  ,   �� B E R R O R         0           <html><head><title>Error building: [[ProjectName]]</title></head>
<body style="font-family:sans-serif;background-color:white;color:black;margin:0em;">
<h1 style="background-color:#0000CC;color:white;margin:0em;padding:0.2em;">Error building: [[ProjectName]]</h1>
<p style="margin:0.1em;">An error occurred while building the module.<br />
<i>[[ErrorClass]]</i><br /><b>[[ErrorMessage]]</b></p>
<p style="background-color:#0000CC;color:white;font-size:0.8em;margin:0em;padding:0.2em;text-align:right;">
<a href="http://yoy.be/xxm/" style="color:white;">xxm</a> [[DateTime]]</p></body></html>�1  $   ���X X M       0           unit xxm;

interface

uses SysUtils, Classes, ActiveX;

const
  //$Date: 2011-11-30 22:13:37 +0100 (wo, 30 nov 2011) $
  XxmRevision='$Rev: 180 $';

type
  IXxmContext=interface;//forward
  IXxmFragment=interface; //forward

  IXxmProject=interface
    ['{78786D00-0000-0002-C000-000000000002}']
    function GetProjectName: WideString;
    property Name:WideString read GetProjectName;
    function LoadPage(Context:IXxmContext;Address:WideString):IXxmFragment;
    function LoadFragment(Context:IXxmContext;Address,RelativeTo:WideString):IXxmFragment;
    procedure UnloadFragment(Fragment: IXxmFragment);
  end;

  TXxmProjectLoadProc=function(AProjectName:WideString): IXxmProject; stdcall;

  TXxmContextString=integer;//enumeration values see below

  TXxmVersion=record
    Major,Minor,Release,Build:integer;
  end;

  TXxmAutoEncoding=(
    aeContentDefined, //content will specify which content to use
    aeUtf8,           //send UTF-8 byte order mark
    aeUtf16,          //send UTF-16 byte order mark
    aeIso8859         //send using the closest new thing to ASCII
  );

  IXxmParameter=interface
    ['{78786D00-0000-0007-C000-000000000007}']
    function GetName:WideString;
    function GetValue:WideString;
    property Name:WideString read GetName;
    property Value:WideString read GetValue;
    function AsInteger:integer;
    function NextBySameName:IXxmParameter;
  end;

  IXxmParameterGet=interface(IXxmParameter)
    ['{78786D00-0000-0008-C000-000000000008}']
  end;

  IxxmParameterPost=interface(IXxmParameter)
    ['{78786D00-0000-0009-C000-000000000009}']
  end;

  IxxmParameterPostFile=interface(IxxmParameterPost)
    ['{78786D00-0000-000A-C000-00000000000A}']
    function GetSize:integer;
    function GetMimeType:WideString;
    property Size:integer read GetSize;
    property MimeType:WideString read GetMimeType;
    procedure SaveToFile(FilePath:AnsiString);//TODO: WideString
    function SaveToStream(Stream:IStream):integer;
  end;

  IXxmContext=interface
    ['{78786D00-0000-0003-C000-000000000003}']
    function GetURL:WideString;
    function GetPage:IXxmFragment;
    function GetContentType:WideString;
    procedure SetContentType(const Value: WideString);
    function GetAutoEncoding:TXxmAutoEncoding;
    procedure SetAutoEncoding(const Value: TXxmAutoEncoding);
    function GetParameter(Key:OleVariant):IXxmParameter;
    function GetParameterCount:integer;
    function GetSessionID:WideString;

    procedure Send(Data: OleVariant); overload;
    procedure SendHTML(Data: OleVariant); overload;
    procedure SendFile(FilePath: WideString);
    procedure SendStream(s:IStream);
    procedure Include(Address: WideString); overload;
    procedure Include(Address: WideString;
      const Values: array of OleVariant); overload;
    procedure Include(Address: WideString;
      const Values: array of OleVariant;
      const Objects: array of TObject); overload;
    procedure DispositionAttach(FileName: WideString);

    function ContextString(cs:TXxmContextString):WideString;
    function PostData:IStream;
    function Connected:boolean;

    //(local:)progress
    procedure SetStatus(Code:integer;Text:WideString);
    procedure Redirect(RedirectURL:WideString; Relative:boolean);
    function GetCookie(Name:WideString):WideString;
    procedure SetCookie(Name,Value:WideString); overload;
    procedure SetCookie(Name,Value:WideString; KeepSeconds:cardinal;
      Comment,Domain,Path:WideString; Secure,HttpOnly:boolean); overload;
    //procedure SetCookie2();

    procedure Send(Value: integer); overload;
    procedure Send(Value: int64); overload;
    procedure Send(Value: cardinal); overload;
    procedure Send(const Values:array of OleVariant); overload;
    procedure SendHTML(const Values:array of OleVariant); overload;

    function GetBufferSize: integer;
    procedure SetBufferSize(ABufferSize: integer);
    procedure Flush;

    property URL:WideString read GetURL;
    property ContentType:WideString read GetContentType write SetContentType;
    property AutoEncoding:TXxmAutoEncoding read GetAutoEncoding write SetAutoEncoding;
    property Page:IXxmFragment read GetPage;
    property Parameter[Key:OleVariant]:IXxmParameter read GetParameter; default;
    property ParameterCount:integer read GetParameterCount;
    property SessionID:WideString read GetSessionID;
    property Cookie[Name:WideString]:WideString read GetCookie;
    property BufferSize: integer read GetBufferSize write SetBufferSize;
  end;

  IXxmFragment=interface
    ['{78786D00-0000-0004-C000-000000000004}']
    function GetProject: IXxmProject;
    function ClassNameEx: WideString;
    procedure Build(const Context:IXxmContext; const Caller:IXxmFragment;
      const Values: array of OleVariant;
      const Objects: array of TObject);
    function GetRelativePath: WideString;
    property Project:IXxmProject read GetProject;
    property RelativePath: WideString read GetRelativePath;
  end;

  IXxmPage=interface(IXxmFragment)
    ['{78786D00-0000-0005-C000-000000000005}']
  end;

  IXxmInclude=interface(IXxmFragment)
    ['{78786D00-0000-0006-C000-000000000006}']
  end;

  IXxmProjectEvents=interface
    ['{78786D00-0000-0013-C000-000000000013}']
    function HandleException(Context:IxxmContext;PageClass:WideString;Ex:Exception):boolean;
  end;

const
  IID_IXxmProject: TGUID = '{78786D00-0000-0002-C000-000000000002}';
  IID_IXxmContext: TGUID = '{78786D00-0000-0003-C000-000000000003}';
  IID_IXxmFragment: TGUID = '{78786D00-0000-0004-C000-000000000004}';
  IID_IXxmPage: TGUID = '{78786D00-0000-0005-C000-000000000005}';
  IID_IXxmInclude: TGUID = '{78786D00-0000-0006-C000-000000000006}';
  IID_IXxmParameter: TGUID = '{78786D00-0000-0007-C000-000000000007}';
  IID_IXxmParameterGet: TGUID = '{78786D00-0000-0008-C000-000000000008}';
  IID_IXxmParameterPost: TGUID = '{78786D00-0000-0009-C000-000000000009}';
  IID_IXxmParameterPostFile: TGUID = '{78786D00-0000-000A-C000-00000000000A}';
  IID_IXxmProjectEvents: TGUID ='{78786D00-0000-0013-C000-000000000013}';

const
  //TXxmContextString enumeration values
  csVersion           = -1000;
  csProjectName       = -1001;
  csURL               = -1002;
  csLocalURL          = -1003;
  csVerb              = -1004;
  csExtraInfo         = -1005;
  csUserAgent         = -1006;
  csQueryString       = -1007;
  csPostMimeType      = -1008;
  csReferer           = -1009;
  csLanguage          = -1010;
  csAcceptedMimeTypes = -1011;
  csRemoteAddress     = -1012;
  csRemoteHost        = -1013;
  csAuthUser          = -1014;
  csAuthPassword      = -1015;
  //
  cs_Max              = -1100;//used by GetParameter
  
type
  TXxmProject=class(TInterfacedObject, IXxmProject)//abstract
  private
    FProjectName: WideString;
    function GetProjectName: WideString;
  public
    constructor Create(AProjectName: WideString);
    destructor Destroy; override;
    function LoadPage(Context: IXxmContext; Address: WideString): IXxmFragment; virtual; abstract;
    function LoadFragment(Context: IXxmContext; Address, RelativeTo: WideString): IXxmFragment; virtual; abstract;
    procedure UnloadFragment(Fragment: IXxmFragment); virtual; abstract;
    property Name:WideString read GetProjectName;
  end;

  TXxmFragment=class(TInterfacedObject, IXxmFragment)//abstract
  private
    FProject: TXxmProject;
    FRelativePath: WideString;
    function GetProject: IXxmProject;
    procedure SetRelativePath(const Value: WideString);
  public
    constructor Create(AProject: TXxmProject);
    destructor Destroy; override;
    function ClassNameEx: WideString; virtual;
    procedure Build(const Context: IXxmContext; const Caller: IXxmFragment;
      const Values: array of OleVariant;
      const Objects: array of TObject); virtual; abstract;
    function GetRelativePath: WideString;
    property Project:IXxmProject read GetProject;
    property RelativePath: WideString read GetRelativePath write SetRelativePath;
  end;

  TXxmPage=class(TXxmFragment, IXxmPage)
  end;

  TXxmInclude=class(TXxmFragment, IXxmInclude)
  end;

function XxmVersion:TXxmVersion;
function HTMLEncode(Data:WideString):WideString; overload;
function HTMLEncode(Data:OleVariant):WideString; overload;
function URLEncode(Data:OleVariant):AnsiString;
function URLDecode(Data:AnsiString):WideString;

implementation

uses Variants;

{ Helper Functions }

function HTMLEncode(Data:OleVariant):WideString;
begin
  Result:=HTMLEncode(VarToWideStr(Data));
end;

function HTMLEncode(Data:WideString):WideString;
const
  GrowStep=$1000;
var
  i,di,ri,dl,rl:integer;
  x:WideString;
begin
  Result:=Data;
  di:=1;
  dl:=Length(Data);
  while (di<=dl) and not(char(Data[di]) in ['&','<','"','>',#13,#10]) do inc(di);
  if di<=dl then
   begin
    ri:=di;
    rl:=((dl div GrowStep)+1)*GrowStep;
    SetLength(Result,rl);
    while (di<=dl) do
     begin
      case Data[di] of
        '&':x:='&amp;';
        '<':x:='&lt;';
        '>':x:='&gt;';
        '"':x:='&quot;';
        #13,#10:
         begin
          if (di<dl) and (Data[di]=#13) and (Data[di+1]=#10) then inc(di);
          x:='<br />'#13#10;
         end;
        else x:=Data[di];
      end;
      if ri+Length(x)>rl then
       begin
        inc(rl,GrowStep);
        SetLength(Result,rl);
       end;
      for i:=1 to Length(x) do
       begin
        Result[ri]:=x[i];
        inc(ri);
       end;
      inc(di);
     end;
    SetLength(Result,ri-1);
   end;
end;

const
  Hex: array[0..15] of AnsiChar='0123456789ABCDEF';

function URLEncode(Data:OleVariant):AnsiString;
var
  s,t:AnsiString;
  p,q,l:integer;
begin
  if VarIsNull(Data) then Result:='' else
   begin
    s:=UTF8Encode(VarToWideStr(Data));
    q:=1;
    l:=Length(s)+$80;
    SetLength(t,l);
    for p:=1 to Length(s) do
     begin
      if q+4>l then
       begin
        inc(l,$80);
        SetLength(t,l);
       end;
      case char(s[p]) of
        #0..#31,'"','#','$','%','&','''','+','/','<','>','?','@','[','\',']','^','`','{','|','}','�':
         begin
          t[q]:='%';
          t[q+1]:=Hex[byte(s[p]) shr 4];
          t[q+2]:=Hex[byte(s[p]) and $F];
          inc(q,2);
         end;
        ' ':
          t[q]:='+';
        else
          t[q]:=s[p];
      end;
      inc(q);
     end;
    SetLength(t,q-1);
    Result:=t;
   end;
end;

function URLDecode(Data:AnsiString):WideString;
var
  t:AnsiString;
  p,q,l:integer;
  b:byte;
begin
  l:=Length(Data);
  SetLength(t,l);
  q:=1;
  p:=1;
  while (p<=l) do
   begin
    case char(Data[p]) of
      '+':t[q]:=' ';
      '%':
       begin
        inc(p);
        b:=0;
        case char(Data[p]) of
          '0'..'9':inc(b,byte(Data[p]) and $F);
          'A'..'F','a'..'f':inc(b,(byte(Data[p]) and $F)+9);
        end;
        inc(p);
        b:=b shl 4;
        case char(Data[p]) of
          '0'..'9':inc(b,byte(Data[p]) and $F);
          'A'..'F','a'..'f':inc(b,(byte(Data[p]) and $F)+9);
        end;
        t[q]:=AnsiChar(b);
       end
      else
        t[q]:=Data[p];
    end;
    inc(p);
    inc(q);
   end;
  SetLength(t,q-1);
  Result:=UTF8Decode(t);
  if not(q=0) and (Result='') then Result:=t;
end;

function XxmVersion: TXxmVersion;
var
  s:AnsiString;
begin
  s:=XxmRevision;
  Result.Major:=1;
  Result.Minor:=1;
  Result.Release:=0;
  Result.Build:=StrToInt(Copy(s,7,Length(s)-8));
end;

{ TXxpProject }

constructor TXxmProject.Create(AProjectName: WideString);
begin
  inherited Create;
  FProjectName:=AProjectName;
end;

destructor TXxmProject.Destroy;
begin
  inherited;
end;

function TXxmProject.GetProjectName: WideString;
begin
  Result:=FProjectName;
end;

{ TXxmFragment }

constructor TXxmFragment.Create(AProject: TXxmProject);
begin
  inherited Create;
  FProject:=AProject;
  FRelativePath:='';//set by xxmFReg, used for relative includes
end;

function TXxmFragment.GetProject: IXxmProject;
begin
  Result:=FProject;
end;

function TXxmFragment.ClassNameEx: WideString;
begin
  Result:=ClassName;
end;

destructor TXxmFragment.Destroy;
begin
  inherited;
end;

function TXxmFragment.GetRelativePath: WideString;
begin
  Result:=FRelativePath;
end;

procedure TXxmFragment.SetRelativePath(const Value: WideString);
begin
  FRelativePath:=Value;
end;

initialization
  IsMultiThread:=true;
end.
?  ,   ���X X M F R E G       0           unit xxmFReg;

interface

uses xxm, Classes;

{

  xxm Fragment Registry

This is a default fragment registry. You are free to change this one  or create a new one for your project.
The TxxmProject (xxmp.pas) calls GetClass with the page section of the URL, or can pre-process the URL.

  $Rev: 152 $ $Date: 2011-09-20 23:06:45 +0200 (di, 20 sep 2011) $

}

type
  TXxmFragmentClass=class of TXxmFragment;

  TXxmFragmentRegistry=class(TObject)
  private
    Registry:TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure RegisterClass(FName: AnsiString; FType: TXxmFragmentClass);
    function GetFragment(Project: TxxmProject;
      FName, RelativeTo: AnsiString): IxxmFragment;
  end;

var
  XxmFragmentRegistry:TXxmFragmentRegistry;

const
  XxmDefaultPage:AnsiString='default.xxm';

implementation

uses SysUtils;

{ TXxmFragmentRegistry }

constructor TXxmFragmentRegistry.Create;
begin
  inherited Create;
  Registry:=TStringList.Create;
  Registry.Sorted:=true;
  Registry.Duplicates:=dupIgnore;//dupError?setting?
  Registry.CaseSensitive:=false;//setting?
end;

destructor TXxmFragmentRegistry.Destroy;
begin
  //Registry.Clear;//?
  Registry.Free;
  inherited;
end;

procedure TXxmFragmentRegistry.RegisterClass(FName: AnsiString;
  FType: TXxmFragmentClass);
begin
  Registry.AddObject(FName,TObject(FType));
end;

function TXxmFragmentRegistry.GetFragment(Project: TxxmProject;
  FName, RelativeTo: AnsiString): IxxmFragment;
var
  i,j,l:integer;
  a,b:AnsiString;
  f:TxxmFragment;
begin
  l:=Length(FName);
  if (l<>0) and (FName[1]='/') then
   begin
    //absolute path
    a:=Copy(FName,2,l-1);
   end
  else
   begin
    //expand relative path
    i:=Length(RelativeTo);
    while (i>0) and (RelativeTo[i]<>'/') do dec(i);
    a:=Copy(RelativeTo,1,i);
    i:=1;
    while i<l do
     begin
      j:=i;
      while (i<l) and (FName[i]<>'/') do inc(i);
      inc(i);
      b:=Copy(FName,j,i-j);
      if b='../' then
       begin
        j:=Length(a)-1;
        while (j<>0) and (a[j]<>'/') do dec(j);
        SetLength(a,j);
       end
      else
        if b<>'./' then
          a:=a+b;
     end;
   end;
  //get fragment class
  i:=Registry.IndexOf(a);
  //folder? add index page name
  if i=-1 then
    if (FName='') or (FName[Length(FName)]='/') then 
	    i:=Registry.IndexOf(FName+XxmDefaultPage)
	  else
	    i:=Registry.IndexOf(FName+'/'+XxmDefaultPage);
  if i=-1 then
    Result:=nil
  else
   begin
    f:=TXxmFragmentClass(Registry.Objects[i]).Create(Project);
    //TODO: cache created instance, incease ref count
    f.RelativePath:=a;
    Result:=f;
   end;
end;

initialization
  XxmFragmentRegistry:=TXxmFragmentRegistry.Create;
finalization
  XxmFragmentRegistry.Free;

end.
 �  4   ���X X M S E S S I O N         0           unit xxmSession;

{

Use a copy of this unit in your xxm project to enable session data.

Extend the TXxmSession class definition with extra data to store with the session.

Add this unit to the uses clause of the project source file (xxmp.pas) and add this line to the LoadPage function of the project object:

function TXxmSomeProject.LoadPage(Context: IXxmContext; Address: WideString): IXxmFragment;
begin
  inherited;
>>>  SetSession(Context);  <<<
  Result:=LoadFragment(Address);
end;

}

interface

uses xxm, Contnrs;

type
  TXxmSession=class(TObject)
  private
    FSessionID:WideString;
  public

    //TODO: full properties?
    Authenticated:boolean;
    Name:AnsiString;

    constructor Create(Context: IXxmContext);
    property SessionID:WideString read FSessionID;
  end;

procedure SetSession(Context: IXxmContext);
procedure AbandonSession;

threadvar
  Session: TXxmSession;

implementation

uses SysUtils;

//TODO: something better than plain objectlist
var
  SessionStore:TObjectList;

procedure SetSession(Context: IXxmContext);
var
  i:integer;
  sid:WideString;
begin
  if SessionStore=nil then SessionStore:=TObjectList.Create(true);
  sid:=Context.SessionID;
  i:=0;
  while (i<SessionStore.Count) and not(TXxmSession(SessionStore[i]).SessionID=sid) do inc(i);
  //TODO: session expiry!!!
  if (i<SessionStore.Count) then Session:=TXxmSession(SessionStore[i]) else
   begin
    //as a security measure, disallow  new sessions on a first POST request
    if Context.ContextString(csVerb)='POST' then
      raise Exception.Create('Access denied.');
    Session:=TXxmSession.Create(Context);
    SessionStore.Add(Session);
   end;
end;

//call AbandonSession to release session data (e.g. logoff)
procedure AbandonSession;
begin
  SessionStore.Remove(Session);
  Session:=nil;
end;

{ TxxmSession }

constructor TXxmSession.Create(Context: IXxmContext);
begin
  inherited Create;
  FSessionID:=Context.SessionID;
  //TODO: initiate expiry

  //default values
  Authenticated:=false;
  Name:='';

end;

initialization
  SessionStore:=nil;
finalization
  FreeAndNil(SessionStore);

end.
R"  0   ���X X M S T R I N G       0           unit xxmString;

interface

uses
  SysUtils, Classes, ActiveX, xxm;

const
  XxmMaxIncludeDepth=64;//TODO: setting?

type
  TStringContext=class(TInterfacedObject, IXxmContext)
  private
    FContext:IXxmContext;
    FBuilding:IXxmFragment;
    FIncludeDepth,FIndex:integer;
    FResult:WideString;
    function GetResult:WideString;
    procedure WriteString(Value:WideString);
  protected
    function Connected: Boolean;
    function ContextString(cs: TXxmContextString): WideString;
    procedure DispositionAttach(FileName: WideString);
    function GetAutoEncoding: TXxmAutoEncoding;
    function GetContentType: WideString;
    function GetCookie(Name: WideString): WideString;
    function GetPage: IXxmFragment;
    function GetParameter(Key: OleVariant): IXxmParameter;
    function GetParameterCount: Integer;
    function GetSessionID: WideString;
    function GetURL: WideString;
    function PostData: IStream;
    procedure Redirect(RedirectURL: WideString; Relative: Boolean);
    procedure SetAutoEncoding(const Value: TXxmAutoEncoding);
    procedure SetContentType(const Value: WideString);
    procedure SetCookie(Name,Value:WideString); overload;
    procedure SetCookie(Name,Value:WideString; KeepSeconds:cardinal;
      Comment,Domain,Path:WideString; Secure,HttpOnly:boolean); overload;
    procedure SetStatus(Code: Integer; Text: WideString);
    function GetBufferSize: integer;
    procedure SetBufferSize(ABufferSize: integer);
    procedure Flush;
  public
    constructor Create(AContext: IXxmContext; ACaller: IXxmFragment);
    destructor Destroy; override;
    procedure Send(Data: OleVariant); overload;
    procedure Send(Value: integer); overload;
    procedure Send(Value: int64); overload;
    procedure Send(Value: cardinal); overload;
    procedure Send(const Values:array of OleVariant); overload;
    procedure SendFile(FilePath: WideString);
    procedure SendHTML(Data: OleVariant); overload;
    procedure SendHTML(const Values:array of OleVariant); overload;
    procedure SendStream(s: IStream);
    procedure Include(Address: WideString); overload;
    procedure Include(Address: WideString;
      const Values: array of OleVariant); overload;
    procedure Include(Address: WideString;
      const Values: array of OleVariant;
      const Objects: array of TObject); overload;
  	procedure Reset;

    property Result:WideString read GetResult;
    procedure SaveToFile(FileName:AnsiString);
  end;

  EXxmUnsupported=class(Exception);
  EXxmIncludeFragmentNotFound=class(Exception);
  EXxmIncludeStackFull=class(Exception);

implementation

uses
  Variants;

resourcestring
  SXxmIncludeFragmentNotFound='Include fragment not found "__"';
  SXxmIncludeStackFull='Maximum level of includes exceeded';

{ TStringContext }

constructor TStringContext.Create(AContext: IXxmContext; ACaller: IXxmFragment);
begin
  inherited Create;
  FContext:=AContext;
  FBuilding:=ACaller;
  FIncludeDepth:=0;
  Reset;
end;

destructor TStringContext.Destroy;
begin
  FContext:=nil;
  FBuilding:=nil;
  inherited;
end;

function TStringContext.GetResult: WideString;
begin
  Result:=Copy(FResult,1,FIndex);
end;

procedure TStringContext.WriteString(Value: WideString);
const
  GrowStep=$10000;
var
  l,x:integer;
begin
  l:=Length(FResult);
  x:=Length(Value);
  if FIndex+x>l then SetLength(FResult,l+((x div GrowStep)+1)*GrowStep);
  Move(Value[1],FResult[FIndex+1],x*2);
  inc(FIndex,x);
end;

procedure TStringContext.Reset;
begin
  FIndex:=0;
  FResult:='';
end;

procedure TStringContext.SaveToFile(FileName: AnsiString);
const
  Utf16ByteOrderMark=#$FF#$FE;
var
  f:TFileStream;
begin
  f:=TFileStream.Create(FileName,fmCreate);
  try
    f.Write(Utf16ByteOrderMark,2);
    f.Write(FResult[1],FIndex*2);
  finally
    f.Free;
  end;
end;

function TStringContext.Connected: Boolean;
begin
  Result:=FContext.Connected;
end;

function TStringContext.ContextString(cs: TXxmContextString): WideString;
begin
  Result:=FContext.ContextString(cs);
end;

function TStringContext.GetAutoEncoding: TXxmAutoEncoding;
begin
  Result:=FContext.AutoEncoding;
end;

function TStringContext.GetContentType: WideString;
begin
  Result:=FContext.ContentType;
end;

function TStringContext.GetCookie(Name: WideString): WideString;
begin
  Result:=FContext.Cookie[Name];
end;

function TStringContext.GetPage: IXxmFragment;
begin
  Result:=FContext.Page;
end;

function TStringContext.GetParameter(Key: OleVariant): IXxmParameter;
begin
  Result:=FContext.Parameter[Key];
end;

function TStringContext.GetParameterCount: Integer;
begin
  Result:=FContext.ParameterCount;
end;

function TStringContext.GetSessionID: WideString;
begin
  Result:=FContext.SessionID;
end;

function TStringContext.GetURL: WideString;
begin
  Result:=FContext.URL;
end;

function TStringContext.PostData: IStream;
begin
  Result:=FContext.PostData;
end;

procedure TStringContext.DispositionAttach(FileName: WideString);
begin
  raise EXxmUnsupported.Create('StringContext doesn''t support DispositionAttach');
end;

procedure TStringContext.Redirect(RedirectURL: WideString;
  Relative: Boolean);
begin
  raise EXxmUnsupported.Create('StringContext doesn''t support Redirect');
end;

procedure TStringContext.SetAutoEncoding(const Value: TXxmAutoEncoding);
begin
  raise EXxmUnsupported.Create('StringContext doesn''t support AutoEncoding');
end;

procedure TStringContext.SetContentType(const Value: WideString);
begin
  raise EXxmUnsupported.Create('StringContext doesn''t support ContentType');
end;

procedure TStringContext.SetStatus(Code: Integer; Text: WideString);
begin
  raise EXxmUnsupported.Create('StringContext doesn''t support Status');
end;

procedure TStringContext.Include(Address: WideString);
begin
  Include(Address, [], []);
end;

procedure TStringContext.Include(Address: WideString;
  const Values: array of OleVariant);
begin
  Include(Address, Values, []);
end;

procedure TStringContext.Include(Address: WideString;
  const Values: array of OleVariant;
  const Objects: array of TObject);
var
  p:IXxmProject;
  f,fb:IXxmFragment;
begin
  if FIncludeDepth=XxmMaxIncludeDepth then
    raise EXxmIncludeStackFull.Create(SXxmIncludeStackFull);
  p:=FContext.Page.Project;
  try
    //TODO: relative path to FContext.ContextString(clLocalURL)
    f:=p.LoadFragment(FContext,Address,FBuilding.RelativePath);
    if f=nil then
      raise EXxmIncludeFragmentNotFound.Create(StringReplace(
        SXxmIncludeFragmentNotFound,'__',Address,[]));
    fb:=FBuilding;
    FBuilding:=f;
    inc(FIncludeDepth);
    try
      //TODO: catch exceptions?
      f.Build(Self,fb,Values,Objects);
    finally
      dec(FIncludeDepth);
      FBuilding:=fb;
      fb:=nil;
      p.UnloadFragment(f);
      f:=nil;
    end;
  finally
    p:=nil;
  end;
end;

procedure TStringContext.Send(Data: OleVariant);
begin
  WriteString(HTMLEncode(Data));
end;

procedure TStringContext.SendHTML(Data: OleVariant);
begin
  WriteString(VarToStr(Data));
end;

procedure TStringContext.SendFile(FilePath: WideString);
begin
  raise EXxmUnsupported.Create('StringContext doesn''t support SendFile');
end;

procedure TStringContext.SendStream(s: IStream);
begin
  raise EXxmUnsupported.Create('StringContext doesn''t support SendStream');
end;

procedure TStringContext.SetCookie(Name, Value: WideString);
begin
  FContext.SetCookie(Name, Value);
end;

procedure TStringContext.SetCookie(Name, Value: WideString;
  KeepSeconds: cardinal; Comment, Domain, Path: WideString; Secure,
  HttpOnly: boolean);
begin
  FContext.SetCookie(Name, Value, KeepSeconds, Comment, Domain, Path,
    Secure, HttpOnly);
end;

procedure TStringContext.Send(Value: int64);
begin
  WriteString(IntToStr(Value));
end;

procedure TStringContext.Send(Value: integer);
begin
  WriteString(IntToStr(Value));
end;

procedure TStringContext.Send(const Values: array of OleVariant);
var
  i:integer;
begin
  for i:=0 to Length(Values)-1 do
    WriteString(HTMLEncode(Values[i]));
end;

procedure TStringContext.Send(Value: cardinal);
begin
  WriteString(IntToStr(Value));
end;

procedure TStringContext.SendHTML(const Values: array of OleVariant);
var
  i:integer;
begin
  for i:=0 to Length(Values)-1 do
    WriteString(VarToStr(Values[i]));
end;

procedure TStringContext.Flush;
begin
  //ignore
end;

function TStringContext.GetBufferSize: integer;
begin
  //ignore
  Result:=-1;
end;

procedure TStringContext.SetBufferSize(ABufferSize: integer);
begin
  //ignore
end;

end.
  �  8   ���W E B _ D P R _ P R O T O       0           library [[ProjectName]];

{
  --- ATTENTION! ---

  This file is re-constructed when the xxm source file changes.
  Any changes to this file will be overwritten.
  If you require changes to this file that can not be defined
  in the xxm source file, set up an alternate prototype-file.

  Prototype-file used:
  "[[ProtoFile]]"
  $Rev: 125 $ $Date: 2011-04-30 01:14:06 +0200 (za, 30 apr 2011) $
}

[[ProjectSwitches]]
uses
	[[@Include]][[IncludeUnit]] in '..\[[IncludePath]][[IncludeUnit]].pas',
	[[@]][[@Fragment]][[FragmentUnit]] in '[[FragmentPath]][[FragmentUnit]].pas', {[[FragmentAddress]]}
	[[@]][[UsesClause]]
	xxmp in '..\xxmp.pas';

{$E xxl}
[[ProjectHeader]]
exports
	XxmProjectLoad;
[[ProjectBody]]
end.
	  <   ���X X M P _ P A S _ P R O T O         0           unit xxmp;

{
  xxm Project

This is a default xxm Project class inheriting from TXxmProject. You are free to change this one for your project.
Use LoadPage to process URL's as a requests is about to start.
(Be carefull with sending content from here though.)
It is advised to link each request to a session here, if you want session management.
(See  an example xxmSession.pas in the public folder.)
Use LoadFragment to handle calls made to Context.Include.

  $Rev: 102 $ $Date: 2010-09-15 14:42:45 +0200 (wo, 15 sep 2010) $
}

interface

uses xxm;

type
  TXxm[[ProjectName]]=class(TXxmProject)
  public
    function LoadPage(Context: IXxmContext; Address: WideString): IXxmFragment; override;
    function LoadFragment(Context: IXxmContext; Address, RelativeTo: WideString): IXxmFragment; override;
    procedure UnloadFragment(Fragment: IXxmFragment); override;
  end;

function XxmProjectLoad(AProjectName:WideString): IXxmProject; stdcall;

implementation

uses xxmFReg;

function XxmProjectLoad(AProjectName:WideString): IXxmProject;
begin
  Result:=TXxm[[ProjectName]].Create(AProjectName);
end;

{ TXxm[[ProjectName]] }

function TXxm[[ProjectName]].LoadPage(Context: IXxmContext; Address: WideString): IXxmFragment;
begin
  inherited;
  //TODO: link session to request
  Result:=XxmFragmentRegistry.GetFragment(Self,Address,'');
end;

function TXxm[[ProjectName]].LoadFragment(Context: IXxmContext; Address, RelativeTo: WideString): IXxmFragment;
begin
  Result:=XxmFragmentRegistry.GetFragment(Self,Address,RelativeTo);
end;

procedure TXxm[[ProjectName]].UnloadFragment(Fragment: IXxmFragment);
begin
  inherited;
  //TODO: set cache TTL, decrease ref count
  //Fragment.Free;
end;

initialization
  IsMultiThread:=true;
end.
   j  8   ���X X M _ P A S _ P R O T O       0           unit [[FragmentUnit]];

{
  --- ATTENTION! ---

  This file is re-constructed when the xxm source file changes.
  Any changes to this file will be overwritten.
  If you require changes to this file that can not be defined
  in the xxm source file, set up an alternate prototype-file.

  Prototype-file used:
  "[[ProtoFile]]"
  $Rev: 102 $ $Date: 2010-09-15 14:42:45 +0200 (wo, 15 sep 2010) $
}

interface

uses xxm;

type
  [[FragmentID]]=class(TXxmPage)
  public
    procedure Build(const Context: IXxmContext; const Caller: IXxmFragment;
      const Values: array of OleVariant; const Objects: array of TObject); override;
  end;

implementation

uses 
  SysUtils, 
[[UsesClause]]
  xxmFReg;
  
[[FragmentDefinitions]]
{ [[FragmentID]] }

procedure [[FragmentID]].Build(const Context: IXxmContext; const Caller: IXxmFragment; 
      const Values: array of OleVariant; const Objects: array of TObject);
[[FragmentHeader]]
begin
  inherited;
[[FragmentBody]]
end;

initialization
  XxmFragmentRegistry.RegisterClass('[[FragmentAddress]]',[[FragmentID]]);
[[FragmentFooter]]

end.
  l  <   ���X X M I _ P A S _ P R O T O         0           unit [[FragmentUnit]];

{
  --- ATTENTION! ---

  This file is re-constructed when the xxm source file changes.
  Any changes to this file will be overwritten.
  If you require changes to this file that can not be defined
  in the xxm source file, set up an alternate prototype-file.

  Prototype-file used:
  "[[ProtoFile]]"
  $Rev: 102 $ $Date: 2010-09-15 14:42:45 +0200 (wo, 15 sep 2010) $
}

interface

uses xxm;

type
  [[FragmentID]]=class(TXxmInclude)
  public
    procedure Build(const Context: IXxmContext; const Caller: IXxmFragment;
      const Values: array of OleVariant; const Objects: array of TObject); override;
  end;

implementation

uses 
  SysUtils, 
[[UsesClause]]
  xxmFReg;
  
[[FragmentDefinitions]]
{ [[FragmentID]] }

procedure [[FragmentID]].Build(const Context: IXxmContext; const Caller: IXxmFragment;
      const Values: array of OleVariant; const Objects: array of TObject);
[[FragmentHeader]]
begin
  inherited;
[[FragmentBody]]
end;

initialization
  XxmFragmentRegistry.RegisterClass('[[FragmentAddress]]',[[FragmentID]]);
[[FragmentFooter]]

end.
