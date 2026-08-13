# Starter Application — เว็บกิจกรรมพัฒนานักศึกษา (สำหรับข้อสอบ POC ด้าน DevOps)

ชุดแอปพลิเคชันตั้งต้นสำหรับข้อสอบภาคปฏิบัติ (POC) ตำแหน่ง **นักวิชาการคอมพิวเตอร์ (ปฏิบัติงานด้าน DevOps และโครงสร้างพื้นฐานระบบ)**
สังกัดงานสารสนเทศนักศึกษา กองพัฒนานักศึกษาและศิษย์เก่าสัมพันธ์ สำนักงานอธิการบดี มหาวิทยาลัยสงขลานครินทร์

> **โจทย์ของผู้เข้าสอบคือการนำแอปพลิเคชันชุดนี้ขึ้นระบบ ไม่ใช่การพัฒนาแอปพลิเคชันขึ้นใหม่**
> ชุดนี้จงใจ **ไม่มี** `Dockerfile`, `docker-compose.yml`, การตั้งค่า Reverse Proxy, CI/CD Pipeline,
> ระบบเฝ้าระวัง (Monitoring) และระบบสำรองข้อมูล (Backup) — ทั้งหมดนี้คือส่วนที่ผู้เข้าสอบต้องจัดทำขึ้นเอง
> ตามข้อ 3.2 ของเอกสารข้อสอบ

---

## 1. โครงสร้างโปรเจกต์

```
starter-app-devops/
├── backend/                 # RESTful API (Node.js + Express + PostgreSQL)
│   ├── src/
│   │   ├── app.js           # ประกอบ Express app และ route ทั้งหมด
│   │   ├── server.js        # จุดเริ่มโปรแกรม + graceful shutdown
│   │   ├── config.js        # อ่านค่าตั้งค่าจาก Environment Variable
│   │   ├── db.js            # Connection pool ของ PostgreSQL
│   │   └── validation.js    # ฟังก์ชันตรวจสอบข้อมูล (ไม่พึ่งฐานข้อมูล)
│   ├── tests/
│   │   └── validation.test.js   # ชุดทดสอบอัตโนมัติ (รันได้โดยไม่ต้องมีฐานข้อมูล)
│   ├── eslint.config.js
│   └── package.json
├── frontend/                # หน้าเว็บ (HTML/CSS/JavaScript ล้วน ไม่ต้อง build)
│   ├── index.html
│   ├── styles.css
│   └── app.js
├── db/
│   └── init.sql             # สร้างตาราง + ข้อมูลตัวอย่าง 16 กิจกรรม
├── .env.example
└── README.md
```

---

## 2. ความต้องการของระบบ (สำหรับรันแบบไม่ใช้ Container)

- Node.js 20 ขึ้นไป
- PostgreSQL 14 ขึ้นไป

---

## 3. วิธีรันแบบไม่ใช้ Container (เพื่อทำความเข้าใจระบบก่อนนำขึ้น Container)

### 3.1 เตรียมฐานข้อมูล

```bash
createdb psu_activities
psql -d psu_activities -f db/init.sql
```

### 3.2 ตั้งค่า Environment Variable

```bash
cp .env.example backend/.env
# แก้ไขค่าใน backend/.env ให้ตรงกับฐานข้อมูลของเครื่องตนเอง
```

### 3.3 รัน Back-end

```bash
cd backend
npm install
npm start           # ให้บริการที่ http://localhost:3001
```

### 3.4 รัน Front-end

หน้าเว็บเป็นไฟล์สแตติกล้วน ให้บริการด้วย Web Server ใดก็ได้ เช่น

```bash
cd frontend
npx serve -l 8080   # เปิดที่ http://localhost:8080
```

Front-end อ่านที่อยู่ของ API จาก `window.API_BASE_URL` ซึ่งกำหนดไว้ในไฟล์ `frontend/index.html`
ค่าเริ่มต้นคือ `/api` (เรียกผ่าน Reverse Proxy) หากรันแยกกันโดยไม่มี Reverse Proxy
ให้แก้เป็น `http://localhost:3001/api` ชั่วคราว

### 3.5 คำสั่งอื่น ๆ

```bash
cd backend
npm test            # รันชุดทดสอบอัตโนมัติ (ไม่ต้องมีฐานข้อมูล)
npm run lint        # ตรวจสอบคุณภาพโค้ด
```

---

## 4. ตัวแปรตั้งค่า (Environment Variable)

ดูรายการทั้งหมดในไฟล์ `.env.example` โดยตัวแปรที่จำเป็นคือ

