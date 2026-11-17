# Lokalne środowisko Docker Compose

Przewodnik po usługach z [compose.yml](./compose.yml).
Adresy `localhost` dotyczą komputera, na którym działa Docker.

## Zacznij tutaj: flow poznawania aplikacji

**Najpierw aplikacja biznesowa, potem opcjonalne pluginy, na końcu infrastruktura.**
Nie musisz otwierać wszystkich paneli, żeby zacząć.
„Langusta” w tym środowisku to **Langfuse** — panel do analizy wywołań AI.

```text
1. AJ / TomorrowCommerce: http://localhost:8080
   Zaloguj się -> kategorie -> produkty -> szczegóły produktu
       |
       +--> 2. Opcjonalnie: pluginy Warehouse i Box Size
       |       Sprawdź rejestrację w /plugins, potem używaj ich w aplikacji
       |
       +--> 3. Opcjonalnie: plugin AI Description
               Szczegóły produktu -> zakładka AI Description -> generowanie
                   |
                   v
            4. LiteLLM: http://localhost:4000/ui/
               Modele, dostęp, wykorzystanie, błędy
                   |
                   v
            5. Langfuse: http://localhost:3100
               Trace wywołania, wejście/wyjście, czas, błąd, tokeny
                   |
                   v
            6. Dopiero gdy potrzebujesz głębszej diagnostyki:
               Presidio / PostgreSQL / ClickHouse / MinIO / Redis
```

### 0. Uruchom środowisko

1. Uruchom infrastrukturę: `docker compose up -d --wait`.
2. Uruchom aplikację Spring Boot i wybrane pluginy zgodnie z
   [README](./README.md). Sam Compose **nie uruchamia** aplikacji AJ ani pluginów.
3. Na Windows możesz uruchomić backend z katalogu repozytorium poleceniem
   `.\mvnw.cmd spring-boot:run`. Skrypt [start-dev.sh](./start-dev.sh)
   wymaga powłoki Bash, np. Git Bash, i uruchamia backend oraz wszystkie pluginy
   mające plik `package.json`.
