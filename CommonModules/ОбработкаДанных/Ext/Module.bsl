﻿Функция ПолучитьСписокИзСтроки(СтрокаЗагрузки, Разделитель) Экспорт
	ВозвращаемыйСписок = Новый СписокЗначений;
	ВозвращаемыйСписок.ЗагрузитьЗначения(СтрРазделить(СтрокаЗагрузки,Разделитель));
	Возврат ВозвращаемыйСписок;
КонецФункции

Функция Транслит(Вход) Экспорт   
    Русский = "абвгдеёжзийклмнопрстуфхцчшщьыъэюяАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЬЫЪЭЮЯ";
    Англ    = "a;b;v;g;d;e;yo;zh;z;i;y;k;l;m;n;o;p;r;s;t;u;f;kh;ts;ch;sh;shch;;y;;e;yu;ya;A;B;V;G;D;E;Yo;Zh;Z;I;Y;K;L;M;N;O;P;R;S;T;U;F;Kh;Ts;Ch;Sh;Shch;;Y;;E;Yu;Ya";
    МассивАнгл = СтрРазделить(Англ,";");
    ДлиннаВход = СтрДлина(Вход);
    Выход = "";
    Для а=1 По ДлиннаВход Цикл 
        ТекущийСимвол = Сред(Вход,а,1);    
        Позиция = Найти(Русский,ТекущийСимвол);
        Если Позиция > 0 Тогда 
            Выход = Выход + МассивАнгл[Позиция-1];
        Иначе 
            Выход = Выход + ТекущийСимвол;
        КонецЕсли;
    КонецЦикла;
    Возврат Выход;   
КонецФункции