| ตัวแปร | ค่าเริ่มต้น | คำอธิบาย |
|--------|------------|----------|
| `PORT` | `3001` | พอร์ตที่ Back-end ให้บริการ |
| `DATABASE_URL` | — | Connection string ของ PostgreSQL (ใช้แทน `PG*` ทั้งชุดได้) |
| `PGHOST` | `localhost` | โฮสต์ของฐานข้อมูล |
| `PGPORT` | `5432` | พอร์ตของฐานข้อมูล |
| `PGDATABASE` | `psu_activities` | ชื่อฐานข้อมูล |
| `PGUSER` | `postgres` | ชื่อผู้ใช้ฐานข้อมูล |
| `PGPASSWORD` | — | รหัสผ่านฐานข้อมูล |
| `CORS_ORIGIN` | `*` | Origin ที่อนุญาตให้เรียก API |
| `LOG_LEVEL` | `info` | ระดับการบันทึก Log (`debug` / `info` / `error`) |

> **ห้าม commit ไฟล์ `.env` ที่มีค่าจริงลงใน Repository** ให้ใช้ `.env.example` เป็นแม่แบบเท่านั้น

---

## 5. รายการ API

Base path ของ API คือ `/api`

| วิธี | Endpoint | คำอธิบาย |
|------|----------|----------|
| GET | `/api/health` | ตรวจสอบสถานะของบริการและการเชื่อมต่อฐานข้อมูล |
| GET | `/api/activities` | รายการกิจกรรม (รองรับ `page`, `limit`, `q`, `category`, `sort`, `order`) |
| GET | `/api/activities/:id` | รายละเอียดกิจกรรมตาม id |
| GET | `/api/categories` | รายชื่อประเภทกิจกรรมทั้งหมด |
| GET | `/api/registrations?activityId=:id` | รายชื่อผู้ลงทะเบียนของกิจกรรมนั้น |
| POST | `/api/registrations` | บันทึกการลงทะเบียนเข้าร่วมกิจกรรม |

### ตัวอย่างการเรียกใช้

```bash
curl http://localhost:3001/api/health
curl "http://localhost:3001/api/activities?page=1&limit=9&category=กีฬา"
curl "http://localhost:3001/api/activities?q=อาสา"
curl http://localhost:3001/api/activities/1
curl "http://localhost:3001/api/registrations?activityId=1"

curl -X POST http://localhost:3001/api/registrations \
  -H "Content-Type: application/json" \
  -d '{"fullName":"สมชาย ใจดี","studentId":"6510110001","faculty":"คณะวิศวกรรมศาสตร์","email":"student@example.com","phone":"0812345678","activityId":1,"consent":true}'
```

### รูปแบบผลลัพธ์

`GET /api/activities` ตอบกลับพร้อมข้อมูลการแบ่งหน้า และส่ง header `X-Total-Count`

```json
{
  "data": [ { "id": 1, "title": "...", "category": "...", "date": "...", "location": "...", "capacity": 80 } ],
  "page": 1,
  "limit": 9,
  "total": 16
}
```

`GET /api/health` ตอบกลับ HTTP 200 เมื่อระบบปกติ และ HTTP 503 เมื่อเชื่อมต่อฐานข้อมูลไม่ได้

```json
{ "status": "ok", "database": "up", "uptimeSeconds": 42, "version": "1.0.0" }
```

---

## 6. ข้อมูลตัวอย่าง

`db/init.sql` สร้างตาราง 2 ตาราง คือ `activities` และ `registrations`
พร้อมข้อมูลกิจกรรมตัวอย่าง **16 รายการ** ครอบคลุม 5 ประเภท
(อบรม/สัมมนา, จิตอาสา, กีฬา, ศิลปวัฒนธรรม, พัฒนาทักษะอาชีพ)
และข้อมูลการลงทะเบียนตัวอย่างจำนวนหนึ่ง เพื่อให้ทดสอบการค้นหา การกรอง การแบ่งหน้า
และการสำรอง/กู้คืนข้อมูลได้

ไฟล์นี้สามารถนำไปใช้เป็น initialization script ของ PostgreSQL container ได้โดยตรง

---

## 7. ข้อควรทราบสำหรับผู้เข้าสอบ

- **ห้ามแก้ไขตรรกะการทำงานหลัก** ของแอปพลิเคชัน แก้ไขได้เท่าที่จำเป็นต่อการนำขึ้นระบบ
  เช่น การอ่านค่าตั้งค่าเพิ่มเติมจาก Environment Variable หรือการเพิ่ม Health Check
  โดยให้ระบุรายการที่แก้ไขไว้ใน README ของผลงานตนเอง
