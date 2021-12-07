///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2020, ООО 1С-Софт
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии Attribution 4.0 International (CC BY 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Область СлужебныйПрограммныйИнтерфейс

// Формирует и сохраняет в ИБ план обновления областей данных.
//
// Параметры:
//  ИдентификаторБиблиотеки  - Строка - имя конфигурации или идентификатор библиотеки,
//  ВсеОбработчики    - ТаблицаЗначений - список всех обработчиков обновления,
//  ОбязательныеРазделенныеОбработчики    - ТаблицаЗначений - список обязательных
//    обработчиков обновления с ОбщиеДанные = Ложь,
//  ИсходнаяВерсияИБ - Строка - исходная версия информационной базы,
//  ВерсияМетаданныхИБ - Строка - версия конфигурации (из метаданных).
//
Процедура СформироватьПланОбновленияОбластиДанных(ИдентификаторБиблиотеки, ВсеОбработчики, 
	ОбязательныеРазделенныеОбработчики, ИсходнаяВерсияИБ, ВерсияМетаданныхИБ) Экспорт
	
	Если ОбщегоНазначения.РазделениеВключено()
		И Не ОбщегоНазначения.ДоступноИспользованиеРазделенныхДанных() Тогда
		
		ОбработчикиОбновления = ВсеОбработчики.СкопироватьКолонки(); // ТаблицаЗначений
		Для Каждого СтрокаОбработчика Из ВсеОбработчики Цикл
			// При формировании плана обновлении области, по умолчанию не добавляем обязательные (*) обработчики.
			Если СтрокаОбработчика.Версия = "*" Тогда
				Продолжить;
			КонецЕсли;
			ЗаполнитьЗначенияСвойств(ОбработчикиОбновления.Добавить(), СтрокаОбработчика);
		КонецЦикла;
		
		Для Каждого ОбязательныйОбработчик Из ОбязательныеРазделенныеОбработчики Цикл
			СтрокаОбработчика = ОбработчикиОбновления.Добавить();
			ЗаполнитьЗначенияСвойств(СтрокаОбработчика, ОбязательныйОбработчик);
			СтрокаОбработчика.Версия = "*";
		КонецЦикла;
		
		ПараметрыОтбора = ОбновлениеИнформационнойБазыСлужебный.ПараметрыОтбораОбработчиков();
		ПараметрыОтбора.ПолучатьРазделенные = Истина;
		ПланОбновленияОбластиДанных = ОбновлениеИнформационнойБазыСлужебный.ОбработчикиОбновленияВИнтервале(
			ОбработчикиОбновления, ИсходнаяВерсияИБ, ВерсияМетаданныхИБ, ПараметрыОтбора);
			
		ОписаниеПлана = Новый Структура;
		ОписаниеПлана.Вставить("ВерсияС", ИсходнаяВерсияИБ);
		ОписаниеПлана.Вставить("ВерсияНа", ВерсияМетаданныхИБ);
		ОписаниеПлана.Вставить("План", ПланОбновленияОбластиДанных);
		
		МенеджерЗаписи = РегистрыСведений.ВерсииПодсистем.СоздатьМенеджерЗаписи();
		МенеджерЗаписи.ИмяПодсистемы = ИдентификаторБиблиотеки;
		
		Блокировка = Новый БлокировкаДанных;
		ЭлементБлокировки = Блокировка.Добавить("РегистрСведений.ВерсииПодсистем");
		ЭлементБлокировки.УстановитьЗначение("ИмяПодсистемы", ИдентификаторБиблиотеки);
		
		НачатьТранзакцию();
		Попытка
			Блокировка.Заблокировать();
			
			МенеджерЗаписи.Прочитать();
			МенеджерЗаписи.ПланОбновления = Новый ХранилищеЗначения(ОписаниеПлана);
			МенеджерЗаписи.Записать();
			
			ЗафиксироватьТранзакцию();
		Исключение
			ОтменитьТранзакцию();
			ВызватьИсключение;
		КонецПопытки;
		
		ПланОбновленияПустой = ПланОбновленияОбластиДанных.Строки.Количество() = 0;
		
		Если ИдентификаторБиблиотеки = Метаданные.Имя Тогда
			// Версию конфигурации можно устанавливать только если ни какие библиотеки не требует обновления
			// иначе механизм обновления в областях не будет запущен и библиотеки останутся не обновленными.
			ПланОбновленияПустой = Ложь;
			
			// Проверка всех планов на пустоту.
			Библиотеки = Новый ТаблицаЗначений;
			Библиотеки.Колонки.Добавить("Имя", Метаданные.РегистрыСведений.ВерсииПодсистем.Измерения.ИмяПодсистемы.Тип);
			Библиотеки.Колонки.Добавить("Версия", Метаданные.РегистрыСведений.ВерсииПодсистем.Ресурсы.Версия.Тип);
			
			ОписанияПодсистем  = СтандартныеПодсистемыПовтИсп.ОписанияПодсистем();
			Для каждого ИмяПодсистемы Из ОписанияПодсистем.Порядок Цикл
				ОписаниеПодсистемы = ОписанияПодсистем.ПоИменам.Получить(ИмяПодсистемы);
				Если НЕ ЗначениеЗаполнено(ОписаниеПодсистемы.ОсновнойСерверныйМодуль) Тогда
					// У библиотеки нет модуля - нет и обработчиков обновления.
					Продолжить;
				КонецЕсли;
				
				СтрокаБиблиотеки = Библиотеки.Добавить();
				СтрокаБиблиотеки.Имя = ОписаниеПодсистемы.Имя;
				СтрокаБиблиотеки.Версия = ОписаниеПодсистемы.Версия;
			КонецЦикла;
			
			Запрос = Новый Запрос;
			Запрос.УстановитьПараметр("Библиотеки", Библиотеки);
			Запрос.Текст =
				"ВЫБРАТЬ
				|	Библиотеки.Имя КАК Имя,
				|	Библиотеки.Версия КАК Версия
				|ПОМЕСТИТЬ Библиотеки
				|ИЗ
				|	&Библиотеки КАК Библиотеки
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|ВЫБРАТЬ
				|	Библиотеки.Имя КАК Имя,
				|	Библиотеки.Версия КАК Версия,
				|	ВерсииПодсистем.ПланОбновления КАК ПланОбновления,
				|	ВЫБОР
				|		КОГДА ВерсииПодсистем.Версия = Библиотеки.Версия
				|			ТОГДА ИСТИНА
				|		ИНАЧЕ ЛОЖЬ
				|	КОНЕЦ КАК Обновлена
				|ИЗ
				|	Библиотеки КАК Библиотеки
				|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.ВерсииПодсистем КАК ВерсииПодсистем
				|		ПО Библиотеки.Имя = ВерсииПодсистем.ИмяПодсистемы";
				
			НачатьТранзакцию();
			Попытка
				Блокировка = Новый БлокировкаДанных;
				ЭлементБлокировки = Блокировка.Добавить("РегистрСведений.ВерсииПодсистем");
				ЭлементБлокировки.Режим = РежимБлокировкиДанных.Разделяемый;
				Блокировка.Заблокировать();
				
				Результат = Запрос.Выполнить();
				
				ЗафиксироватьТранзакцию();
			Исключение
				ОтменитьТранзакцию();
				ВызватьИсключение;
			КонецПопытки;
			
			Выборка = Результат.Выбрать();
			Пока Выборка.Следующий() Цикл
				
				Если НЕ Выборка.Обновлена Тогда
					ПланОбновленияПустой = Ложь;
					
					ШаблонКомментария = НСтр("ru = 'Обновление версии конфигурации было выполнено до обновления версии библиотеки %1'");
					ТекстКомментария = СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(ШаблонКомментария, Выборка.Имя);
					ЗаписьЖурналаРегистрации(
						ОбновлениеИнформационнойБазы.СобытиеЖурналаРегистрации(),
						УровеньЖурналаРегистрации.Ошибка,
						,
						,
						ТекстКомментария);
					
					Прервать;
				КонецЕсли;
				
				Если Выборка.ПланОбновления = Неопределено Тогда
					ОписаниеПланаОбновленияБиблиотеки = Неопределено;
				Иначе
					ОписаниеПланаОбновленияБиблиотеки = Выборка.ПланОбновления.Получить();
				КонецЕсли;
				
				Если ОписаниеПланаОбновленияБиблиотеки = Неопределено Тогда
					ПланОбновленияПустой = Ложь;
					
					ШаблонКомментария = НСтр("ru = 'Не существует план обновления библиотеки %1'");
					ТекстКомментария = СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(ШаблонКомментария, Выборка.Имя);
					ЗаписьЖурналаРегистрации(
						ОбновлениеИнформационнойБазы.СобытиеЖурналаРегистрации(),
						УровеньЖурналаРегистрации.Ошибка,
						,
						,
						ТекстКомментария);
					
					Прервать;
				КонецЕсли;
				
				Если ОписаниеПланаОбновленияБиблиотеки.ВерсияНа <> Выборка.Версия Тогда
					ПланОбновленияПустой = Ложь;
					
					ШаблонКомментария = НСтр("ru = 'Обнаружен некорректный план обновления библиотеки %1
						|Требуется план обновления на версию %2, найден план для обновления на версию %3'");
					ТекстКомментария = СтроковыеФункцииКлиентСервер.ПодставитьПараметрыВСтроку(ШаблонКомментария, Выборка.Имя, Строка(ОписаниеПланаОбновленияБиблиотеки.ВерсияНа), Строка(Выборка.Версия));
					ЗаписьЖурналаРегистрации(
						ОбновлениеИнформационнойБазы.СобытиеЖурналаРегистрации(),
						УровеньЖурналаРегистрации.Ошибка,
						,
						,
						ТекстКомментария);
					
					Прервать;
				КонецЕсли;
				
				Если ОписаниеПланаОбновленияБиблиотеки.План.Строки.Количество() > 0 Тогда
					ПланОбновленияПустой = Ложь;
					Прервать;
				КонецЕсли;
				
			КонецЦикла;
		КонецЕсли;
		
		Если ПланОбновленияПустой Тогда
			
			// План обновления не содержит разделенных оперативных или монопольных обработчиков.
			// Выполняется проверка наличия разделенных отложенных обработчиков.
			ПараметрыОтбораОтложенных = ОбновлениеИнформационнойБазыСлужебный.ПараметрыОтбораОбработчиков();
			ПараметрыОтбораОтложенных.ПолучатьРазделенные = Истина;
			ПараметрыОтбораОтложенных.РежимОбновления = "Отложенно";
			
			ОтложенныеОбработчики = ОбновлениеИнформационнойБазыСлужебный.ОбработчикиОбновленияВИнтервале(ОбработчикиОбновления, ИсходнаяВерсияИБ, ВерсияМетаданныхИБ, ПараметрыОтбораОтложенных);
			
			// Нет разделенных отложенных обработчиков, установить новую версию библиотеки.
			Если ОтложенныеОбработчики.Строки.Количество() = 0 Тогда
			
				УстановитьВерсиюВсехОбластейДанных(ИдентификаторБиблиотеки, ИсходнаяВерсияИБ, ВерсияМетаданныхИБ);
				
			КонецЕсли;
			
		КонецЕсли;
		
	КонецЕсли;
	
КонецПроцедуры

// Блокирует запись в регистре сведений ВерсииПодсистемОбластейДанных, которая соответствует текущей области данных,
// и возвращает ключ этой записи.
//
// Возвращаемое значение:
//   РегистрСведенийКлючЗаписи
//
Функция ЗаблокироватьВерсииОбластиДанных() Экспорт
	
	КлючЗаписи = Неопределено;
	Если ОбщегоНазначения.РазделениеВключено() Тогда
		
		Если ОбщегоНазначения.ДоступноИспользованиеРазделенныхДанных() Тогда
			УстановитьПривилегированныйРежим(Истина);
		КонецЕсли;
		
		КлючЗаписи = КлючЗаписиВерсийПодсистем();
		
	КонецЕсли;
	
	Если КлючЗаписи <> Неопределено Тогда
		Попытка
			ЗаблокироватьДанныеДляРедактирования(КлючЗаписи);
		Исключение
			ЗаписьЖурналаРегистрации(ОбновлениеИнформационнойБазы.СобытиеЖурналаРегистрации() + "." 
				+ НСтр("ru = 'Обновление области данных'", ОбщегоНазначения.КодОсновногоЯзыка()),
				УровеньЖурналаРегистрации.Ошибка,,,
				ПодробноеПредставлениеОшибки(ИнформацияОбОшибке()));
			ВызватьИсключение(НСтр("ru = 'Ошибка обновления области данных. Запись версий области данных заблокирована.'"));
		КонецПопытки;
	КонецЕсли;
	Возврат КлючЗаписи;
	
КонецФункции

// Разблокирует запись в регистре сведений ВерсииПодсистемОбластейДанных.
//
// Параметры: 
//   КлючЗаписи - РегистрСведенийКлючЗаписи.
//
Процедура РазблокироватьВерсииОбластиДанных(КлючЗаписи) Экспорт
	
	Если КлючЗаписи <> Неопределено Тогда
		РазблокироватьДанныеДляРедактирования(КлючЗаписи);
	КонецЕсли;
	
КонецПроцедуры

Функция ЗапланированныйМоментЗапускаОбновленияОбласти() Экспорт
	
	ОтборЗаданий = Новый Структура;
	ОтборЗаданий.Вставить("ИмяМетода", "ОбновлениеИнформационнойБазыСлужебныйВМоделиСервиса.ВыполнитьОбновлениеТекущейОбластиДанных");
	ЗаданияВыполнитьОбновлениеТекущейОбластиДанных = РегламентныеЗаданияСервер.НайтиЗадания(ОтборЗаданий);
	Если ЗаданияВыполнитьОбновлениеТекущейОбластиДанных.Количество() > 0 Тогда
		ЗапланированныйМоментЗапуска = (ЗаданияВыполнитьОбновлениеТекущейОбластиДанных[0].ЗапланированныйМоментЗапуска - Дата(1, 1, 1)) * 1000 + ЗаданияВыполнитьОбновлениеТекущейОбластиДанных[0].Миллисекунды;
	Иначе
		ЗапланированныйМоментЗапуска = ТекущаяУниверсальнаяДатаВМиллисекундах();
	КонецЕсли;
	
	Возврат ЗапланированныйМоментЗапуска;
	
КонецФункции

Функция ОбластиОбновленныеНаВерсию(ИмяПодсистемы, Версия) Экспорт
	Запрос = Новый Запрос;
	Запрос.УстановитьПараметр("ИмяПодсистемы", ИмяПодсистемы);
	Запрос.УстановитьПараметр("Версия", Версия);
	Запрос.Текст =
		"ВЫБРАТЬ
		|	ВерсииПодсистемОбластейДанных.ОбластьДанныхВспомогательныеДанные КАК ОбластьДанных
		|ИЗ
		|	РегистрСведений.ВерсииПодсистемОбластейДанных КАК ВерсииПодсистемОбластейДанных
		|ГДЕ
		|	ВерсииПодсистемОбластейДанных.ИмяПодсистемы = &ИмяПодсистемы
		|	И ВерсииПодсистемОбластейДанных.Версия = &Версия";
	ОбластиОбновленныеНаВерсию = Запрос.Выполнить().Выгрузить().ВыгрузитьКолонку("ОбластьДанных");
	
	Возврат ОбластиОбновленныеНаВерсию;
КонецФункции

#Область ОбработчикиСобытийПодсистемКонфигурации

// См. ОбновлениеИнформационнойБазыБСП.ПередОбновлениемИнформационнойБазы.
Процедура ПередОбновлениемИнформационнойБазы() Экспорт
	
	Если ОбщегоНазначения.РазделениеВключено()
		И ОбщегоНазначения.ДоступноИспользованиеРазделенныхДанных() Тогда
		
		ВерсияОбщихДанных = ОбновлениеИнформационнойБазыСлужебный.ВерсияИБ(Метаданные.Имя, Истина);
		Если ОбновлениеИнформационнойБазыСлужебный.НеобходимоВыполнитьОбновление(Метаданные.Версия, ВерсияОбщихДанных) Тогда
			Сообщение = НСтр("ru = 'Не выполнена общая часть обновления информационной базы.
				|Обратитесь к администратору.'");
			ЗаписьЖурналаРегистрации(ОбновлениеИнформационнойБазы.СобытиеЖурналаРегистрации(), УровеньЖурналаРегистрации.Ошибка,,, Сообщение);
			ВызватьИсключение Сообщение;
		КонецЕсли;
	КонецЕсли;
	
КонецПроцедуры	

// Только для внутреннего использования.
Процедура ПриОпределенииВерсииИБ(Знач ИдентификаторБиблиотеки, Знач ПолучитьВерсиюОбщихДанных, СтандартнаяОбработка, ВерсияИБ) Экспорт
	
	Если ОбщегоНазначения.РазделениеВключено()
		И ОбщегоНазначения.ДоступноИспользованиеРазделенныхДанных()
		И Не ПолучитьВерсиюОбщихДанных Тогда
		
		СтандартнаяОбработка = Ложь;
		МодульРаботаВМоделиСервиса = ОбщегоНазначения.ОбщийМодуль("РаботаВМоделиСервиса");
		
		ТекстЗапроса = 
		"ВЫБРАТЬ
		|	ВерсииПодсистемОбластейДанных.Версия
		|ИЗ
		|	РегистрСведений.ВерсииПодсистемОбластейДанных КАК ВерсииПодсистемОбластейДанных
		|ГДЕ
		|	ВерсииПодсистемОбластейДанных.ИмяПодсистемы = &ИмяПодсистемы
		|	И ВерсииПодсистемОбластейДанных.ОбластьДанныхВспомогательныеДанные = &ОбластьДанныхВспомогательныеДанные";
		Запрос = Новый Запрос(ТекстЗапроса);
		Запрос.УстановитьПараметр("ИмяПодсистемы", ИдентификаторБиблиотеки);
		Запрос.УстановитьПараметр("ОбластьДанныхВспомогательныеДанные", МодульРаботаВМоделиСервиса.ЗначениеРазделителяСеанса());
		ТаблицаЗначений = Запрос.Выполнить().Выгрузить();
		ВерсияИБ = "";
		Если ТаблицаЗначений.Количество() > 0 Тогда
			ВерсияИБ = СокрЛП(ТаблицаЗначений[0].Версия);
		КонецЕсли;
		
	КонецЕсли;
	
КонецПроцедуры

// Только для внутреннего использования.
Процедура ПриОпределенииПервогоВходаВОбластьДанных(СтандартнаяОбработка, Результат) Экспорт
	
	Если ОбщегоНазначения.РазделениеВключено()
		И ОбщегоНазначения.ДоступноИспользованиеРазделенныхДанных() Тогда
		
		СтандартнаяОбработка = Ложь;
		МодульРаботаВМоделиСервиса = ОбщегоНазначения.ОбщийМодуль("РаботаВМоделиСервиса");
		
		ТекстЗапроса = 
		"ВЫБРАТЬ ПЕРВЫЕ 1
		|	1
		|ИЗ
		|	РегистрСведений.ВерсииПодсистемОбластейДанных КАК ВерсииПодсистемОбластейДанных
		|ГДЕ
		|	ВерсииПодсистемОбластейДанных.ОбластьДанныхВспомогательныеДанные = &ОбластьДанныхВспомогательныеДанные";
		Запрос = Новый Запрос(ТекстЗапроса);
		Запрос.УстановитьПараметр("ОбластьДанныхВспомогательныеДанные", МодульРаботаВМоделиСервиса.ЗначениеРазделителяСеанса());
		Результат = Запрос.Выполнить().Пустой();
		
	КонецЕсли;
	
КонецПроцедуры

// Только для внутреннего использования.
Процедура ПриУстановкеВерсииИБ(Знач ИдентификаторБиблиотеки, Знач НомерВерсии, СтандартнаяОбработка) Экспорт
	
	Если ОбщегоНазначения.РазделениеВключено()
		И ОбщегоНазначения.ДоступноИспользованиеРазделенныхДанных() Тогда
		
		СтандартнаяОбработка = Ложь;
		МодульРаботаВМоделиСервиса = ОбщегоНазначения.ОбщийМодуль("РаботаВМоделиСервиса");
		
		ОбластьДанных = МодульРаботаВМоделиСервиса.ЗначениеРазделителяСеанса();
		
		МенеджерЗаписи = РегистрыСведений.ВерсииПодсистемОбластейДанных.СоздатьМенеджерЗаписи();
		МенеджерЗаписи.ОбластьДанныхВспомогательныеДанные = ОбластьДанных;
		МенеджерЗаписи.ИмяПодсистемы = ИдентификаторБиблиотеки;
		МенеджерЗаписи.Версия = НомерВерсии;
		МенеджерЗаписи.Записать();
		
	КонецЕсли;
	
КонецПроцедуры

// Только для внутреннего использования.
Процедура ПриПроверкеРегистрацииОтложенныхОбработчиковОбновления(РегистрацияВыполнена, СтандартнаяОбработка) Экспорт
	
	Если ОбщегоНазначения.РазделениеВключено()
		И ОбщегоНазначения.ДоступноИспользованиеРазделенныхДанных() Тогда
		
		СтандартнаяОбработка = Ложь;
		МодульРаботаВМоделиСервиса = ОбщегоНазначения.ОбщийМодуль("РаботаВМоделиСервиса");
		
		Запрос = Новый Запрос;
		Запрос.Текст =
			"ВЫБРАТЬ
			|	ВерсииПодсистемОбластейДанных.ИмяПодсистемы
			|ИЗ
			|	РегистрСведений.ВерсииПодсистемОбластейДанных КАК ВерсииПодсистемОбластейДанных
			|ГДЕ
			|	НЕ ВерсииПодсистемОбластейДанных.ВыполненаРегистрацияОтложенныхОбработчиков
			|	И ВерсииПодсистемОбластейДанных.ОбластьДанныхВспомогательныеДанные = &ОбластьДанныхВспомогательныеДанные";
			
		Запрос.УстановитьПараметр("ОбластьДанныхВспомогательныеДанные", МодульРаботаВМоделиСервиса.ЗначениеРазделителяСеанса());
		Результат = Запрос.Выполнить().Выгрузить();
		РегистрацияВыполнена = (Результат.Количество() = 0);
	КонецЕсли;
	
КонецПроцедуры

// Только для внутреннего использования.
Процедура ПриОтметкеРегистрацииОтложенныхОбработчиковОбновления(ИмяПодсистемы, Значение, СтандартнаяОбработка) Экспорт
	
	Если ОбщегоНазначения.РазделениеВключено()
		И ОбщегоНазначения.ДоступноИспользованиеРазделенныхДанных() Тогда
		
		СтандартнаяОбработка = Ложь;
		
		НаборЗаписей = РегистрыСведений.ВерсииПодсистемОбластейДанных.СоздатьНаборЗаписей();
		Если ИмяПодсистемы <> Неопределено Тогда
			НаборЗаписей.Отбор.ИмяПодсистемы.Установить(ИмяПодсистемы);
		КонецЕсли;
		НаборЗаписей.Прочитать();
		
		Если НаборЗаписей.Количество() = 0 Тогда
			Возврат;
		КонецЕсли;
		
		Для Каждого ЗаписьРегистра Из НаборЗаписей Цикл
			ЗаписьРегистра.ВыполненаРегистрацияОтложенныхОбработчиков = Значение;
		КонецЦикла;
		НаборЗаписей.Записать();
		
	КонецЕсли;
	
КонецПроцедуры

// Только для внутреннего использования.
Процедура ПриОтправкеВерсийПодсистем(ЭлементДанных, ОтправкаЭлемента, Знач СозданиеНачальногоОбраза, СтандартнаяОбработка) Экспорт
	
	Если Не ОбщегоНазначения.РазделениеВключено()
		И ОбщегоНазначения.ДоступноИспользованиеРазделенныхДанных() Тогда
		Возврат;
	КонецЕсли;
	
	СтандартнаяОбработка = Ложь;
	
	Если ОтправкаЭлемента = ОтправкаЭлементаДанных.Удалить
		ИЛИ ОтправкаЭлемента = ОтправкаЭлементаДанных.Игнорировать Тогда
		
		// Стандартную обработку не переопределяем.
		
	ИначеЕсли ТипЗнч(ЭлементДанных) = Тип("РегистрСведенийНаборЗаписей.ВерсииПодсистем") Тогда
		
		Если СозданиеНачальногоОбраза Тогда
			
			Для Каждого СтрокаНабора Из ЭлементДанных Цикл
				
				ТекстЗапроса =
				"ВЫБРАТЬ
				|	ВерсииПодсистемОбластейДанных.Версия КАК Версия
				|ИЗ
				|	РегистрСведений.ВерсииПодсистемОбластейДанных КАК ВерсииПодсистемОбластейДанных
				|ГДЕ
				|	ВерсииПодсистемОбластейДанных.ИмяПодсистемы = &ИмяПодсистемы";
				
				Запрос = Новый Запрос;
				Запрос.УстановитьПараметр("ИмяПодсистемы", СтрокаНабора.ИмяПодсистемы);
				Запрос.Текст = ТекстЗапроса;
				
				Выборка = Запрос.Выполнить().Выбрать();
				
				Если Выборка.Следующий() Тогда
					
					СтрокаНабора.Версия = Выборка.Версия;
					
				Иначе
					
					СтрокаНабора.Версия = "";
					
				КонецЕсли;
				
			КонецЦикла;
			
		Иначе
			
			// Выгрузку регистра выполняем только при создании начального образа.
			ОтправкаЭлемента = ОтправкаЭлементаДанных.Игнорировать;
			
		КонецЕсли;
		
	КонецЕсли;
	
КонецПроцедуры

// См. ОчередьЗаданийПереопределяемый.ПриОпределенииПсевдонимовОбработчиков.
Процедура ПриОпределенииПсевдонимовОбработчиков(СоответствиеИменПсевдонимам) Экспорт
	
	СоответствиеИменПсевдонимам.Вставить("ОбновлениеИнформационнойБазыСлужебныйВМоделиСервиса.ВыполнитьОбновлениеТекущейОбластиДанных");
	
КонецПроцедуры

// См. ВыгрузкаЗагрузкаДанныхПереопределяемый.ПриЗаполненииТиповИсключаемыхИзВыгрузкиЗагрузки.
Процедура ПриЗаполненииТиповИсключаемыхИзВыгрузкиЗагрузки(Типы) Экспорт
	
	Типы.Добавить(Метаданные.РегистрыСведений.ВерсииПодсистемОбластейДанных);
	
КонецПроцедуры

// См. ОчередьЗаданийПереопределяемый.ПриОпределенииИспользованияРегламентныхЗаданий.
Процедура ПриОпределенииИспользованияРегламентныхЗаданий(ТаблицаИспользования) Экспорт
	
	НоваяСтрока = ТаблицаИспользования.Добавить();
	НоваяСтрока.РегламентноеЗадание = "ОбновлениеОбластейДанных";
	НоваяСтрока.Использование       = Истина;
	
КонецПроцедуры

// См. ОбновлениеИнформационнойБазыБСП.ПослеОбновленияИнформационнойБазы.
Процедура ПослеОбновленияИнформационнойБазы(Знач ПредыдущаяВерсия, Знач ТекущаяВерсия,
		Знач ВыполненныеОбработчики, ВыводитьОписаниеОбновлений, МонопольныйРежим) Экспорт
	
	Если ОбщегоНазначения.ДоступноИспользованиеРазделенныхДанных() Тогда
		
		ПараметрыБлокировки = СоединенияИБ.ПолучитьБлокировкуСеансовОбластиДанных();
		Если НЕ ПараметрыБлокировки.Установлена Тогда
			Возврат;
		КонецЕсли;
		ПараметрыБлокировки.Установлена = Ложь;
		СоединенияИБ.УстановитьБлокировкуСеансовОбластиДанных(ПараметрыБлокировки);
		Возврат;
		
	КонецЕсли;
	
	Если Не МонопольныйРежим() Тогда
		ОбъектМетаданных = Метаданные.РегламентныеЗадания.Найти("ОбновлениеОбластейДанных");
		Задание = РегламентныеЗаданияСервер.ПолучитьРегламентноеЗадание(ОбъектМетаданных);
		// АПК:280-выкл обработка исключения не требуется
		Попытка
			ФоновыеЗадания.Выполнить(Задание.Метаданные.ИмяМетода, , Задание.Ключ, Задание.Наименование);
		Исключение
			// Значит задание уже запущено.
			// Обработка исключения не требуется.
		КонецПопытки;
		// АПК:280-вкл
	КонецЕсли;
	
КонецПроцедуры

// См. ВыгрузкаЗагрузкаДанныхПереопределяемый.ПослеЗагрузкиДанных.
Процедура ПослеЗагрузкиДанных(Контейнер) Экспорт
	
	Сведения = ОбновлениеИнформационнойБазыСлужебный.СведенияОбОбновленииИнформационнойБазы();
	ОбновлениеЗавершено = Сведения.ОтложенноеОбновлениеЗавершеноУспешно;
	Если ОбновлениеЗавершено <> Истина Тогда
		ОбновлениеИнформационнойБазыСлужебный.ПеререгистрироватьДанныеДляОтложенногоОбновления();
	КонецЕсли;
	ОбновлениеИнформационнойБазыСлужебный.ОтметитьРегистрациюОтложенныхОбработчиковОбновления(, Истина);
	
КонецПроцедуры

// Вызывается перед выгрузкой данных.
//
// Параметры:
//  Контейнер - ОбработкаОбъект.ВыгрузкаЗагрузкаДанныхМенеджерКонтейнера - менеджер
//    контейнера, используемый в процессе выгрузи данных. Подробнее см. комментарий
//    к программному интерфейсу обработки ВыгрузкаЗагрузкаДанныхМенеджерКонтейнера.
//
Процедура ПередВыгрузкойДанных(Контейнер) Экспорт
	
	Если Не ОбщегоНазначения.ПодсистемаСуществует("ТехнологияСервиса.ВыгрузкаЗагрузкаДанных") Тогда
		Возврат;
	КонецЕсли;
	
	ИмяФайла = Контейнер.СоздатьПроизвольныйФайл("xml", ТипДанныхДляВыгрузкиЗагрузкиВерсийПодсистем());
	ВерсииПодсистем = Новый Структура();
	
	ОписанияПодсистем = СтандартныеПодсистемыПовтИсп.ОписанияПодсистем().ПоИменам;
	Для Каждого ОписаниеПодсистемы Из ОписанияПодсистем Цикл
		ВерсииПодсистем.Вставить(ОписаниеПодсистемы.Ключ, ОбновлениеИнформационнойБазы.ВерсияИБ(ОписаниеПодсистемы.Ключ));
	КонецЦикла;
	
	МодульВыгрузкаЗагрузкаДанных = ОбщегоНазначения.ОбщийМодуль("ВыгрузкаЗагрузкаДанных");
	МодульВыгрузкаЗагрузкаДанных.ЗаписатьОбъектВФайл(ВерсииПодсистем, ИмяФайла);
	
	Контейнер.УстановитьКоличествоОбъектов(ИмяФайла, ВерсииПодсистем.Количество());
	
КонецПроцедуры

// Вызывается перед загрузкой данных.
//
// Параметры:
//  Контейнер - ОбработкаОбъект.ВыгрузкаЗагрузкаДанныхМенеджерКонтейнера - менеджер
//    контейнера, используемый в процессе загрузки данных. Подробнее см. комментарий
//    к программному интерфейсу обработки ВыгрузкаЗагрузкаДанныхМенеджерКонтейнера.
//
Процедура ПередЗагрузкойДанных(Контейнер) Экспорт
	
	Если Не ОбщегоНазначения.ПодсистемаСуществует("ТехнологияСервиса.ВыгрузкаЗагрузкаДанных") Тогда
		Возврат;
	КонецЕсли;
	
	ИмяФайла = Контейнер.ПолучитьПроизвольныйФайл(ТипДанныхДляВыгрузкиЗагрузкиВерсийПодсистем());
	
	МодульВыгрузкаЗагрузкаДанных = ОбщегоНазначения.ОбщийМодуль("ВыгрузкаЗагрузкаДанных");
	ВерсииПодсистем = МодульВыгрузкаЗагрузкаДанных.ПрочитатьОбъектИзФайла(ИмяФайла);
	
	НачатьТранзакцию();
	
	Попытка
		
		Для Каждого ВерсияПодсистемы Из ВерсииПодсистем Цикл
			ОбновлениеИнформационнойБазыСлужебный.УстановитьВерсиюИБ(ВерсияПодсистемы.Ключ, ВерсияПодсистемы.Значение, (ВерсияПодсистемы.Ключ = Метаданные.Имя));
			ПриОтметкеРегистрацииОтложенныхОбработчиковОбновления(ВерсияПодсистемы.Ключ, Истина, Истина);
		КонецЦикла;
		
		ЗафиксироватьТранзакцию();
		
	Исключение
		
		ОтменитьТранзакцию();
		ВызватьИсключение;
		
	КонецПопытки;
	
КонецПроцедуры

// См. ИнтеграцияПодсистемБСП.ПриПолученииПриоритетаОбновления.
Процедура ПриПолученииПриоритетаОбновления(Приоритет) Экспорт
	Приоритет = Константы.ПриоритетОбновленияВОбластяхДанных.Получить();
КонецПроцедуры

#КонецОбласти

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

#Область ОбработчикиОбновленияИнформационнойБазы

Функция ТипДанныхДляВыгрузкиЗагрузкиВерсийПодсистем()
	
	Возврат "1cfresh\ApplicationData\SubstemVersions";
	
КонецФункции

#КонецОбласти

#Область ОбновлениеОбластейДанных

// Возвращает ключ записи для регистра сведений ВерсииПодсистемОбластейДанных.
//
// Возвращаемое значение: 
//   РегистрСведенийКлючЗаписи.ВерсииПодсистемОбластейДанных - ключ записи регистра сведений.
//
Функция КлючЗаписиВерсийПодсистем()
	
	ЗначенияКлюча = Новый Структура;
	Если ОбщегоНазначения.РазделениеВключено()
		И ОбщегоНазначения.ДоступноИспользованиеРазделенныхДанных() Тогда
		
		МодульРаботаВМоделиСервиса = ОбщегоНазначения.ОбщийМодуль("РаботаВМоделиСервиса");
		
		ЗначенияКлюча.Вставить("ОбластьДанныхВспомогательныеДанные", МодульРаботаВМоделиСервиса.ЗначениеРазделителяСеанса());
		ЗначенияКлюча.Вставить("ИмяПодсистемы", "");
		КлючЗаписи = МодульРаботаВМоделиСервиса.СоздатьКлючЗаписиРегистраСведенийВспомогательныхДанных(
			РегистрыСведений.ВерсииПодсистемОбластейДанных, ЗначенияКлюча);
		
	КонецЕсли;
	
	Возврат КлючЗаписи;
	
КонецФункции


// Выбирает все области данных с неактуальными версиями
// и при необходимости формирует фоновые задания по обновлению
// версии в них.
//
Процедура ЗапланироватьОбновлениеОбластейДанных()
	
	Если НЕ ОбщегоНазначения.РазделениеВключено()
		Или Не ОбщегоНазначения.ПодсистемаСуществует("ТехнологияСервиса.ОчередьЗаданий") Тогда
		Возврат;
	КонецЕсли;
	
	УстановитьПривилегированныйРежим(Истина);
	
	МодульОчередьЗаданий = ОбщегоНазначения.ОбщийМодуль("ОчередьЗаданий");
	МодульРаботаВМоделиСервиса = ОбщегоНазначения.ОбщийМодуль("РаботаВМоделиСервиса");
	
	ВерсияМетаданных = Метаданные.Версия;
	Если ПустаяСтрока(ВерсияМетаданных) Тогда
		Возврат;
	КонецЕсли;
	
	ВерсияОбщихДанных = ОбновлениеИнформационнойБазыСлужебный.ВерсияИБ(Метаданные.Имя, Истина);
	Если ОбновлениеИнформационнойБазыСлужебный.НеобходимоВыполнитьОбновление(ВерсияМетаданных, ВерсияОбщихДанных) Тогда
		// Не выполнено обновление общих данных смысла планировать
		// обновление областей нет.
		Возврат;
	КонецЕсли;
	
	Запрос = Новый Запрос;
	Запрос.Текст =
	"ВЫБРАТЬ
	|	ОбластиДанных.ОбластьДанныхВспомогательныеДанные КАК ОбластьДанных
	|ИЗ
	|	РегистрСведений.ОбластиДанных КАК ОбластиДанных
	|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.ВерсииПодсистемОбластейДанных КАК ВерсииПодсистемОбластейДанных
	|		ПО ОбластиДанных.ОбластьДанныхВспомогательныеДанные = ВерсииПодсистемОбластейДанных.ОбластьДанныхВспомогательныеДанные
	|			И (ВерсииПодсистемОбластейДанных.ИмяПодсистемы = &ИмяПодсистемы)
	|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.РейтингАктивностиОбластейДанных КАК РейтингАктивностиОбластейДанных
	|		ПО ОбластиДанных.ОбластьДанныхВспомогательныеДанные = РейтингАктивностиОбластейДанных.ОбластьДанныхВспомогательныеДанные
	|ГДЕ
	|	ОбластиДанных.Статус В (ЗНАЧЕНИЕ(Перечисление.СтатусыОбластейДанных.Используется))
	|	И ЕСТЬNULL(ВерсииПодсистемОбластейДанных.Версия, """") <> &Версия
	|
	|УПОРЯДОЧИТЬ ПО
	|	ЕСТЬNULL(РейтингАктивностиОбластейДанных.Рейтинг, 9999999),
	|	ОбластьДанных";
	Запрос.УстановитьПараметр("ИмяПодсистемы", Метаданные.Имя);
	Запрос.УстановитьПараметр("Версия", ВерсияМетаданных);
	Результат = ВыполнитьЗапросВнеТранзакции(Запрос);
	Если Результат.Пустой() Тогда // Предварительное чтение, возможно с проявлениями грязного чтения.
		Возврат;
	КонецЕсли;
	
	Запрос = Новый Запрос;
	Запрос.Текст =
	"ВЫБРАТЬ ПЕРВЫЕ 1
	|	ВерсииПодсистемОбластейДанных.Версия КАК Версия
	|ИЗ
	|	РегистрСведений.ВерсииПодсистемОбластейДанных КАК ВерсииПодсистемОбластейДанных
	|ГДЕ
	|	ВерсииПодсистемОбластейДанных.ОбластьДанныхВспомогательныеДанные = &ОбластьДанных
	|	И ВерсииПодсистемОбластейДанных.ИмяПодсистемы = &ИмяПодсистемы";
	Запрос.УстановитьПараметр("ИмяПодсистемы", Метаданные.Имя);
	
	ТребуетсяУстановитьЗапланированныйМоментЗапуска = Ложь;
	
	Если ОбщегоНазначения.ПодсистемаСуществует("ТехнологияСервиса.БазоваяФункциональность") Тогда
		
		МодульТехнологияСервиса = ОбщегоНазначения.ОбщийМодуль("ТехнологияСервиса");
		ВерсияБиблиотекиБТС = МодульТехнологияСервиса.ВерсияБиблиотеки();
		ТребуетсяУстановитьЗапланированныйМоментЗапуска = ОбщегоНазначенияКлиентСервер.СравнитьВерсии(ВерсияБиблиотекиБТС, "2.0.1.0") > 0;
		
		Если ТребуетсяУстановитьЗапланированныйМоментЗапуска Тогда
	
			ЗапланированныйМоментЗапуска = ТекущаяУниверсальнаяДатаВМиллисекундах();
			
		КонецЕсли;
		
	КонецЕсли;
	
	Выборка = Результат.Выбрать();
	Пока Выборка.Следующий() Цикл
		ЗначенияКлюча = Новый Структура;
		ЗначенияКлюча.Вставить("ОбластьДанныхВспомогательныеДанные", Выборка.ОбластьДанных);
		ЗначенияКлюча.Вставить("ИмяПодсистемы", "");
		КлючЗаписи = МодульРаботаВМоделиСервиса.СоздатьКлючЗаписиРегистраСведенийВспомогательныхДанных(
			РегистрыСведений.ВерсииПодсистемОбластейДанных, ЗначенияКлюча);
		
		ОшибкаУстановкиБлокировки = Ложь;
		
		НачатьТранзакцию();
		Попытка
			Попытка
				ЗаблокироватьДанныеДляРедактирования(КлючЗаписи); // Будет снята при окончании транзакции.
			Исключение
				ОшибкаУстановкиБлокировки = Истина;
				ВызватьИсключение;
			КонецПопытки;
			
			Запрос.УстановитьПараметр("ОбластьДанных", Выборка.ОбластьДанных);
		
			Блокировка = Новый БлокировкаДанных;
			
			ЭлементБлокировки = Блокировка.Добавить("РегистрСведений.ВерсииПодсистемОбластейДанных");
			ЭлементБлокировки.УстановитьЗначение("ОбластьДанныхВспомогательныеДанные", Выборка.ОбластьДанных);
			ЭлементБлокировки.УстановитьЗначение("ИмяПодсистемы", Метаданные.Имя);
			ЭлементБлокировки.Режим = РежимБлокировкиДанных.Разделяемый;
			
			ЭлементБлокировки = Блокировка.Добавить("РегистрСведений.ОбластиДанных");
			ЭлементБлокировки.УстановитьЗначение("ОбластьДанныхВспомогательныеДанные", Выборка.ОбластьДанных);
			ЭлементБлокировки.Режим = РежимБлокировкиДанных.Разделяемый;
			
			Блокировка.Заблокировать();
			
			СтатусОбласти = МодульРаботаВМоделиСервиса.СтатусОбластиДанных(Выборка.ОбластьДанных);
			
			Результаты = Запрос.Выполнить().Выгрузить();
			СтрокаВерсии = Неопределено;
			Если Результаты.Количество() > 0 Тогда
				СтрокаВерсии = Результаты[0];
			КонецЕсли;
			
			Если СтатусОбласти = Неопределено
				ИЛИ СтатусОбласти <> Перечисления["СтатусыОбластейДанных"].Используется
				ИЛИ (СтрокаВерсии <> Неопределено И СтрокаВерсии.Версия = ВерсияМетаданных) Тогда
				
				// Записи не соответствуют исходному критерию.
				ЗафиксироватьТранзакцию();
				Продолжить;
			КонецЕсли;
			
			ОтборЗадания = Новый Структура;
			ОтборЗадания.Вставить("ИмяМетода", "ОбновлениеИнформационнойБазыСлужебныйВМоделиСервиса.ВыполнитьОбновлениеТекущейОбластиДанных");
			ОтборЗадания.Вставить("Ключ", "1");
			ОтборЗадания.Вставить("ОбластьДанных", Выборка.ОбластьДанных);
			Задания = МодульОчередьЗаданий.ПолучитьЗадания(ОтборЗадания);
			Если Задания.Количество() > 0 Тогда
				// Уже есть задание обновления области.
				ЗафиксироватьТранзакцию();
				Продолжить;
			КонецЕсли;
			
			
			ЕстьРасширенияИзменяющиеСтруктуру = Ложь;
			ПараметрыЗапускаЗадания = Новый Массив;
			
			// АПК:287-выкл вызывается метод расширения БТС.
			Если ОбщегоНазначения.ПодсистемаСуществует("ТехнологияСервиса.РасширенияВМоделиСервиса") Тогда
				МодульРасширенияВМоделиСервиса = ОбщегоНазначения.ОбщийМодуль("РасширенияВМоделиСервиса");
				ИдентификаторыРасширений = МодульРасширенияВМоделиСервиса.АктивироватьОтключенныеРасширенияВОбласти(Выборка.ОбластьДанных,
					ЕстьРасширенияИзменяющиеСтруктуру);
				ПараметрыЗапускаЗадания.Добавить(ИдентификаторыРасширений);
			КонецЕсли;
			// АПК:287-вкл
			
			ПараметрыЗадания = Новый Структура;
			ПараметрыЗадания.Вставить("ИмяМетода"    , "ОбновлениеИнформационнойБазыСлужебныйВМоделиСервиса.ВыполнитьОбновлениеТекущейОбластиДанных");
			ПараметрыЗадания.Вставить("Параметры"    , ПараметрыЗапускаЗадания);
			ПараметрыЗадания.Вставить("Ключ"         , "1");
			ПараметрыЗадания.Вставить("ОбластьДанных", Выборка.ОбластьДанных);
			ПараметрыЗадания.Вставить("ЭксклюзивноеВыполнение", Истина);
			ПараметрыЗадания.Вставить("КоличествоПовторовПриАварийномЗавершении", 3);
			
			Если ТребуетсяУстановитьЗапланированныйМоментЗапуска Тогда
			
				ПараметрыЗадания.Вставить("ЗапланированныйМоментЗапуска", ЗапланированныйМоментЗапуска);
				ЗапланированныйМоментЗапуска = ЗапланированныйМоментЗапуска + 1;
				
			КонецЕсли;
			
			МодульОчередьЗаданий.ДобавитьЗадание(ПараметрыЗадания);
			
			ЗафиксироватьТранзакцию();
			
		Исключение
			
			ОтменитьТранзакцию();
			Если ОшибкаУстановкиБлокировки Тогда
				Продолжить;
			Иначе
				ВызватьИсключение;
			КонецЕсли;
			
		КонецПопытки;
		
	КонецЦикла;
	
КонецПроцедуры

// Выполняет обновление версии информационной базы в текущей области данных
// и снимает блокировку сеансов в области, в случае если она была установлена
// ранее.
//
Процедура ВыполнитьОбновлениеТекущейОбластиДанных(АктивированныеРасширения = Неопределено) Экспорт
	
	Если АктивированныеРасширения = Неопределено Тогда
		АктивированныеРасширения = Новый Массив;
	КонецЕсли;
	
	ЕстьОшибка = Ложь;
	УстановитьПривилегированныйРежим(Истина);
	
	Попытка
		ОбновлениеИнформационнойБазы.ВыполнитьОбновлениеИнформационнойБазы();
	Исключение
		ЕстьОшибка = Истина;
		ТекстОшибки = ПодробноеПредставлениеОшибки(ИнформацияОбОшибке());
	КонецПопытки;
	
	Для Каждого Идентификатор Из АктивированныеРасширения Цикл
		
		Расширения = РасширенияКонфигурации.Получить(Новый Структура("УникальныйИдентификатор", Идентификатор), ИсточникРасширенийКонфигурации.СеансАктивные);
		Если Расширения.Количество() = 0 Тогда
			Продолжить;
		КонецЕсли;
		
		Расширения[0].Активно = Ложь;
		Расширения[0].Записать();
		
	КонецЦикла;
	
	Если ЕстьОшибка Тогда
		ВызватьИсключение ТекстОшибки;
	КонецЕсли;
	
КонецПроцедуры

// Обработчик регламентного задания ОбновлениеОбластейДанных.
// Выбирает все области данных с неактуальными версиями
// и при необходимости формирует фоновые задания ОбновлениеИБ в них.
//
Процедура ОбновлениеОбластейДанных() Экспорт
	
	Если НЕ ОбщегоНазначения.РазделениеВключено() Тогда
		Возврат;
	КонецЕсли;
	
	// Вызов ПриНачалеВыполненияРегламентногоЗадания не используется,
	// т.к. необходимые действия выполняются в частном порядке.
	
	ЗапланироватьОбновлениеОбластейДанных();
	
КонецПроцедуры

// Только для внутреннего использования.
Функция МинимальнаяВерсияОбластейДанных() Экспорт
	
	УстановитьПривилегированныйРежим(Истина);
	
	Если ОбщегоНазначения.РазделениеВключено()
		И ОбщегоНазначения.ДоступноИспользованиеРазделенныхДанных() Тогда
		
		ВызватьИсключение НСтр("ru = 'Вызов функции ОбновлениеИнформационнойБазыСлужебныйПовтИсп.МинимальнаяВерсияОбластейДанных()
		                             |недоступен из сеансов с установленным значением разделителей модели сервиса.'");
	КонецЕсли;
	
	Запрос = Новый Запрос;
	Запрос.УстановитьПараметр("ИмяПодсистемы", Метаданные.Имя);
	Запрос.Текст =
	"ВЫБРАТЬ РАЗЛИЧНЫЕ
	|	ВерсииПодсистемОбластейДанных.Версия КАК Версия
	|ИЗ
	|	РегистрСведений.ВерсииПодсистемОбластейДанных КАК ВерсииПодсистемОбластейДанных
	|ГДЕ
	|	ВерсииПодсистемОбластейДанных.ИмяПодсистемы = &ИмяПодсистемы";
	
	Выборка = Запрос.Выполнить().Выбрать();
	
	МинимальнаяВерсияИБ = Неопределено;
	
	Пока Выборка.Следующий() Цикл
		Если ОбщегоНазначенияКлиентСервер.СравнитьВерсии(Выборка.Версия, МинимальнаяВерсияИБ) > 0 Тогда
			МинимальнаяВерсияИБ = Выборка.Версия;
		КонецЕсли
	КонецЦикла;
	
	Возврат МинимальнаяВерсияИБ;
	
КонецФункции

// Только для внутреннего использования.
Процедура УстановитьВерсиюВсехОбластейДанных(ИдентификаторБиблиотеки, ИсходнаяВерсияИБ, ВерсияМетаданныхИБ)
	
	Блокировка = Новый БлокировкаДанных;
	Блокировка.Добавить("РегистрСведений.ВерсииПодсистемОбластейДанных");
	Блокировка.Добавить("РегистрСведений.ОбластиДанных");
	
	НачатьТранзакцию();
	Попытка
		Блокировка.Заблокировать();
		
		НаборЗаписей = РегистрыСведений.ВерсииПодсистемОбластейДанных.СоздатьНаборЗаписей();
		НаборЗаписей.Отбор.ИмяПодсистемы.Установить(ИдентификаторБиблиотеки, Истина);
		НаборЗаписей.Прочитать();
		
		// Изменить существующие записи
		Для Каждого Запись Из НаборЗаписей Цикл
			Если Запись.Версия = ИсходнаяВерсияИБ Тогда
				Запись.Версия = ВерсияМетаданныхИБ;
				Запись.ВыполненаРегистрацияОтложенныхОбработчиков = Ложь;
			КонецЕсли;
		КонецЦикла;
		
		// Добавить отсутствующие записи
		Запрос = Новый Запрос;
		Запрос.Текст =
		"ВЫБРАТЬ
		|	ОбластиДанных.ОбластьДанныхВспомогательныеДанные КАК ОбластьДанных
		|ИЗ
		|	РегистрСведений.ОбластиДанных КАК ОбластиДанных
		|		ЛЕВОЕ СОЕДИНЕНИЕ РегистрСведений.ВерсииПодсистемОбластейДанных КАК ВерсииПодсистемОбластейДанных
		|		ПО ОбластиДанных.ОбластьДанныхВспомогательныеДанные = ВерсииПодсистемОбластейДанных.ОбластьДанныхВспомогательныеДанные
		|ГДЕ
		|	ОбластиДанных.Статус = ЗНАЧЕНИЕ(Перечисление.СтатусыОбластейДанных.Используется)
		|	И ВерсииПодсистемОбластейДанных.ОбластьДанныхВспомогательныеДанные ЕСТЬ NULL";
		Выборка = Запрос.Выполнить().Выбрать();
		Пока Выборка.Следующий() Цикл
			Запись = НаборЗаписей.Добавить();
			Запись.ОбластьДанныхВспомогательныеДанные = Выборка.ОбластьДанных;
			Запись.ИмяПодсистемы = ИдентификаторБиблиотеки;
			Запись.Версия = ВерсияМетаданныхИБ;			
		КонецЦикла;
		
		НаборЗаписей.Записать();
		
		ЗафиксироватьТранзакцию();
	Исключение
		ОтменитьТранзакцию();
		ВызватьИсключение;
	КонецПопытки;
	
КонецПроцедуры

#КонецОбласти

Функция ВыполнитьЗапросВнеТранзакции(Знач Запрос)
	
	Если ТранзакцияАктивна() Тогда
		ВызватьИсключение(НСтр("ru = 'Транзакция активна. Выполнение запроса вне транзакции невозможно.'"));
	КонецЕсли;
	
	КоличествоПопыток = 0;
	
	Результат = Неопределено;
	Пока Истина Цикл
		Попытка
			Результат = Запрос.Выполнить(); // Чтение вне транзакции, возможно появление ошибки.
			                                // Could not continue scan with NOLOCK due to data movement
			                                // в этом случае нужно повторить попытку чтения.
			Прервать;
		Исключение
			КоличествоПопыток = КоличествоПопыток + 1;
			Если КоличествоПопыток = 5 Тогда
				ВызватьИсключение;
			КонецЕсли;
		КонецПопытки;
	КонецЦикла;
	
	Возврат Результат;
	
КонецФункции

#КонецОбласти