Функция РасшифроватьGZIP(ДвоичныеДанные) Экспорт
	// Получение сжатого тела из GZIP
	Поток = ДвоичныеДанные.ОткрытьПотокДляЧтения();
	Поток.Перейти(10, ПозицияВПотоке.Начало);
	БуферТелаФайла = Новый БуферДвоичныхДанных(Поток.Размер()-10);
	Поток.Прочитать(БуферТелаФайла,0,Поток.Размер()-18);
	// Получение CRC(Контрольного хэша файла)
	БуферCRC = Новый БуферДвоичныхДанных(4);
	Поток.Перейти(Поток.Размер()-8, ПозицияВПотоке.Начало);
	Поток.Прочитать(БуферCRC,0,4);
	CRC=БуферCRC.ПрочитатьЦелое32(0);
	// Получение размера несжатого файла
	БуферРазмерНесжатого = Новый БуферДвоичныхДанных(4);
	Поток.Перейти(Поток.Размер()-4, ПозицияВПотоке.Начало);
	Поток.Прочитать(БуферРазмерНесжатого,0,4);
	РазмерРаспакованногоФайла=БуферРазмерНесжатого.ПрочитатьЦелое32(0);
	// Сформирование валидной ZIP структуры
	Поток.Закрыть();
	ПотокВПамяти = Новый ПотокВПамяти(БуферТелаФайла);
	
	ИмяСжатогоФайла="body.json";
	ДлинаИмениСжатогоФайла		= СтрДлина(ИмяСжатогоФайла);
	РазмерСжатогоФайла			= ПотокВПамяти.Размер();
	ВремяФайла					= 0;
	ДатаФайла					= 0;
	РазмерZIP = 98+ДлинаИмениСжатогоФайла*2+РазмерСжатогоФайла; //98 Байт заголовки, 2 раза длина файла + размер сжатого тела
	БинарныйБуфер = Новый БуферДвоичныхДанных(РазмерZIP);
	//	// [Local File Header]
	ДлинаФиксированнойЧастиLFH = 30;
	
	БинарныйБуфер.ЗаписатьЦелое32(0	, 67324752);					//Обязательная сигнатура 0x04034B50
	БинарныйБуфер.ЗаписатьЦелое16(4	, 20); 							//Минимальная версия для распаковки
	БинарныйБуфер.ЗаписатьЦелое16(6	, 2050);						//Битовый флаг
	БинарныйБуфер.ЗаписатьЦелое16(8	, 8); 							//Метод сжатия (0 - без сжатия, 8 - deflate)
	БинарныйБуфер.ЗаписатьЦелое16(10, ВремяФайла); 					//Время модификации файла
	БинарныйБуфер.ЗаписатьЦелое16(12, ДатаФайла); 					//Дата модификации файла
	БинарныйБуфер.ЗаписатьЦелое32(14, CRC);							//Контрольная сумма
	БинарныйБуфер.ЗаписатьЦелое32(18, РазмерСжатогоФайла);			//Сжатый размер
	БинарныйБуфер.ЗаписатьЦелое32(22, РазмерРаспакованногоФайла);	//Несжатый размер
	БинарныйБуфер.ЗаписатьЦелое16(26, ДлинаИмениСжатогоФайла);		//Длина название файла
	БинарныйБуфер.ЗаписатьЦелое16(28, 0);							//Длина поля с дополнительными данными
	
	//Название файла
	Для й = 0 По ДлинаИмениСжатогоФайла - 1 Цикл
		БинарныйБуфер.Установить(ДлинаФиксированнойЧастиLFH + й, КодСимвола(Сред(ИмяСжатогоФайла, й + 1, 1)));
	КонецЦикла;
	
	// [Сжатые данные]
	БуферСжатыхДанных = Новый БуферДвоичныхДанных(РазмерСжатогоФайла);
	
	ПотокВПамяти.Прочитать(БуферСжатыхДанных, 0, РазмерСжатогоФайла);
	ПотокВПамяти.Закрыть();
	
	БинарныйБуфер.Записать(ДлинаФиксированнойЧастиLFH + ДлинаИмениСжатогоФайла, БуферСжатыхДанных);
	
	ТекущееСмещение = ДлинаФиксированнойЧастиLFH + ДлинаИмениСжатогоФайла + РазмерСжатогоФайла;
	
	// [Central directory file header]
	ДлинаФиксированнойЧастиCDFH	= 46;
	ДлинаДополнительныхДанных	= 0;
	
	БинарныйБуфер.ЗаписатьЦелое32(ТекущееСмещение + 0	, 33639248);					//Обязательная сигнатура 0x02014B50
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + 4	, 814); 						//Версия для создания
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + 6	, 20); 							//Минимальная версия для распаковки
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + 8	, 2050);						//Битовый флаг
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + 10	, 8); 							//Метод сжатия (0 - без сжатия, 8 - deflate)
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + 12	, ВремяФайла); 					//Время модификации файла
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + 14	, ДатаФайла); 					//Дата модификации файла
	БинарныйБуфер.ЗаписатьЦелое32(ТекущееСмещение + 16	, CRC);							//Контрольная сумма
	БинарныйБуфер.ЗаписатьЦелое32(ТекущееСмещение + 20	, РазмерСжатогоФайла);			//Сжатый размер
	БинарныйБуфер.ЗаписатьЦелое32(ТекущееСмещение + 24	, РазмерРаспакованногоФайла);	//Несжатый размер
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + 28	, ДлинаИмениСжатогоФайла);		//Длина название файла
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + 30	, ДлинаДополнительныхДанных);	//Длина поля с дополнительными данными
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + 32	, 0);							//Длина комментариев к файлу
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + 34	, 0);							//Номер диска
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + 36	, 0);							//Внутренние аттрибуты файла
	БинарныйБуфер.ЗаписатьЦелое32(ТекущееСмещение + 38	, 2176057344);					//Внешние аттрибуты файла
	БинарныйБуфер.ЗаписатьЦелое32(ТекущееСмещение + 42	, 0);							//Смещение до структуры LocalFileHeader
	
	//Название файла
	Для й = 0 По ДлинаИмениСжатогоФайла - 1 Цикл
		БинарныйБуфер.Установить(ТекущееСмещение + ДлинаФиксированнойЧастиCDFH + й, КодСимвола(Сред(ИмяСжатогоФайла, й + 1, 1)));
	КонецЦикла;
	
	ТекущееСмещение = ТекущееСмещение + ДлинаФиксированнойЧастиCDFH + ДлинаИмениСжатогоФайла;
	
	//Дополнительные данные отсутствуют
	
	//Данные комментария отсутствуют
	
	ТекущееСмещение = ТекущееСмещение + ДлинаДополнительныхДанных;
	
	// [End of central directory record (EOCD)]
	РазмерCentralDirectory		= ДлинаФиксированнойЧастиCDFH + ДлинаИмениСжатогоФайла + ДлинаДополнительныхДанных;
	СмещениеCentralDirectory	= ДлинаФиксированнойЧастиLFH  + ДлинаИмениСжатогоФайла + РазмерСжатогоФайла;
	
	БинарныйБуфер.ЗаписатьЦелое32(ТекущееСмещение + 0	, 101010256);					//Обязательная сигнатура 0x06054B50
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + 4	, 0); 							//Номер диска
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + 6	, 0); 							//Номер диска, где находится начало Central Directory
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + 8	, 1); 							//Количество записей в Central Directory в текущем диске
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + 10	, 1); 							//Всего записей в Central Directory
	БинарныйБуфер.ЗаписатьЦелое32(ТекущееСмещение + 12	, РазмерCentralDirectory);		//Размер Central Directory
	БинарныйБуфер.ЗаписатьЦелое32(ТекущееСмещение + 16	, СмещениеCentralDirectory);	//Смещение Central Directory
	БинарныйБуфер.ЗаписатьЦелое16(ТекущееСмещение + 20	, 0);							//Длина комментария
	
	//Данные комментария отсутствуют
	РазделительПутей=ПолучитьРазделительПути();
	КаталогВременныхФайлов=КаталогВременныхФайлов()+РазделительПутей+"GZIP";
	
	ПотокВПамяти = Новый ПотокВПамяти(БинарныйБуфер);
	Файл = Новый ЧтениеZipФайла(ПотокВПамяти);
	Файл.Извлечь(Файл.Элементы[0], КаталогВременныхФайлов,РежимВосстановленияПутейФайловZIP.НеВосстанавливать);
	ПотокВПамяти.Закрыть();
	//Чтение текста
	ЧтениеТекста=Новый ЧтениеТекста(КаталогВременныхФайлов+РазделительПутей+"body.json", КодировкаТекста.UTF8);
	Текст=ЧтениеТекста.Прочитать();
	ЧтениеТекста.Закрыть();
	УдалитьФайлы(КаталогВременныхФайлов);
	Возврат Текст;	
