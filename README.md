# Smart DNS

🧩 **Smart DNS** — DNS-сервер с возможностью проксирования выбранных сайтов через ваш VPS. Аналог Comms DNS. 
Работает на связке **Adguard Home** и **Nginx**:

- **Adguard Home** обрабатывает DNS-запросы и подменяет IP для выбранных доменов.
- **Nginx** в режиме `stream` проксирует трафик к выбранным доменам на ваш VPS.

Вы указываете список доменов (например, `openai.com`, `claude.ai`, `google.com`),  
и DNS-сервер будет возвращать IP вашего VPS. Запросы пойдут в Nginx на VPS. Всё остальное работает напрямую.  
Это удобно для обхода геоблокировок сервисов. ⚠️ При блокировках на уровне провайдера или РКН метод не поможет.

---

## Структура проекта

```

smart-dns/
├── adguard/
│   ├── docker-compose.yml   # запуск Adguard Home
│   ├── domains.txt          # список доменов для проксирования
│   ├── gen_entries.sh      # генерация правил для Nginx и Adguard
│   ├── conf/                # конфигурация Adguard Home
│   └── work/                # рабочие файлы Adguard Home
└── nginx/
    └── nginx.conf           # основной конфиг с SNI-proxy

````

---

## Как это работает

1. В `domains.txt` перечисляются домены для проксирования.
2. `gen_entries.sh` генерирует из них правила для Adguard Home и Nginx.
3. Adguard Home отвечает клиенту IP-адресом VPS.
4. Nginx принимает HTTPS-запросы и перенаправляет их дальше.

---

## Быстрый старт

1. Клонируйте репозиторий:
   ```bash
   git clone https://github.com/curserio/smart-dns.git
   cd smart-dns/adguard
   ```

2. Отредактируйте `adguard/docker-compose.yml`.
   Если планируете использовать DoH/DoT, смонтируйте сертификаты:

   ```yaml
   - ../nginx/certs:/opt/certs
   ```

   Подробности по Adguard Home — [на docker hub](https://hub.docker.com/r/adguard/adguardhome).

3. Запустите Adguard Home:

   ```bash
   docker-compose up -d
   ```

4. Проведите первичную настройку: откройте `http://<IP_VPS>:3000`.
   После этого админка будет доступна на `http://<IP_VPS>:8080`.

5. Если используете DNS-over-HTTPS, убедитесь, что порт в `docker-compose.yml` и `nginx.conf` совпадает.
   Пример:

   ```
   dns.example.com   127.0.0.1:9443;
   ```

6. Настройте `nginx/nginx.conf` (секция `stream`).
   Домены в `map` — это белый список для проксирования.

7. Укажите домены в `domains.txt`.
   Или отредактировать вручную (`nginx.conf` и админка Adguard → DNS rewrites), либо воспользоваться скриптом:

   ```bash
   ./gen_entries.sh domains.txt <IP_VPS>
   ```

   Результат нужно вставить:

   * **Adguard rewrites** в `adguard/conf/AdGuardHome.yaml` → секция `filtering` (rewrites)
   * **NGINX map entries** в `nginx/nginx.conf` → секция `map`

8. Перезапустите Nginx и Adguard Home.

---

## Дополнительно

* На том же Nginx можно запускать свои сайты.
  Для этого добавьте домен в `map` (например, `one.example.com 127.0.0.1:8443;`)
  и настройте отдельный `server` с проксированием на порт `8443`.
* Поддерживаются зашифрованные DNS (DoH/DoT).
* Adguard Home даёт бонусом блокировку рекламы и трекеров.
