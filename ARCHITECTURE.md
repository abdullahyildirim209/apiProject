# JSP Tabanli REST API - Mimari Analiz ve Rehber

> Bu proje **pure JSP** (saf JSP) tabanli bir REST API backend'idir. Geleneksel Servlet veya Spring MVC kullanilmamis; bunun yerine JSP dosyalari hem controller hem model gorevi goruyor. Her JSP dosyasi `application/json` donduruyor - yani klasik HTML sayfalari ureten JSP'den farkli olarak, burada JSP bir **JSON API engine** olarak kullanilmis.

---

## Neden Bu Mimari?

JSP'yi sadece view katmani gibi degil, dogrudan bir REST endpoint gibi kullanmak amaclanmis. Yani her JSP dosyasi bir nevi controller + service gibi davraniyor ve JSON donuyor.

Bu projede Spring Boot'taki gibi dependency injection, controller annotation'lari, repository katmani gibi soyutlamalar yok. Her sey manuel ve daha "low-level". Bunun sebebi, JSP lifecycle'ini, Servlet yapisini ve JDBC'yi dogrudan anlamak.

---

## Spring Boot ile Karsilastirma Tablosu

Eger Spring Boot'tan geliyorsan, kafani karistiran nokta buyuk ihtimalle soyutlamalarin olmamasi. Asagidaki tablo, bu projedeki her parcayi bildigin Spring kavramiyla eslestiriyor:

| Bu Projede | Spring Boot Karsiligi | Aciklama |
|---|---|---|
| `index.jsp` | `@RestController` + `@GetMapping` | HTTP istegini karsilar, JSON dondurur |
| `authenticate.jsp` | `@PostMapping("/auth")` | Kimlik dogrulama endpoint'i |
| `update.jsp` | `@PutMapping` veya `@PostMapping` | Guncelleme endpoint'i |
| `test.jsp` | `@GetMapping("/test")` | Test/raw SQL endpoint'i |
| `Postgre.jsp` | `@Repository` + `JdbcTemplate` | Veritabani erisim katmani |
| `Json.jsp` | `@RequestBody` + DTO parsing | Request body okuma ve query builder |
| `Redis.jsp` | `RedisTemplate` / `@Cacheable` | Cache katmani |
| `Mongo.jsp` | `MongoTemplate` + `@Slf4j` Logger | Loglama/audit katmani |
| `Request.jsp` | `HttpServletRequest` wrapper + `@Value` | HTTP request yardimcilari |
| `config.jsp` | `@Configuration` + `application.properties` | Ortam degiskenleri yukleme |
| `error.jsp` | `@ControllerAdvice` + `@ExceptionHandler` | Global hata yakalama |
| `<%@include %>` | `@Autowired` / `@Import` | Dependency dahil etme mekanizmasi |
| `dotenv` nesnesi | `@Value("${...}")` | Ortam degiskeni okuma |
| `Docker-compose.yml` | `docker-compose.yml` (ayni) | Altyapi servisleri |

---

## Mantigin Oturmasi Icin Bilinmesi Gerekenler

### 1. JSP aslinda bir Servlet'tir

Bu en kritik nokta. JSP dosyasi Tomcat tarafindan otomatik olarak bir **Java Servlet sinifina** derlenir. Yani su JSP kodu:

```jsp
<%
    String name = "Dunya";
    out.print("Merhaba " + name);
%>
```

Tomcat tarafindan arka planda su sekle donusturulur:

```java
public class index_jsp extends HttpServlet {
    public void _jspService(HttpServletRequest request, HttpServletResponse response) {
        JspWriter out = response.getWriter();
        String name = "Dunya";
        out.print("Merhaba " + name);
    }
}
```

Bu sayede JSP icinde yazilan her `<% ... %>` scriptlet kodu, aslinda bir servlet'in `service()` metodu icerisinde calisir. `request`, `response`, `out`, `session` gibi nesneler JSP'nin **implicit object**'leridir - yani tanimlamadan dogrudan kullanabilirsin.

### 2. `<%@include %>` compile-time birlestirmedir

```jsp
<%@include file="classes/Postgre.jsp" %>
```

Bu satir, `Postgre.jsp` dosyasinin icerigini **derleme zamaninda** mevcut dosyaya yapistirir. Runtime'da ayri bir dosya cagrisi yapilmaz. Sonuc olarak, `Postgre.jsp` icinde tanimlanan `Postgre` sinifi, `index.jsp`'nin derlenmis servlet'inin bir **ic sinifi** (inner class) haline gelir.