КонецФункции

Функция ЗашифроватьGZIP(АдресХранилища)
	
	ИмяСжимаемогоФайла = ПолучитьИмяВременногоФайла();
	ФайлДвоичные 	   = ПолучитьИзВременногоХранилища(АдресХранилища);
	ФайлДвоичные.Записать(ИмяСжимаемогоФайла);
	
	ИмяЗипФайла = ПолучитьИмяВременногоФайла("zip");
	Сжатие = Новый ЗаписьZipФайла(ИмяЗипФайла,,,МетодСжатияZIP.Сжатие,УровеньСжатияZIP.Максимальный);
	Сжатие.Добавить(ИмяСжимаемогоФайла, РежимСохраненияПутейZIP.НеСохранятьПути);
	Сжатие.Записать();
	ЧтениеДанных = Новый ЧтениеДанных(ИмяЗипФайла);
	
	Сигнатура 				 = ЧтениеДанных.ПрочитатьЦелое32();//+4
	Версия 					 = ЧтениеДанных.ПрочитатьЦелое16();//+6
	БитФлаг 				 = ЧтениеДанных.ПрочитатьЦелое16();//+8
	МетодКомпрессии 		 = ЧтениеДанных.ПрочитатьЦелое16();//+10
	ВремяМодификации 		 = ЧтениеДанных.ПрочитатьЦелое16();//+12
	ДатаМодификации 		 = ЧтениеДанных.ПрочитатьЦелое16();//+14
	КонтрольнаяСумма 		 = ЧтениеДанных.ПрочитатьЦелое32();//+18
	СжатыйРазмер 			 = ЧтениеДанных.ПрочитатьЦелое32();//+22
	РаспакованныйРазмер 	 = ЧтениеДанных.ПрочитатьЦелое32();//+26
	ДлинаИмениФайла 		 = ЧтениеДанных.ПрочитатьЦелое16();//28
	ДлинаДополнительныхПолей = ЧтениеДанных.ПрочитатьЦелое16();//30
	ЧтениеДанных.Пропустить(ДлинаИмениФайла + ДлинаДополнительныхПолей);//44
	РезультатЧтения = ЧтениеДанных.Прочитать(СжатыйРазмер);
	
	СжатыйБуфер = РезультатЧтения.ПолучитьБуферДвоичныхДанных();
	
	СигнатураГзип = 35615;//2байта 8b1f
	МетодСжатияДефлейт = 8;//1байт
	ФлагМетодаКомпрессии = 2; //1байт
	
	БуферГзипНачало = Новый БуферДвоичныхДанных(10);
	БуферГзипНачало.ЗаписатьЦелое16(0, СигнатураГзип);
	БуферГзипНачало.Установить(2,МетодСжатияДефлейт);
	БуферГзипНачало.Установить(8,ФлагМетодаКомпрессии);
	
	БуферГзипКонец = Новый БуферДвоичныхДанных(8);
	БуферГзипКонец.ЗаписатьЦелое32(0, КонтрольнаяСумма);
	БуферГзипКонец.ЗаписатьЦелое32(4, РаспакованныйРазмер);
	
	БуферРезульт = БуферГзипНачало.Соединить(СжатыйБуфер).Соединить(БуферГзипКонец);
	Поток = Новый ПотокВПамяти(БуферРезульт);
	ДвоичныеГзип = Поток.ЗакрытьИПолучитьДвоичныеДанные();
	
	Возврат ДвоичныеГзип;
	