- แอปพลิเคชันนี้อ่านค่าตั้งค่าทั้งหมดจาก Environment Variable อยู่แล้ว
  จึงพร้อมสำหรับการนำไปใส่ Container โดยไม่ต้องแก้ซอร์สโค้ด
- `GET /api/health` มีไว้ให้ใช้กับ `HEALTHCHECK` ของ Container และระบบเฝ้าระวัง
- Back-end พิมพ์ Log ออกทาง stdout/stderr ในรูปแบบ JSON บรรทัดละรายการ
  เพื่อให้รวบรวมเข้าสู่ระบบจัดการ Log ได้สะดวก

---

## คำตอบและแนวทางการดำเนินงาน

แนวทางที่เลือกใช้คือการนำแอปพลิเคชันเดิมขึ้นให้บริการในรูปแบบ Container โดยแยกหน้าที่ของ
Front-end, Back-end และฐานข้อมูลออกจากกันอย่างชัดเจน พร้อมจัดทำ Reverse Proxy, CI/CD,
Monitoring, Logging และระบบ Backup/Restore ให้ครบถ้วนตามขอบเขตงานด้าน DevOps

การดำเนินงานมุ่งรักษา business logic และ API contract เดิมทั้งหมด การเปลี่ยนแปลงจึงอยู่ใน
ส่วนของโครงสร้างพื้นฐาน การกำหนดค่า และเครื่องมือปฏิบัติการเท่านั้น โดยไฟล์หลักที่จัดทำเพิ่ม ได้แก่
`compose.yaml`, Dockerfile ของแต่ละบริการ, `frontend/nginx.conf`, `monitoring/`,
`backup/`, `ops/` และ `.github/workflows/ci-cd.yml`

---

## การออกแบบสถาปัตยกรรมระบบ

สถาปัตยกรรมที่เลือกใช้มีลำดับการรับส่งข้อมูลดังนี้

```text
ผู้ใช้ :8080
    │
    ▼
Nginx (Static Front-end + Reverse Proxy /api)
    │ private app network
    ▼
Node.js / Express :3001
    │ private data network
    ▼
PostgreSQL 16 + persistent named volume
```

เหตุผลในการออกแบบมีดังนี้

- ใช้ Nginx เป็นจุดรับการเชื่อมต่อจากภายนอกเพียงจุดเดียว เพื่อให้บริการ Static Front-end
  และส่งคำขอ `/api/...` ไปยัง Back-end โดยคง prefix `/api` ตามสัญญา API เดิม
- แยกเครือข่ายเป็น `edge`, `app`, `data` และ `monitoring` เพื่อลดการเข้าถึงข้ามบริการ
  โดย Back-end และ PostgreSQL ไม่มี host port
- ใช้ named volume กับ PostgreSQL เพื่อให้ข้อมูลคงอยู่เมื่อ Container ถูกสร้างใหม่
- กำหนด Health Check ให้ Front-end, Back-end และฐานข้อมูล เพื่อใช้ควบคุมลำดับการเริ่มบริการ
  และใช้เป็นข้อมูลตรวจสอบสถานะ
- ให้ Back-end ทำงานด้วยผู้ใช้ที่ไม่ใช่ root และรองรับ `SIGTERM` เพื่อปิด HTTP server
  และฐานข้อมูล connection pool อย่างเรียบร้อย
- จำกัด Docker log ด้วย `json-file` driver ขนาด 10 MB จำนวน 5 ไฟล์ต่อบริการ

ค่าเริ่มต้นเปิดเฉพาะ Nginx ที่ `127.0.0.1:8080` ส่วนการเปิดใช้งานจริงสามารถกำหนด
`APP_BIND_ADDRESS=0.0.0.0` และวาง TLS termination หรือ Load Balancer ไว้ด้านหน้าได้

---

## การจัดทำ Container และการนำระบบขึ้นใช้งาน

Back-end image ใช้ Node.js 20 Alpine และติดตั้ง Production dependency ด้วย `npm ci --omit=dev`
เพื่อให้การติดตั้งอ้างอิง `package-lock.json` และลดขนาด image จากนั้นคัดลอกเฉพาะไฟล์ที่จำเป็น
และรันด้วยผู้ใช้ `node`

