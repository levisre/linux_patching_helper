{
Linux Patching Helper
Main Project code
Created by Levis Nickaster
Email: levintaeyeon@live.com
My personal blog: http://ltops9.wordpress.com
}

program patching_helper;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, lazcontrols, runtimetypeinfocontrols, mainform;

{$R *.res}

begin
  Application.Title:='Linux Patching Helper';
  RequireDerivedFormResource := True;
  Application.Initialize;
  Application.CreateForm(TPatcherForm, PatcherForm);
  Application.Run;
  PatcherForm.bval := false;;
end.

