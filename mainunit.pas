unit MainUnit;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, DBGrids,
  ExtCtrls, sqlite3conn, sqldb, DB, Menus, ComCtrls, DOM, XMLRead;

type

  { TForm1 }

  TForm1 = class(TForm)
    // IDE-Generated & Designer Components
    MainMenu1: TMainMenu;
    MenuItemExit: TMenuItem;
    MenuItemCollection: TMenuItem;
    MenuItemAddAlbum: TMenuItem;
    MenuItemDeleteAlbum: TMenuItem;
    MenuItem1: TMenuItem;
    MenuItemRefresh: TMenuItem;
    MenuItemSave: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    AddAlbum: TMenuItem;
    MenuItemDelete: TMenuItem;
    MenuItemManage: TMenuItem;
    MenuItemHelp: TMenuItem;
    MenuItemAbout: TMenuItem;
    Separator1: TMenuItem;
    Separator2: TMenuItem;
    Separator3: TMenuItem;
    Separator5: TMenuItem;

    PanelMain: TPanel;
    Splitter1: TSplitter;
    albgrid: TDBGrid;
    trkgrid: TDBGrid;
    StatusBar1: TStatusBar;
    OpenDialog1: TOpenDialog;

    // Database Components (aligned with designer names)
    SQLiteConn: TSQLConnector;
    SQLTrans: TSQLTransaction;
    AlbumsQuery: TSQLQuery;
    TracksQuery: TSQLQuery;
    AlbumsDataSource: TDataSource;
    TracksDataSource: TDataSource;

    // Event Handlers
    procedure AddAlbumClick(Sender: TObject);
    procedure albgridDblClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure MenuItemDeleteClick(Sender: TObject);
    procedure MenuItemAboutClick(Sender: TObject);
    procedure MenuItemExitClick(Sender: TObject);
    procedure MenuItemManageClick(Sender: TObject);
    procedure MenuItemRefreshClick(Sender: TObject);
    procedure MenuItemSaveClick(Sender: TObject);
    procedure miFileImportXSPFClick(Sender: TObject);
    procedure Separator3Click(Sender: TObject);
    procedure Splitter1CanOffset(Sender: TObject; var NewOffset: Integer; var Accept: Boolean);
    procedure BtnImportXSPFClick(Sender: TObject);
  private
    procedure DeleteAlbumClick(Sender: TObject);
    procedure InitDatabase;
    procedure LoadCollection;
    procedure UpdateCollectionStats;
    procedure AutoFitGrid(Grid: TDBGrid);
    procedure AlbumsQueryAfterScroll(DataSet: TDataSet);
    procedure FieldGetText(Sender: TField; var AText: string; DisplayText: Boolean);
    procedure DurationGetText(Sender: TField; var AText: string; DisplayText: Boolean);
    function GetOrCreateArtist(const ArtistName: string): Integer;
    function GetOrCreateGenre(const GenreName: string): Integer;
    function GetOrCreateAlbum(const AlbumTitle: string; AlbumArtistID: Integer): Integer;
    function InsertXSPFTrack(const ArtistName, AlbumTitle, TrackTitle, GenreName: string; TrackNum, DurationMs, AlbumArtistID: Integer): Boolean;
  public
  end;

var
  Form1: TForm1;

implementation

{$R *.lfm}

{ TForm1 }

procedure TForm1.FormCreate(Sender: TObject);
begin
  // Set clean initial window dimensions
  WindowState := wsNormal;
  Position := poScreenCenter;
  SetBounds(100, 100, 950, 850);
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  AlbumsQuery.AfterScroll := @AlbumsQueryAfterScroll;
  InitDatabase;
  LoadCollection;
end;

procedure TForm1.MenuItemDeleteClick(Sender: TObject);
var
  AlbumID: Integer;
  AlbumTitle: string;
  Q: TSQLQuery;
