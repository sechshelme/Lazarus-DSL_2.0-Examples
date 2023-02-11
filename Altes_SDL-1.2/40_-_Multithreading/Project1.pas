program Project1;

uses
  sdl,
  sdl_image;

const
  Screen_Width: integer = 640;
  Screen_Heigth: integer = 480;
  Screen_BPP: integer = 32;

  ThreadCount = 4;

type
  PThread = ^TThread;

  TThread = record
    r: TSDL_Rect;
    thread: PSDL_Thread;
  end;

var
  image, screen: PSDL_Surface;
  quit: boolean = False;


  thread: array[0..ThreadCount - 1] of TThread;

  function Load_Image(const filename: string): PSDL_Surface;
  var
    loadedImage, optimizedImage: PSDL_Surface;
  begin
    Result := nil;
    loadedImage := IMG_Load(PChar(filename));
    if loadedImage <> nil then begin
      optimizedImage := SDL_DisplayFormat(loadedImage);
      SDL_FreeSurface(loadedImage);
    end else begin
      WriteLn('Kann Datei ' + filename + ' nicht laden');
      exit;
    end;
    if optimizedImage <> nil then begin
      SDL_SetColorKey(optimizedImage, SDL_SRCCOLORKEY, SDL_MapRGB(optimizedImage^.format, $0, $FF, $FF));
    end;
    Result := optimizedImage;
  end;

  procedure Apply_Surface(x, y: integer; Source, destination: PSDL_Surface);
  var
    offset: SDL_Rect;
  begin
    offset.x := x;
    offset.y := y;
    SDL_BlitSurface(Source, nil, destination, @offset);
  end;

  function Load_Files: boolean;
  begin
    Result := True;

    // Load Images
    image := Load_Image('image.png');
    if image = nil then begin
      Result := False;
      Exit;
    end;
  end;

  procedure put_pixel32(surface: PSDL_Surface; x, y: integer; pixel: uint32);
  var
    pixels: PUInt32;
  begin
    pixels := surface^.pixels;
    pixels[y * surface^.w + x] := pixel;
  end;

  function my_thread(Data: Pointer): integer; cdecl;
  var
    r: TSDL_Rect;
    x, y, j: integer;
  begin
    r := PThread(Data)^.r;

    while not quit do begin
      for x := 0 to r.w - 10 do begin
        for y := 0 to r.h - 10 do begin
          for j:=0 to 999 do
          put_pixel32(screen, x + r.x, y + r.y, Random($FFFFFF));
        end;
      end;
    end;
  end;

  function Create: boolean;
  begin
    Result := False;

    // Start SDL
    if SDL_Init(SDL_INIT_EVERYTHING) < 0 then begin
      Writeln('Kann SDL nicht öffnen: ', SDL_GetError);
      Exit;
    end;

    // screen Setup
    screen := SDL_SetVideoMode(Screen_Width, Screen_Heigth, Screen_BPP, SDL_SWSURFACE);
    if screen = nil then begin
      Writeln('Kann kein Fenster öffnen: ', SDL_GetError);
      Exit;
    end;

    // Fenster Titel
    SDL_WM_SetCaption('Thread test', nil);

    if not Load_Files then begin
      WriteLn('Fehler beim Dateien laden !');
      Result := False;
      Exit;
    end;

    Result := True;

  end;

  // Mit der original Funktion geht es nicht.
  // function SDL_CreateThread(fn: PInt; Data: Pointer): PSDL_Thread; cdecl; external SDLLibName;

  function SDL_CreateThread(fn: Pointer; Data: Pointer): PSDL_Thread; cdecl; external SDLLibName;

  function Run: boolean;
  var
    event: TSDL_Event;
    i: integer;
  begin
    for i := 0 to ThreadCount - 1 do begin
      thread[i].r.x := i * 110 + 10;
      thread[i].r.y := 10;
      thread[i].r.w := 100;
      thread[i].r.h := 100;
      thread[i].thread := SDL_CreateThread(@my_thread, @thread[i]);
    end;

    repeat
      while SDL_PollEvent(@event) <> 0 do begin
        case event.type_ of
          SDL_KEYDOWN: begin
            case event.key.keysym.sym of
              SDLK_ESCAPE: begin
                quit := True;
              end;
            end;
          end;
          SDL_QUITEV: begin
            quit := True;
          end;
        end;
      end;
  //    SDL_Delay(1000);

      if SDL_Flip(screen) = -1 then begin
        WriteLn('Flip Error !');
        Result := False;
        Exit;
      end;
    until quit;
//    SDL_Delay(100);
    Result := True;
  end;

  procedure Destroy;
  var
  i2,  i: integer;

  begin
    for i := 0 to ThreadCount - 1 do begin
      SDL_WaitThread(thread[i].thread,i2);
//      SDL_KillThread(thread[i].thread);
    end;

    // Images freigeben
    SDL_FreeSurface(image);

    // SDL beenden
    SDL_Quit;
  end;

begin
  if not Create then begin
    Halt(1);
  end;
  if not Run then begin
    Halt(1);
  end;
  Destroy;
end.
