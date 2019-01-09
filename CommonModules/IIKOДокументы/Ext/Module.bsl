﻿Функция ПреобразоватьДатуВремя(ИсходнаяСтрока)
	Попытка
		ЧастиДатыВремени = СтрРазделить(ИсходнаяСтрока, "T");
		нЧастиДаты = СтрРазделить(ЧастиДатыВремени[0], "-");
		Возврат Дата(нЧастиДаты[2]+"."+нЧастиДаты[1]+"."+нЧастиДаты[0]+" "+ЧастиДатыВремени[1]);
	Исключение
		ОбработкаДанных.ЗаписатьВЛог(ИнформацияОбОшибке().Описание);
	КонецПопытки;
КонецФункции

Функция ПолучитьВерсиюОбъекта(ПП)
	МассивОтвета = IIKOСправочники.ВыполнитьНаСервереАйко("НомерОбъекта",,ПП);
	
	Если МассивОтвета = Неопределено Тогда
		Возврат Неопределено;
	КонецЕсли;
	
	Если МассивОтвета.Количество()>0 Тогда
		Возврат МассивОтвета[0].Получить("res");
	Иначе
		Возврат Неопределено;
	КонецЕсли;
КонецФункции

Функция ПолучитьHTTPЗаголовки(РазмерФайлаОтправки, П)
	АйкоВерсия = IIKOСправочники.ВыполнитьНаСервереАйко("Версия",,П)[0].Получить("serverversion");
	ЗаголовкиHTTP = Новый Соответствие();
	ЗаголовкиHTTP.Вставить("Content-Type", "text/xml");
	ЗаголовкиHTTP.Вставить("X-Resto-LoginName", П.IIKO_LOGIN);
	ЗаголовкиHTTP.Вставить("X-Resto-PasswordHash", П.IIKO_PASS);
	ЗаголовкиHTTP.Вставить("X-Resto-BackVersion", АйкоВерсия);
	ЗаголовкиHTTP.Вставить("X-Resto-AuthType", "BACK");
	ЗаголовкиHTTP.Вставить("X-Resto-ServerEdition", "IIKO_"+П.IIKO_BACK_TYPE);
	ЗаголовкиHTTP.Вставить("Accept-Language", "ru");
	ЗаголовкиHTTP.Вставить("Content-Length", РазмерФайлаОтправки);
	ЗаголовкиHTTP.Вставить("Expect", "100-continue");
	ЗаголовкиHTTP.Вставить("Accept-Encoding", "gzip");
	ЗаголовкиHTTP.Вставить("Connection", "Close");
	
	Возврат ЗаголовкиHTTP;
КонецФункции

Функция ПолучитьСоответствиеДокументовIIKO() Экспорт
	СДокументов = Новый Соответствие;
	Данные = "IncomingInvoice;Приходная накладная;INCOMING_INVOICE:"+
	"OutgoingInvoice;Расходная накладная;OUTGOING_INVOICE:"+
	"ReturnedInvoice;Возвратная накладная;RETURNED_INVOICE:"+
	"InternalTransfer;Внутреннее перемещение;INTERNAL_TRANSFER:"+
	"TreeMenuChangeDocument;Приказ об изменении прейскуранта;MENU_CHANGE:"+
	"WriteoffDocument;Акт списания;WRITEOFF_DOCUMENT";
	СтрокиДанных = СтрРазделить(Данные, ":");
	Для каждого СтрокаДанных Из СтрокиДанных Цикл
		ЧастиСтроки = СтрРазделить(СтрокаДанных, ";");
		СДокументов.Вставить(ЧастиСтроки[0], 
							Новый Структура("Заголовок,ИмяДляЗапросаНомера", ЧастиСтроки[1], ЧастиСтроки[2]));
	КонецЦикла;
	Возврат СДокументов;
КонецФункции

