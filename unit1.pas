unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Menus, ComCtrls,
  DBGrids, ExtCtrls; //, PairSplitter;

type

  { TForm1 }

  TForm1 = class(TForm)
    DBGrid1: TDBGrid;
    DBGrid2: TDBGrid;
    MainMenu1: TMainMenu;
    MenuItem1: TMenuItem;
    miFileImportXSPF: TMenuItem;
    miFileExit: TMenuItem;
    PanelMain: TPanel;
    Separator1: TMenuItem;
    Splitter1: TSplitter;
    StatusBar1: TStatusBar;
    procedure miFileExitClick(Sender: TObject);
    procedure Splitter1CanOffset(Sender: TObject; var NewOffset: Integer;
      var Accept: Boolean);
  private

  public

  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.miFileExitClick(Sender: TObject);
begin
  Close;
end;

procedure TForm1.Splitter1CanOffset(Sender: TObject; var NewOffset: Integer;
  var Accept: Boolean);
begin

end;

end.