Front-end image ใช้ Nginx แบบ unprivileged เพื่อให้บริการ `index.html`, `styles.css` และ
`app.js` พร้อม Reverse Proxy ไปยัง Back-end ส่วน Backup image ใช้ PostgreSQL client
และ OpenSSL สำหรับสำรอง ตรวจสอบ และเข้ารหัสข้อมูล

`compose.yaml` ประกอบบริการหลักคือ `frontend`, `backend` และ `db` พร้อมบริการเสริม
`backup` และชุด Monitoring ที่เปิดใช้งานผ่าน Compose profiles โดยมี `restart: unless-stopped`,
health-based dependency และเวลาสำหรับ graceful shutdown

คำสั่งหลักที่ใช้ยืนยันว่า Configuration และ Container images ใช้งานได้มีดังนี้

```bash
docker compose config --quiet
docker compose build backend frontend backup
docker compose up -d --wait --wait-timeout 180
docker compose ps
```

ผลจากการตรวจสอบพบว่าบริการหลักเริ่มทำงานและผ่าน Health Check โดยมีเพียง Front-end
ที่แสดง host port `127.0.0.1:8080->8080/tcp` ตามที่ออกแบบไว้

---

## การจัดการ Configuration และข้อมูลลับ

การตั้งค่าทั้งหมดแยกออกจาก Container image และมีตัวอย่างใน `.env.example` โดยแบ่งเป็น
ค่าของ Application, Database, Images, Backup และ Monitoring ทำให้สามารถเปลี่ยนค่าตาม
Environment ได้โดยไม่ต้องแก้ source code

รหัสผ่านฐานข้อมูลและ passphrase สำหรับเข้ารหัส Backup ไม่ถูกบันทึกใน Git หรือส่งเป็น
plain environment variable แต่จัดเก็บเป็นไฟล์ต่อไปนี้และ mount เข้า Container ในรูปแบบ secret

- `secrets/postgres_password.txt`
- `secrets/backup_encryption_passphrase.txt`

ได้จัดทำ `ops/init-secrets.ps1` และ `ops/init-secrets.sh` สำหรับสร้างค่าลับแบบสุ่ม
พร้อมเพิ่มกฎใน `.gitignore` เพื่อป้องกันการ commit ไฟล์ดังกล่าว ส่วน Production ต้องนำค่า
มาจาก Secret Manager ของแพลตฟอร์ม

Back-end Container อ่านรหัสผ่านผ่าน `PGPASSWORD_FILE` ใน entrypoint ก่อนเริ่ม Node.js
ขณะที่ PostgreSQL ใช้ `POSTGRES_PASSWORD_FILE` โดยตรง วิธีนี้ทำให้ไม่ต้องฝังค่า Secret
ไว้ใน Container image หรือเขียนค่าจริงลงใน Compose configuration โดย Back-end จะกำหนด
`PGPASSWORD` จากไฟล์ Secret เฉพาะตอนเริ่ม process ภายใน Container

สำหรับการรัน Back-end นอก Container ต้อง export Environment Variable หรือเรียก
`node --env-file=.env src/server.js` เนื่องจาก Application ไม่ได้โหลดไฟล์ `.env` อัตโนมัติ

`db/init.sql` มีคำสั่ง `DROP TABLE` และข้อมูล seed จึงกำหนดให้ PostgreSQL image เรียกใช้
เฉพาะเมื่อสร้าง data volume ใหม่เท่านั้น ไฟล์นี้ไม่ถูกใช้เป็น migration หรือ restore script
และต้องไม่นำไปรันซ้ำกับฐานข้อมูล Production

---

## การทดสอบและตรวจสอบระบบ

การตรวจสอบแบ่งเป็น Quality Gate ของ source code และการตรวจสอบระบบหลัง Deploy
เพื่อให้ครอบคลุมทั้งความถูกต้องของฟังก์ชันและความพร้อมของโครงสร้างพื้นฐาน

Quality Gate ใช้คำสั่งต่อไปนี้

```bash
cd backend
npm ci
npm test
npm run lint
```

หลังเริ่มระบบได้ใช้ `ops/smoke-test.sh` ตรวจ Front-end, `/api/health`, รายการกิจกรรม,
รายละเอียดกิจกรรม และรายชื่อผู้ลงทะเบียนผ่าน Reverse Proxy

```bash
sh ops/smoke-test.sh http://127.0.0.1:8080
```

ในสภาพแวดล้อมทดสอบได้เปิด `SMOKE_WRITE_TEST=true` เพื่อตรวจ
`POST /api/registrations` เพิ่มเติม ส่วน Production กำหนดให้เป็น read-only เพื่อไม่สร้าง
ข้อมูลทดสอบในฐานข้อมูลจริง

