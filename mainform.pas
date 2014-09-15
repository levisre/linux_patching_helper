{
Linux Patching Helper
MainForm Code
Created by Levis Nickaster
Email: levintaeyeon@live.com
My personal blog: http://ltops9.wordpress.com
}
unit mainform;

{$mode objfpc}{$H+}

interface

uses

  Classes, SysUtils, FileUtil, SynEditTypes, SynMemo, Forms, Controls, Graphics,
  Dialogs, StdCtrls, process, Themes, ExtCtrls;
type
  { TPatcherForm }
  TPatcherForm = class(TForm)
    aboutbtn: TButton;
    Button1: TButton;
    headerbtn: TButton;
    SaveDialog1: TSaveDialog;
    savefilebtn: TButton;
    cleartext: TButton;
    Label5: TLabel;
    isIntel: TRadioButton;
    isatt: TRadioButton;
    Label6: TLabel;
    statuslbl: TLabel;
    patternbox: TEdit;
    findoffsetbtn: TButton;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    searchbtn: TButton;
    entrybox: TEdit;
    getinfo: TButton;
    stringdump: TButton;
    datadump: TButton;
    codedump: TButton;
    filedir: TEdit;
    Label1: TLabel;
    openfiledlg: TOpenDialog;
    openfilebtn: TButton;
    outputMemo: TSynMemo;
    Timer1: TTimer;
    procedure aboutbtnClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure cleartextClick(Sender: TObject);
    procedure codedumpClick(Sender: TObject);
    procedure datadumpClick(Sender: TObject);
    procedure findoffsetbtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure getinfoClick(Sender: TObject);
    procedure headerbtnClick(Sender: TObject);
    procedure isattChange(Sender: TObject);
    procedure isIntelChange(Sender: TObject);
    procedure openfilebtnClick(Sender: TObject);
    procedure savefilebtnClick(Sender: TObject);
    procedure searchbtnClick(Sender: TObject);
    procedure stringdumpClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
  private
    { private declarations }
  public
    bval: boolean;
    function ExecCommand: boolean;
    { public declarations }
  end;
const READ_BYTES = 2048;
  var
  PatcherForm: TPatcherForm;
  ExecCMD : String;
  tmppath: string;
implementation

{$R *.lfm}

{ TPatcherForm }

function RemoveSpace(s:string):string;
begin
     result := StringReplace(s, ' ', '', [rfReplaceAll]);
end;

function HexToInt(input:string): string;
  var i: integer;
    tmpstr :string;
    begin
      tmpstr := RemoveSpace(input);
      i:=1;
      Result:='';
      try
        while (i<Length(tmpstr)) do
        begin
          Result := Result + chr(StrToInt('$'+tmpstr[i]+tmpstr[i+1]));
          i:=i+2;
        end;
        except
          ShowMessage('Error in pattern format');
      end;
    end;

function ReadLine( var Stream: TFileStream): string;
var
  ch: AnsiChar;