4. Jeśli pracujesz nad samym frontendem hosta, uruchom `npm run dev` w
   [src/main/frontend](./src/main/frontend). Domyślny adres Vite to
   [http://localhost:5173](http://localhost:5173), a żądania `/api` są przekazywane
   do backendu na `8080`. Jeśli port jest zajęty, sprawdź adres wypisany przez Vite.
   To alternatywa developerska dla frontendu zbudowanego i serwowanego przez Spring Boot.

### 1. Otwórz aplikację i poznaj jej podstawowy przebieg

| Miejsce | Adres | Wymagane? | Co zrobić |
|---|---|---|---|
| Aplikacja AJ / TomorrowCommerce | [http://localhost:8080](http://localhost:8080) | **Tak — punkt startowy** | Zaloguj się kontem aplikacji; to osobne konto od Langfuse i LiteLLM. |
| Logowanie AJ | [http://localhost:8080/login](http://localhost:8080/login) | Tak, przy braku sesji | Zaloguj się przed korzystaniem z chronionych widoków. |
| Kategorie | [http://localhost:8080/categories](http://localhost:8080/categories) | Zalecane | Przejrzyj kategorie przed pracą z produktami. |
| Produkty | [http://localhost:8080/products](http://localhost:8080/products) | **Tak — główny scenariusz** | Otwórz produkt i sprawdź dane podstawowe oraz dostępne zakładki. |
| Zarządzanie pluginami | [http://localhost:8080/plugins](http://localhost:8080/plugins) | Opcjonalne | Sprawdź, jakie rozszerzenia są zarejestrowane i czy mają właściwe URL-e. |

### 2. Opcjonalnie: sprawdź pluginy w kontekście aplikacji

**Zaczynaj od aplikacji na `8080`, nie od bezpośredniego URL-a pluginu.**
Rozszerzenia korzystają z kontekstu hosta, np. aktualnego produktu i komunikacji
przez SDK. Sam działający serwer pluginu nie oznacza jeszcze jego rejestracji.

| Plugin | Adres serwera pluginu | Gdzie używać w aplikacji | Co sprawdzić |
|---|---|---|---|
| Warehouse | [http://localhost:3001](http://localhost:3001) | Menu „Warehouse”, zakładka „Stock Info” i informacja „Availability” przy produkcie. | Stany magazynowe i rozszerzenia widoku produktu. |
| Box Size | [http://localhost:3002](http://localhost:3002) | Szczegóły produktu: zakładka i informacja „Box Size”. | Wymiary opakowania dla wybranego produktu. |
| AI Description | Baza: `http://localhost:3003`; widok: [http://localhost:3003/product-tab](http://localhost:3003/product-tab) | Szczegóły produktu: zakładka „AI Description”. | Generowanie opisu przez LiteLLM; testuj z poziomu hosta, który przekazuje kontekst produktu. |

AI Description nie ma strony głównej pod `/` — odpowiedź `404` dla
`http://localhost:3003` sama w sobie nie oznacza awarii pluginu.

Jeśli rozszerzenia nie widać, przejdź do
[dodawania pluginu](http://localhost:8080/plugins/new), podaj identyfikator
i manifest JSON odpowiedniego pluginu:
[Warehouse](./plugins/warehouse/manifest.json),
[Box Size](./plugins/box-size/manifest.json),
[AI Description](./plugins/ai-description/manifest.json).
Następnie sprawdź jego stan w panelu pluginów.

### 3. Prześledź jedno wywołanie AI od początku do końca

1. Otwórz [LiteLLM UI](http://localhost:4000/ui/) i sprawdź konfigurację modelu.
   Plugin AI Description żąda modelu `gpt-4o-mini`; jego `LITELLM_API_KEY`
   musi uprawniać do wywołania bramy. Dostawca modelu również wymaga konfiguracji.
2. Wróć do aplikacji AJ, otwórz produkt i użyj zakładki „AI Description”.
3. W przeglądarce otwórz DevTools → Network. Sprawdź żądanie generowania i odpowiedź.
4. W LiteLLM sprawdź wykorzystanie lub błędy związane z tym wywołaniem.
5. Otwórz [Langfuse](http://localhost:3100), wybierz projekt i znajdź najnowszy
   trace według czasu. Sprawdź wejście, wyjście, czas i ewentualny błąd.
   Ślad może pojawić się z opóźnieniem; jego brak może oznaczać problem raportowania,
   a nie brak samego wywołania modelu.

### 4. Gdzie zajrzeć, gdy coś nie działa

| Objaw | Zacznij od | Następny krok |
|---|---|---|
| Nie działa logowanie, produkty lub kategorie | AJ: DevTools → Network i logi Spring Boot | Główna baza `postgres` na `localhost:5432`. |
| Nie widać pluginu albo jego widok jest pusty | [Panel pluginów AJ](http://localhost:8080/plugins) i konsola przeglądarki | Rejestracja, stan, URL i działający serwer konkretnego pluginu. |
| Generowanie AI zwraca błąd | Żądanie w przeglądarce, potem [LiteLLM](http://localhost:4000/ui/) | Klucz, model, dostawca; przy blokadzie danych osobowych sprawdź politykę Presidio. |
| Model odpowiedział, ale nie ma śladu | Właściwy projekt i zakres czasu w [Langfuse](http://localhost:3100) | Callbacki LiteLLM, konfiguracja dostępu do Langfuse i logi workera. |
| Chcesz zobaczyć dane biznesowe | DBeaver → `localhost:5432`, baza `aj` | Nie szukaj produktów AJ w bazach Langfuse ani LiteLLM. |
| Diagnozujesz magazyn lub analitykę Langfuse | [MinIO](http://localhost:9011), [ClickHouse](http://localhost:8123/play) | Sięgaj tutaj dopiero po sprawdzeniu panelu i logów Langfuse. |

## Szczegółowa lista paneli i usług

## Gdzie można poklikać

„Główny endpoint” oznacza miejsce do normalnej pracy z daną usługą
(panel albo operację API), a nie test jej dostępności.

| Adres | Główny endpoint? | Co znajdziesz | Od czego zacząć |
|---|---|---|---|
| [Langfuse](http://localhost:3100) | **Tak — panel** | Ślady wywołań AI, błędy, czasy odpowiedzi, tokeny i koszty, jeśli zostały zaraportowane. | Otwórz projekt i przejrzyj traces po wykonaniu zapytania przez LiteLLM. |
| [LiteLLM UI](http://localhost:4000/ui/) | **Tak — panel** | Modele, klucze, wykorzystanie i konfiguracja dostępna w danej wersji. | Sprawdź modele i ustawienia dostępu. |
| [LiteLLM Swagger UI](http://localhost:4000/) | Nie — dokumentacja i testy API | Interaktywna dokumentacja API. | Rozwiń endpoint, użyj „Try it out”; dla chronionych operacji potrzebna jest autoryzacja. |
| [MinIO Console](http://localhost:9011) | **Tak — panel** | Przeglądanie magazynu obiektowego zgodnego z S3. | Sprawdź bucket `langfuse` i obiekty zapisywane przez Langfuse. |
| [ClickHouse SQL Playground](http://localhost:8123/play) | **Tak — konsola SQL** | Prosty interfejs do wykonywania SQL w ClickHouse. | Po zalogowaniu wykonaj `SHOW DATABASES`. To bezpośredni dostęp do bazy, nie panel Langfuse. |

### Logowanie
Do aplikacji zaloguj się na http://localhost:8080/login danymi:

Login: admin
Hasło: admin123


W kolumnie „Hasło” podana jest **nazwa zmiennej, której wartość należy wpisać**,
nie dosłowny tekst hasła. Dzięki temu dokument nie powiela sekretów.

| Usługa / panel | Login | Hasło / klucz | Gdzie odczytać |
|---|---|---|---|
| Langfuse | Wartość `LANGFUSE_INIT_USER_EMAIL` | `LANGFUSE_INIT_USER_PASSWORD` | Sekcja `langfuse.environment` w [compose.yml](./compose.yml); dotyczy konta utworzonego przy inicjalizacji. |
| LiteLLM UI | `admin`, chyba że ustawiono `UI_USERNAME` | `UI_PASSWORD`; gdy nieustawione — wartość `LITELLM_MASTER_KEY` | Lokalny plik `litellm/.env`, wskazany przez `env_file` w [compose.yml](./compose.yml). |
| LiteLLM Swagger / API | Nie ma osobnego loginu | `LITELLM_MASTER_KEY` albo uprawniony virtual key | Przycisk „Authorize” w Swaggerze; w kliencie HTTP nagłówek `Authorization: Bearer <klucz>`. |
| MinIO Console / S3 | Wartość `MINIO_ROOT_USER` | `MINIO_ROOT_PASSWORD` | Sekcja `minio.environment` w [compose.yml](./compose.yml). Dla S3 są to odpowiednio access key i secret key. |
| ClickHouse | `default` (`CLICKHOUSE_USER`) | `CLICKHOUSE_PASSWORD` | Sekcja `clickhouse.environment` w [compose.yml](./compose.yml). |
| PostgreSQL AJ | `aj` (`POSTGRES_USER`), baza `aj` | `POSTGRES_PASSWORD` | Sekcja `postgres.environment` w [compose.yml](./compose.yml); port `5432`. |
| PostgreSQL Langfuse | `langfuse`, baza `langfuse` | `POSTGRES_PASSWORD` | Sekcja `langfuse-db.environment` w [compose.yml](./compose.yml); port `5433`. |
| PostgreSQL LiteLLM | `litellm`, baza `litellm` | `POSTGRES_PASSWORD` | Sekcja `litellm-db.environment` w [compose.yml](./compose.yml); port `5434`. |
| Redis | Brak skonfigurowanego uwierzytelniania | Brak | W obecnym Compose nie ustawiono hasła ani ACL. |
| Presidio Analyzer / Anonymizer | Brak | Brak | Obecny Compose nie dodaje autoryzacji przed API Presidio. |

Zmienne `LANGFUSE_INIT_USER_*` nie resetują hasła istniejącego konta.
PostgreSQL również nie zmienia hasła istniejącej bazy przez samą zmianę
`POSTGRES_PASSWORD` w Compose.

Zasady domyślnego logowania LiteLLM opisuje
[oficjalna dokumentacja UI](https://docs.litellm.ai/docs/proxy/ui).
Konta utworzone później w panelu mogą mieć własne dane logowania.

Nie kopiuj kluczy ani haseł do tego przewodnika. Konfiguracja Compose jest
przeznaczona do lokalnego developmentu, nie do publicznego wdrożenia.

## Główne API i pomocnicze endpointy

Te adresy służą klientom HTTP, aplikacjom i integracjom.
Żądania **POST wymagają JSON-a** — samo otwarcie adresu w przeglądarce
nie wykona operacji.

| Adres | Metoda / protokół | Główny endpoint? | Zastosowanie |
|---|---|---|---|
| `http://localhost:4000/v1/chat/completions` | POST | **Tak — wywołania AI** | Zapytanie do modelu przez LiteLLM. Wymaga właściwego modelu, klucza i dostępu do dostawcy. |
| `http://localhost:5002/analyze` | POST | **Tak — wykrywanie PII** | Zwraca typy i pozycje danych osobowych w tekście. |
| `http://localhost:5001/anonymize` | POST | **Tak — anonimizacja** | Przekształca fragmenty wskazane przez analizator. |
| `http://localhost:5001/deanonymize` | POST | Nie — dodatkowa operacja | Odwraca obsługiwane przekształcenia, np. szyfrowanie z odpowiednim kluczem. Nie odtworzy tekstu zastąpionego etykietą. |
| [ClickHouse HTTP](http://localhost:8123) | HTTP SQL | **Tak — SQL przez HTTP** | Zapytania do bazy z odpowiednią autoryzacją. |
| [MinIO S3 API](http://localhost:9010) | S3 przez HTTP | **Tak — magazyn obiektów** | Endpoint dla klientów S3. Bez podpisanego żądania może zwrócić błąd dostępu. |
| [Presidio: operatory anonimizacji](http://localhost:5001/anonymizers) | GET | Nie — pomocniczy | Lista dostępnych operatorów jako JSON. |
| [Presidio: operatory deanonimizacji](http://localhost:5001/deanonymizers) | GET | Nie — pomocniczy | Lista operatorów odwracających obsługiwane przekształcenia. |

<details>
<summary>Diagnostyka: health checki (nie są głównymi endpointami)</summary>

| Adres | Główny endpoint? | Zastosowanie |
|---|---|---|
| [Langfuse health](http://localhost:3100/api/public/health) | Nie | Stan aplikacji Langfuse. |
| [LiteLLM liveness](http://localhost:4000/health/liveliness) | Nie | Czy proces odpowiada; nie potwierdza dostępu do modeli. |
| [ClickHouse ping](http://localhost:8123/ping) | Nie | Test dostępności serwera. |
| [MinIO liveness](http://localhost:9010/minio/health/live) | Nie | Test działania MinIO; poprawna odpowiedź może mieć pustą treść. |
| [Presidio Analyzer health](http://localhost:5002/health) | Nie | Stan usługi wykrywającej dane osobowe. |
| [Presidio Anonymizer health](http://localhost:5001/health) | Nie | Stan usługi anonimizującej dane. |

</details>

## Bazy i protokoły inne niż HTTP

Tych adresów nie otwierasz w przeglądarce. Użyj klienta bazy, np. DBeaver,
DataGrip, `psql`, `redis-cli` albo klienta ClickHouse.

| Usługa | Adres z komputera | Adres z sieci Compose | Baza / przeznaczenie |
|---|---|---|---|
| `postgres` | `localhost:5432` | `postgres:5432` | `aj` — dane aplikacji biznesowej. |
| `langfuse-db` | `localhost:5433` | `langfuse-db:5432` | `langfuse` — relacyjne dane Langfuse. |
| `litellm-db` | `localhost:5434` | `litellm-db:5432` | `litellm` — dane bramy AI. |
| `redis` | `localhost:6379` | `redis:6379` | Kolejki i dane pomocnicze Langfuse. |
| `clickhouse` | `localhost:9000` | `clickhouse:9000` | Natywny protokół ClickHouse; HTTP jest na porcie `8123`. |

Przykład: `5433:5432` oznacza **port komputera : port kontenera**.
Dlatego z DBeavera łączysz się z Langfuse PostgreSQL przez `localhost:5433`,
ale sam Langfuse używa `langfuse-db:5432`.
`localhost` wewnątrz kontenera oznacza ten kontener, nie komputer gospodarza.

## Co daje każdy obraz

**Obraz** jest szablonem uruchomieniowym. **Usługa** to wpis w Compose,
a **kontener** to uruchomiona instancja obrazu. Ten sam obraz PostgreSQL
obsługuje tu trzy niezależne instancje baz.

| Usługa | Obraz | Rola w ekosystemie |
|---|---|---|
| `postgres` | `postgres:18` | Główna baza aplikacji AJ. Przechowuje dane biznesowe; jest niezależna od baz narzędzi AI. |
| `langfuse-db` | `postgres:18` | Relacyjny magazyn Langfuse: m.in. użytkownicy, organizacje, projekty i konfiguracja. Nie zastępuje ClickHouse. |
| `clickhouse` | `clickhouse/clickhouse-server:26.8.37.168` | Analityczna baza Langfuse do danych obserwowalności i ich agregowania. Umożliwia analizę dużej liczby zdarzeń AI. |
| `minio` | `pgsty/minio:latest` | Lokalny odpowiednik magazynu S3. Langfuse ma skonfigurowany zapis danych zdarzeń do bucketu `langfuse`. |
| `minio-setup` | `pgsty/mc:latest` | Jednorazowy klient administracyjny MinIO. Ustawia połączenie i tworzy bucket `langfuse`; zakończenie z kodem `0` jest prawidłowe. Nie ma panelu ani portu. |
| `redis` | `redis:7` | Wspiera Langfuse w kolejkowaniu pracy i przechowywaniu danych pomocniczych. W tym Compose LiteLLM nie ma skonfigurowanego połączenia do Redis. |
| `langfuse` | `langfuse/langfuse:latest` | Aplikacja webowa i API obserwowalności AI. Zbiera informacje o wywołaniach i udostępnia je w panelu. |
| `langfuse-worker` | `langfuse/langfuse-worker:latest` | Procesuje zadania Langfuse w tle, korzystając z jego infrastruktury. Nie jest drugim panelem. Port kontenera `3030` nie jest opublikowany na komputerze. |
| `presidio-analyzer` | `mcr.microsoft.com/presidio-analyzer:latest` | Wykrywa dane osobowe i zwraca ich typ, pozycję i pewność detekcji. Sam nie maskuje tekstu. |
| `presidio-anonymizer` | `mcr.microsoft.com/presidio-anonymizer:latest` | Przekształca wykryte fragmenty, np. zastępuje e-mail etykietą. Nie wykrywa samodzielnie, gdzie są dane osobowe. |
| `litellm-db` | `postgres:18` | Trwały magazyn LiteLLM: m.in. konfiguracja modeli zapisywanych w bazie oraz dane administracyjne i wykorzystania. |
| `litellm` | `docker.io/litellm/litellm:main-stable` | Wspólna brama API do zewnętrznych modeli. Łączy routing do dostawców, guardrail Presidio i raportowanie do Langfuse. Nie uruchamia lokalnie modeli OpenAI ani Anthropic. |

## Konkurencyjne rozwiązania i przydatne aplikacje

Poniższe narzędzia **nie są uruchomione w tym Compose**. Linki prowadzą
do ich stron, a nie do lokalnych paneli. To propozycje do porównania,
nie zalecenie dołożenia wszystkiego naraz.

### Alternatywy dla obecnych usług

| Obecna usługa | Konkurencyjne rozwiązania | Kiedy warto rozważyć |
|---|---|---|
| Langfuse | [Arize Phoenix](https://arize.com/docs/phoenix), [LangSmith](https://docs.langchain.com/langsmith/home) | Phoenix do obserwowalności i ewaluacji AI z naciskiem na OpenTelemetry; LangSmith do debugowania, ewaluacji i pracy z ekosystemem LangChain. |
| LiteLLM | [Portkey](https://portkey.ai/docs), [Kong AI Gateway](https://developer.konghq.com/ai-gateway/) | Gdy porównujesz bramy AI, routing, polityki dostępu i integrację z istniejącą bramą API. |
| Presidio | [Google Sensitive Data Protection](https://cloud.google.com/sensitive-data-protection/docs), [Amazon Comprehend PII](https://docs.aws.amazon.com/comprehend/latest/dg/how-pii.html) | Gdy preferujesz zarządzaną usługę wykrywania danych wrażliwych. Sprawdź języki, obsługę PESEL i zasady wysyłania tekstu do chmury — nie są identyczne z Presidio. |
| MinIO | [SeaweedFS](https://github.com/seaweedfs/seaweedfs), [LocalStack](https://docs.localstack.cloud/) | SeaweedFS jako alternatywny magazyn z API S3; LocalStack do lokalnego testowania API AWS, nie jako docelowy produkcyjny magazyn. |
| Redis | [Valkey](https://valkey.io/) | Gdy szukasz alternatywy z protokołem zgodnym z Redis. Przed zamianą sprawdź wersje i wymagania Langfuse. |

To nie są automatyczne zamienniki obrazu w Compose. Zmiana może wymagać
konfiguracji integracji, migracji danych i osobnych testów.
ClickHouse i PostgreSQL są elementami architektury Langfuse;
nie zastępuj ich dowolną bazą tylko dlatego, że również obsługuje SQL.

### Aplikacje, które ułatwią pracę z obecnym Compose

| Aplikacja | Do czego się przyda | Gdzie się podłączyć / jak zalogować |
|---|---|---|
| [DBeaver Community](https://dbeaver.io/) | Jeden klient do przeglądania PostgreSQL i ClickHouse oraz wykonywania SQL. | PostgreSQL: `localhost:5432`, `5433`, `5434`; ClickHouse: sterownik HTTP i port `8123`. Dane w tabeli „Logowanie”. |
| [pgAdmin](https://www.pgadmin.org/) | Panel do administracji PostgreSQL. | Dodaj trzy serwery z portami `5432`, `5433`, `5434`. Konto samego pgAdmin ustawiasz przy jego instalacji; to nie jest konto bazy. |
| [Redis Insight](https://redis.io/insight/) | Przeglądanie kluczy Redis i diagnostyka danych pomocniczych Langfuse. | `localhost:6379`; obecnie bez hasła. Nie edytuj ani nie kasuj kluczy kolejki w ciemno. |
| [Bruno](https://www.usebruno.com/), [Postman](https://www.postman.com/) | Wysyłanie JSON-a do Presidio i testowanie LiteLLM bez pisania aplikacji. | Presidio: bez autoryzacji; LiteLLM: Bearer token z uprawnionym kluczem. |
| [S3 Browser](https://s3browser.com/), [Cyberduck](https://cyberduck.io/) | Przeglądanie i przesyłanie obiektów MinIO z aplikacji desktopowej. | Endpoint `http://localhost:9010`; access key = `MINIO_ROOT_USER`, secret key = `MINIO_ROOT_PASSWORD`. Wybierz połączenie S3 przez HTTP. |

**Na początek:** obecne panele + DBeaver + Bruno wystarczą do większości
eksperymentów. Redis Insight dołóż, gdy potrzebujesz zajrzeć do Redis.
Nie musisz zakładać kont u konkurencyjnych dostawców, aby używać tego Compose.

Adresy `localhost` w tej tabeli zakładają narzędzia uruchomione na komputerze.
Jeżeli uruchomisz np. pgAdmin w kontenerze, użyj nazw usług i portów wewnętrznych
z tabeli baz, a kontener dołącz do sieci Compose.

## Jak to współpracuje

```text
Aplikacja / plugin / klient API
              |
              v
           LiteLLM ----------------------> zewnętrzny dostawca modelu
              |                           (po kontroli guardraila)
              +--> Presidio Analyzer
              |           |
              |           v
              |    Presidio Anonymizer
              |
              +--> litellm-db
              |
              +--> Langfuse: raportowanie sukcesów i błędów
                         |
                         +--> langfuse-db: dane relacyjne
                         +--> Redis: kolejki / dane pomocnicze
                         +--> MinIO: magazyn zdarzeń S3
                         +--> ClickHouse: dane analityczne
                         +--> Langfuse Worker: przetwarzanie w tle

Aplikacja AJ --> postgres: dane biznesowe
```

W [konfiguracji LiteLLM](./litellm/config.yaml):

- guardrail `presidio-pii` działa w trybie `pre_call` i ma `default_on: true`;
- numery kart (`CREDIT_CARD`) mają politykę `BLOCK`;
- telefon, e-mail i `PL_PESEL` mają politykę `MASK`;
- własne rozpoznawanie encji wskazuje
  [presidio_recognizers.json](./litellm/presidio_recognizers.json);
- callbacki sukcesu i błędu wskazują Langfuse;
- włączone jest przechowywanie promptów w logach wykorzystania.
  Przed przesyłaniem prawdziwych danych sprawdź, co faktycznie zapisują logi
  i ślady — sama obecność Presidio nie gwarantuje usunięcia wszystkich danych wrażliwych.

Uruchomione kontenery nie oznaczają jeszcze działającego wywołania LLM.
Potrzebne są klucze dostawców i poprawne nazwy modeli lub wdrożeń.
Wpis Azure zawiera placeholder `NAZWA_WDROZENIA_Z_AZURE`, który trzeba
zastąpić właściwą nazwą przed użyciem tej trasy.

## Co zostaje po zatrzymaniu

| Wolumen | Zawartość |
|---|---|
| `postgres-data` | Dane biznesowe AJ. |
| `langfuse-db-data` | Dane PostgreSQL Langfuse. |
| `clickhouse-data` | Dane ClickHouse. |
| `minio-data` | Obiekty MinIO. |
| `litellm-db-data` | Dane PostgreSQL LiteLLM. |

Redis nie ma tu podpiętego wolumenu — nie traktuj jego danych jako trwałych
po odtworzeniu kontenera.

`docker compose down` zachowuje nazwane wolumeny.
**`docker compose down -v` usuwa je razem z danymi.**

## Czego ten Compose nie uruchamia

- Aplikacji Spring Boot AJ.
- Frontendów pluginów i ich serwerów developerskich.
- Zewnętrznych modeli AI.
- Osobnych paneli pgAdmin ani RedisInsight.

Adresów frontendów i Spring Boota nie da się więc wyprowadzić z tego Compose.
Ich uruchamianie opisuje [README](./README.md).