КонецФункции

Функция ПолучитьХэш(Стр) Экспорт
	ХД = Новый ХешированиеДанных(ХешФункция.SHA1);
	ХД.Добавить(Стр);
	Возврат НРег(СтрЗаменить(СокрЛП(ХД.ХешСумма)," ", ""))
КонецФункции

Функция ПробразованиеИмениИзWEB(СтрокаОтвета) Экспорт
	СтрокаОтвета = СокрЛП(СтрокаОтвета);	
	СтрокаОтвета = СтрЗаменить(СтрокаОтвета, "&amp;", "&");
	Возврат СтрокаОтвета;
КонецФункции

Процедура ЗаписатьВЛог(СтрокаНаЗапись) Экспорт
	Попытка
		Файл = Новый ЗаписьТекста(КаталогВременныхФайлов()+"http.log",,,Истина);
		Файл.ЗаписатьСтроку("["+ТекущаяДата()+"] " + СтрокаНаЗапись);
		Файл.Закрыть();	
	Исключение
		ВызватьИсключение(ОписаниеОшибки()); 
	КонецПопытки;
КонецПроцедуры

Функция ОшибкаJ(СтрокаОшибки) Экспорт
	Возврат Новый Структура("errorString", СтрокаОшибки);
КонецФункции

Функция ПолучитьМассивКлючей(Се) Экспорт
	МассивКлючей = Новый Массив;
	Для каждого С Из Се Цикл
		МассивКлючей.Добавить("'"+С.Ключ+"'");
	КонецЦикла;	
	Возврат МассивКлючей;
КонецФункции

