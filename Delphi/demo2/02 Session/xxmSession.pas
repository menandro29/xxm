unit xxmSession;

{

Use a copy of this unit in your xxm project to enable session data.

Extend the TXxmSession class definition with extra data to store with the session.

Add this unit to the uses clause of the project source file (xxmp.pas) and add this line to the LoadPage function of the project object:

function TXxmSomeProject.LoadPage(Context: IXxmContext; Address: WideString): IXxmFragment;
begin
  inherited;
>>>  SetSession(Context.SessionID);  <<<
  Result:=LoadFragment(Address);
end;

}

interface

uses Contnrs;

type
  TXxmSession=class(TObject)
  private
    FSessionID:WideString;
  public

    //TODO: full properties?
    Authenticated:boolean;
    Name:string;

    constructor Create(SessionID:WideString);
    property SessionID:WideString read FSessionID;
  end;

procedure SetSession(SessionID: WideString);
procedure AbandonSession;

threadvar
  Session: TXxmSession;

implementation

uses SysUtils;

//TODO: something better than plain objectlist
var
  SessionStore:TObjectList;

procedure SetSession(SessionID: WideString);
var
  i:integer;
begin
  if SessionStore=nil then SessionStore:=TObjectList.Create(true);
  i:=0;
  while (i<SessionStore.Count) and not(TXxmSession(SessionStore[i]).SessionID=SessionID) do inc(i);
  //TODO: session expiry!!!
  if (i<SessionStore.Count) then Session:=TXxmSession(SessionStore[i]) else
   begin
    Session:=TXxmSession.Create(SessionID);
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

constructor TXxmSession.Create(SessionID: WideString);
begin
  inherited Create;
  FSessionID:=SessionID;
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