///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2020, ООО 1С-Софт
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии Attribution 4.0 International (CC BY 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Область ОбработчикиСобытийФормы

&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)
	
	// СтандартныеПодсистемы.ПодключаемыеКоманды
	Если ОбщегоНазначения.ПодсистемаСуществует("СтандартныеПодсистемы.ПодключаемыеКоманды") Тогда
		МодульПодключаемыеКоманды = ОбщегоНазначения.ОбщийМодуль("ПодключаемыеКоманды");
		МодульПодключаемыеКоманды.ПриСозданииНаСервере(ЭтотОбъект);
	КонецЕсли;
	// Конец СтандартныеПодсистемы.ПодключаемыеКоманды
	
	Если ОбщегоНазначения.ЭтоМобильныйКлиент() Тогда
		Элементы.ФормаСоздать.Отображение = ОтображениеКнопки.Картинка;
	КонецЕсли;
	
КонецПроцедуры

#КонецОбласти

#Область ОбработчикиСобытийЭлементовШапкиФормы

&НаКлиенте
Процедура ДополнительнаяИнформацияОбработкаНавигационнойСсылки(Элемент, НавигационнаяСсылкаФорматированнойСтроки, СтандартнаяОбработка)
	
	Если НавигационнаяСсылкаФорматированнойСтроки = "ПерейтиКМакетамПечатныхФорм" Тогда
		СтандартнаяОбработка = Ложь;
		ОткрытьФорму("РегистрСведений.ПользовательскиеМакетыПечати.Форма.МакетыПечатныхФорм");
	КонецЕсли;
	
КонецПроцедуры

#КонецОбласти

#Область ОбработчикиСобытийЭлементовТаблицыФормыСписок

&НаКлиенте
Процедура СписокПриАктивизацииСтроки(Элемент)
	
	// СтандартныеПодсистемы.ПодключаемыеКоманды
	Если ОбщегоНазначенияКлиент.ПодсистемаСуществует("СтандартныеПодсистемы.ПодключаемыеКоманды") Тогда
		МодульПодключаемыеКомандыКлиент = ОбщегоНазначенияКлиент.ОбщийМодуль("ПодключаемыеКомандыКлиент");
		МодульПодключаемыеКомандыКлиент.НачатьОбновлениеКоманд(ЭтотОбъект);
	КонецЕсли;
	// Конец СтандартныеПодсистемы.ПодключаемыеКоманды
	
КонецПроцедуры

&НаСервереБезКонтекста
Процедура СписокПриПолученииДанныхНаСервере(ИмяЭлемента, Настройки, Строки)
	
	Для Каждого Строка Из Строки Цикл
		Строка.Значение.Данные["Наименование"] = МультиязычностьСервер.ПредставлениеЯзыка(Строка.Значение.Данные["Код"]);
	КонецЦикла;
	
КонецПроцедуры

#КонецОбласти

#Область ОбработчикиКомандФормы

&НаКлиенте
Процедура Создать(Команда)
	
	ОписаниеОповещения = Новый ОписаниеОповещения("ПриВыбореЯзыка", ЭтотОбъект);
	ОткрытьФорму("Справочник.ЯзыкиПечатныхФорм.Форма.ПодборЯзыкаИзСпискаДоступных", , ЭтотОбъект, , , , ОписаниеОповещения);
	
КонецПроцедуры

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

// СтандартныеПодсистемы.ПодключаемыеКоманды
&НаКлиенте
Процедура Подключаемый_ВыполнитьКоманду(Команда)
	МодульПодключаемыеКомандыКлиент = ОбщегоНазначенияКлиент.ОбщийМодуль("ПодключаемыеКомандыКлиент");
	МодульПодключаемыеКомандыКлиент.НачатьВыполнениеКоманды(ЭтотОбъект, Команда, Элементы.Список);
КонецПроцедуры

&НаКлиенте
Процедура Подключаемый_ПродолжитьВыполнениеКомандыНаСервере(ПараметрыВыполнения, ДополнительныеПараметры) Экспорт
	ВыполнитьКомандуНаСервере(ПараметрыВыполнения);
КонецПроцедуры

&НаСервере
Процедура ВыполнитьКомандуНаСервере(ПараметрыВыполнения)
	МодульПодключаемыеКоманды = ОбщегоНазначения.ОбщийМодуль("ПодключаемыеКоманды");
	МодульПодключаемыеКоманды.ВыполнитьКоманду(ЭтотОбъект, ПараметрыВыполнения, Элементы.Список);
КонецПроцедуры

&НаКлиенте
Процедура Подключаемый_ОбновитьКоманды()
	МодульПодключаемыеКомандыКлиентСервер = ОбщегоНазначенияКлиент.ОбщийМодуль("ПодключаемыеКомандыКлиентСервер");
	МодульПодключаемыеКомандыКлиентСервер.ОбновитьКоманды(ЭтотОбъект, Элементы.Список);
КонецПроцедуры

// Конец СтандартныеПодсистемы.ПодключаемыеКоманды

// Параметры:
//  ВыбранныеЯзыки - Массив из Структура:
//   * Код - Строка
//   * Наименование - Строка
//
&НаКлиенте
Процедура ПриВыбореЯзыка(ВыбранныеЯзыки, ДополнительныеПараметры) Экспорт
	
	Если ВыбранныеЯзыки = Неопределено Тогда
		Возврат;
	КонецЕсли;
	
	ДобавленныеЯзыки = ДобавитьЯзыки(ВыбранныеЯзыки);
	ОбщегоНазначенияКлиент.ОповеститьОбИзмененииОбъектов(ДобавленныеЯзыки);
	Элементы.Список.ТекущаяСтрока = ДобавленныеЯзыки[0];
	Элементы.Список.ВыделенныеСтроки.Очистить();
	Для Каждого Язык Из ДобавленныеЯзыки Цикл
		Элементы.Список.ВыделенныеСтроки.Добавить(Язык);
	КонецЦикла;
	
КонецПроцедуры

&НаСервере
Функция ДобавитьЯзыки(ВыбранныеЯзыки)
	
	Результат = Новый Массив;
	Для Каждого ОписаниеЯзыка Из ВыбранныеЯзыки Цикл
		ЯзыкСсылка = Справочники.ЯзыкиПечатныхФорм.НайтиПоКоду(ОписаниеЯзыка.Код);
		Если ЗначениеЗаполнено(ЯзыкСсылка) Тогда
			ЯзыкОбъект = ЯзыкСсылка.ПолучитьОбъект();
		Иначе
			ЯзыкОбъект = Справочники.ЯзыкиПечатныхФорм.СоздатьЭлемент();
		КонецЕсли;
		ЗаполнитьЗначенияСвойств(ЯзыкОбъект, ОписаниеЯзыка);
		ЯзыкОбъект.ПометкаУдаления = Ложь;
		
		Блокировка = Новый БлокировкаДанных;
		ЭлементБлокировки = Блокировка.Добавить("Справочник.ЯзыкиПечатныхФорм");
		ЭлементБлокировки.УстановитьЗначение("Код", ЯзыкОбъект.Код);
		
		НачатьТранзакцию();
		Попытка
			Блокировка.Заблокировать();
			ЯзыкОбъект.Записать();
			ЗафиксироватьТранзакцию();
		Исключение
			ОтменитьТранзакцию();
			ВызватьИсключение;
		КонецПопытки;
		
		Результат.Добавить(ЯзыкОбъект.Ссылка);
	КонецЦикла;
	
	Возврат Результат;
	
КонецФункции

#КонецОбласти
