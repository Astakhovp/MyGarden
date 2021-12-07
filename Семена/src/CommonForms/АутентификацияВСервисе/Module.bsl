///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2020, ООО 1С-Софт
// Все права защищены. Эта программа и сопроводительные материалы предоставляются 
// в соответствии с условиями лицензии Attribution 4.0 International (CC BY 4.0)
// Текст лицензии доступен по ссылке:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Область ОбработчикиСобытийФормы

&НаКлиенте
Процедура ПриОткрытии(Отказ)
	
	Если ВладелецФормы = Неопределено Тогда
		РежимОткрытияОкна = РежимОткрытияОкнаФормы.БлокироватьВесьИнтерфейс;
	КонецЕсли;
	
КонецПроцедуры

&НаКлиенте
Процедура ПриЗакрытии(ЗавершениеРаботы)
	
	Если ЗавершениеРаботы Тогда
		Возврат;
	КонецЕсли;
	ОповеститьОВыборе(ПарольПользователяСервиса);
	
КонецПроцедуры

#КонецОбласти

#Область ОбработчикиКомандФормы

&НаКлиенте
Процедура ОК(Команда)
	
	ТекстОшибки = "";
	
	Если ТипЗнч(ЭтотОбъект.ОписаниеОповещенияОЗакрытии) = Тип("ОписаниеОповещения") Тогда
		ПарольПользователяСервиса = Пароль;
		Попытка
			ВыполнитьОбработкуОповещения(ЭтотОбъект.ОписаниеОповещенияОЗакрытии, ПарольПользователяСервиса);
		Исключение
			ИнформацияОбОшибке = ИнформацияОбОшибке();
			ЗаписатьОшибкуВЖурнал(ПодробноеПредставлениеОшибки(ИнформацияОбОшибке));
			ТекстОшибки = КраткоеПредставлениеОшибки(ИнформацияОбОшибке) + Символы.ПС
				+ НСтр("ru = 'Возможно пароль введен неверно, повторите ввод пароля.'");
		КонецПопытки;
	КонецЕсли;
	
	Закрыть();
	
	Если ЗначениеЗаполнено(ТекстОшибки) Тогда
		ПоказатьПредупреждение(, ТекстОшибки);
	КонецЕсли;
	
КонецПроцедуры

&НаКлиенте
Процедура Отмена(Команда)
	
	Закрыть();
	
КонецПроцедуры

#КонецОбласти

#Область СлужебныеПроцедурыИФункции

&НаСервереБезКонтекста
Процедура ЗаписатьОшибкуВЖурнал(ТекстОшибки)
	
	ЗаписьЖурналаРегистрации(
		НСтр("ru = 'Ошибка выполнения'", ОбщегоНазначения.КодОсновногоЯзыка()),
		УровеньЖурналаРегистрации.Ошибка,,, ТекстОшибки);
	
КонецПроцедуры

#КонецОбласти
