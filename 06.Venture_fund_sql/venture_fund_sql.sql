/* В проекте 23 задачи на составление запросов различной сложности к БД (PostgreSQL).
Данные: датасет Startup Investments с Kaggle (https://www.kaggle.com/justinas/startup-investments) */

/* 1. Отобразим все записи из таблицы "company" по компаниям, которые закрылись.*/

SELECT *
FROM company
WHERE status = 'closed';

/* 2. Выведем количество привлечённых средств для новостных компаний США. 
Используем данные из таблицы company. Отсортируем таблицу по убыванию значений в поле funding_total. */

SELECT funding_total 
FROM company 
WHERE category_code = 'news'
  AND country_code  = 'USA'
ORDER BY funding_total DESC;

/* 3. Найдем общую сумму сделок по покупке одних компаний другими в долларах. 
Отберем сделки, которые осуществлялись только за наличные с 2011 по 2013 год включительно. */

SELECT SUM(price_amount)
FROM acquisition
WHERE term_code = 'cash'
AND acquired_at BETWEEN '01-01-2011' AND '31-12-2013';

/* 4. Отобразим имя, фамилию и названия аккаунтов людей в твиттере, у которых названия аккаунтов начинаются на 'Silver'. */

SELECT first_name,
       last_name,
       twitter_username 
FROM people
WHERE twitter_username LIKE 'Silver%';

/* 5. Выведем на экран всю информацию о людях, у которых названия аккаунтов в твиттере содержат подстроку 'money', а фамилия начинается на 'K'. */

SELECT *
FROM people
WHERE twitter_username LIKE '%money%'
  AND last_name LIKE 'K%';

/* 6. Для каждой страны отобразим общую сумму привлечённых инвестиций, которые получили компании, зарегистрированные в этой стране.
Страну, в которой зарегистрирована компания, можно определить по коду страны. Отсортируем данные по убыванию суммы. */ 

SELECT SUM(funding_total) AS total,
       country_code 
FROM company
GROUP BY country_code
ORDER BY total DESC;

/* 7. Составим таблицу, в которую войдёт дата проведения раунда, а также минимальное и максимальное значения суммы инвестиций, привлечённых в эту дату.
Оставим в итоговой таблице только те записи, в которых минимальное значение суммы инвестиций не равно нулю и не равно максимальному значению. */

SELECT funded_at,
       MIN(raised_amount),
       MAX(raised_amount)
FROM funding_round
GROUP BY funded_at
HAVING MIN(raised_amount) NOT IN (0, MAX(raised_amount));

/* 8. Создадим поле с категориями:
Для фондов, которые инвестируют в 100 и более компаний, назначим категорию "high_activity".
Для фондов, которые инвестируют в 20 и более компаний до 100, назначим категорию "middle_activity".
Если количество инвестируемых компаний фонда не достигает 20, назначим категорию "low_activity".
Отобразим все поля таблицы fund и новое поле с категориями. */

SELECT *,
  CASE
      WHEN invested_companies >= 100  THEN 'high_activity'
      WHEN invested_companies >= 20 AND invested_companies < 100 THEN 'middle_activity'
      ELSE 'low_activity'
  END
FROM fund;

/* 9. Для каждой из категорий, назначенных в предыдущем задании, посчитаем округлённое до ближайшего целого числа среднее количество инвестиционных раундов, в которых фонд принимал участие.
Выведем на экран категории и среднее число инвестиционных раундов. Отсортируем таблицу по возрастанию среднего. */

SELECT
       CASE
           WHEN invested_companies>=100 THEN 'high_activity'
           WHEN invested_companies>=20 THEN 'middle_activity'
           ELSE 'low_activity'
       END AS activity,
       ROUND(AVG(investment_rounds))
FROM fund
GROUP BY activity
ORDER BY ROUND(AVG(investment_rounds));

/* 10. Проанализируем, в каких странах находятся фонды, которые чаще всего инвестируют в стартапы. 
Для каждой страны посчитаем минимальное, максимальное и среднее число компаний, в которые инвестировали фонды этой страны, основанные с 2010 по 2012 год включительно.
Исключим страны с фондами, у которых минимальное число компаний, получивших инвестиции, равно нулю. Выгрузим десять самых активных стран-инвесторов.
Отсортируем таблицу по среднему количеству компаний от большего к меньшему, а затем по коду страны в лексикографическом порядке. */

SELECT country_code,
      MIN(invested_companies),
      MAX(invested_companies),
      AVG(invested_companies)
FROM (SELECT *
      FROM fund       
      WHERE EXTRACT (YEAR FROM founded_at) BETWEEN 2010 AND 2012) AS f
 
GROUP BY country_code
HAVING MIN(invested_companies) > 0
ORDER BY AVG(invested_companies) DESC
LIMIT 10;

/* 11. Отобразим имя и фамилию всех сотрудников стартапов. 
Добавим поле с названием учебного заведения, которое окончил сотрудник, если эта информация известна. */ 

SELECT pep.first_name,
       pep.last_name,
       ed.instituition