Функция ПолучитьНомерДокумента(ТипДокумента, П)
	XMLЗапроса = "<?xml version=""1.0"" encoding=""utf-8""?>
	|<args>
	|	<entities-version>" + ПолучитьВерсиюОбъекта(П) + "</entities-version>   
	|	<client-type>BACK</client-type>
	|	<enable-warnings>false</enable-warnings>	
	|	<request-watchdog-check-results>false</request-watchdog-check-results>
	|	<documentType>"+ТипДокумента+"</documentType>
	|</args>";
	
	КаталогВременныхФайлов = КаталогВременныхФайлов();
	HTTPСоединение = Новый HTTPСоединение(П.IIKO_HOST, Число(П.IIKO_PORT));
	ФайлДляЗапроса = КаталогВременныхФайлов+"documentnumber-request.xml";
	
	Запись = Новый ЗаписьТекста(ФайлДляЗапроса, КодировкаТекста.UTF8);
	Запись.Записать(XMLЗапроса);
	Запись.Закрыть();        
	ФайлОтправки = Новый Файл(ФайлДляЗапроса);
	РазмерФайлаОтправки = XMLСтрока(ФайлОтправки.Размер());
	
	Попытка
		ПутьМетода = "/resto/services/document?methodName=getNextDocumentNumber";
		HTTPЗапрос = Новый HTTPЗапрос(ПутьМетода);
		HTTPЗапрос.УстановитьИмяФайлаТела(ФайлДляЗапроса);
		HTTPЗапрос.Заголовки = ПолучитьHTTPЗаголовки(РазмерФайлаОтправки, П);
		HTTPОтвет = HTTPСоединение.ОтправитьДляОбработки(HTTPЗапрос);
		ОбработкаДанных.ЗаписатьВЛог("Данные на запрос номера документа отправлены в Айко.");
		Если HTTPОтвет.КодСостояния = 200 Тогда
			СтрокаЗначимыхПолей = "success,returnValue,resultStatus";
			СписокЗП = ОбработкаДанных.ПолучитьСписокИзСтроки(СтрокаЗначимыхПолей, ",");
			СтруктураОтвета = ОбработатьHTTPОтветIIKO(HTTPОтвет, СписокЗП);
			Если НРег(СтруктураОтвета.success) = "true" Тогда
				Возврат СтруктураОтвета.returnValue;
			Иначе
				Возврат Неопределено;
			КонецЕсли;
		Иначе
			ОбработкаДанных.ЗаписатьВЛог("Сервер вернул ответ, отличный от успешного.");	
		КонецЕсли;
	Исключение
		ОбработкаДанных.ЗаписатьВЛог(ИнформацияОбОшибке().Описание);
	КонецПопытки;
КонецФункции

Функция ПередатьXMLДокументВАйко(XMLДокумента,П) Экспорт

	КаталогВременныхФайлов = КаталогВременныхФайлов();	
	
		HTTPСоединение = Новый HTTPСоединение(П.IIKO_HOST, Число(П.IIKO_PORT));
		ФайлДляЗапроса = КаталогВременныхФайлов+"document-request.xml";
		
		Запись = Новый ЗаписьТекста(ФайлДляЗапроса, КодировкаТекста.UTF8);
		Запись.Записать(XMLДокумента);
		Запись.Закрыть();        
		ФайлОтправки = Новый Файл(ФайлДляЗапроса);
		РазмерФайлаОтправки = XMLСтрока(ФайлОтправки.Размер());
		
		Попытка
			ПутьМетода = "/resto/services/document?methodName=saveOrUpdateDocumentWithValidation";
			HTTPЗапрос = Новый HTTPЗапрос(ПутьМетода);
			HTTPЗапрос.УстановитьИмяФайлаТела(ФайлДляЗапроса);
			HTTPЗапрос.Заголовки = ПолучитьHTTPЗаголовки(РазмерФайлаОтправки, П);
			HTTPОтвет = HTTPСоединение.ОтправитьДляОбработки(HTTPЗапрос);
			ОбработкаДанных.ЗаписатьВЛог("Данные по документу отправлены в Айко.");
			Если HTTPОтвет.КодСостояния = 200 Тогда
				СтрокаЗначимыхПолей = "success,valid,documentNumber,errorString";
				СписокЗП = ОбработкаДанных.ПолучитьСписокИзСтроки(СтрокаЗначимыхПолей, ",");
				Возврат ОбработатьHTTPОтветIIKO(HTTPОтвет, СписокЗП);
			Иначе
				ОбработкаДанных.ЗаписатьВЛог("Сервер вернул ответ, отличный от успешного.");	
			КонецЕсли;
		Исключение
			ОбработкаДанных.ЗаписатьВЛог(ИнформацияОбОшибке().Описание);
		КонецПопытки;
КонецФункции

