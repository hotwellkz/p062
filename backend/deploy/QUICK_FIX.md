# 🔧 Быстрое исправление для Windows

## Проблема 1: PowerShell требует `.\` перед именем файла

**Неправильно:**
```powershell
START_DEPLOY.bat
```

**Правильно:**
```powershell
.\START_DEPLOY.bat
```

## Проблема 2: Неправильный путь к файлам

Если вы находитесь в `backend/deploy`, пути будут неправильными.

**Решение:** Вернитесь в корень проекта перед копированием файлов:

```powershell
# Вернитесь в корень проекта
cd C:\Users\studo\Downloads\p039-master\p039-master

# Теперь пути будут правильными
scp backend\vps\synology-port-forward.sh root@159.255.37.158:/root/
scp backend\deploy\synology_deploy.sh admin@192.168.100.222:/tmp/
```

## ✅ Правильная последовательность действий

### Вариант 1: Использовать batch файл

```powershell
cd C:\Users\studo\Downloads\p039-master\p039-master\backend\deploy
.\START_DEPLOY.bat
```

### Вариант 2: Ручной деплой

```powershell
# 1. Вернитесь в корень проекта
cd C:\Users\studo\Downloads\p039-master\p039-master

# 2. Настройка VPS
scp backend\vps\synology-port-forward.sh root@159.255.37.158:/root/
ssh root@159.255.37.158
# На VPS:
chmod +x /root/synology-port-forward.sh
bash /root/synology-port-forward.sh
exit

# 3. Деплой на Synology
scp backend\deploy\synology_deploy.sh admin@192.168.100.222:/tmp/
scp backend\deploy\config.sh admin@192.168.100.222:/tmp/
ssh admin@192.168.100.222
# На Synology:
chmod +x /tmp/*.sh
bash /tmp/synology_deploy.sh
```

---

**Готово! Теперь всё должно работать! 🚀**