Bunu Spring'deki `@Autowired` gibi dusunebilirsin - ama burada dependency injection framework'u yok, dogrudan dosya birlestirilmesi var.

### 3. Include zinciri neden onemli

`Postgre.jsp` dosyasinin basinda su satirlar var:

```jsp
<%@include file="Mongo.jsp" %>
<%@include file="Json.jsp" %>
```

Yani `index.jsp` sadece `Postgre.jsp`'yi include ettiginde, otomatik olarak `Mongo.jsp` ve `Json.jsp` de dahil olmus oluyor. Zincir soyle calisir:

```
index.jsp
  └── config.jsp          → dotenv nesnesi olusur
  └── Postgre.jsp
        └── Mongo.jsp     → Mongo sinifi tanimlanir
        └── Json.jsp      → Json sinifi tanimlanir (Postgre'nin parent'i)
        └── Postgre sinifi tanimlanir (Json'dan extends)
```

Tum bu dosyalar derleme zamaninda tek bir servlet'e birlesir.

---

## Katman Katman Mimari Analiz

### Katman 1: Endpoint JSP'ler (Controller Katmani)

Bu dosyalar, istemciden gelen HTTP isteklerini karsilayan giris noktalaridir. Her biri ayni kalipla calisir:

```
1. config.jsp include et  → dotenv nesnesi olusur (.env dosyasindan)
2. classes/*.jsp include et → Java siniflari sayfaya dahil edilir
3. Scriptlet icinde is mantigi calistirilir
4. JSON response yazilir
```

#### `index.jsp` - SELECT Endpoint'i

```
config.jsp → Postgre.jsp include
→ Postgre nesnesi olustur (request body'den JSON okur)
→ Eger hata yoksa postgre.select() cagir
→ JSON sonuc yaz
```

**Gercek kod akisi** (`index.jsp:3-10`):
```jsp
Postgre postgre = new Postgre(request.getInputStream());
if(postgre.error != 1){
    out.print(postgre.select());
}
```

Spring karsiligi soyleydi:
```java
@PostMapping("/")
public ResponseEntity<?> index(@RequestBody QueryRequest req) {
    return ResponseEntity.ok(postgreRepository.select(req));
}
```

#### `authenticate.jsp` - Kimlik Dogrulama Endpoint'i

Bu endpoint en karmasik akisa sahip. Adim adim:

```
1. config.jsp → dotenv yukle
2. Request.jsp → UUID token uret
3. Postgre.jsp → kullaniciyi dogrula (SELECT ile)
4. Basariliysa:
   a. Token'i ve IP adresini SET clause'una yerlestir
   b. UPDATE ile veritabanina kaydet
   c. Redis'e IP:token cifti olarak yaz (2 dk TTL)
   d. 200 + token dondur
5. Basarisizsa:
   a. 401 Unauthorized dondur
```

**Gercek kod akisi** (`authenticate.jsp:15-46`):
```jsp
Request rh        = new Request();                              // UUID token uretilir
String token      = rh.getToken();
Postgre postgre   = new Postgre(request.getInputStream());      // body parse + DB baglanti

InetAddress inetAddress = InetAddress.getLocalHost();
String ipAddress        = inetAddress.getHostAddress();         // sunucu IP'si alinir

JSONObject jo     = postgre.select();                           // kullanici dogrulama
Integer jo_status = (Integer) (jo.get("status"));

if(jo_status.equals(200)){                                      // kullanici bulundu
    postgre.set = postgre.set.replace("--token--", token);      // placeholder'lar dolduruluyor
    postgre.set = postgre.set.replace("--ip--", ipAddress);
    JSONObject jou = postgre.update();                          // DB'ye token yazilir

    if(jou_status.equals("200")){
        Redis redis = new Redis();
        redis.setString(ipAddress, token);                      // Redis'e cache yazilir (2dk TTL)
        out.print("{\"status\": 200, \"token\": \"" + token + "\"}");
    }
}
```

Burada dikkat edilmesi gereken onemli bir desen var: istemci JSON body'de `--token--` ve `--ip--` gibi placeholder'lar gonderiyor, sunucu tarafinda bunlar gercek degerlerle replace ediliyor. Bu, SET clause'unu dinamik hale getirmenin yaratici bir yolu.

