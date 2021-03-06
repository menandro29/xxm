unit xxmAhttpdContext;

interface

uses SysUtils, Classes, ActiveX, HTTPD2, xxm, xxmContext,
  xxmHeaders, xxmParams, xxmPReg, xxmPRegXml, xxmParUtils;

type
  TxxmAhttpdContext=class(TXxmGeneralContext, IxxmHttpHeaders)
  private
    rq: Prequest_rec;
    FConnected: boolean;
    FRedirectPrefix, FSessionID: AnsiString;
    FCookieParsed: boolean;
    FCookie: AnsiString;
    FCookieIdx: TParamIndexes;
    FBuffer: TMemoryStream;
  protected
    procedure SendStream(s:IStream); override;
    function GetSessionID:WideString; override;
    procedure DispositionAttach(FileName: WideString); override;
    function ContextString(cs:TXxmContextString):WideString; override;
    function Connected:boolean; override;
    procedure Redirect(RedirectURL:WideString; Relative:boolean); override;
    function GetCookie(Name:WideString):WideString; override;
    procedure SetBufferSize(ABufferSize: Integer); override;
    procedure Flush; override;
    procedure SendHeader; override;
    procedure SendRaw(const Data: WideString); override;
    function GetProjectEntry:TXxmProjectEntry; override;
    function GetRequestHeader(const Name: WideString): WideString; override;
    procedure AddResponseHeader(const Name, Value: WideString); override;
    procedure SetStatus(Code:integer;Text:WideString); override;
    //IxxmHttpHeaders
    function GetRequestHeaders:IxxmDictionaryEx;
    function GetResponseHeaders:IxxmDictionaryEx;
  public
    constructor Create(r:Prequest_rec);
    destructor Destroy; override;
    procedure Execute;
  end;

  EXxmRWriteFailed=class(Exception);
  EXxmAutoBuildFailed=class(Exception);
  EXxmPageRedirected=class(Exception);

implementation

uses Windows, Variants, ComObj, xxmCommonUtils, xxmAhttpdClientStream, xxmAhttpdPars;

resourcestring
  SXxmRWriteFailed='ap_rwrite failed';

{ TxxmAhttpdContext }

constructor TxxmAhttpdContext.Create(r: Prequest_rec);
begin
  inherited Create(ap_construct_url(r.pool,r.unparsed_uri,r));
  rq:=r;
  FConnected:=true;
  FRedirectPrefix:='';//see Execute
  FCookieParsed:=false;
  FSessionID:='';//see GetSessionID
  FBuffer:=nil;
end;

destructor TxxmAhttpdContext.Destroy;
begin
  rq:=nil;
  if FBuffer<>nil then FBuffer.Free;
  inherited;
end;

procedure TxxmAhttpdContext.Execute;
var
  x,y:AnsiString;
  i:integer;
begin
  try
    AddResponseHeader('X-Powered-By',SelfVersion);
    if XxmProjectCache=nil then XxmProjectCache:=TXxmProjectCacheXml.Create;

    //parse url
    x:=rq.uri;
    y:=rq.path_info;

    i:=2;
    if XxmProjectCache.ProjectFromURI(Self,x,i,FProjectName,FFragmentName) then
      FRedirectPrefix:=FRedirectPrefix+'/'+FProjectName
    else
      FRedirectPrefix:=copy(x,1,Length(x)-Length(y));//?

    x:=apr_table_get(rq.headers_in,'Content-Length');
    if x<>'' then FPostData:=TxxmAhttpdClientStream.Create(rq);

    BuildPage;

  except
    on EXxmPageRedirected do Flush;
    on EXxmAutoBuildFailed do ;//assert output done
    on e:Exception do
      if not HandleException(e) then
       begin
        rq.status:=500;
        rq.status_line:=apr_pstrdup(rq.pool,'500 Internal Server Error');
        try
          if FPostData=nil then x:='none' else x:=IntToStr(FPostData.Size)+' bytes';
        except
          x:='unknown';
        end;
        SendError('error',[
          'ERRORCLASS',e.ClassName,
          'ERROR',HTMLEncode(e.Message),
          'CLASS',FPageClass,
          'URL',HTMLEncode(rq.unparsed_uri),
          'POSTDATA',x,
          'QUERYSTRING',HTMLEncode(rq.args),
          'VERSION',SelfVersion
        ]);
       end;
  end;
end;

function TxxmAhttpdContext.GetProjectEntry: TXxmProjectEntry;
begin
  Result:=XxmProjectCache.GetProject(FProjectName);
end;

function TxxmAhttpdContext.Connected: boolean;
begin
  //Result:=not(rq.connection.aborted);
  Result:=((rq.connection.flags1 and 1)=0);
end;

function TxxmAhttpdContext.ContextString(
  cs: TXxmContextString): WideString;
