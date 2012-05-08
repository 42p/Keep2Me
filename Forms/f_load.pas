unit f_load;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  Winapi.shellapi,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.Buttons,
  Vcl.StdCtrls,
  Vcl.ComCtrls,
  Vcl.ImgList,
  Vcl.Clipbrd,
  Vcl.IdAntiFreeze,
  IdBaseComponent,
  IdAntiFreezeBase,
  JvTrayIcon,
  acAlphaImageList,
  sSpeedButton,
  loaders,
  funcs,
  shortlinks,
  ConstStrings;

type
  TFLoad = class(TForm)
    pb: TProgressBar;
    mmo_Link: TMemo;
    btn_Copy: TsSpeedButton;
    btn_Open: TsSpeedButton;
    Images: TsAlphaImageList;
    lbl_link: TLabel;
    cbb_view: TComboBox;
    procedure btn_CopyClick(Sender: TObject);
    procedure btn_OpenClick(Sender: TObject);
    procedure cbb_viewChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private
    OriginLink: String;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    procedure LoadFile(FileName: string);
  end;

implementation

{$R *.dfm}

procedure TFLoad.btn_CopyClick(Sender: TObject);
begin
  Clipboard.AsText := mmo_Link.Text;
end;

procedure TFLoad.btn_OpenClick(Sender: TObject);
begin
  ShellExecute(Handle, 'open', PChar(OriginLink), nil, nil, SW_SHOW);
end;

procedure TFLoad.cbb_viewChange(Sender: TObject);
begin
  case cbb_view.ItemIndex of
    0: mmo_Link.Text := OriginLink;
    1: mmo_Link.Text := Format('[IMG]%s[/IMG]', [OriginLink]);
    2: mmo_Link.Text := Format('[URL]%s[/URL]', [OriginLink]);
    3: mmo_Link.Text := Format('<img>%s</img>', [OriginLink]);
    4: mmo_Link.Text := Format('<a href="%s">%s</a>', [OriginLink, OriginLink]);
  end;
end;

procedure TFLoad.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.ExStyle := Params.ExStyle or WS_EX_APPWINDOW;
  Params.WndParent := GetDesktopWindow;
end;

procedure TFLoad.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Application.RemoveComponent(self);
  Action := caFree;
end;

procedure TFLoad.FormCreate(Sender: TObject);
begin
  Application.InsertComponent(self);
end;

procedure TFLoad.LoadFile(FileName: string);
  procedure ReTry;
  begin
    if MessageDlg('������ ��������. ����������� ��� ���?', mtConfirmation, mbYesNo, 0) = mrYes then LoadFile(FileName)
    else begin
      DeleteFile(FileName);
      Hide;
    end;
  end;
  procedure EnableBtns(B: Boolean);
  begin
    cbb_view.Enabled := B;
    btn_Open.Enabled := B;
    btn_Copy.Enabled := B;
  end;

var
  Cloader: TLoader;
  CShorter: TShorter;
  r: string;
begin
  try
    mmo_Link.Clear;
    OriginLink := '';
    cbb_view.ItemIndex := 0;
    EnableBtns(false);
    if not GSettings.HideLoadForm then Show
    else Hide;
    Cloader := LoadersArray[GSettings.LoaderIndex].Obj.Create;
    Cloader.SetLoadBar(pb);
    Cloader.LoadFile(FileName);
  finally
    if Cloader.Error then begin
      Cloader.Free;
      ReTry;
    end else begin
      DeleteFile(FileName);
      r := Cloader.GetLink;
      try
        if GSettings.ShortLinkIndex > 0 then begin
          CShorter := ShortersArray[GSettings.ShortLinkIndex - 1].Obj.Create;
          CShorter.SetLoadBar(pb);
          CShorter.LoadFile(r);
          if CShorter.Error then GSettings.TrayIcon.BalloonHint(SYS_KEEP2ME, '�� ������� ��������� ������')
          else r := CShorter.GetLink;
        end;
      except
        FreeAndNil(CShorter);
      end;
      AddToRecentFiles(r, ExtractFileName(FileName), rfImg);
      OriginLink := r;
      mmo_Link.Text := r;
      if GSettings.CopyLink then Clipboard.AsText := r;
      FreeAndNil(Cloader);
      pb.Position := pb.Max;
      EnableBtns(true);
      GSettings.TrayIcon.Hint := r;
      if GSettings.ShowInTray then GSettings.TrayIcon.BalloonHint('���� ��������', r);
    end;
  end;
end;

end.