#### `update.jsp` - UPDATE Endpoint'i

En sade endpoint. Body'den tablo, set ve where bilgilerini okur, UPDATE calistirir:

```jsp
Postgre postgre = new Postgre(request.getInputStream());
out.print(postgre.update());
```

#### `test.jsp` - Raw SQL Endpoint'i

Dogrudan SQL sorgusu calistirmak icin. Body'de `sql` alani dolu geldiginde bu kullanilir:

```jsp
Postgre postgre = new Postgre(request.getInputStream());
if(postgre.error != 1) {
    out.print(postgre.rawSql());
}
```

---

### Katman 2: Class JSP'ler (Model/Service Katmani)

#### `Json.jsp` - Temel Sinif (Abstract Query Builder)

`Json` sinifi, tum veritabani islemlerinin temelini olusturur. Gorevi:
1. HTTP request body'sini okumak (InputStream → String → JSONObject)
2. JSON'dan sorgu parametrelerini cikarir: `table`, `sql`, `where`, `set`, `limit`
3. WHERE ve SET clause'larini dinamik olarak olusturmak

**Body okuma mekanizmasi** (`Json.jsp:34-36`):
```java
public JSONObject jsonRead(InputStream inputStream){
    Scanner s     = new Scanner(inputStream).useDelimiter("\\A");
    String result = s.hasNext() ? s.next() : "";
    jsonObject    = new JSONObject(result);
    parseRequestJsonBody(jsonObject);
    // ...
}
```

`Scanner("\\A")` deseni - InputStream'in **tamamini** tek seferde okur. `\A` regex'te "string baslangicindan once" demektir, dolayisiyla delimiter hic eslesmedigi icin Scanner tum icerigi tek bir token olarak okur. Bu, StackOverflow'da "Java read InputStream to String" aramasinin en yaygin cevabi.

**WHERE clause olusturma** (`Json.jsp:78-90`):
```java
Iterator<String> keys = where.keys();
while(keys.hasNext()) {
    if(i == 0) filter += " WHERE ";
    else       filter += " AND ";
    String key = keys.next();
    filter += " " + key + " = '" + where.get(key) + "'";
    i++;
}
```

Ornek: `{"where": {"username": "ali", "status": "active"}}` girdisi icin:
```sql
 WHERE username = 'ali' AND status = 'active'
```

**SET clause olusturma** (`Json.jsp:93-106`) - ayni mantikla:
```sql
 SET token = '--token--', ip = '--ip--'
```

**Kalitim iliskisi:** `Postgre extends Json` - Postgre sinifi JSON parse yeteneklerini Json'dan miras alir. Constructor'da `jsonRead()` cagirildiginda, body otomatik olarak parse edilir ve `table`, `filter`, `set`, `sql` gibi alanlar dolar.

#### `Postgre.jsp` - Veritabani Erisim Katmani

Spring'deki `@Repository` katmaninin karsiligi. `Json` sinifinden turetilmis.

**Constructor akisi** (`Postgre.jsp:32-43`):
```java
public Postgre(InputStream inputStream){
    requestBodyParameters = jsonRead(inputStream);  // Json'dan miras: body oku + parse et
    if(table == null && sql.equals("")){
        error = 1;                                   // tablo da sql de yoksa hata
    } else{
        connect();                                   // PostgreSQL'e baglan
    }
}
```

**Baglanti kurma** (`Postgre.jsp:45-64`):
```java
String url = "jdbc:postgresql://" + dotenv.get("POSTGRES_SERVER") + ":"
           + dotenv.get("POSTGRES_PORT") + "/" + dotenv.get("POSTGRES_DB")
           + "?user=" + dotenv.get("POSTGRES_USER") + "&password="
           + dotenv.get("POSTGRES_PASSWORD") + "&ssl=" + dotenv.get("POSTGRES_SSL");

Class.forName("org.postgresql.Driver").newInstance();
conn = java.sql.DriverManager.getConnection(url);
stmt = conn.createStatement();
```

Burada `dotenv` nesnesi `config.jsp`'den geliyor - include zinciri sayesinde bu degisken scope'ta mevcut.