การตรวจ Failure Case ใช้ `/api/health` ซึ่งตอบ HTTP 200 เมื่อเชื่อมต่อฐานข้อมูลได้
และออกแบบให้ตอบ HTTP 503 เมื่อฐานข้อมูลไม่พร้อม นอกจากนี้ได้สร้าง Container ใหม่ทั้งชุด
โดยไม่ลบ volume และตรวจว่าจำนวน registrations ยังคงเดิม เพื่อยืนยัน Data Persistence

---

## การเฝ้าระวังและจัดการ Log

ระบบ Monitoring ที่เลือกใช้ประกอบด้วย Prometheus, Alertmanager, Blackbox Exporter,
cAdvisor และ Node Exporter โดยเปิดใช้งานผ่าน `monitoring` profile

```bash
docker compose --profile monitoring up -d --wait --wait-timeout 240
```

Blackbox Exporter ตรวจ `/healthz` ของ Nginx และ `/api/health` ผ่านเส้นทางเดียวกับผู้ใช้
ส่วน cAdvisor และ Node Exporter เก็บ Container และ Host metrics ตามลำดับ
Node Exporter ยังอ่าน Backup metrics จาก textfile collector

`/api/health` ตรวจการเชื่อมต่อฐานข้อมูลจริง จึงใช้เป็น Readiness และ Availability Probe
ไม่ใช้เป็น Liveness Probe เพียงตัวเดียว เพราะการที่ฐานข้อมูลหยุดทำงานไม่ได้หมายความว่า
Node.js process ต้องถูก restart

Alert rules ที่จัดเตรียมไว้ครอบคลุม Monitoring target ติดต่อไม่ได้, HTTP probe ล้มเหลว,
Backup ครั้งล่าสุดล้มเหลว และไม่มี Backup สำเร็จภายใน 26 ชั่วโมง โดย Alertmanager
แสดงผลผ่าน UI เป็นค่าเริ่มต้น ส่วน Production ต้องกำหนด Email หรือ Webhook receiver
จาก Secret Manager เพิ่มเติม

Back-end เขียน Log เป็น JSON ทีละบรรทัดออก stdout/stderr โดยไม่บันทึก request body
ซึ่งอาจมีข้อมูลส่วนบุคคล ทำให้สามารถส่งต่อไปยัง Log Collector ของหน่วยงานได้โดยไม่แก้ Application

---

## การสำรองและกู้คืนข้อมูล

ระบบ Backup ใช้ `pg_dump` แบบ custom format และตรวจความสมบูรณ์เบื้องต้นด้วย
`pg_restore --list` ก่อนเข้ารหัสด้วย AES-256-CBC และ PBKDF2 จากนั้นสร้าง SHA-256 checksum
และลบไฟล์ที่หมดอายุตาม `BACKUP_RETENTION_DAYS`

```bash
docker compose --profile backup run --rm backup backup.sh
```

Backup ถูกจัดเก็บแยกจาก PostgreSQL volume โดย `BACKUP_DIR` สามารถกำหนดให้ชี้ไปยัง
Off-host storage, NAS หรือ Object-storage-mounted path ได้ การมี persistent volume
เพียงอย่างเดียวจึงไม่ถูกนับเป็นการสำรองข้อมูล

Restore script ตรวจ checksum, ถอดรหัส และตรวจ archive ก่อนสร้างฐานข้อมูลเป้าหมายใหม่
พร้อมปฏิเสธการ Restore ทับฐานข้อมูลต้นทาง

```bash
docker compose --profile backup run --rm backup \
  restore.sh /backups/psu_activities_YYYYMMDDTHHMMSSZ.dump.enc restored_psu_activities
```

ได้จัดทำ `ops/verify-backup-restore.sh` สำหรับ Restore Drill โดยสร้างฐานข้อมูล
`restore_verify_<timestamp>` เปรียบเทียบจำนวนแถวในตาราง `activities` และ `registrations`
กับฐานข้อมูลต้นทาง แล้วลบเฉพาะฐานข้อมูลทดสอบเมื่อเสร็จสิ้น

ผลของ Backup ถูกส่งออกเป็น `starter_backup_last_run_success` และ
`starter_backup_last_success_timestamp_seconds` เพื่อให้ Prometheus ตรวจสอบและแจ้งเตือนได้

---

## กระบวนการ CI/CD การ Deploy และ Rollback