FROM people AS pep
LEFT JOIN education AS ed ON pep.id=ed.person_id;

/* 12. Для каждой компании найдем количество учебных заведений, которые окончили её сотрудники. 
Выведем название компании и число уникальных названий учебных заведений. Составим топ-5 компаний по количеству университетов. */

SELECT cp.name,
       COUNT(DISTINCT ed.instituition)
FROM company AS cp
INNER JOIN people AS p ON cp.id=p.company_id
INNER JOIN education AS ed ON p.id=ed.person_id
GROUP BY cp.name
ORDER BY COUNT(DISTINCT ed.instituition) DESC
LIMIT 5;

/* 13. Составим список с уникальными названиями закрытых компаний, для которых первый раунд финансирования оказался последним. */

SELECT DISTINCT (c.name),
       c.id AS c_id
FROM company AS c
INNER JOIN funding_round AS f ON f.company_id = c.id 
WHERE 
  c.status = 'closed'
  AND f.is_first_round = 1
  AND f.is_last_round = 1;

/* 14. Составим список уникальных номеров сотрудников, которые работают в компаниях, отобранных в предыдущем задании. */

SELECT DISTINCT p.id
FROM people AS p
WHERE p.company_id IN (SELECT c.id
                       FROM company AS c
                       INNER JOIN funding_round AS f ON f.company_id = c.id 
                       WHERE c.status = 'closed'
                         AND f.is_first_round = 1
                         AND f.is_last_round = 1);

/* 15. Составим таблицу, куда войдут уникальные пары с номерами сотрудников из предыдущей задачи и учебным заведением, которое окончил сотрудник. */

WITH
staff AS(
SELECT DISTINCT p.id
FROM people AS p
WHERE p.company_id IN (SELECT c.id
                       FROM company AS c
                       INNER JOIN funding_round AS f ON f.company_id = c.id 
                       WHERE c.status = 'closed'
                         AND f.is_first_round = 1
                         AND f.is_last_round = 1))
 
SELECT DISTINCT staff.id,
instituition
FROM staff
INNER JOIN education AS e ON e.person_id = staff.id;


/* 16. Посчитаем количество учебных заведений для каждого сотрудника из предыдущего задания. При подсчёте учитем, что некоторые сотрудники могли окончить одно и то же заведение дважды. */

WITH
staff AS(
SELECT DISTINCT p.id
FROM people AS p
WHERE p.company_id IN (SELECT c.id
                       FROM company AS c
                       INNER JOIN funding_round AS f ON f.company_id = c.id 
                       WHERE c.status = 'closed'
                         AND f.is_first_round = 1
                         AND f.is_last_round = 1)) 

SELECT DISTINCT staff.id,
       COUNT (instituition)
FROM staff
INNER JOIN education AS e ON e.person_id = staff.id
GROUP BY staff.id;

/* 17. Дополним предыдущий запрос и выведем среднее число учебных заведений (всех, не только уникальных), которые окончили сотрудники разных компаний.
Нужно вывести только одну запись, группировка здесь не понадобится. */

WITH
staff AS(
SELECT p.id,
       COUNT(e.instituition) AS count_i
FROM people AS p
INNER JOIN education AS e ON e.person_id = p.id
WHERE p.company_id IN (SELECT c.id
                       FROM company AS c
                       INNER JOIN funding_round AS f ON f.company_id = c.id 
                       WHERE c.status = 'closed'
                         AND f.is_first_round = 1
                         AND f.is_last_round = 1)
GROUP BY p.id) 
SELECT AVG(count_i)
FROM staff;

/* 18. Напишем похожий запрос: выведем среднее число учебных заведений (всех, не только уникальных), которые окончили сотрудники Facebook (сервис, запрещённый на территории РФ). */

WITH
staff AS(
SELECT p.id,
       COUNT(e.instituition) AS count_i
FROM people AS p
INNER JOIN education AS e ON e.person_id = p.id
WHERE p.company_id IN (SELECT c.id
                       FROM company AS c
                       WHERE c.name  = 'Facebook')
GROUP BY p.id) 
SELECT AVG(count_i)
FROM staff;


/* 19. Составим таблицу из полей: 
- "name_of_fund" — название фонда;
- "name_of_company" — название компании;
- "amount" — сумма инвестиций, которую привлекла компания в раунде.
В таблицу войдут данные о компаниях, в истории которых было больше шести важных этапов, а раунды финансирования проходили с 2012 по 2013 год включительно. */

SELECT f.name AS name_of_fund,
       com.name AS name_of_company,
       fr.raised_amount AS amount
FROM investment AS i
INNER JOIN company AS com ON i.company_id=com.id
INNER JOIN fund AS f ON i.fund_id=f.id
INNER JOIN funding_round AS fr ON i.funding_round_id=fr.id
WHERE com.milestones > 6
AND EXTRACT (YEAR FROM fr.funded_at::date) BETWEEN 2012 AND 2013;