**select() metodu** (`Postgre.jsp:66-111`):
```java
public JSONObject select(){
    if(!sql.equals("")){
        query = sql;                                        // raw SQL varsa onu kullan
    } else{
        query = "SELECT * FROM " + table + filter + limit;  // yoksa parcalardan olustur
    }
    rs = stmt.executeQuery(query);
    // ResultSet → JSONArray donusumu
    ResultSetMetaData rsmd = rs.getMetaData();
    int columnCount = rsmd.getColumnCount();
    while (rs.next()) {
        JSONObject rowdata = new JSONObject();
        for (int i = 1; i <= columnCount; i++) {
            String name = rsmd.getColumnName(i);
            rowdata.put(name, rs.getString(name));          // kolon adi = key, deger = value
        }
        userList.put(rowdata);
    }
}
```

`ResultSetMetaData` kullanimi burada cok onemli: kolon adlarini hardcode etmek yerine, metadata'dan dinamik olarak okuyor. Bu sayede **herhangi bir tablo** icin calisiyor - generic bir yapiya sahip.

**update() metodu** (`Postgre.jsp:113-138`):
```java
query = "UPDATE " + table + set + filter;
PreparedStatement pstmt = conn.prepareStatement(query);
pstmt.executeUpdate();
```

**rawSql() metodu** (`Postgre.jsp:140-156`) - Aslinda `select()` metodunu cagirir. Raw SQL zaten `sql` alaninda sakli oldugu icin, `select()` icinde `if(!sql.equals(""))` kosulu onu yakalar.

#### `Redis.jsp` - Cache Katmani

Redisson kutuphanesi ile Redis'e baglanir. Authenticate akisinda IP adresi key, token value olarak kullanilir.

```java
class Redis{
    public Redis(){
        Config cnfg = new Config();
        cnfg.useSingleServer()
            .setAddress("redis://" + dotenv.get("REDIS_SERVER") + ":" + dotenv.get("REDIS_PORT"))
            .setPassword(dotenv.get("REDIS_PASSWORD"));
        redisson = Redisson.create(cnfg);
    }

    public void setString(String key, String value){
        RBucket<String> bucket = redisson.getBucket(key);
        bucket.set(value, 2, TimeUnit.MINUTES);             // 2 dakika TTL
    }

    public String getString(String key){
        RBucket<String> bucket = redisson.getBucket(key);
        return bucket.get();
    }
}
```

`RBucket` Redisson'un en temel veri yapisıdır - tek bir key-value cifti tutar. `2, TimeUnit.MINUTES` parametresi degerin 2 dakika sonra otomatik silinmesini saglar (token suresi).

#### `Mongo.jsp` - Loglama/Audit Katmani

Tum islemleri ve hatalari MongoDB'ye yazar. Spring'deki `@Slf4j` + `MongoTemplate` kombinasyonunun karsiligi.

**Temel metot - `setAndInsert()`** (`Mongo.jsp:99-128`):
```java
public void setAndInsert(Exception e, String method, String type, String file, String message){
    JSONObject jo = new JSONObject();
    if(e != null){
        // Hata varsa: stack trace cikar
        StringWriter sw = new StringWriter();
        PrintWriter pw  = new PrintWriter(sw);
        e.printStackTrace(pw);
        jo.put("message1", e.getMessage());
        jo.put("trace", sw.toString());
    } else{
        // Bilgi logu: sadece mesaj
        jo.put("message1", message);
    }
    jo.put("method", method);
    jo.put("type", type);      // "error", "watch", "trace"
    jo.put("file", file);
    set(jo);                    // Document'i hazirla
    insert();                   // MongoDB'ye yaz
}
```

Kullanim ornekleri:
```java
// Hata loglama
mongo.setAndInsert(sqlException, "connect", "error", "Postgre.jsp", null);

// Bilgi loglama
mongo.setAndInsert(null, "jsonRead", "watch", "Json.jsp", requestBody);

// Iz surme (trace)
mongo.setAndInsert(null, "connect", "trace", "Postgre.jsp", connectionUrl);
```

Her sinifin `catch` bloklarinda `Mongo.setAndInsert()` cagirilir - bu sekilde merkezi bir hata takip sistemi olusturulmus.

#### `Request.jsp` - HTTP Request Yardimcilari

```java
class Request{
    private String token;

    public Request(){
        this.token = UUID.randomUUID().toString();   // Constructor'da token uretilir
    }

    public Map<String, String> parameters(){
        // Form parametrelerini Map olarak dondurur
        Enumeration parameterNames = request.getParameterNames();
        Map<String, String> hm = new HashMap<>();
        while(parameterNames.hasMoreElements()){
            String name  = (String) parameterNames.nextElement();
            String value = request.getParameter(name);
            hm.put(name, value);
        }
        return hm;
    }

    public String getToken() {
        return this.token;
    }
}
```

