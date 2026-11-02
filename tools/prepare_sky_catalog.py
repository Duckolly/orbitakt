from pathlib import Path
import csv,json,zipfile,io,hashlib
import argparse
parser=argparse.ArgumentParser(description='Build the offline sky subsets from source datasets. No network requests.')
parser.add_argument('--input-dir',required=True,help='Directory with hyg.csv, cities.zip, HYG_LICENSE.md, GEONAMES_README.txt')
args=parser.parse_args()
r=Path(__file__).resolve().parents[1];p=r/'app';raw=Path(args.input_dir);a=p/'assets/sky';a.mkdir(parents=True,exist_ok=True)
figures=[
 ('Большая Медведица',[[54061,53910,58001,59774,54061],[59774,62956,65378,67301]]),
 ('Малая Медведица',[[11767,85822,82080,77055,79822,75097,72607,77055]]),
 ('Кассиопея',[[746,3179,4427,6686,8886]]),
 ('Орион',[[25336,27989,26727,27366,24436,25930,25336],[25930,26311,26727],[25336,26207,27989]]),
 ('Лебедь',[[102098,100453,95947],[94779,100453,104732]]),
 ('Лира',[[91262,91971,92791,93194,92420,91971]]),
 ('Орёл',[[97278,97649,98036]]),
 ('Лев',[[49669,49583,50583,50335,48455,47908],[50583,54879,57632,54872,49669]]),
 ('Близнецы',[[36850,32246,30343],[37826,35550,31681],[36850,37826],[30343,31681]]),
 ('Телец',[[25428,20889,20205,21421,26451],[20205,20455]]),
 ('Скорпион',[[78265,78401,80112,80763,81266,82396,82514,84143,86228,87073,86670,85927,85696]]),
 ('Южный Крест',[[60718,61084],[62434,59747]]),
 ('Большой квадрат',[[113963,113881,677,1067,113963]]),
 ('Андромеда',[[677,5447,9640]]),
]
needed={x for _,paths in figures for path in paths for x in path}
labels={11767:'Полярная',32349:'Сириус',91262:'Вега',24436:'Ригель',27989:'Бетельгейзе',65474:'Спика',69673:'Арктур',24608:'Капелла',102098:'Денеб',97649:'Альтаир',80763:'Антарес',7588:'Ахернар',30438:'Канопус',71683:'Альфа Центавра',49669:'Регул',37826:'Поллукс',36850:'Кастор',25336:'Беллатрикс',54061:'Дубхе',67301:'Алькаид'}
needed|=labels.keys()
allrows={}
with (raw/'hyg.csv').open() as f:
 for x in csv.DictReader(f):
  if x['hip']:allrows[int(x['hip'])]=x
assert not needed-allrows.keys(),needed-allrows.keys()
stars=[]
for hip,x in sorted(allrows.items()):
 mag=float(x['mag'])
 if mag>4.5 and hip not in needed:continue
 stars.append({'id':hip,'ra':round(float(x['ra'])*15,7),'dec':round(float(x['dec']),7),'mag':mag,'name':labels.get(hip,'')})