/* 20. Выгрузим таблицу, в которой будут такие поля:
- название компании-покупателя;
- сумма сделки;
- название компании, которую купили;
- сумма инвестиций, вложенных в купленную компанию;
- доля, которая отображает, во сколько раз сумма покупки превысила сумму вложенных в компанию инвестиций, округлённая до ближайшего целого числа.
Не будем учитывать те сделки, в которых сумма покупки равна нулю. Если сумма инвестиций в компанию равна нулю, исключим такую компанию из таблицы.
Отсортируем таблицу по сумме сделки от большей к меньшей, а затем по названию купленной компании в лексикографическом порядке. Ограничим таблицу первыми десятью записями. */

WITH acquiring AS
(SELECT c.name AS buyer,
a.price_amount AS price,
a.id AS KEY
FROM acquisition AS a
LEFT JOIN company AS c ON a.acquiring_company_id = c.id
WHERE a.price_amount > 0),
acquired AS
(SELECT c.name AS acquisition,
c.funding_total AS investment,
a.id AS KEY
FROM acquisition AS a
LEFT JOIN company AS c ON a.acquired_company_id = c.id
WHERE c.funding_total > 0)
SELECT acqn.buyer,
acqn.price,
acqd.acquisition,
acqd.investment,
ROUND(acqn.price / acqd.investment) AS uplift
FROM acquiring AS acqn
JOIN acquired AS acqd ON acqn.KEY = acqd.KEY
ORDER BY price DESC, acquisition
LIMIT 10;

/* 21. Выгрузим таблицу, в которую войдут названия компаний из категории social, получившие финансирование с 2010 по 2013 год включительно. 
Проверим, что сумма инвестиций не равна нулю. Выведем также номер месяца, в котором проходил раунд финансирования. */

SELECT  c.name AS social,
EXTRACT (MONTH FROM fr.funded_at) AS month
FROM company AS c
LEFT JOIN funding_round AS fr ON c.id = fr.company_id
WHERE c.category_code = 'social'
AND fr.funded_at BETWEEN '2010-01-01' AND '2013-12-31'
AND fr.raised_amount <> 0;

/* 22. Отберем данные по месяцам с 2010 по 2013 год, когда проходили инвестиционные раунды.
Сгруппируем данные по номеру месяца и получим таблицу, в которой будут поля: 
- номер месяца, в котором проходили раунды;
- количество уникальных названий фондов из США, которые инвестировали в этом месяце;
- количество компаний, купленных за этот месяц;
- общая сумма сделок по покупкам в этом месяце. */

WITH
fundings AS (SELECT EXTRACT (MONTH FROM CAST(fr.funded_at AS date)) AS funding_month,
                    COUNT(DISTINCT f.id) AS id_fund
             FROM fund AS f     
             LEFT JOIN investment AS i ON f.id=i.fund_id
             LEFT JOIN funding_round AS fr ON i.funding_round_id=fr.id
             WHERE f.country_code = 'USA'
               AND EXTRACT(YEAR FROM CAST (fr.funded_at AS date)) BETWEEN 2010 AND 2013
             GROUP BY funding_month),
 
acquisitions AS (SELECT EXTRACT (MONTH FROM CAST(acquired_at AS date)) AS funding_month,
                 COUNT(acquired_company_id) AS acquired,
                 SUM(price_amount) AS sum_total
                 FROM acquisition
                 WHERE EXTRACT(YEAR FROM CAST (acquired_at AS date)) BETWEEN 2010 AND 2013
                 GROUP BY funding_month) 
                 
SELECT fd.funding_month,
       fd.id_fund,
       a.acquired,
       a.sum_total
FROM fundings AS fd 
INNER JOIN acquisitions AS a ON fd.funding_month = a.funding_month;

/* 23. Составим сводную таблицу и выведем среднюю сумму инвестиций для стран, в которых есть стартапы, зарегистрированные в 2011, 2012 и 2013 годах. 
Данные за каждый год  - в отдельном поле. 
Отсортируем таблицу по среднему значению инвестиций за 2011 год от большего к меньшему. */

WITH
     inv_2011 AS (SELECT country_code,
                         AVG(funding_total) AS total_avg_2011
                  FROM company
                  WHERE EXTRACT(YEAR FROM CAST(founded_at AS date)) = 2011
                  GROUP BY country_code),
     inv_2012 AS (SELECT country_code,
                         AVG(funding_total) AS total_avg_2012
                  FROM company
                  WHERE EXTRACT(YEAR FROM CAST(founded_at AS date)) = 2012
                  GROUP BY country_code),
     inv_2013 AS (SELECT country_code,
                         AVG(funding_total) AS total_avg_2013
                  FROM company
                  WHERE EXTRACT(YEAR FROM CAST(founded_at AS date)) = 2013
                  GROUP BY country_code)           
SELECT inv_2011.country_code,
       inv_2011.total_avg_2011,
       inv_2012.total_avg_2012,
       inv_2013.total_avg_2013
FROM inv_2011 
INNER JOIN inv_2012 ON inv_2011.country_code = inv_2012.country_code
INNER JOIN inv_2013 ON inv_2012.country_code = inv_2013.country_code
ORDER BY total_avg_2011 DESC;