---

### Katman 3: Konfigürasyon

#### `config.jsp` - Ortam Degiskenleri

```jsp
<%@ page import="io.github.cdimascio.dotenv.Dotenv" %>
<%
    Dotenv dotenv = Dotenv
        .configure()
        .directory(request.getServletContext().getRealPath(""))
        .filename(".env")
        .ignoreIfMalformed()
        .load();
%>
```

`dotenv-java` kutuphanesi Node.js ekosisteminden esinlenilmis. `.env` dosyasindan degiskenleri yukler. Bu nesne include zinciri sayesinde tum class JSP'lerde erisilebilir durumda.

#### `error.jsp` - Global Hata Yakalayici

```jsp
<%@ page isErrorPage="true" %>
```

Bu directive JSP'nin hata sayfasi oldugunu belirtir. Baska JSP'lerde `<%@ page errorPage="error.jsp" %>` ile bu sayfaya yonlendirme yapilir. Yakalanmamis tum exception'lar buraya duser, MongoDB'ye loglanir ve JSON error response dondurulur.

Spring'deki karsiligi:
```java
@ControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(Exception.class)
    public ResponseEntity<?> handleAll(Exception ex) { ... }
}
```

---

### Katman 4: Docker Altyapisi

`Docker-compose.yml` dort servisi ayaga kaldirir:

| Servis | Image | Port | IP (Bridge) | Amac |
|--------|-------|------|-------------|------|
| PostgreSQL | bitnami/postgresql:latest | 5432 | 173.17.0.2 | Ana veritabani |
| PgAdmin | dpage/pgadmin4 | 8888 | 173.17.0.8 | DB yonetim araci |
| Redis | bitnami/redis:latest | 6379 | 173.17.0.5 | Token cache |
| MongoDB | mongo:7.0 | 27017 | 173.17.0.4 | Loglama |

Tum servisler `standart` adinda bir bridge network uzerinde sabit IP'lerle calisir.

---

## Veri Akis Diyagrami

```
Istemci (Postman / Frontend)
    |
    | HTTP POST + JSON Body
    | { "table": "users", "where": {"id": "1"}, "limit": "10" }
    v
+----------------------------------------------------------+
| Endpoint JSP (ornek: index.jsp)                          |
|                                                          |
|  <%@include config.jsp %>    → dotenv olusur             |
|  <%@include Postgre.jsp %>   → Mongo + Json + Postgre   |
|                                                          |
|  new Postgre(request.getInputStream())                   |
+----------------------------------------------------------+
    |
    v
+----------------------------------------------------------+
| Json.jsonRead() - Body Parse                             |
|                                                          |
|  Scanner ile InputStream → String                        |
|  String → JSONObject                                     |
|  parseRequestJsonBody():                                 |
|    table  = "users"                                      |
|    filter = " WHERE id = '1'"                            |
|    limit  = " limit 10"                                  |
|    sql    = "" (bos, cunku raw SQL yok)                  |
|                                                          |
|  Mongo.setAndInsert() → istek logu MongoDB'ye yazilir    |
+----------------------------------------------------------+
    |
    v
+----------------------------------------------------------+
| Postgre.connect() - Veritabani Baglantisi                |
|                                                          |
|  dotenv'den: host, port, db, user, password okunur       |
|  JDBC URL olusturulur                                    |
|  DriverManager.getConnection(url)                        |
|  Statement olusturulur                                   |
+----------------------------------------------------------+
    |
    v
+----------------------------------------------------------+
| Postgre.select() - Sorgu Calistirma                      |
|                                                          |
|  sql bos mu? → Evet:                                     |
|    query = "SELECT * FROM users WHERE id = '1' limit 10" |
|                                                          |
|  stmt.executeQuery(query)                                |
|  ResultSetMetaData ile kolon adlari okunur               |
|  Her satir → JSONObject (kolon adi = key)                |
|  Tum satirlar → JSONArray                                |
+----------------------------------------------------------+
    |
    v
+----------------------------------------------------------+
| JSON Response                                            |
|                                                          |
|  {                                                       |
|    "status": 200,                                        |
|    "users": [                                            |
|      {"id": "1", "name": "Ali", "email": "ali@x.com"}   |
|    ]                                                     |
|  }                                                       |
+----------------------------------------------------------+
    |
    v
Istemciye donus
```