begin
ch := #0;
result := '';
while (Stream.Read( ch, 1) = 1) and (ch <> #13) do
  begin
 result:= result+ch;
  end;
if ch = #13 then
  begin
  if (Stream.Read( ch, 1) = 1) and (ch <> #10) then
    Stream.Seek(-1, soCurrent) // unread it if not LF character.
  end
end;

function TPatcherForm.ExecCommand: boolean;
var
MemStream : TMemoryStream;
Process: TProcess;
Numbytes: Longint;
BytesRead: Longint;
begin
    Result:= false;
    MemStream := TMemoryStream.create;
    BytesRead:=0;
    Process := TProcess.Create(nil);
    Process.CommandLine := ExecCMD;
    Process.Options := [poUsePipes];
    Process.Execute;
    try
       While True do
       begin
               MemStream.SetSize(BytesRead + READ_BYTES);
               Numbytes:=Process.Output.Read((MemStream.Memory + BytesRead)^, READ_BYTES);
               if Numbytes > 0 then
               begin
                    Inc(BytesRead,Numbytes);
               end else Break;
       end;
       MemStream.SetSize(BytesRead);
       outputMemo.Lines.LoadFromStream(MemStream);
       outputMemo.SetFocus;
    finally
       MemStream.Free;
       Process.Free;
    end;
    Timer1.Enabled:=false;
    result:=true;
end;

procedure TPatcherForm.FormCreate(Sender: TObject);
begin
  tmppath:=GetTempDir + '/ph.dmp';
  if not FileExists('/usr/bin/objdump') then
  begin
   ShowMessage('objdump not found in /usr/bin! You MUST install binutils first');
   Application.Terminate;
  end;
end;

procedure TPatcherForm.datadumpClick(Sender: TObject);
begin
  ExecCMD := 'objdump -s ' + filedir.Text;
  Timer1.Enabled:=true;
  statuslbl.Caption:='Data Dump OK! Now Try to find the RVA by searching!';
end;

procedure TPatcherForm.findoffsetbtnClick(Sender: TObject);
var inpfile: TMemoryStream;
strstream: TStringStream;
inpattern: string;
offset: integer;
begin
     try
        inpattern := HexToInt(patternbox.Text);
        inpfile:=TMemoryStream.Create;
        inpfile.LoadFromFile(filedir.Text);
        strstream:=TStringStream.Create('');
        strstream.CopyFrom(inpfile,inpfile.Size);
        offset := Pos(inpattern,strstream.DataString);
        if offset>0 then
        begin
             outputMemo.Lines.Add('Found pattern at offset '+ IntToHex(offset-1,8));
             statuslbl.Caption:='Found pattern at offset '+ IntToHex(offset-1,8);
             outputMemo.Lines.add('Now use a hex editor and go to this offset. Good luck!');
             outputMemo.SelStart:=Length(outputMemo.Text);
             outputMemo.SetFocus;
        end;
        strstream.Destroy;
        inpfile.Destroy;
     except on e: Exception do
            outputMemo.Lines.Append(e.Message);
     end;
end;


procedure TPatcherForm.codedumpClick(Sender: TObject);
begin
  if isintel.Checked then
  ExecCMD := 'objdump -d -M intel -j.text ' + filedir.Text
  else
  ExecCMD := 'objdump -d -j.text ' + filedir.Text;
  Timer1.Enabled:=true;
  statuslbl.Caption:='Code dumping done! Let''s start searching!';

end;

procedure TPatcherForm.cleartextClick(Sender: TObject);
begin
  entrybox.Clear;
end;

procedure TPatcherForm.aboutbtnClick(Sender: TObject);
begin
  MessageDlg('About','Linux Patching Helper 0.02 beta'+sLineBreak + 'Created by Levis Nickaster' + sLineBreak
  + 'http://team-rept.com' + sLineBreak + 'http://ltops9.wordpress.com',
  mtInformation, [mbOK],0);
end;

procedure TPatcherForm.Button1Click(Sender: TObject);
begin
    outputMemo.CaretX:=outputMemo.CaretX-1;
    outputMemo.SearchReplace(entrybox.Text,entrybox.Text,[ssoBackwards]);
    statuslbl.Caption:='String Found at line ' + IntToStr(outputMemo.CaretY);
end;

procedure TPatcherForm.getinfoClick(Sender: TObject);
begin
  ExecCMD:= 'file ' + filedir.Text;
  Timer1.Enabled:=true;
  statuslbl.Caption:='Command Executed OK!';
end;

procedure TPatcherForm.headerbtnClick(Sender: TObject);
begin
  ExecCMD:= 'objdump -x ' + filedir.Text;
  Timer1.Enabled:=true;
  statuslbl.Caption:='Command executed OK!';
end;

procedure TPatcherForm.isattChange(Sender: TObject);
begin
  if isatt.Checked then isIntel.Checked:=false;
end;

procedure TPatcherForm.isIntelChange(Sender: TObject);
begin
  if isintel.Checked then isatt.Checked:=false;
end;

procedure TPatcherForm.openfilebtnClick(Sender: TObject);
begin
  if(openfiledlg.Execute) then
  filedir.Text := openfiledlg.FileName;
end;

procedure TPatcherForm.savefilebtnClick(Sender: TObject);
begin
  if(SaveDialog1.Execute) then
  begin
       outputMemo.Lines.SaveToFile(SaveDialog1.FileName);
       statuslbl.Caption:='Data saved to:' + SaveDialog1.FileName;
  end;
end;

procedure TPatcherForm.searchbtnClick(Sender: TObject);
begin
  outputMemo.SetFocus;
  outputMemo.SearchReplace(entrybox.text,entrybox.Text,[ssoFindContinue]);
  statuslbl.Caption:='String Found at line ' + IntToStr(outputMemo.CaretY);
end;

procedure TPatcherForm.stringdumpClick(Sender: TObject);
begin
  ExecCMD:='strings ' + filedir.Text;
  Timer1.Enabled:=true;
  statuslbl.Caption:= 'String dump OK! Let''s start searching!';
end;

procedure TPatcherForm.Timer1Timer(Sender: TObject);
begin
   ExecCommand;
end;

end.

