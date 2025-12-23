# 📦 Установка Node.js на Synology

## Проблема

Node.js не установлен на Synology, что блокирует деплой backend.

## ✅ Решение: Установите Node.js

### Метод 1: Через Package Center (Самый простой) ⭐

1. Откройте DSM веб-интерфейс: `https://192.168.100.222:5001`
2. Перейдите в **Package Center**
3. Найдите **Node.js v20** (или последнюю LTS версию)
4. Нажмите **Install**
5. Дождитесь установки

### Метод 2: Через SSH (ipkg)

**Подключитесь к Synology:**

```powershell
# Попробуйте через VPS (VPN)
ssh root@159.255.37.158
ssh admin@10.8.0.2

# Или напрямую (если SSH работает)
ssh admin@192.168.100.222
```

**На Synology выполните:**

```bash
# Установка ipkg (если не установлен)
cd /tmp
wget http://ipkg.nslu2-linux.org/feeds/optware/syno-i686/cross/unstable/syno-i686-bootstrap_1.2-7_i686.xsh
sh syno-i686-bootstrap_1.2-7_i686.xsh

# Обновление пакетов
ipkg update

# Установка Node.js
ipkg install node
```

### Метод 3: Ручная установка через nvm

**На Synology:**

```bash
# Установка nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Перезагрузка shell
source ~/.bashrc

# Установка Node.js 20
nvm install 20
nvm use 20
nvm alias default 20

# Проверка
node -v
npm -v
```

### Метод 4: Использовать готовый скрипт

**Скопируйте скрипт на Synology:**

```powershell
# С вашего компьютера
scp backend\deploy\install_nodejs_synology.sh root@159.255.37.158:/tmp/
ssh root@159.255.37.158
scp /tmp/install_nodejs_synology.sh admin@10.8.0.2:/tmp/
ssh admin@10.8.0.2
bash /tmp/install_nodejs_synology.sh
```

## ✅ После установки Node.js

**Проверьте установку:**

```bash
node -v
npm -v
```

**Затем запустите деплой снова:**

```bash
cd /volume1/shortsai/app/backend
bash /tmp/synology_deploy.sh
```

## 🔍 Где находится Node.js на Synology

После установки через Package Center, Node.js обычно находится в:
- `/volume1/@appstore/Node.js_v20/usr/local/bin/node`
- `/usr/local/bin/node` (символическая ссылка)

Добавьте в PATH (если нужно):

```bash
export PATH="/volume1/@appstore/Node.js_v20/usr/local/bin:$PATH"
```

---

**После установки Node.js, деплой должен продолжиться! 🚀**