(a/'stars.json').write_text(json.dumps({'source':'HYG v4.1, David Nash / Astronexus','license':'CC BY-SA 4.0','epoch':'J2000.0','stars':stars},ensure_ascii=False,separators=(',',':'))+'\n')
constellations=[{'name':name,'paths':paths} for name,paths in figures]
(a/'figures.json').write_text(json.dumps({'author':'ДВИЖ contributors','description':'Собственные упрощённые линии-ориентиры; не границы всех 88 созвездий','figures':constellations},ensure_ascii=False,separators=(',',':'))+'\n')
with zipfile.ZipFile(raw/'cities.zip') as z: rows=[line.split('\t') for line in z.read('cities15000.txt').decode().splitlines()]
wanted=[('RU','Samara','Самара'),('RU','Moscow','Москва'),('RU','Saint Petersburg','Санкт-Петербург'),('RU','Kazan','Казань'),('RU','Yekaterinburg','Екатеринбург'),('RU','Novosibirsk','Новосибирск'),('RU','Krasnodar','Краснодар'),('RU','Sochi','Сочи'),('RU','Kaliningrad','Калининград'),('RU','Vladivostok','Владивосток'),('RU','Murmansk','Мурманск'),('RU','Irkutsk','Иркутск'),('RU','Omsk','Омск'),('RU','Rostov-na-Donu','Ростов-на-Дону'),('RU','Tyumen','Тюмень'),('RU','Volgograd','Волгоград'),('RU','Ufa','Уфа'),('RU','Perm','Пермь'),('RU','Chelyabinsk','Челябинск'),('RU','Voronezh','Воронеж'),('RU','Arkhangelsk','Архангельск'),('RU','Krasnoyarsk','Красноярск'),('RU','Yakutsk','Якутск'),('RU','Khabarovsk','Хабаровск'),('RU','Saratov','Саратов'),('RU','Tolyatti','Тольятти'),('RU','Ulyanovsk','Ульяновск'),('RU','Izhevsk','Ижевск'),('RU','Yaroslavl','Ярославль'),('KZ','Almaty','Алматы'),('KZ','Astana','Астана'),('BY','Minsk','Минск'),('AM','Yerevan','Ереван'),('GE','Tbilisi','Тбилиси'),('FR','Paris','Париж'),('TR','Istanbul','Стамбул'),('DE','Berlin','Берлин'),('AE','Dubai','Дубай'),('TH','Bangkok','Бангкок'),('AU','Sydney','Сидней'),('ZA','Cape Town','Кейптаун'),('BR','Sao Paulo','Сан-Паулу'),('AR','Buenos Aires','Буэнос-Айрес'),('US','New York City','Нью-Йорк')]
cities=[]
for country,name,ru in wanted:
 matches=[x for x in rows if x[8]==country and name in [x[1],x[2],*x[3].split(',')]]
 assert matches,(country,name)
 x=max(matches,key=lambda x:int(x[14] or 0))
 cities.append({'id':int(x[0]),'name':ru,'country':country,'lat':float(x[4]),'lon':float(x[5])})
(a/'cities.json').write_text(json.dumps({'source':'GeoNames cities15000','license':'CC BY 4.0','cities':sorted(cities,key=lambda x:x['name'])},ensure_ascii=False,separators=(',',':'))+'\n')
notice='''Данные звёзд: HYG v4.1, David Nash / Astronexus, https://github.com/astronexus/HYG-Database
Лицензия CC BY-SA 4.0: https://creativecommons.org/licenses/by-sa/4.0/
Изменения ДВИЖ: выбор ярких звёзд (mag ≤ 4.5) и опорных звёзд фигур; поля HIP, RA, Dec, magnitude; округление; русские подписи. assets/sky/stars.json распространяется под CC BY-SA 4.0.

Координаты городов: GeoNames, https://www.geonames.org/
Лицензия CC BY 4.0: https://creativecommons.org/licenses/by/4.0/
Изменения ДВИЖ: выбор городов, координат центров и русских подписей; assets/sky/cities.json.

Линии фигур — собственные упрощённые схемы ДВИЖ. Это ориентиры, не официальные границы всех созвездий.
Лицензии данных относятся к соответствующим наборам. Исходный код приложения имеет свою лицензию (LICENSE).
'''
(a/'NOTICE.txt').write_text(notice)
licenses=r/'docs/data_licenses';licenses.mkdir(exist_ok=True)
for name in ['HYG_LICENSE.md','GEONAMES_README.txt']:(licenses/name).write_bytes((raw/name).read_bytes())
(r/'docs/SKY_DATA_SOURCES.json').write_text(json.dumps({'hyg_url':'https://raw.githubusercontent.com/astronexus/HYG-Database/main/hyg/CURRENT/hygdata_v41.csv','hyg_sha256':hashlib.sha256((raw/'hyg.csv').read_bytes()).hexdigest(),'geonames_url':'https://download.geonames.org/export/dump/cities15000.zip','geonames_sha256':hashlib.sha256((raw/'cities.zip').read_bytes()).hexdigest(),'stars':len(stars),'figures':len(figures),'cities':len(cities),'derived_data_notice':notice},ensure_ascii=False,indent=2)+'\n')
for hip in sorted(needed):print(hip,allrows[hip]['proper'],allrows[hip]['con'])
print('DATA READY',len(stars),len(figures),len(cities))