begin
  // Ensure an album is currently selected in the grid
  if AlbumsQuery.EOF or (AlbumsQuery.RecordCount = 0) then
  begin
    ShowMessage('Please select an album to delete.');
    Exit;
  end;

  // Grab the ID and Title of the currently selected album
  AlbumID := AlbumsQuery.FieldByName('id').AsInteger;
  AlbumTitle := AlbumsQuery.FieldByName('Album').AsString;

  // Ask for user confirmation before deleting
  if MessageDlg('Delete Album',
                Format('Are you sure you want to delete "%s" and all its tracks?', [AlbumTitle]),
                mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := SQLiteConn;
    Q.Transaction := SQLTrans;

    if not SQLTrans.Active then
      SQLTrans.StartTransaction;

    try
      // 1. Delete associated tracks first (maintains foreign key integrity)
      Q.SQL.Text := 'DELETE FROM tracks WHERE album_id = :album_id';
      Q.Params.ParamByName('album_id').AsInteger := AlbumID;
      Q.ExecSQL;

      // 2. Delete the album itself
      Q.SQL.Text := 'DELETE FROM albums WHERE id = :album_id';
      Q.Params.ParamByName('album_id').AsInteger := AlbumID;
      Q.ExecSQL;

      // Commit the transaction
      SQLTrans.Commit;

      // Refresh the UI display
      LoadCollection;
      ShowMessage('Album successfully deleted.');
    except
      on E: Exception do
      begin
        if SQLTrans.Active then
          SQLTrans.Rollback;
        ShowMessage('Error deleting album: ' + E.Message);
      end;
    end;
  finally
    Q.Free;
  end;
end;

procedure TForm1.MenuItemAboutClick(Sender: TObject);
begin
  MessageDlg('CD Collection Manager',
             'Lazarus / SQLite3 CD Collection Manager' + sLineBreak +
             'Built for Linux (Fedora / openSUSE) Windows 11',
             mtInformation, [mbOK], 0);
end;

procedure TForm1.MenuItemExitClick(Sender: TObject);
begin
  Close;
end;

procedure TForm1.MenuItemManageClick(Sender: TObject);
begin
  // Placeholder for opening your Add/Edit Album dialog
  ShowMessage('Manage Album dialog, place holder for a future edits Feature.');
end;

procedure TForm1.MenuItemRefreshClick(Sender: TObject);
begin
  LoadCollection;
end;

procedure TForm1.MenuItemSaveClick(Sender: TObject);
begin
  // Placeholder for opening your Add/Edit Album dialog
  ShowMessage('Save Album dialog, place holder for DB exports.');
end;

procedure TForm1.DeleteAlbumClick(Sender: TObject);
var
  AlbumID: Integer;
  AlbumTitle: string;
  Q: TSQLQuery;
begin
  // Ensure an album is currently selected in the grid
  if AlbumsQuery.EOF or (AlbumsQuery.RecordCount = 0) then
  begin
    ShowMessage('Please select an album to delete.');
    Exit;
  end;

  // Grab the ID and Title of the currently selected album
  AlbumID := AlbumsQuery.FieldByName('id').AsInteger;
  AlbumTitle := AlbumsQuery.FieldByName('Album').AsString;

  // Ask for user confirmation before deleting
  if MessageDlg('Delete Album',
                Format('Are you sure you want to delete "%s" and all its tracks?', [AlbumTitle]),
                mtConfirmation, [mbYes, mbNo], 0) <> mrYes then
    Exit;

  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := SQLiteConn;
    Q.Transaction := SQLTrans;

    if not SQLTrans.Active then
      SQLTrans.StartTransaction;

    try
      // 1. Delete associated tracks first (maintains foreign key integrity)
      Q.SQL.Text := 'DELETE FROM tracks WHERE album_id = :album_id';
      Q.Params.ParamByName('album_id').AsInteger := AlbumID;
      Q.ExecSQL;

      // 2. Delete the album itself
      Q.SQL.Text := 'DELETE FROM albums WHERE id = :album_id';
      Q.Params.ParamByName('album_id').AsInteger := AlbumID;
      Q.ExecSQL;

      // Commit the transaction
      SQLTrans.Commit;

      // Refresh the UI display
      LoadCollection;
      ShowMessage('Album successfully deleted.');
    except
      on E: Exception do
      begin
        if SQLTrans.Active then
          SQLTrans.Rollback;
        ShowMessage('Error deleting album: ' + E.Message);
      end;
    end;
  finally
    Q.Free;
  end;
end;

procedure TForm1.albgridDblClick(Sender: TObject);
var
  AlbumID: Integer;
  // NewGenre: String;
  GenreID: Integer;
  CmdQuery: TSQLQuery;
  NewGenre: String = '';
begin
  if AlbumsQuery.IsEmpty then Exit;

  AlbumID := AlbumsQuery.FieldByName('id').AsInteger;

  // Pop up input box
  if InputQuery('Edit Album Genre', 'Enter new genre for this album:', NewGenre) then
  begin
    NewGenre := Trim(NewGenre);
    if NewGenre = '' then Exit;

    CmdQuery := TSQLQuery.Create(nil);
    try
      CmdQuery.DataBase := SQLiteConn;
      CmdQuery.Transaction := SQLTrans;

      // 1. Check if the genre already exists in the genres table
      CmdQuery.SQL.Text := 'SELECT id FROM genres WHERE name = :gname;';
      CmdQuery.Params.ParamByName('gname').AsString := NewGenre;
      CmdQuery.Open;

      if CmdQuery.IsEmpty then
      begin
        // If it doesn't exist, insert it
        CmdQuery.Close;
        CmdQuery.SQL.Text := 'INSERT INTO genres (name) VALUES (:gname);';
        CmdQuery.Params.ParamByName('gname').AsString := NewGenre;
        CmdQuery.ExecSQL;
        SQLTrans.Commit;

        // Get the newly created genre ID
        CmdQuery.SQL.Text := 'SELECT last_insert_rowid() AS id;';
        CmdQuery.Open;
        GenreID := CmdQuery.FieldByName('id').AsInteger;
      end
      else
      begin
        // If it exists, use its existing ID
        GenreID := CmdQuery.FieldByName('id').AsInteger;
      end;
      CmdQuery.Close;

      // 2. Update the album with the new genre_id
      CmdQuery.SQL.Text := 'UPDATE albums SET genre_id = :gid WHERE id = :aid;';
      CmdQuery.Params.ParamByName('gid').AsInteger := GenreID;
      CmdQuery.Params.ParamByName('aid').AsInteger := AlbumID;
      CmdQuery.ExecSQL;
      SQLTrans.Commit;

      // 3. Refresh the UI to reflect the change immediately
      LoadCollection;

    finally
      CmdQuery.Free;
    end;
  end;
end;

procedure TForm1.AddAlbumClick(Sender: TObject);
begin
  // Placeholder for opening your Add/Edit Album dialog
  // ShowMessage('Add Album dialog will launch here.');
  BtnImportXSPFClick(Sender);
end;

procedure TForm1.UpdateCollectionStats;
var
  StatQuery: TSQLQuery;
begin
  StatQuery := TSQLQuery.Create(nil);
  try
    StatQuery.DataBase := SQLiteConn;
    StatQuery.Transaction := SQLTrans;

    StatQuery.SQL.Text :=
      'SELECT ' +
      '  (SELECT COUNT(*) FROM albums) AS TotalAlbums, ' +
      '  (SELECT COUNT(*) FROM artists WHERE EXISTS (SELECT 1 FROM albums WHERE albums.artist_id = artists.id)) AS TotalArtists, ' +
      '  (SELECT COUNT(*) FROM tracks) AS TotalTracks;';

    StatQuery.Open;

    // Display summary directly in the status bar
    StatusBar1.SimpleText := Format(' Library Summary: %d Albums | %d Artists | %d Tracks',
      [StatQuery.FieldByName('TotalAlbums').AsInteger,
       StatQuery.FieldByName('TotalArtists').AsInteger,
       StatQuery.FieldByName('TotalTracks').AsInteger]);

    StatQuery.Close;
  finally
    StatQuery.Free;
  end;
end;

procedure TForm1.miFileImportXSPFClick(Sender: TObject);
begin
  BtnImportXSPFClick(Sender);
end;

procedure TForm1.Separator3Click(Sender: TObject);
begin

end;

procedure TForm1.Splitter1CanOffset(Sender: TObject; var NewOffset: Integer;
  var Accept: Boolean);
begin
end;

procedure TForm1.InitDatabase;
var
  DbPath: string;
begin
  DbPath := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'cd_collection.db';
  SQLiteConn.DatabaseName := DbPath;
  SQLiteConn.ConnectorType := 'SQLite3';

  // 1. Open connection
  SQLiteConn.Connected := True;

  // 2. Ensure transaction is active
  if not SQLTrans.Active then
    SQLTrans.Active := True;

  // 3. Bind queries
  AlbumsQuery.DataBase := SQLiteConn;
  AlbumsQuery.Transaction := SQLTrans;
  TracksQuery.DataBase := SQLiteConn;
  TracksQuery.Transaction := SQLTrans;

  SQLiteConn.ExecuteDirect('PRAGMA foreign_keys = ON;');

  // --- Table Creation Statements ---
  SQLiteConn.ExecuteDirect(
    'CREATE TABLE IF NOT EXISTS artists (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
    '  name TEXT UNIQUE NOT NULL' +
    ');'
  );

  SQLiteConn.ExecuteDirect(
    'CREATE TABLE IF NOT EXISTS genres (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
    '  name TEXT UNIQUE NOT NULL' +
    ');'
  );

  SQLiteConn.ExecuteDirect(
    'CREATE TABLE IF NOT EXISTS albums (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
    '  title TEXT NOT NULL, ' +
    '  artist_id INTEGER, ' +
    '  genre_id INTEGER, ' +
    '  FOREIGN KEY(artist_id) REFERENCES artists(id) ON DELETE SET NULL, ' +
    '  FOREIGN KEY(genre_id) REFERENCES genres(id) ON DELETE SET NULL, ' +
    '  UNIQUE(title, artist_id)' +
    ');'
  );

  SQLiteConn.ExecuteDirect(
    'CREATE TABLE IF NOT EXISTS tracks (' +
    '  id INTEGER PRIMARY KEY AUTOINCREMENT, ' +
    '  title TEXT NOT NULL, ' +
    '  track_num INTEGER, ' +
    '  duration_ms INTEGER, ' +
    '  artist_id INTEGER, ' +
    '  album_id INTEGER, ' +
    '  genre_id INTEGER, ' +
    '  FOREIGN KEY(artist_id) REFERENCES artists(id) ON DELETE SET NULL, ' +
    '  FOREIGN KEY(album_id) REFERENCES albums(id) ON DELETE SET NULL, ' +
    '  FOREIGN KEY(genre_id) REFERENCES genres(id) ON DELETE SET NULL' +
    ');'
  );

  if SQLTrans.Active then
    SQLTrans.CommitRetaining;

  // Removed the blocking ShowMessage popup here!
end;

procedure TForm1.AutoFitGrid(Grid: TDBGrid);
var
  i: Integer;
  ColWidth, MaxWidth: Integer;
begin
  if not Assigned(Grid.DataSource) or not Assigned(Grid.DataSource.DataSet) then Exit;
  if Grid.DataSource.DataSet.IsEmpty then Exit;

  Grid.Canvas.Font := Grid.Font;

  for i := 0 to Grid.Columns.Count - 1 do
  begin
    if not Grid.Columns[i].Visible then Continue;

    MaxWidth := Grid.Canvas.TextWidth(Grid.Columns[i].Title.Caption) + 20;

    Grid.DataSource.DataSet.First;
    while not Grid.DataSource.DataSet.EOF do
    begin
      ColWidth := Grid.Canvas.TextWidth(Grid.DataSource.DataSet.FieldByName(Grid.Columns[i].FieldName).AsString) + 20;
      if ColWidth > MaxWidth then
        MaxWidth := ColWidth;
      Grid.DataSource.DataSet.Next;
    end;
    Grid.DataSource.DataSet.First;

    if MaxWidth < 50 then MaxWidth := 50;
    Grid.Columns[i].Width := MaxWidth;
  end;
end;

procedure TForm1.LoadCollection;
begin
  try
    if not SQLiteConn.Connected then
      SQLiteConn.Connected := True;

    if not SQLTrans.Active then
      SQLTrans.StartTransaction;

    AlbumsQuery.Close;
    AlbumsQuery.SQL.Text :=
      'SELECT ' +
      '  alb.id AS id, ' +
      '  art.name AS "Artist", ' +
      '  alb.title AS "Album", ' +
      '  g.name AS "Genre" ' +
      'FROM albums alb ' +
      'LEFT JOIN artists art ON alb.artist_id = art.id ' +
      'LEFT JOIN genres g    ON alb.genre_id = g.id ' +
      'ORDER BY art.name, alb.title;';
    AlbumsQuery.Open;

    // Attach custom text handlers if the fields exist in the query result
    if Assigned(AlbumsQuery.FindField('Artist')) then
      AlbumsQuery.FieldByName('Artist').OnGetText := @FieldGetText;
    if Assigned(AlbumsQuery.FindField('Album')) then
      AlbumsQuery.FieldByName('Album').OnGetText := @FieldGetText;
    if Assigned(AlbumsQuery.FindField('Genre')) then
      AlbumsQuery.FieldByName('Genre').OnGetText := @FieldGetText;

    // Hide the primary key (id) column if it's visible in the grid
    if albgrid.Columns.Count > 0 then
      albgrid.Columns[0].Visible := False;

    AutoFitGrid(albgrid);
    UpdateCollectionStats;
  except
    on E: Exception do
      ShowMessage('Error loading collection: ' + E.Message);
  end;
end;

procedure TForm1.AlbumsQueryAfterScroll(DataSet: TDataSet);
var
  AlbumID: Integer;
begin
  if AlbumsQuery.IsEmpty then
  begin
    TracksQuery.Close;
    Exit;
  end;

  AlbumID := AlbumsQuery.FieldByName('id').AsInteger;

  TracksQuery.Close;
  TracksQuery.PacketRecords := -1;
  TracksQuery.SQL.Text :=
    'SELECT ' +
    '  t.id, ' +
    '  t.track_num AS "Track", ' +
    '  t.title AS "Title", ' +
    '  t.duration_ms AS "Duration", ' +
    '  art.name AS "Artist" ' +
    'FROM tracks t ' +
    'LEFT JOIN artists art ON t.artist_id = art.id ' +
    'WHERE t.album_id = :album_id ' +
    'ORDER BY t.track_num;';

  TracksQuery.Params.ParamByName('album_id').AsInteger := AlbumID;
  TracksQuery.Open;

  if Assigned(TracksQuery.FindField('Title')) then
    TracksQuery.FieldByName('Title').OnGetText := @FieldGetText;
  if Assigned(TracksQuery.FindField('Artist')) then
    TracksQuery.FieldByName('Artist').OnGetText := @FieldGetText;
  if Assigned(TracksQuery.FindField('Duration')) then
    TracksQuery.FieldByName('Duration').OnGetText := @DurationGetText;

  if trkgrid.Columns.Count > 0 then
    trkgrid.Columns[0].Visible := False;

  AutoFitGrid(trkgrid);
end;

procedure TForm1.DurationGetText(Sender: TField; var AText: string; DisplayText: Boolean);
var
  TotalSecs, Mins, Secs: Integer;
begin
  if Sender.IsNull then
    AText := ''
  else
  begin
    TotalSecs := Sender.AsInteger div 1000;
    Mins := TotalSecs div 60;
    Secs := TotalSecs mod 60;
    AText := Format('%d:%.2d', [Mins, Secs]);
  end;
end;

procedure TForm1.FieldGetText(Sender: TField; var AText: string; DisplayText: Boolean);
begin
  AText := Sender.AsString;
end;

function TForm1.GetOrCreateArtist(const ArtistName: string): Integer;
var
  Q: TSQLQuery;
begin
  Result := -1;
  if Trim(ArtistName) = '' then Exit;

  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := SQLiteConn;
    Q.Transaction := SQLTrans;

    // Check if artist already exists
    Q.SQL.Text := 'SELECT id FROM artists WHERE name = :name';
    Q.Params.ParamByName('name').AsString := Trim(ArtistName);
    Q.Open;

    if not Q.EOF then
    begin
      Result := Q.FieldByName('id').AsInteger;
    end
    else
    begin
      Q.Close;

      // 1. Insert the new artist using ExecSQL
      Q.SQL.Text := 'INSERT INTO artists (name) VALUES (:name)';
      Q.Params.ParamByName('name').AsString := Trim(ArtistName);
      Q.ExecSQL;

      // 2. Commit the transaction so the database registers the new row
      if Assigned(SQLTrans) and SQLTrans.Active then
        SQLTrans.CommitRetaining;

      // 3. Fetch the newly generated ID using a clean SELECT statement and Open
      Q.Close;
      Q.SQL.Text := 'SELECT last_insert_rowid() AS id';
      Q.Open;
      if not Q.EOF then
        Result := Q.FieldByName('id').AsInteger;
    end;
    Q.Close;
  finally
    Q.Free;
  end;
end;

function TForm1.GetOrCreateGenre(const GenreName: string): Integer;
var
  Q: TSQLQuery;
begin
  Result := -1;
  if Trim(GenreName) = '' then Exit;

  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := SQLiteConn;
    Q.Transaction := SQLTrans;

    Q.SQL.Text := 'SELECT id FROM genres WHERE name = :name';
    Q.Params.ParamByName('name').AsString := GenreName;
    Q.Open;

    if not Q.IsEmpty then
      Result := Q.FieldByName('id').AsInteger
    else
    begin
      Q.Close;
      Q.SQL.Text := 'INSERT INTO genres (name) VALUES (:name)';
      Q.Params.ParamByName('name').AsString := GenreName;
      Q.ExecSQL;

      Q.Close;
      Q.SQL.Text := 'SELECT last_insert_rowid() AS new_id';
      Q.Open;
      Result := Q.FieldByName('new_id').AsInteger;
    end;
  finally
    Q.Free;
  end;
end;

function TForm1.GetOrCreateAlbum(const AlbumTitle: string; AlbumArtistID: Integer): Integer;
var
  Q: TSQLQuery;
begin
  Result := -1;
  if Trim(AlbumTitle) = '' then Exit;

  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := SQLiteConn;
    Q.Transaction := SQLTrans;

    Q.SQL.Text := 'SELECT id FROM albums WHERE title = :title AND artist_id = :artist_id';
    Q.Params.ParamByName('title').AsString := Trim(AlbumTitle);
    Q.Params.ParamByName('artist_id').AsInteger := AlbumArtistID;
    Q.Open;

    if not Q.EOF then
    begin
      Result := Q.FieldByName('id').AsInteger;
    end
    else
    begin
      Q.Close;

      // 1. Insert the new album
      Q.SQL.Text := 'INSERT INTO albums (title, artist_id) VALUES (:title, :artist_id)';
      Q.Params.ParamByName('title').AsString := Trim(AlbumTitle);
      Q.Params.ParamByName('artist_id').AsInteger := AlbumArtistID;
      Q.ExecSQL;

      // 2. Commit the transaction using SQLTrans directly
      if Assigned(SQLTrans) and SQLTrans.Active then
        SQLTrans.CommitRetaining;

      // 3. Fetch the newly generated ID
      Q.Close;
      Q.SQL.Text := 'SELECT last_insert_rowid() AS id';
      Q.Open;
      if not Q.EOF then
        Result := Q.FieldByName('id').AsInteger;
    end;
    Q.Close;
  finally
    Q.Free;
  end;
end;

function TForm1.InsertXSPFTrack(const ArtistName, AlbumTitle, TrackTitle, GenreName: string; TrackNum, DurationMs, AlbumArtistID: Integer): Boolean;
var
  ArtistID, AlbumID, GenreID: Integer;
  Q: TSQLQuery;
begin
  Result := False;

  ArtistID := GetOrCreateArtist(ArtistName);
  AlbumID  := GetOrCreateAlbum(AlbumTitle, AlbumArtistID);
  GenreID  := GetOrCreateGenre(GenreName);

  Q := TSQLQuery.Create(nil);
  try
    Q.DataBase := SQLiteConn;
    Q.Transaction := SQLTrans;

    Q.SQL.Text :=
      'SELECT id FROM tracks ' +
      'WHERE title = :title AND album_id = :album_id AND track_num = :track_num';
    Q.Params.ParamByName('title').AsString := TrackTitle;
    Q.Params.ParamByName('track_num').AsInteger := TrackNum;
    if AlbumID > 0 then
      Q.Params.ParamByName('album_id').AsInteger := AlbumID
    else
      Q.Params.ParamByName('album_id').Clear;
    Q.Open;

    if Q.IsEmpty then
    begin
      Q.Close;
      Q.SQL.Text :=
        'INSERT INTO tracks (title, track_num, duration_ms, artist_id, album_id, genre_id) ' +
        'VALUES (:title, :track_num, :duration_ms, :artist_id, :album_id, :genre_id)';

      Q.Params.ParamByName('title').AsString := TrackTitle;
      Q.Params.ParamByName('track_num').AsInteger := TrackNum;

      if DurationMs > 0 then
        Q.Params.ParamByName('duration_ms').AsInteger := DurationMs
      else
        Q.Params.ParamByName('duration_ms').Clear;

      if ArtistID > 0 then Q.Params.ParamByName('artist_id').AsInteger := ArtistID else Q.Params.ParamByName('artist_id').Clear;
      if AlbumID > 0  then Q.Params.ParamByName('album_id').AsInteger  := AlbumID  else Q.Params.ParamByName('album_id').Clear;
      if GenreID > 0  then Q.Params.ParamByName('genre_id').AsInteger  := GenreID  else Q.Params.ParamByName('genre_id').Clear;

      Q.ExecSQL;
      Result := True;
    end;
  finally
    Q.Free;
  end;
end;

procedure TForm1.BtnImportXSPFClick(Sender: TObject);
var
  Doc: TXMLDocument;
  TrackNodes: TDOMNodeList;
  TrackNode, ChildNode: TDOMNode;
  I: Integer;
  Title, Creator, Album, Genre, AlbumArtist: string;
  TrackNum: Integer;
  Duration: Int64;
  ImportCount: Integer;
  AlbumArtistID: Integer;
  FileName: string;
  CreatorsList: TStringList;
begin
  OpenDialog1.Filter := 'XSPF Playlists (*.xspf)|*.xspf|All Files (*.*)|*.*';
  if not OpenDialog1.Execute then Exit;
  FileName := OpenDialog1.FileName;

  ImportCount := 0;
  Doc := nil;
  CreatorsList := TStringList.Create;
  try
    CreatorsList.Sorted := True;
    CreatorsList.Duplicates := dupIgnore;

    try
      ReadXMLFile(Doc, FileName);

      TrackNodes := Doc.GetElementsByTagName('track');
      if (TrackNodes = nil) or (TrackNodes.Count = 0) then
      begin
        ShowMessage('No tracks found in XSPF file.');
        Exit;
      end;

      // 1. Determine Album Title from Playlist Title if available
      Album := 'Audio CD Playlist';
      if Assigned(Doc.GetElementsByTagName('title')) and
         (Doc.GetElementsByTagName('title').Count > 0) and
         Assigned(Doc.GetElementsByTagName('title').Item[0].FirstChild) then
        Album := Trim(UTF8Encode(Doc.GetElementsByTagName('title').Item[0].FirstChild.NodeValue));

      // 2. Pre-scan all tracks to collect unique creators for Album Artist determination
      for I := 0 to TrackNodes.Count - 1 do
      begin
        TrackNode := TrackNodes.Item[I];
        ChildNode := TrackNode.FirstChild;
        while Assigned(ChildNode) do
        begin
          if LowerCase(ChildNode.NodeName) = 'creator' then
          begin
            if Assigned(ChildNode.FirstChild) then
            begin
              Creator := Trim(UTF8Encode(ChildNode.FirstChild.NodeValue));
              if (Creator <> '') and (CreatorsList.IndexOf(Creator) < 0) then
                CreatorsList.Add(Creator);
            end;
            Break;
          end;
          ChildNode := ChildNode.NextSibling;
        end;
      end;

      // 3. If multiple unique creators exist, mark as Various Artists
      if CreatorsList.Count > 1 then
        AlbumArtist := 'Various Artists'
      else if CreatorsList.Count = 1 then
        AlbumArtist := CreatorsList[0]
      else
        AlbumArtist := 'Unknown Artist';

      AlbumArtistID := GetOrCreateArtist(AlbumArtist);

      if not SQLTrans.Active then
        SQLTrans.StartTransaction;

      // 4. Import tracks into database
      for I := 0 to TrackNodes.Count - 1 do
      begin
        TrackNode := TrackNodes.Item[I];
        Title := '';
        Creator := '';
        Genre := '';
        TrackNum := I + 1;
        Duration := 0;

        ChildNode := TrackNode.FirstChild;
        while Assigned(ChildNode) do
        begin
          if LowerCase(ChildNode.NodeName) = 'title' then
          begin
            if Assigned(ChildNode.FirstChild) then
              Title := Trim(UTF8Encode(ChildNode.FirstChild.NodeValue));
          end
          else if LowerCase(ChildNode.NodeName) = 'creator' then
          begin
            if Assigned(ChildNode.FirstChild) then
              Creator := Trim(UTF8Encode(ChildNode.FirstChild.NodeValue));
          end
          else if LowerCase(ChildNode.NodeName) = 'album' then
          begin
            if Assigned(ChildNode.FirstChild) then
              Album := Trim(UTF8Encode(ChildNode.FirstChild.NodeValue));
          end
          else if LowerCase(ChildNode.NodeName) = 'tracknum' then
          begin
            if Assigned(ChildNode.FirstChild) then
              TryStrToInt(UTF8Encode(ChildNode.FirstChild.NodeValue), TrackNum);
          end
          else if LowerCase(ChildNode.NodeName) = 'duration' then
          begin
            if Assigned(ChildNode.FirstChild) then
              TryStrToInt64(UTF8Encode(ChildNode.FirstChild.NodeValue), Duration);
          end
          else if LowerCase(ChildNode.NodeName) = 'genre' then
          begin
            if Assigned(ChildNode.FirstChild) then
              Genre := Trim(UTF8Encode(ChildNode.FirstChild.NodeValue));
          end;

          ChildNode := ChildNode.NextSibling;
        end;

        if Trim(Title) = '' then
          Title := Format('Track %d', [TrackNum]);

        if Trim(Creator) = '' then
          Creator := AlbumArtist;

        if InsertXSPFTrack(Creator, Album, Title, Genre, TrackNum, Duration, AlbumArtistID) then
          Inc(ImportCount);
      end;

      SQLTrans.Commit;
      LoadCollection;

      if ImportCount > 0 then
        ShowMessage(Format('Successfully imported %d tracks from XSPF playlist!', [ImportCount]))
      else
        ShowMessage('All tracks from this playlist are already in the database.');

    except
      on E: Exception do
      begin
        if Assigned(SQLTrans) and SQLTrans.Active then
          SQLTrans.Rollback;
        ShowMessage('Error importing XSPF file: ' + E.Message);
      end;
    end;
  finally
    CreatorsList.Free;
    if Assigned(Doc) then
      Doc.Free;
  end;
end;

end.