---

## Ornek API Request'leri

### SELECT - Tablo sorgusu
```json
POST /api/index.jsp
{
    "table": "users",
    "where": {
        "status": "active"
    },
    "limit": "10"
}
```

### SELECT - Raw SQL sorgusu
```json
POST /api/test.jsp
{
    "sql": "SELECT u.name, o.total FROM users u JOIN orders o ON u.id = o.user_id"
}
```

### UPDATE
```json
POST /api/update.jsp
{
    "table": "users",
    "set": {
        "name": "Yeni Isim",
        "email": "yeni@mail.com"
    },
    "where": {
        "id": "5"
    }
}
```

### AUTHENTICATE
```json
POST /api/authenticate.jsp
{
    "table": "users",
    "where": {
        "username": "admin",
        "password": "123456"
    },
    "set": {
        "token": "--token--",
        "ip_address": "--ip--"
    }
}
```

---

## Kodda Gozlemlenen Spesifik Pattern'ler

| Pattern | Kodda Nerede | Aciklama |
|---------|-------------|----------|
| `Scanner(inputStream).useDelimiter("\\A")` | `Json.jsp:35` | InputStream'i tek seferde String'e cevirir |
| `ResultSetMetaData` ile dinamik kolon okuma | `Postgre.jsp:74-83` | Herhangi bir tablo icin generic calismasi |
| `UUID.randomUUID().toString()` | `Request.jsp:22` | Token uretimi |
| `InetAddress.getLocalHost().getHostAddress()` | `authenticate.jsp:21-22` | Sunucu IP adresini alma |
| `<%@include %>` ile sinif dahil etme | Tum endpoint'ler | Compile-time dosya birlestirme |
| `<%@ page errorPage="..." %>` | `authenticate.jsp:8` | JSP hata yonlendirmesi |
| `PreparedStatement` kullanimi | `Postgre.jsp:119-122` | Sadece update'de kullanilmis |
| `RBucket` ile Redis key-value | `Redis.jsp:33-34` | Redisson'un temel veri yapisi |
| MongoDB `Document` builder pattern | `Mongo.jsp:80-86` | Fluent API ile dokuman olusturma |
| `set.replace("--token--", token)` | `authenticate.jsp:28-29` | Placeholder pattern ile dinamik deger |

---

## Kullanilan Teknolojiler ve Kaynaklar

Proje gelistirilirken spesifik bir "tek kaynak" uzerinden ilerlenmedil. Daha cok asagidaki konulara bakilarak ilerlenmis:

### Temel Konular