Функция ОбработатьHTTPОтветIIKO(Источник, СписокЗначимыхПолей, GZIPСжатие = Истина) Экспорт
	СтруктураОтвета = Новый Структура;
	
	ЧтениеXml = Новый ЧтениеXML();
	ДанныеXML = ?(GZIPСжатие, РасшифроватьGZIP(Источник.ПолучитьТелоКакДвоичныеДанные()), Источник.ПолучитьТелоКакСтроку());
	ЧтениеXml.УстановитьСтроку(ДанныеXML);
	Пока ЧтениеXml.Прочитать() Цикл
		Если ЧтениеXml.ТипУзла = ТипУзлаXML.НачалоЭлемента Тогда
			Для каждого ЗначимоеПоле Из СписокЗначимыхПолей Цикл
				Если ЧтениеXml.Имя = ЗначимоеПоле.Значение Тогда
					ЧтениеXml.Прочитать();
					СтруктураОтвета.Вставить(ЗначимоеПоле, ЧтениеXml.Значение);
				КонецЕсли;
			КонецЦикла;
		КонецЕсли;
	КонецЦикла;
	ЧтениеXml.Закрыть();
	Возврат СтруктураОтвета;
КонецФункции

Функция ПолучитьИнфоСервера(ПП)	Экспорт
	Попытка
		HTTPСоединение = Новый HTTPСоединение(ПП.IIKO_HOST, Число(ПП.IIKO_PORT));
		ПутьМетода = "/resto/get_server_info.jsp?encoding=UTF-8";
		HTTPЗапрос = Новый HTTPЗапрос(ПутьМетода);
		HTTPОтвет = HTTPСоединение.ОтправитьДляОбработки(HTTPЗапрос);
		ОбработкаДанных.ЗаписатьВЛог("Данные на запрос информации о сервере отправлены в Айко.");
		Если HTTPОтвет.КодСостояния = 200 Тогда
			СтрокаЗначимыхПолей = "serverName,edition,version";
			СписокЗП = ОбработкаДанных.ПолучитьСписокИзСтроки(СтрокаЗначимыхПолей, ",");
			СтруктураОтвета = ОбработкаДанных.ОбработатьHTTPОтветIIKO(HTTPОтвет, СписокЗП, Ложь);
			Возврат СтруктураОтвета;
		Иначе
			ТекстОшибки = "При получении информации о сервере IIKO получен ответ, отличный от успешного: "+HTTPОтвет.КодСостояния;
			ОбработкаДанных.ЗаписатьВЛог(ТекстОшибки);
			Возврат Неопределено;
		КонецЕсли;
	Исключение
		ОбработкаДанных.ЗаписатьВЛог(ИнформацияОбОшибке().Описание);
		Возврат Неопределено;
	КонецПопытки;	
КонецФункции

Функция ПолучитьHTTPЗаголовки(РазмерФайлаОтправки, П) Экспорт
	
	ЗаголовкиHTTP = Новый Соответствие();
	ЗаголовкиHTTP.Вставить("Content-Type", "text/xml");
	ЗаголовкиHTTP.Вставить("X-Resto-LoginName", П.IIKO_LOGIN);
	ЗаголовкиHTTP.Вставить("X-Resto-PasswordHash", П.IIKO_PASS);
	ЗаголовкиHTTP.Вставить("X-Resto-BackVersion", П.version);
	ЗаголовкиHTTP.Вставить("X-Resto-AuthType", "BACK");
	ЗаголовкиHTTP.Вставить("X-Resto-ServerEdition", П.IIKO_BACK_TYPE);
	ЗаголовкиHTTP.Вставить("Accept-Language", "ru");
	ЗаголовкиHTTP.Вставить("Content-Length", РазмерФайлаОтправки);
	ЗаголовкиHTTP.Вставить("Expect", "100-continue");
	ЗаголовкиHTTP.Вставить("Accept-Encoding", "gzip");
	ЗаголовкиHTTP.Вставить("Connection", "Close");
	
	Возврат ЗаголовкиHTTP;
КонецФункции