begin
  case cs of
    csVersion:Result:=SelfVersion+', '+ap_get_server_version;
    csExtraInfo:Result:='';//TODO?
    csVerb:Result:=rq.method;
    csQueryString:Result:=rq.args;
    csUserAgent:Result:=apr_table_get(rq.headers_in,'User-Agent');
    csAcceptedMimeTypes:Result:=apr_table_get(rq.headers_in,'Accept');
    csPostMimeType:Result:=apr_table_get(rq.headers_in,'Content-Type');
    csURL:Result:=GetURL;
    csReferer:Result:=apr_table_get(rq.headers_in,'Referer');
    csLanguage:Result:=apr_table_get(rq.headers_in,'Accept-Language');
    csRemoteAddress:Result:=rq.main.connection.remote_ip;
    csRemoteHost:Result:=rq.main.connection.remote_host;
    csAuthUser:Result:=apr_table_get(rq.headers_in,'Auth-User');
    csAuthPassword:Result:=apr_table_get(rq.headers_in,'Auth-Password');
    csProjectName:Result:=FProjectName;
    csLocalURL:Result:=FFragmentName;
  end;
end;

procedure TxxmAhttpdContext.DispositionAttach(FileName: WideString);
begin
  if FileName='' then
    AddResponseHeader('Content-Disposition','attachment')
  else
    AddResponseHeader('Content-Disposition','attachment; filename="'+FileName+'"');
end;

function TxxmAhttpdContext.GetCookie(Name: WideString): WideString;
begin
  if not(FCookieParsed) then
   begin
    FCookie:=apr_table_get(rq.headers_in,'Cookie');
    SplitHeaderValue(FCookie,0,Length(FCookie),FCookieIdx);
    FCookieParsed:=true;
   end;
  Result:=GetParamValue(FCookie,FCookieIdx,Name);
end;

function TxxmAhttpdContext.GetRequestHeaders: IxxmDictionaryEx;
begin
  //TODO: check freed by ref counting?
  Result:=TxxmAhttpdTable.Create(rq.pool,rq.headers_in);
end;

function TxxmAhttpdContext.GetResponseHeaders: IxxmDictionaryEx;
begin
  //TODO: check freed by ref counting?
  Result:=TxxmAhttpdTable.Create(rq.pool,rq.headers_out);
end;

function TxxmAhttpdContext.GetSessionID: WideString;
const
  SessionCookie='xxmSessionID';
begin
  if FSessionID='' then
   begin
    FSessionID:=GetCookie(SessionCookie);
    if FSessionID='' then
     begin
      FSessionID:=Copy(CreateClassID,2,32);
      SetCookie(SessionCookie,FSessionID);//expiry?
     end;
   end;
  Result:=FSessionID;
end;

procedure TxxmAhttpdContext.Redirect(RedirectURL: WideString;
  Relative: boolean);
var
  NewURL:WideString;
