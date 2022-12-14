&НаКлиенте
Процедура ЧтениеФайлаCSV()
   ФайлCSV = Новый ТекстовыйДокумент;
   ФайлCSV.Прочитать("D:\import_21092020.csv");
   ЗагрузитьCSV(ФайлCSV);
КонецПроцедуры

&НаСервере
Процедура ОбновитьЦену()
    ВремяНачала = ТекущаяДата();
    
    Запрос = Новый Запрос;
    Запрос.Текст =
    “ВЫБРАТЬ
    |   Товары.Ссылка
    |ИЗ
    |   Справочник.Товары КАК Товары”;
    
    ТаблицаТоваров = Запрос.Выполнить().Выгрузить();
    
    // определяем максимальное количество потоков
    ЧислоПотоков = 8;
    
    ЧислоСтрокВТаблице = ТаблицаТоваров.Количество();
    
    // объем порции данных для обработки каждым потоком
    РазмерПорции = Цел(ЧислоСтрокаВТаблице/ЧислоПотоков);
    
    // массив, где будут храниться фоновые задания
    МассивЗаданий = Новый Массив;
    
    Для НомерПотока = 1 По ЧислоПотоков Цикл
    
        // определяем индекс для начала обработки данных данным потоком
        // разные потоки обрабатывают разные части таблицы
        ИндексНачала = (НомерПотока – 1)*РазмерПорции;
        
        Если (НомерПотока = ЧислоПотоков) Тогда
            // если это последний поток, то он обрабатывает все оставшиеся данные
            // т.к. число потоков может не быть кратно количеству строк в таблице
            РазмерПорции = ЧислоСтрокВТаблице-(ЧислоПотоков*РазмерПорции)+РазмерПорции;
        КонецЕсли;
        
        // определяем массив параметров для процедуры
        НаборПараметров = Новый Массив;
        НаборПараметров.Добавить(ТаблицаТоваров);
        НаборПараметров.Добавить(ИндексНачала);
        НаборПараметров.Добавить(РазмерПорции);
        
        // запуск фонового задания
        Задание = ФоновыеЗадания.Выполнить(“ОбщийМодуль1.ОбновитьЦенуТовара”, НаборПараметров);
        
        // добавляем задание в массив, чтобы потом отследить выполнение
        МассивЗаданий.Добавить(Задание);
        
    КонецЦикла;
    
    // проверим результат выполнения фоновых заданий
    Если МассивЗаданий.Количество() > 0 Тогда
        Попытка
            ФоновыеЗадания.ОжидатьЗавершения(МассивЗаданий);
        Исключение
            // действия в случае ошибки
        КонецПопытки;
    КонецЕсли;
    
    Длительность = ТекущаяДата()-ВремяНачала;
    
    Сообщить(“Длительность: “ + Длительность + “сек.”);
    
КонецПроцедуры




Процедура ЗагрузитьCSVФайлВТаблицу(ИмяФайла, ШаблонСДанными, ИнформацияПоКолонкам)
	
	Файл = Новый Файл(ИмяФайла);
	Если НЕ Файл.Существует() Тогда 
		Возврат;
	КонецЕсли;
	
	ЧтениеТекста = Новый ЧтениеТекста(ИмяФайла);
	Строка = ЧтениеТекста.ПрочитатьСтроку();
	Если Строка = Неопределено Тогда 
		ТекстСообщения = НСтр("ru = 'Не получилось загрузить данные из этого файла. Убедитесь в корректности данных в файле.'");
		ВызватьИсключение ТекстСообщения;
	КонецЕсли;
	
	КолонкиШапки = СтрРазделить(Строка, ";", Ложь);
	Источник = Новый ТаблицаЗначений;
	ПозицияКолонкиВФайле = Новый Соответствие();
	
	Позиция = 1;
	Для каждого Колонка Из КолонкиШапки Цикл
		НайденнаяКолонка = НайтиИнформациюОКолонке(ИнформацияПоКолонкам, "Синоним", Колонка);
		Если НайденнаяКолонка = Неопределено Тогда
			НайденнаяКолонка = НайтиИнформациюОКолонке(ИнформацияПоКолонкам, "ПредставлениеКолонки", Колонка);
		КонецЕсли;
		Если НайденнаяКолонка <> Неопределено Тогда
			НоваяКолонка = Источник.Колонки.Добавить();
			НоваяКолонка.Имя = НайденнаяКолонка.ИмяКолонки;
			НоваяКолонка.Заголовок = Колонка;
			ПозицияКолонкиВФайле.Вставить(Позиция, НоваяКолонка.Имя);
			Позиция = Позиция + 1;
		КонецЕсли;
	КонецЦикла;
	
	Если Источник.Колонки.Количество() = 0 Тогда
		Возврат;
	КонецЕсли;
	
	Пока Строка <> Неопределено Цикл
		НоваяСтрока = Источник.Добавить();
		Позиция = СтрНайти(Строка, ";");
		Индекс = 0;
		Пока Позиция > 0 Цикл
			Если Источник.Колонки.Количество() < Индекс + 1 Тогда
				Прервать;
			КонецЕсли;
			ИмяКолонки = ПозицияКолонкиВФайле.Получить(Индекс + 1);
			Если ИмяКолонки <> Неопределено Тогда
				НоваяСтрока[ИмяКолонки] = Лев(Строка, Позиция - 1);
			КонецЕсли;
			Строка = Сред(Строка, Позиция + 1);
			Позиция = СтрНайти(Строка, ";");
			Индекс = Индекс + 1;
		КонецЦикла;
		Если Источник.Колонки.Количество() = Индекс + 1  Тогда
			НоваяСтрока[Индекс] = Строка;
		КонецЕсли;

		Строка = ЧтениеТекста.ПрочитатьСтроку();
	КонецЦикла;
	
	ЗаполнитьТаблицуПоЗагруженнымДаннымИзФайла(Источник, ШаблонСДанными, ИнформацияПоКолонкам);
	