**JSP Lifecycle ve Scriptlet Yapisi**
- JSP'nin aslinda bir Servlet'e compile edildigini anlamak temel. Oracle'in eski JSP dokumantasyonlari bu konuda en iyi kaynak.
- [Oracle JSP Tutorial](https://docs.oracle.com/javaee/5/tutorial/doc/bnagx.html)
- [Jakarta EE - JSP Spesifikasyonu](https://jakarta.ee/specifications/pages/)
- [JavaPoint JSP Tutorial](https://www.javatpoint.com/jsp-include-directive)

**Servlet-JSP Iliskisi**
- JSP'nin arkasinda Servlet-JSP iliskisi yatiyor. Her JSP dosyasi compile edildiginde bir Servlet sinifi olusur.
- Scriptlet icindeki Java kodu servlet'in `service()` metodu icinde calisir.

**JDBC ile Dinamik Query Olusturma**
- Dogrudan `java.sql.*` kullanilarak veritabanina erisim. ORM (Hibernate, JPA) kullanilmamis.
- [PostgreSQL JDBC Driver](https://jdbc.postgresql.org/documentation/)
- [Baeldung - JDBC ile PostgreSQL](https://www.baeldung.com/java-connect-postgresql)
- [Oracle JDBC Tutorial](https://docs.oracle.com/javase/tutorial/jdbc/)

**JSONObject / JSONArray Kullanimi**
- `org.json` kutuphanesi ile JSON isleme.
- [GitHub - stleary/JSON-java](https://github.com/stleary/JSON-java)
- [Baeldung - org.json](https://www.baeldung.com/java-org-json)

### Servis Entegrasyonlari

**Redisson ile Redis**
- Redisson client kutuphanesi. `RBucket` ile basit key-value islemleri.
- [Redisson Wiki](https://github.com/redisson/redisson/wiki/Table-of-Content) (kodda referans verilmis)
- [Baeldung - Redisson](https://www.baeldung.com/redis-redisson)

**MongoDB Java Driver**
- Senkron driver ile loglama.
- [MongoDB Java Driver](https://www.mongodb.com/docs/drivers/java/sync/current/usage-examples/) (kodda referans verilmis)
- [Baeldung - MongoDB ve Java](https://www.baeldung.com/java-mongodb)

**dotenv-java**
- Node.js ekosisteminden esinlenilmis `.env` dosyasi yonetimi.
- [GitHub - cdimascio/dotenv-java](https://github.com/cdimascio/dotenv-java)

**Docker Compose**
- [Docker Compose](https://docs.docker.com/compose/)
- [Bitnami PostgreSQL](https://hub.docker.com/r/bitnami/postgresql)
- [Bitnami Redis](https://hub.docker.com/r/bitnami/redis)

### Genel Ogrenme Kaynaklari
- **Baeldung (baeldung.com)** - Java/JSP/JDBC konularinda en populer kaynak
- **JavaPoint (javatpoint.com)** - JSP/Servlet ogretici site
- **StackOverflow** - Ozellikle `Scanner("\\A")` gibi spesifik pattern'ler
- **JSON.org** - JSON formatinin resmi sitesi

---

## Mimari Degerlendirme ve Iyilestirme Onerileri

Bu proje bir **ogrenme/prototip projesi** niteligi tasiyor. Asagida, uretim ortamina tasimak istenirse dikkat edilmesi gereken noktalar:

### 1. SQL Injection Riski
WHERE ve SET clause'lari string birlestirme ile olusturuluyor (`Json.jsp:87`, `Json.jsp:103`).

**Mevcut durum:**
```java
filter = filter + " " + key + " = '" + where.get(key) + "'";
```

**Olasi saldiri:** `{"where": {"id": "1' OR '1'='1"}}` gonderilebilir.

**Oneri:** `PreparedStatement` ile parametrik sorgulara gecilmeli. `update()` metodu zaten PreparedStatement kullaniyor - ayni yaklasim `select()` icin de uygulanmali.

### 2. Connection Pooling Yok
Her HTTP isteginde yeni bir JDBC baglantisi aciliyor (`Postgre.jsp:51`). Yogun trafik altinda bu ciddi performans sorunu olusturur.

**Oneri:** HikariCP gibi bir connection pool kutuphanesi kullanilabilir.

### 3. Kaynak Yonetimi
JDBC connection'lari her zaman kapatilmiyor. `select()` icinde `rs` ve `stmt` kapatiliyor ama `conn` hic kapatilmiyor. Bu memory leak'e yol acar.

**Oneri:** try-with-resources kullanimina gecis veya `finally` bloklarinda tum kaynaklarin kapatilmasi.

### 4. Servlet'e Gecis
JSP icerisinde class tanimlamak yerine ayri `.java` dosyalari ve Servlet'ler kullanilmali. Bu:
- IDE destegini arttirir (autocomplete, refactoring)
- Unit test yazmayi mumkun kilar
- Kod organizasyonunu iyilestirir

### 5. Hata Yonetimi
`Mongo.setAndInsert()` icinde hata olursa kendini recursive olarak cagiriyor (`Mongo.jsp:126`). Bu sonsuz donguye yol acabilir.

### 6. Uzun Vadeli Gecis
Spring Boot + JPA ile modern mimari saglanabilir. Mevcut yapidaki her katmanin Spring karsiligi zaten yukarda tabloda gosterildi.

---

## Sonuc

Bu proje, JSP'nin "sadece HTML uretir" yanilgisini kiran, alisilagelmis disinda bir yaklasim sergiliyor. JSP'yi bir JSON API engine olarak kullanarak, web gelistirmenin temel yapi taslarini (HTTP request/response, SQL, caching, loglama) soyutlama katmanlari olmadan dogrudan gosteriyor.

Spring Boot'tan geliyorsan, burada gordugum her seyin arka planda Spring'in senin icin otomatik olarak yaptigini dusun. Bu proje, o "sihrin" altindaki mekanizmayi anlaman icin degerli bir referans.