ได้จัดทำ GitHub Actions workflow ให้ทำงานเมื่อเปิด Pull Request, Push ไปยัง `main`,
สร้าง Tag รูปแบบ `v*` หรือสั่งงานด้วย `workflow_dispatch`

กระบวนการ CI ประกอบด้วย

- ติดตั้ง dependency ด้วย `npm ci` และรัน Unit Test กับ ESLint
- ตรวจ Workflow, Dockerfile และ Shell Script ด้วย `actionlint`, `hadolint` และ `shellcheck`
- ตรวจ `docker compose config` และ Build Backend, Front-end และ Backup images
- Push images ไปยัง GHCR โดยใช้ Git commit SHA เป็น immutable tag

กระบวนการ CD ทำงานเมื่อกำหนด `DEPLOY_ENABLED=true` หรือสั่ง Manual Deploy
บน Self-hosted Runner ที่มี labels `self-hosted`, `linux` และ `production`
โดย GitHub Environment `production` ต้องมี `POSTGRES_PASSWORD` และ
`BACKUP_ENCRYPTION_PASSPHRASE`

ก่อน Deploy release ใหม่ หากมี image tag เดิมและกำหนด `PRE_DEPLOY_BACKUP=true`
ระบบจะสำรองฐานข้อมูล จากนั้น Pull images, เริ่มบริการ, รอ Health Check และรัน Smoke Test
หากขั้นตอนใดไม่ผ่านและมี tag ก่อนหน้า `ops/deploy.sh` จะนำค่าจาก
`.deploy/current-image-tag` กลับมาใช้งานและตรวจระบบซ้ำ

แนวทางนี้ทำให้แต่ละ Release อ้างอิงกลับไปยัง Git commit ได้ และสามารถ Rollback
โดยไม่ต้อง Build image ใหม่ระหว่างเหตุขัดข้อง

---

## สรุปผลการตรวจรับ

ตารางต่อไปนี้เป็นผลจากรอบการตรวจรับที่ดำเนินการในสภาพแวดล้อมทดสอบครั้งนี้
จำนวนข้อมูลอาจเปลี่ยนแปลงได้ในการ Deploy รอบอื่นและไม่ถือเป็นค่าตายตัวของระบบ

| รายการตรวจสอบ | วิธีตรวจสอบ | ผลที่ได้ |
|---|---|---|
| Unit Test | `npm test` | ผ่าน 11/11 Tests บน Node.js v22.17.0 |
| Code Quality | `npm run lint` | ผ่าน ไม่มี ESLint Error |
| Compose Configuration | `docker compose config --quiet` | ผ่านด้วย Docker Compose v2.35.1 |
| Container Build | `docker compose build backend frontend backup` | Backend, Front-end และ Backup images Build สำเร็จ |
| Container Health | `docker compose ps` | PostgreSQL, Back-end และ Front-end เป็น Healthy ส่วน Monitoring services ทำงานอยู่ |
| Reverse Proxy และ API | `ops/smoke-test.sh` | ผ่านทั้ง Read-only requests และ `POST /api/registrations` |
| Data Persistence | Recreate Containers โดยไม่ลบ Volume | Registrations ยังคง 36 รายการ |
| Backup และ Restore | `ops/verify-backup-restore.sh` | Restore สำเร็จและจำนวน `activities:registrations` เท่ากับ `16:36` |
| Monitoring | Query Prometheus | HTTP Probes ผ่าน 2/2 และ Backup Success Metric เท่ากับ 1 |
| Configuration Linters | `actionlint`, `hadolint`, `shellcheck` | ผ่านทั้งหมด |
| Graceful Shutdown | หยุด Back-end ด้วย `SIGTERM` | พบ Log `server_shutting_down` และ Container ปิดภายในเวลาที่กำหนด |
| Application Scope | ตรวจ Git Diff และ API | ไม่มีการแก้ Business Logic หรือ Public API |

จากผลการตรวจรับ ระบบสามารถ Build, เริ่มให้บริการ, ตรวจสอบสถานะ, รักษาข้อมูลหลังสร้าง
Container ใหม่, สำรองและกู้คืนข้อมูล รวมถึงรองรับกระบวนการ Deploy และ Rollback ได้ตามแนวทางที่ออกแบบ

สำหรับ Production ต้องกำหนด TLS, Alertmanager receiver, Off-host Backup location,
Secret Manager และ Self-hosted Runner ให้ตรงกับโครงสร้างพื้นฐานของหน่วยงานก่อนเปิดให้บริการจริง