Функция СформироватьXMLТоваровДокумента(ТипДокумента, Элементы, ИдДокумента)
	й = 0;
	XMLТоваров = "";
	Для Каждого Товар Из Элементы Цикл
		й = й + 1;
		ИдТовара = Новый УникальныйИдентификатор;
		Если ТипДокумента = "IncomingInvoice" ИЛИ
		 	 ТипДокумента = "OutgoingInvoice" ИЛИ
		 	 ТипДокумента = "ReturnedInvoice" Тогда
			 
			XMLТоваров = XMLТоваров + "<i cls=""" + ТипДокумента + "Item"" eid=""" + ИдТовара + """>
|				<invoice cls=""" + ТипДокумента + """ eid=""" + ИдДокумента + """ />										  
|				<store>" + 			Товар.store + "</store>		  
|				<code>" + 			Товар.code + "</code>										  		
|				<price>" + 			Товар.price + "</price>
|				<priceWithoutNds>" + ?(Товар.Свойство("priceWithoutNds"), Товар.priceWithoutNds, Товар.price*(1-Товар.ndsPercent/100)) + "</priceWithoutNds>
|				<sum>" + 			Товар.sum + "</sum>											  		
|				<ndsPercent>" + 	Товар.ndsPercent + "</ndsPercent>										
|				<sumWithoutNds>" + 	Товар.sumWithoutNds + "</sumWithoutNds>								
|				<discountSum>0</discountSum>									
|				<actualAmount>" + 	Товар.amount + "</actualAmount>									
|				<amountUnit>" + 	Товар.amountUnit + "</amountUnit>	
|				<containerId>00000000-0000-0000-0000-000000000000</containerId>	
|				<num>" + й + "</num>													
|				<product>" + 		Товар.product + "</product>			
|				<amount>" + 		Товар.amount + "</amount>												
|				<id>" + ИдТовара + "</id>";
			
			Если ТипДокумента = "IncomingInvoice" Тогда
				XMLТоваров = XMLТоваров + "<supCode /><supProductName />";	
			КонецЕсли;
			
			Если ТипДокумента = "OutgoingInvoice" Тогда
				XMLТоваров = XMLТоваров + "<amountFactor>1</amountFactor>";	
			КонецЕсли;
			
			Если ТипДокумента = "ReturnedInvoice" Тогда
				XMLТоваров = XMLТоваров + "<incomePrice>0</incomePrice>";	
			КонецЕсли;
			
			XMLТоваров = XMLТоваров + "</i>";
		КонецЕсли;
		
		Если ТипДокумента = "InternalTransfer" ИЛИ ТипДокумента = "WriteoffDocument" Тогда
			Если ТипДокумента = "InternalTransfer" Тогда
				ИмяПоляДокумента = "transfer";	
			Иначе
				ИмяПоляДокумента = "writeoffDocument";
			КонецЕсли;
			
			XMLТоваров = XMLТоваров + "<i eid=""" + ИдТовара + """>
|				<"+ИмяПоляДокумента+" eid=""" + ИдДокумента + """ />												  
|				<num>" + й + "</num>										  		  
|				<product>" + 	Товар.product + "</product>	
|				<amountUnit>" + Товар.amountUnit + "</amountUnit>
|				<amount>" + 	Товар.amount + "</amount>
|				<containerId>00000000-0000-0000-0000-000000000000</containerId>
|				<id>" + ИдТовара + "</id>					
|			</i>";	
		КонецЕсли;
		
		Если ТипДокумента = "TreeMenuChangeDocument" Тогда
			XMLТоваров = XMLТоваров + "<i eid=""" + ИдТовара + """>
|				<document eid=""" + ИдДокумента + """ />												  
|				<num>" + й + "</num>										  
|				<department cls=""Department"">" + Товар.department + "</department>		  
|				<product>" + Товар.product + "</product>	
|				<newPrice>" + Товар.newPrice + "</newPrice>
|				<isDishOfDay>false</isDishOfDay>
|				<isFlyerProgram>false</isFlyerProgram>
|				<pricesForCategories />
|				<includeForCategories />
|				<containerId>00000000-0000-0000-0000-000000000000</containerId>
|				<id>" + ИдТовара + "</id>					
|			</i>";	
		КонецЕсли;
	КонецЦикла;
	
	Возврат "<items>"+Символы.ПС+Символы.Таб+Символы.Таб+Символы.Таб+XMLТоваров+Символы.ПС+Символы.Таб+Символы.Таб + "</items>";
КонецФункции

Функция СформироватьXMLДокументаIIKO(СтруктураДокумента, П)
	ИдДокумента = Новый УникальныйИдентификатор;
	
	СДокумента = ПолучитьСоответствиеДокументовIIKO();
	ПоляДокумента = СДокумента.Получить(СтруктураДокумента.ИмяМетода);
	Если ПоляДокумента = Неопределено Тогда
		Возврат Неопределено;
	КонецЕсли;
	
	НомерДокумента = ПолучитьНомерДокумента(ПоляДокумента.ИмяДляЗапросаНомера, П);
	Если НомерДокумента = Неопределено Тогда
		Возврат Неопределено;
	КонецЕсли;
	// Форматная строка дат
	ФСДат = "ДФ=yyyy-MM-ddTHH:mm:ss.000+03.00";
	
	XMLДокумента = "<document cls=""" + СтруктураДокумента.ИмяМетода + """ eid=""" + ИдДокумента + """>	
	|<id>" + 			ИдДокумента + 					"</id>
	|<dateIncoming>" + 	Формат(ПреобразоватьДатуВремя(СтруктураДокумента.dateIncoming), ФСДат) + "</dateIncoming>
	|<documentNumber>" + НомерДокумента + 				"</documentNumber>
	|<comment>" + 		СтруктураДокумента.comment + 	"</comment>
	|" + СформироватьXMLТоваровДокумента(СтруктураДокумента.ИмяМетода, СтруктураДокумента.items, ИдДокумента) + "
	|<status>NEW</status>
	|<revision>0</revision>";
	
	Если СтруктураДокумента.ИмяМетода = "IncomingInvoice" ИЛИ
		 СтруктураДокумента.ИмяМетода = "OutgoingInvoice" ИЛИ
		 СтруктураДокумента.ИмяМетода = "ReturnedInvoice" Тогда
		 
		XMLДокумента = XMLДокумента + 
		"<defaultStore>" + СтруктураДокумента.defaultStore + "</defaultStore>
		|<supplier>" + СтруктураДокумента.supplier + "</supplier>";
		 
		Если СтруктураДокумента.ИмяМетода = "IncomingInvoice" Тогда
			XMLДокумента = XMLДокумента + 
			"<incomingDate>" + Формат(ПреобразоватьДатуВремя(СтруктураДокумента.dateIncoming), ФСДат) + "</incomingDate>
			|<incomingDocumentNumber>" + СтруктураДокумента.incomingDocumentNumber + "</incomingDocumentNumber>
			|<automatic>false</automatic>
			|<boughtAtFront>false</boughtAtFront>
			|<editable>true</editable>
			|<invoice />
			|<manualDueDate>false</manualDueDate>
			|<transportInvoiceNumber />";
		КонецЕсли;
		
		Если СтруктураДокумента.ИмяМетода = "OutgoingInvoice" Тогда
			XMLДокумента = XMLДокумента +
			"<editable>true</editable>
			|<isAutomatic>false</isAutomatic>
			|<isCorrected>false</isCorrected>
			|<manualDueDate>false</manualDueDate>
			|<recalculateSumByCost>false</recalculateSumByCost>";
		КонецЕсли;
		
		Если СтруктураДокумента.ИмяМетода = "ReturnedInvoice" Тогда
			XMLДокумента = XMLДокумента + "<storeCostAffected>false</storeCostAffected>";
		КонецЕсли;
	КонецЕсли;
	
	Если СтруктураДокумента.ИмяМетода = "InternalTransfer" ИЛИ СтруктураДокумента.ИмяМетода = "WriteoffDocument" Тогда
		XMLДокумента = XMLДокумента + 
		"<isAutomatic>false</isAutomatic>
		|<editable>true</editable>";
		
		Если СтруктураДокумента.ИмяМетода = "InternalTransfer" Тогда
			XMLДокумента = XMLДокумента + 
			"<storeFrom>" + СтруктураДокумента.storeFrom + "</storeFrom>
			|<storeTo>" + СтруктураДокумента.storeTo + "</storeTo>";	
		Иначе
			XMLДокумента = XMLДокумента + 
			"<store>" + СтруктураДокумента.store + "</store>
			|<accountTo>" + СтруктураДокумента.accountTo + "</accountTo>";
		КонецЕсли;
	КонецЕсли;
	
	Если СтруктураДокумента.ИмяМетода = "TreeMenuChangeDocument" Тогда
		XMLДокумента = XMLДокумента +
		"<dateTo>" + Формат(ПреобразоватьДатуВремя(СтруктураДокумента.dateTo), ФСДат) + "</dateTo>
		|<shortName>" + СтруктураДокумента.shortName +"</shortName>	
		|<deletePreviousMenu>false</deletePreviousMenu>";
	КонецЕсли;
	
	Возврат XMLДокумента + "</document>";
КонецФункции

Функция СформироватьXMLПакетДокументаIIKO(СтруктураДокумента, П) Экспорт	

	XMLПакет = "<?xml version=""1.0"" encoding=""utf-8""?>
	|<args>
	|	<entities-version>" + ПолучитьВерсиюОбъекта(П) + "</entities-version>   
	|	<client-type>BACK</client-type>
	|	<enable-warnings>false</enable-warnings>	
	|	<request-watchdog-check-results>false</request-watchdog-check-results>
	|	" + СформироватьXMLДокументаIIKO(СтруктураДокумента, П) + "
	|	<suppressWarnings cls=""java.util.ArrayList"" />
	|</args>";
	
	Возврат XMLПакет;	
КонецФункции

Функция ОбработатьHTTPОтветIIKO(Источник, СписокЗначимыхПолей)
	СтруктураОтвета = Новый Структура;
	
	ЧтениеXml = Новый ЧтениеXML();
	ЧтениеXml.УстановитьСтроку(ОбработкаДанных.РасшифроватьGZIP(Источник.ПолучитьТелоКакДвоичныеДанные()));
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