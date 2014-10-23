{$STACKFRAMES OFF}
unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtDlgs, ExtCtrls, jpeg, ImgList, Buttons, Spin;

type
  TForm1 = class(TForm)
    GroupBox1: TGroupBox;
    ListBox1: TListBox;
    btnAddImg: TButton;
    btnDelImg: TButton;
    OpenPictureDialog1: TOpenPictureDialog;
    Timer1: TTimer;
    SaveDialog1: TSaveDialog;
    btnDown: TBitBtn;
    btnUp: TBitBtn;
    GroupBox2: TGroupBox;
    Image1: TImage;
    btnPlayAnim: TButton;
    btnStopAnim: TButton;
    btnMakeAnim: TButton;
    btnMakeLattice: TButton;
    spinLineCount: TSpinEdit;
    Label1: TLabel;
    procedure btnAddImgClick(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
    procedure btnPlayAnimClick(Sender: TObject);
    procedure btnStopAnimClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure btnMakeAnimClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnMakeLatticeClick(Sender: TObject);
    procedure btnDelImgClick(Sender: TObject);
    procedure btnUpClick(Sender: TObject);
    procedure btnDownClick(Sender: TObject);
  private
    { Private declarations }
    imgArr: array of TBitmap;

  procedure loadImgArray();
  procedure freeImgArray();
  public
    { Public declarations }
  end;

var
  Form1: TForm1;


implementation

uses Types;

{$R *.dfm}

procedure TForm1.loadImgArray;                  //Загрузка картинок в массиив
var i:integer;
    img:TImage;
begin
  freeImgArray;                                 //Освобождение массива
  SetLength(imgArr, ListBox1.Count);            //Выделение памяти
  img:=TImage.Create(nil);
  for i:=0 to Length(imgArr)-1 do               //Загрузка массива
  begin
    imgArr[i]:= TBitmap.Create;
    img.Picture.LoadFromFile(ListBox1.Items[i]);
    imgArr[i].Assign(img.Picture.Graphic);
  end;
  img.Destroy;
end;

procedure TForm1.freeImgArray;                  //Освобождение массива картинок
var i:integer;
begin
  for i:=0 to Length(imgArr)-1 do
    imgArr[i].Destroy;
  SetLength(imgArr, 0);
end;

///////////////////////////////////////////////////
procedure TForm1.FormCreate(Sender: TObject);
begin
  Form1.DoubleBuffered:=true;                   //Включить двойную буферизацию. Чтоб не моргала анимация
end;

procedure TForm1.btnAddImgClick(Sender: TObject); //Добавление кадров
var files:TStrings;
begin
  if (OpenPictureDialog1.Execute) then
  begin
    files:=OpenPictureDialog1.Files;
    ListBox1.Items.AddStrings(files);
  end;
end;

procedure TForm1.btnDelImgClick(Sender: TObject); //Удаление файлов из списка
begin
  ListBox1.Items.Delete(ListBox1.ItemIndex);
end;

procedure TForm1.btnUpClick(Sender: TObject);     //Поднять кадр по списку в верх
var position:integer;
begin
  if (ListBox1.ItemIndex > 0) then
  begin
    position:=ListBox1.ItemIndex;
    ListBox1.Items.Move(position, position-1);
    ListBox1.ItemIndex:=position-1;
  end;
end;

procedure TForm1.btnDownClick(Sender: TObject);   //Опустить кадр по списку в низ
var position:integer;
begin
  if (ListBox1.ItemIndex < ListBox1.Count-1) then
  begin
    position:=ListBox1.ItemIndex;
    ListBox1.Items.Move(position, position+1);
    ListBox1.ItemIndex:=position+1;
  end;
end;

procedure TForm1.ListBox1Click(Sender: TObject);   //Клик по кадру выводит картинку на экран
begin
  if (ListBox1.ItemIndex <> -1) then
    Image1.Picture.LoadFromFile(ListBox1.Items[ListBox1.ItemIndex]);
end;

procedure TForm1.btnPlayAnimClick(Sender: TObject);//Проиграть анимацию
begin
  loadImgArray;                   //Загрузить массив картинок
  Timer1.Tag:=0;
  Timer1.Enabled:=true;           //Запустить таймер для прокрутки анимациии
  btnPlayAnim.Enabled:=false;
  btnStopAnim.Enabled:=true;
end;

procedure TForm1.btnStopAnimClick(Sender: TObject); //Остановить анимацию
begin
  Timer1.Enabled:=false;          //Остановить таймер
  freeImgArray;                   //Удалить массив картинок
  btnPlayAnim.Enabled:=true;
  btnStopAnim.Enabled:=false;
end;

procedure TForm1.Timer1Timer(Sender: TObject);    //Итерация таймера анимации
begin
  if (Timer1.Tag >= Length(imgArr)) then Timer1.Tag:=0;
  if (Length(imgarr) > 0) then
  begin
    Image1.Picture.Bitmap.Assign(imgArr[timer1.tag]);
    Timer1.Tag:=timer1.Tag+1;
  end;
end;

procedure TForm1.btnMakeAnimClick(Sender: TObject); //Собрать анимацию
var i:integer;
    bm:TBitmap;
    JpegIm: TJpegImage;
    source: TRect;
    filename:string;
    linesize, countLine, countFrame:integer;
begin
  btnStopAnim.Click;                                //Останавливаем проигрывание анимации
  countLine:=spinLineCount.Value;                   //Получаем число штрихов на картинку
  countFrame:=ListBox1.Count;                       //Получаем количество кадров анимации
  if (countFrame > 0) then                          //Если анимацию можно собрать
  begin
    loadImgArray;                                   //Загружаем массив картинок
    for i:=1 to Length(imgArr)-1 do                 //Проверка совпадения размеров кадров
      if ((imgArr[0].Width <> imgArr[i].Width) or
          (imgArr[0].Height <> imgArr[i].Height)) then
          begin
            ShowMessage('Размеры картинок не совпадают');
            exit;
          end;

    bm:=TBitmap.Create;
    bm.Width:=imgArr[0].Width;
    bm.Height:=imgArr[0].Height;

    linesize:= bm.Width div countLine;               //Получаем размер линии
    if (linesize = 0) then linesize:=1;              //Если размер линии равен 0 устанавливаем размер в один пиксель
    i:=0;
    source:=RECT(0,0,0,0);                           //Начинаем сначала первого кадра
    while source.Right < bm.Width do                 //Пока не обработана вся картинка
    begin
      source.Left:=source.Left+linesize;             //Выбираем нужный прямоугольник
      source.Top:=0;
      source.Right:=source.Left+linesize;
      source.Bottom:=bm.Height;
      bm.Canvas.CopyRect(source, imgArr[i].Canvas, source); //Копируем кусочек анимации из каждого кадра в общую анимацию
      inc(i);
      if (i >= Length(imgArr)) then i:=0;            //Выбираем следущий кадр по списку
    end;
    Image1.Picture.Bitmap.Assign(bm);                //Выводим полученную анимацию на экран

    if (SaveDialog1.Execute) then                    //Предлагаем сохранить анимацию
    begin
      JpegIm:= TJpegImage.Create;
      JpegIm.Assign(bm);
      JpegIm.CompressionQuality := 100;
      JpegIm.Compress;
      JpegIm.SaveToFile(ChangeFileExt(SaveDialog1.FileName,'.jpg'));
      JpegIm.Destroy;
    end;

    bm.Destroy;                                      //Чистим память
    freeImgArray;                                    //Чистим память
  end;
end;

procedure TForm1.btnMakeLatticeClick(Sender: TObject); //Собрать решетку анимации
var i:integer;
    bm:TBitmap;
    JpegIm: TJpegImage;
    source: TRect;
    linesize, countLine, countFrame:integer;
begin
  btnStopAnim.Click;                                //Останавливаем проигрывание анимации
  countLine:=spinLineCount.Value;                   //Получаем число штрихов на картинку
  countFrame:=ListBox1.Count;                       //Получаем количество кадров анимации
  if (countFrame > 0) then                          //Если анимацию можно собрать
  begin
    loadImgArray;                                   //Загружаем массив картинок
    for i:=1 to Length(imgArr)-1 do                 //Проверка совпадения размеров кадров
      if ((imgArr[0].Width <> imgArr[i].Width) or
          (imgArr[0].Height <> imgArr[i].Height)) then
          begin
            ShowMessage('Размеры картинок не совпадают');
            exit;
          end;

    bm:=TBitmap.Create;
    bm.Width:=imgArr[0].Width;
    bm.Height:=imgArr[0].Height;
    bm.Canvas.Brush.Color:=clBlack;


    linesize:= bm.Width div countLine;              //Получаем размер линии
    source:=Rect(0,0,0,0);                          //Начинаем сначала первого кадра
    while (source.Right < bm.Width) do              //Пока не обработана вся картинка
    begin
      source.Left:=source.Right+linesize;           //Выбираем нужный прямоугольник
      source.Top:=0;
      source.Right:=source.Left+linesize*(countFrame-1);
      source.Bottom:=bm.Height;
      bm.Canvas.FillRect(source);                   //Рисуем кусочек сетки
    end;
    Image1.Picture.Bitmap.Assign(bm);               //Выводим полученную сетку на экран

    bm.Canvas.Brush.Color:=clWhite;                 //Рисуем на сетке число штрихов и число кадров. Для каждой анимации своя сетка
    bm.Canvas.TextOut(1,0,'Line count: '+IntToStr(countLine)+'; Frame count: '+IntToStr(ListBox1.Count));
    if (SaveDialog1.Execute) then                   //Предлагаем сохранить
    begin
      JpegIm:= TJpegImage.Create;
      JpegIm.Assign(bm);
      JpegIm.CompressionQuality := 100;
      JpegIm.Compress;
      JpegIm.SaveToFile(ChangeFileExt(SaveDialog1.FileName,'.jpg'));
      JpegIm.Destroy;
    end;

    bm.Destroy;                                     //Чистим память
    freeImgArray;                                   //Чистим память
  end;    
end;

end.