begin
  //HeaderOK;//see SetStatus
  SetStatus(301,'Moved Permanently');
  NewURL:=RedirectURL;
  if Relative and (NewURL<>'') and (NewURL[1]='/') then NewURL:=FRedirectPrefix+NewURL;
  AddResponseHeader('Location',NewURL);
  //TODO: move this to execute's except?
  SendRaw('<a href="'+HTMLEncode(NewURL)+'">'+HTMLEncode(NewURL)+'</a>'#13#10);
  if FBufferSize<>0 then Flush;
  raise EXxmPageRedirected.Create(RedirectURL);
end;

procedure TxxmAhttpdContext.SendRaw(const Data: WideString);
var
  s:AnsiString;
  l:integer;
  p:pointer;
begin
  if Data<>'' then
   begin
    if CheckSendStart then
      case FAutoEncoding of
        aeUtf8:
         begin
          s:=Utf8ByteOrderMark;
          if FBuffer<>nil then
            FBuffer.Write(s[1],3)
          else
            if ap_rwrite(s[1],3,rq)<>3 then raise EXxmRWriteFailed.Create(SXxmRWriteFailed);
         end;
        aeUtf16:
         begin
          s:=Utf16ByteOrderMark;
          if FBuffer<>nil then
            FBuffer.Write(s[1],2)
          else
            if ap_rwrite(s[1],2,rq)<>2 then raise EXxmRWriteFailed.Create(SXxmRWriteFailed);
         end;
      end;
    case FAutoEncoding of
      aeUtf16:
       begin
        l:=Length(Data)*2;
        if FBuffer<>nil then
          FBuffer.Write(Data[1],l)
        else
         begin
          p:=@Data[1];
          if ap_rwrite(p^,l,rq)<>l then raise EXxmRWriteFailed.Create(SXxmRWriteFailed);
         end;
       end;
      aeUtf8:
       begin
        s:=UTF8Encode(Data);
        l:=Length(s);
        if FBuffer<>nil then
          FBuffer.Write(s[1],l)
        else
          if ap_rwrite(s[1],l,rq)<>l then raise EXxmRWriteFailed.Create(SXxmRWriteFailed);
       end;
      else
       begin
        s:=Data;
        l:=Length(s);
        if FBuffer<>nil then
          FBuffer.Write(s[1],l)
        else
          if ap_rwrite(s[1],l,rq)<>l then raise EXxmRWriteFailed.Create(SXxmRWriteFailed);
       end;
    end;
    if FBuffer=nil then
      ap_rflush(rq)//? only every x bytes?
    else
      if FBuffer.Position>=FBufferSize then Flush;
   end;
end;

procedure TxxmAhttpdContext.SendStream(s: IStream);
const
  dSize=$10000;
var
  d:array[0..dSize-1] of byte;
  l:integer;
begin
  {
  if not(FHeaderSent) then
   begin
    //TODO: (Apache does 'Transfer-Encoding: chunked' for us!)
    //'Content-Length':=IntToStr(s.Size);
    //'Accept-Ranges':='bytes';
   end;
  }
  CheckSendStart;
  if FBuffer<>nil then Flush;
  repeat
    l:=dSize;
    OleCheck(s.Read(@d[0],dSize,@l));
    if l<>0 then
     begin
      if ap_rwrite(d[0],l,rq)<>l then
        raise EXxmRWriteFailed.Create(SXxmRWriteFailed);
      ap_rflush(rq);//?
     end;
  until l=0;
end;

procedure TxxmAhttpdContext.SetStatus(Code: integer; Text: WideString);
begin
  inherited;
  rq.status:=Code;
  rq.status_line:=apr_pstrdup(rq.pool,
    PAnsiChar(IntToStr(Code)+' '+AnsiString(Text)));
end;

procedure TxxmAhttpdContext.SendHeader;
begin
  //rq.status_line Sent by first ap_rwrite?
  rq.content_type:=apr_pstrdup(rq.pool,PAnsiChar(AnsiString(FContentType)));
  case FAutoEncoding of
    aeUtf8:   rq.content_encoding:=apr_pstrdup(rq.pool,PAnsiChar('utf-8'));
    aeUtf16:  rq.content_encoding:=apr_pstrdup(rq.pool,PAnsiChar('utf-16'));
    aeIso8859:rq.content_encoding:=apr_pstrdup(rq.pool,PAnsiChar('iso-8859-15'));
    else      ;//rq.content_encoding:=apr_pstrdup(rq.pool,PAnsiChar('?
  end;
  //rq.connection.keepalive?//TODO

  //clear buffer just in case
  if FBuffer<>nil then FBuffer.Position:=0;
end;

function TxxmAhttpdContext.GetRequestHeader(const Name: WideString): WideString;
begin
  Result:=WideString(apr_table_get(rq.headers_in,PAnsiChar(AnsiString(Name))));
end;

procedure TxxmAhttpdContext.AddResponseHeader(const Name, Value: WideString);
begin
  HeaderCheckName(Name);
  HeaderCheckValue(Value);
  if SettingCookie then
   begin
    SettingCookie:=false;
    apr_table_add(rq.headers_out,
      apr_pstrdup(rq.pool,PAnsiChar(AnsiString(Name))),
      apr_pstrdup(rq.pool,PAnsiChar(AnsiString(Value))));
   end
  else
    apr_table_set(rq.headers_out,
      apr_pstrdup(rq.pool,PAnsiChar(AnsiString(Name))),
      apr_pstrdup(rq.pool,PAnsiChar(AnsiString(Value))));
end;

procedure TxxmAhttpdContext.Flush;
var
  i:int64;
begin
  if FBuffer<>nil then
   begin
    i:=FBuffer.Position;
    if i<>0 then
     begin
      if ap_rwrite(FBuffer.Memory^,i,rq)<>i then raise EXxmRWriteFailed.Create(SXxmRWriteFailed);
      FBuffer.Position:=0;
      ap_rflush(rq)//?
     end;
   end;
end;

procedure TxxmAhttpdContext.SetBufferSize(ABufferSize: Integer);
begin
  inherited;
  if ABufferSize=0 then
   begin
    if FBuffer<>nil then
     begin
      //assert Flush called by inherited
      FBuffer.Free;
      FBuffer:=nil;
     end;
   end
  else
   begin
    //TODO: keep in a pool after use, take from pool here
    if FBuffer=nil then FBuffer:=TMemoryStream.Create;//TODO: tmp file when large buffer
    if FBuffer.Position>ABufferSize then Flush;
    FBuffer.Size:=ABufferSize;
   end;
end;

end.
